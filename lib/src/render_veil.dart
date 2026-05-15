import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'veil_notifier.dart';

/// The core [RenderObject] that applies the greyscale filter, blur,
/// colour overlay, and `Unveiled` child overdraw for a `Veil` widget.
///
/// ### Paint pipeline (4 steps)
///
/// 1. **Greyscale** — the entire subtree is composited through a
///    `ColorFilterLayer` built from the ITU-R BT.709 luminance matrix,
///    lerped by [greyAmount].
/// 2. **Blur** — a `BackdropFilterLayer` applies gaussian blur at [blurAmount]
///    sigma over the greyscale result.
/// 3. **Overlay** — a solid [overlayColor] rect is painted at [overlayAmount]
///    opacity via an `OpacityLayer`.
/// 4. **Unveiled overdraw** — each [RenderRepaintBoundary] registered in
///    [notifier] is re-painted on top of all layers, unfiltered and undimmed,
///    clipped to its own bounds via `pushClipRect`.
///
/// ### Why `pushColorFilter` / `pushOpacity` / `pushClipRect`?
///
/// Raw `canvas.saveLayer` / `canvas.restore` crashes with
/// _"native peer has been collected"_ when a child [RepaintBoundary] is
/// composited mid-paint. Flutter's compositing primitives always supply
/// a fresh, valid `PaintingContext` into their callbacks and are immune to
/// this race condition.
///
/// ### Why `isRepaintBoundary` is always `true`
///
/// Toggling it based on runtime state causes Flutter's
/// `PipelineOwner.flushPaint` to assert `'node.isRepaintBoundary': is not true`
/// when the animation crosses zero after the node was already queued as a
/// repaint boundary. Keeping it permanently `true` is safe — [paint]'s fast
/// path handles the zero-effect case with negligible overhead.
class RenderVeil extends RenderProxyBox {
  /// Creates a [RenderVeil].
  RenderVeil({
    required double greyAmount,
    required double blurAmount,
    required double overlayAmount,
    required Color overlayColor,
    required VeilNotifier notifier,
  })  : _greyAmount = greyAmount,
        _blurAmount = blurAmount,
        _overlayAmount = overlayAmount,
        _overlayColor = overlayColor,
        _notifier = notifier {
    notifier.addListener(markNeedsPaint);
  }

  // ── BT.709 luminance colour matrices ─────────────────────────────────────

  static const List<double> _kGreyMatrix = [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0,      0,      0,      1, 0,
  ];

  static const List<double> _kIdentityMatrix = [
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  // ── Precision thresholds ──────────────────────────────────────────────────

  /// Below this value the greyscale filter is skipped entirely.
  static const double _kEffectivelyZero = 0.001;

  /// At or above this value the exact const [_kGreyMatrix] is used.
  static const double _kEffectivelyOne = 0.999;

  // ── Zero-allocation caches ────────────────────────────────────────────────

  /// Pre-allocated 20-element buffer written in-place by [_lerpMatrix].
  final List<double> _matrixBuffer = List<double>.filled(20, 0);

  /// Cached [ColorFilter] — rebuilt only when [greyAmount] changes.
  ColorFilter? _cachedColorFilter;

  /// The [greyAmount] at which [_cachedColorFilter] was last built.
  double _cachedColorFilterAmount = -1;

  /// Cached [ImageFilter] for blur — rebuilt only when [blurAmount] changes.
  ImageFilter? _cachedBlurFilter;

  /// The [blurAmount] at which [_cachedBlurFilter] was last built.
  double _cachedBlurAmount = -1;

  /// Cached overlay [Paint] — rebuilt only when [overlayColor] changes.
  late Paint _overlayPaint = Paint()..color = _overlayColor; // coverage:ignore-line

  // ── greyAmount ────────────────────────────────────────────────────────────

  double _greyAmount; // coverage:ignore-line

  /// Current greyscale intensity in `[0.0, 1.0]`.
  double get greyAmount => _greyAmount; // coverage:ignore-line

  set greyAmount(double v) {
    if (_greyAmount == v) return;
    _greyAmount = v;
    markNeedsPaint();
  }

  // ── blurAmount ────────────────────────────────────────────────────────────

  double _blurAmount;

  /// Current blur sigma. `0.0` = no blur.
  double get blurAmount => _blurAmount; // coverage:ignore-line

  set blurAmount(double v) {
    if (_blurAmount == v) return;
    _blurAmount = v;
    markNeedsPaint();
  }

  // ── overlayAmount ─────────────────────────────────────────────────────────

  double _overlayAmount;

  /// Current overlay opacity in `[0.0, 1.0]`.
  double get overlayAmount => _overlayAmount; // coverage:ignore-line

  set overlayAmount(double v) {
    if (_overlayAmount == v) return;
    _overlayAmount = v;
    markNeedsPaint();
  }

  // ── overlayColor ──────────────────────────────────────────────────────────

  Color _overlayColor;

  /// Opaque overlay colour (alpha always 255; opacity via [overlayAmount]).
  Color get overlayColor => _overlayColor; // coverage:ignore-line

  set overlayColor(Color v) {
    if (_overlayColor == v) return;
    _overlayColor = v;
    _overlayPaint = Paint()..color = v;
    markNeedsPaint();
  }

  // ── notifier ──────────────────────────────────────────────────────────────

  VeilNotifier _notifier;

  /// The notifier tracking `Unveiled` [RenderRepaintBoundary] descendants.
  VeilNotifier get notifier => _notifier; // coverage:ignore-line

  set notifier(VeilNotifier v) {
    if (_notifier == v) return; // coverage:ignore-line
    _notifier.removeListener(markNeedsPaint); // coverage:ignore-line
    _notifier = v; // coverage:ignore-line
    _notifier.addListener(markNeedsPaint); // coverage:ignore-line
  }

  @override
  void dispose() {
    _notifier.removeListener(markNeedsPaint);
    super.dispose();
  }

  // ── Compositing flags ─────────────────────────────────────────────────────

  @override
  bool get isRepaintBoundary => true; // coverage:ignore-line

  @override
  bool get alwaysNeedsCompositing => true; // coverage:ignore-line

  // ── Filter helpers ────────────────────────────────────────────────────────

  /// Returns a cached [ColorFilter] for [t], or `null` when negligible.
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

  /// Returns a cached [ImageFilter] for blur [sigma], or `null` when negligible.
  ImageFilter? _getBlurFilter(double sigma) {
    if (sigma <= _kEffectivelyZero) return null;
    if (_cachedBlurFilter != null &&
        (sigma - _cachedBlurAmount).abs() < 0.0001) {
      return _cachedBlurFilter;
    }
    _cachedBlurFilter = ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
      tileMode: TileMode.decal,
    );
    _cachedBlurAmount = sigma;
    return _cachedBlurFilter;
  }

  /// Lerps between [_kIdentityMatrix] and [_kGreyMatrix] in-place.
  List<double> _lerpMatrix(double t) {
    for (var i = 0; i < 20; i++) {
      _matrixBuffer[i] = lerpDouble(_kIdentityMatrix[i], _kGreyMatrix[i], t)!;
    }
    return _matrixBuffer; // coverage:ignore-line
  }

  // ── paint ─────────────────────────────────────────────────────────────────

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    final colorFilter = _getColorFilter(_greyAmount);
    final blurFilter = _getBlurFilter(_blurAmount);
    final hasOverlay = _overlayAmount > _kEffectivelyZero;

    // Fast path — all effects negligible, paint normally with zero overhead.
    if (colorFilter == null && blurFilter == null && !hasOverlay) {
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

    // ── Step 2: Blur via BackdropFilterLayer ──────────────────────────────
    // Applied on top of the greyscale result. Unveiled children with
    // UnveiledBlurMode.none are painted unblurred in Step 4.
    if (blurFilter != null) {
      context.pushLayer(
        BackdropFilterLayer(filter: blurFilter),
        (innerContext, innerOffset) {
          // Paint a transparent rect to trigger the backdrop filter.
          // The filter samples the already-painted greyscale pixels below.
          innerContext.canvas.drawRect(
            innerOffset & size,
            Paint()..color = const Color(0x00000000),
          );
        },
        offset,
      );
    }

    // ── Step 3: Colour overlay via OpacityLayer ───────────────────────────
    if (hasOverlay) {
      final alpha = (_overlayAmount * 255).round().clamp(0, 255);
      context.pushOpacity(
        offset,
        alpha,
        (innerContext, innerOffset) => innerContext.canvas.drawRect(
          (innerOffset & size).intersect(innerContext.estimatedBounds),
          _overlayPaint,
        ),
      );
    }

    // ── Step 4: Overdraw Unveiled boundaries — unfiltered and undimmed ────
    // Each Unveiled child is re-painted on top of all effects.
    // Its internal blur (if any) is self-contained via ImageFiltered widget.
    if (optOuts.isEmpty) return;

    for (final boundary in optOuts) {
      // Guard 1: boundary must still be attached to the render tree.
      if (!boundary.attached) continue;

      // Guard 2: its engine layer must be live.
      final boundaryLayer = boundary.layer;
      if (boundaryLayer == null || !boundaryLayer.attached) {
        continue; // coverage:ignore-line
      }

      // Compute boundary position in our local coordinate space.
      final transform = boundary.getTransformTo(this);
      final boundaryOffset =
          MatrixUtils.transformPoint(transform, Offset.zero) + offset;
      final boundaryRect = boundaryOffset & boundary.size;

      // Guard 3: skip if drifted outside our bounds.
      if (!myBounds.overlaps(boundaryRect)) continue; // coverage:ignore-line

      context.pushClipRect( // coverage:ignore-line
        needsCompositing, // coverage:ignore-line
        boundaryOffset, // coverage:ignore-line
        Offset.zero & boundary.size, // coverage:ignore-line
        (innerContext, innerOffset) => // coverage:ignore-line
            innerContext.paintChild(boundary, innerOffset), // coverage:ignore-line
      );
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('greyAmount', greyAmount));
    properties.add(DoubleProperty('blurAmount', blurAmount));
    properties.add(DoubleProperty('overlayAmount', overlayAmount));
    properties.add(ColorProperty('overlayColor', overlayColor));
    properties.add(IntProperty('unveiledCount', notifier.boundaries.length));
  }
}
