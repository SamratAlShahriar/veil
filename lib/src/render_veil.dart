import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:veil/veil.dart';

import 'veil_notifier.dart';

/// The core [RenderObject] that applies the greyscale filter, colour overlay,
/// and [Unveiled] child overdraw for a [Veil] widget.
///
/// ### Paint pipeline (3 steps)
///
/// 1. **Greyscale** — the entire subtree is composited through a
///    [ColorFilterLayer] built from the ITU-R BT.709 luminance matrix,
///    lerped by [greyAmount].
/// 2. **Overlay** — a solid [overlayColor] rect is painted at [overlayAmount]
///    opacity via an [OpacityLayer].
/// 3. **Unveiled overdraw** — each [RenderRepaintBoundary] registered in
///    [notifier] is re-painted on top of both layers, unfiltered and undimmed,
///    clipped to its own bounds via `pushClipRect`.
///
/// ### Why `pushColorFilter` / `pushOpacity` / `pushClipRect`?
///
/// Raw `canvas.saveLayer` / `canvas.restore` crashes with
/// _"native peer has been collected"_ when a child [RepaintBoundary] is
/// composited mid-paint — Flutter's `_compositeChild` finalises the current
/// `Picture` and disposes the underlying native canvas, invalidating any
/// local `canvas` reference. Flutter's compositing primitives always supply
/// a fresh, valid `PaintingContext` into their callbacks and are immune to
/// this race condition.
///
/// ### Why `isRepaintBoundary` is always `true`
///
/// Toggling it based on runtime state (e.g. `greyAmount > 0`) causes
/// Flutter's `PipelineOwner.flushPaint` to fire the assertion
/// `'node.isRepaintBoundary': is not true` when the animation crosses zero
/// after the node was already queued as a repaint boundary. Keeping it
/// permanently `true` is safe — [paint]'s fast path handles the zero-effect
/// case with negligible overhead.
class RenderVeil extends RenderProxyBox {
  /// Creates a [RenderVeil].
  RenderVeil({
    required double greyAmount,
    required double overlayAmount,
    required Color overlayColor,
    required VeilNotifier notifier,
  })  : _greyAmount = greyAmount,
        _overlayAmount = overlayAmount,
        _overlayColor = overlayColor,
        _notifier = notifier {
    notifier.addListener(markNeedsPaint);
  }

  // ── BT.709 luminance colour matrices ─────────────────────────────────────
  // ITU-R BT.709 coefficients (R=0.2126, G=0.7152, B=0.0722) provide
  // perceptually accurate greyscale matching the sRGB colour space.

  static const List<double> _kGreyMatrix = [
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  static const List<double> _kIdentityMatrix = [
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ];

  // ── Precision thresholds ──────────────────────────────────────────────────

  /// Below this value the greyscale filter is skipped entirely, guaranteeing
  /// pixel-perfect original colours with no floating-point drift from a
  /// near-identity matrix.
  static const double _kEffectivelyZero = 0.001;

  /// At or above this value the exact const [_kGreyMatrix] is used rather
  /// than a lerped matrix, avoiding floating-point drift at full greyscale.
  static const double _kEffectivelyOne = 0.999;

  // ── Zero-allocation caches ────────────────────────────────────────────────

  /// Pre-allocated 20-element buffer written in-place by [_lerpMatrix].
  /// Reused every animation frame — zero heap allocations.
  final List<double> _matrixBuffer = List<double>.filled(20, 0);

  /// Cached [ColorFilter]. Rebuilt only when [greyAmount] changes.
  ColorFilter? _cachedColorFilter;

  /// The [greyAmount] value at which [_cachedColorFilter] was last built.
  double _cachedColorFilterAmount = -1;

  /// Cached overlay [Paint]. Rebuilt only when [overlayColor] changes.
  late Paint _overlayPaint = Paint()..color = _overlayColor;

  // ── greyAmount ────────────────────────────────────────────────────────────

  double _greyAmount;

  /// Current greyscale intensity in `[0.0, 1.0]`.
  double get greyAmount => _greyAmount;

  set greyAmount(double v) {
    if (_greyAmount == v) return;
    _greyAmount = v;
    markNeedsPaint();
  }

  // ── overlayAmount ─────────────────────────────────────────────────────────

  double _overlayAmount;

  /// Current overlay opacity in `[0.0, 1.0]`.
  double get overlayAmount => _overlayAmount;

  set overlayAmount(double v) {
    if (_overlayAmount == v) return;
    _overlayAmount = v;
    markNeedsPaint();
  }

  // ── overlayColor ──────────────────────────────────────────────────────────

  Color _overlayColor;

  /// Opaque overlay colour (alpha is always 255; opacity is [overlayAmount]).
  Color get overlayColor => _overlayColor;

  set overlayColor(Color v) {
    if (_overlayColor == v) return;
    _overlayColor = v;
    _overlayPaint = Paint()..color = v;
    markNeedsPaint();
  }

  // ── notifier ──────────────────────────────────────────────────────────────

  VeilNotifier _notifier;

  /// The notifier tracking [Unveiled] [RenderRepaintBoundary] descendants.
  VeilNotifier get notifier => _notifier;

  set notifier(VeilNotifier v) {
    if (_notifier == v) return;
    _notifier.removeListener(markNeedsPaint);
    _notifier = v;
    _notifier.addListener(markNeedsPaint);
  }

  @override
  void dispose() {
    _notifier.removeListener(markNeedsPaint);
    super.dispose();
  }

  // ── Compositing flags ─────────────────────────────────────────────────────

  /// Always `true` — see class-level documentation for why this must not
  /// toggle dynamically.
  @override
  bool get isRepaintBoundary => true;

  @override
  bool get alwaysNeedsCompositing => true;

  // ── Matrix / filter helpers ───────────────────────────────────────────────

  /// Returns a cached [ColorFilter] for [t], or `null` when [t] is
  /// negligibly small (fast path — no filter applied).
  ///
  /// The cache means no [ColorFilter] allocation occurs on frames where only
  /// [overlayAmount] is changing (e.g. overlay-only animation).
  ColorFilter? _getColorFilter(double t) {
    if (t <= _kEffectivelyZero) return null;
    if (_cachedColorFilter != null &&
        (t - _cachedColorFilterAmount).abs() < 0.0001) {
      return _cachedColorFilter;
    }
    final matrix = t >= _kEffectivelyOne ? _kGreyMatrix : _lerpMatrix(t);
    _cachedColorFilter = ColorFilter.matrix(matrix);
    _cachedColorFilterAmount = t;
    return _cachedColorFilter;
  }

  /// Lerps between [_kIdentityMatrix] and [_kGreyMatrix] into [_matrixBuffer]
  /// in-place and returns the buffer (zero allocation).
  List<double> _lerpMatrix(double t) {
    for (var i = 0; i < 20; i++) {
      _matrixBuffer[i] = lerpDouble(_kIdentityMatrix[i], _kGreyMatrix[i], t)!;
    }
    return _matrixBuffer;
  }

  // ── paint ─────────────────────────────────────────────────────────────────

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    final colorFilter = _getColorFilter(_greyAmount);
    final hasOverlay = _overlayAmount > _kEffectivelyZero;

    // Fast path — both effects negligible, delegate to RenderProxyBox.
    // Zero compositing overhead; the permanent repaint boundary costs nothing
    // because Flutter only repaints on explicit markNeedsPaint() calls.
    if (colorFilter == null && !hasOverlay) {
      super.paint(context, offset);
      return;
    }

    final optOuts = _notifier.boundaries;
    final myBounds = offset & size;

    // ── Step 1: Greyscale via ColorFilterLayer ────────────────────────────
    if (colorFilter != null) {
      context.pushColorFilter(
        offset,
        colorFilter,
        (innerContext, innerOffset) =>
            innerContext.paintChild(child!, innerOffset),
      );
    } else {
      context.paintChild(child!, offset);
    }

    // ── Step 2: Colour overlay via OpacityLayer ───────────────────────────
    // [Unveiled] children are painted on top in Step 3 and are therefore
    // unaffected by this overlay.
    if (hasOverlay) {
      final alpha = (_overlayAmount * 255).round().clamp(0, 255);
      context.pushOpacity(
        offset,
        alpha,
        (innerContext, innerOffset) => innerContext.canvas.drawRect(
            (innerOffset & size).intersect(innerContext.estimatedBounds),
            _overlayPaint),
      );
    }

    // ── Step 3: Overdraw Unveiled boundaries — unfiltered and undimmed ────
    if (optOuts.isEmpty) return;

    for (final boundary in optOuts) {
      // Guard 1: boundary must still be attached to the render tree.
      if (!boundary.attached) continue;

      // Guard 2: its engine layer must be live.
      final boundaryLayer = boundary.layer;
      if (boundaryLayer == null || !boundaryLayer.attached) continue;

      // Compute boundary position in our local coordinate space.
      final transform = boundary.getTransformTo(this);
      final boundaryOffset =
          MatrixUtils.transformPoint(transform, Offset.zero) + offset;
      final boundaryRect = boundaryOffset & boundary.size;

      // Guard 3: skip if drifted outside our bounds — occurs transiently
      // during scroll as layout and paint phases catch up to each other.
      if (!myBounds.overlaps(boundaryRect)) continue;

      context.pushClipRect(
        needsCompositing,
        boundaryOffset,
        Offset.zero & boundary.size,
        (innerContext, innerOffset) =>
            innerContext.paintChild(boundary, innerOffset),
      );
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('greyAmount', greyAmount));
    properties.add(DoubleProperty('overlayAmount', overlayAmount));
    properties.add(ColorProperty('overlayColor', overlayColor));
    properties.add(IntProperty('unveiledCount', notifier.boundaries.length));
  }
}
