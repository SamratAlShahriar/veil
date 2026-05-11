// ignore_for_file: deprecated_member_use
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:veil/src/render_veil.dart';
import 'package:veil/src/veil_notifier.dart';
import 'package:veil/src/veil_scope.dart';

/// Applies an animated greyscale and optional colour overlay effect to [child].
///
/// Any descendant wrapped in `Unveiled` remains full-colour and is unaffected
/// by the overlay — even while the effect is animating.
///
/// ### How it works
///
/// Internally uses `RenderVeil` — a custom [RenderObject] that:
/// 1. Paints the entire subtree through a `ColorFilterLayer` (greyscale).
/// 2. Paints an `OpacityLayer` tinted with [overlayColor] on top.
/// 3. Re-paints each `Unveiled` child on top of both layers — unfiltered
///    and undimmed — using its cached [RenderRepaintBoundary].
///
/// All compositing uses Flutter's own primitives (`pushColorFilter`,
/// `pushOpacity`, `pushClipRect`) rather than raw `canvas.saveLayer` /
/// `canvas.restore`, making it immune to the _"native peer collected"_ crash
/// that occurs when a child [RepaintBoundary] is composited mid-paint.
///
/// ### Performance
///
/// - The [ColorFilter] and overlay [Paint] are cached and only rebuilt when
///   their inputs actually change — zero heap allocations per animation frame
///   at steady state.
/// - The greyscale colour matrix is pre-allocated and written in-place.
/// - `isRepaintBoundary` is permanently `true` to satisfy Flutter's
///   `PipelineOwner.flushPaint` invariant — toggling it dynamically causes an
///   assertion failure when the animation crosses zero mid-frame.
///
/// ### Example
///
/// ```dart
/// Veil(
///   enable: isSoldOut,
///   greyOpacity: 1.0,
///   overlayOpacity: 0.35,
///   overlayColor: Colors.black,
///   duration: Duration(milliseconds: 400),
///   child: ProductCard(
///     child: Column(
///       children: [
///         ProductImage(),     // greyscale + dimmed
///         ProductTitle(),     // greyscale + dimmed
///         Unveiled(           // full colour, not dimmed
///           child: PriceTag(),
///         ),
///         Unveiled(           // full colour, not dimmed
///           child: AddToCartButton(),
///         ),
///       ],
///     ),
///   ),
/// )
/// ```
class Veil extends StatefulWidget {
  /// Creates a [Veil].
  ///
  /// Both [greyOpacity] and [overlayOpacity] must be between `0.0` and `1.0`.
  const Veil({
    super.key,
    required this.child,
    this.enable = true,
    this.greyOpacity = 1.0,
    this.overlayOpacity = 0.0,
    this.overlayColor = const Color(0xFF000000),
    this.duration = const Duration(milliseconds: 350),
    this.curve = Curves.easeInOut,
  })  : assert(
          greyOpacity >= 0.0 && greyOpacity <= 1.0,
          'greyOpacity must be between 0.0 and 1.0',
        ),
        assert(
          overlayOpacity >= 0.0 && overlayOpacity <= 1.0,
          'overlayOpacity must be between 0.0 and 1.0',
        );

  /// The widget subtree to apply the veil effect to.
  final Widget child;

  /// Whether the veil effects are active.
  ///
  /// Toggling animates the transition over [duration] using [curve].
  final bool enable;

  /// Greyscale intensity when [enable] is `true`.
  ///
  /// `1.0` = fully greyscale (default), `0.0` = original colours retained.
  ///
  /// Uses ITU-R BT.709 luminance coefficients for perceptually accurate
  /// greyscale conversion matching the sRGB colour space.
  final double greyOpacity;

  /// Opacity of the colour overlay painted on top of the greyscale effect.
  ///
  /// `0.0` = no overlay (default), `1.0` = fully opaque.
  ///
  /// The overlay colour is set via [overlayColor]. `Unveiled` children are
  /// **not** affected by the overlay.
  final double overlayOpacity;

  /// Colour of the overlay tint. Defaults to opaque black.
  ///
  /// The alpha channel of this [Color] is intentionally ignored — overlay
  /// transparency is controlled exclusively by [overlayOpacity], keeping
  /// the two concerns orthogonal and predictable.
  ///
  /// Common values:
  /// - `Colors.black` — classic dim / disabled look (default)
  /// - `Colors.orange` — warm "out of season" tint
  /// - `Color(0xFF1A237E)` — cool "coming soon" blue tint
  final Color overlayColor;

  /// Duration of the enable / disable transition animation.
  final Duration duration;

  /// Curve applied to the enable / disable transition animation.
  final Curve curve;

  @override
  State<Veil> createState() => _VeilState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<bool>('enable', enable));
    properties.add(DoubleProperty('greyOpacity', greyOpacity));
    properties.add(DoubleProperty('overlayOpacity', overlayOpacity));
    properties.add(ColorProperty('overlayColor', overlayColor));
    properties.add(DiagnosticsProperty<Duration>('duration', duration));
    properties.add(DiagnosticsProperty<Curve>('curve', curve));
  }
}

class _VeilState extends State<Veil> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  final VeilNotifier _notifier = VeilNotifier();

  // Cached opaque overlay colour — recomputed only when overlayColor changes,
  // not on every build() call during animation (60+ times per second).
  late Color _opaqueOverlayColor;

  @override
  void initState() {
    super.initState();
    _opaqueOverlayColor = _toOpaque(widget.overlayColor);
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: widget.enable ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  @override
  void didUpdateWidget(Veil old) {
    super.didUpdateWidget(old);

    if (old.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (old.curve != widget.curve) {
      _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    }
    if (old.enable != widget.enable) {
      widget.enable ? _controller.forward() : _controller.reverse();
    }
    if (old.overlayColor != widget.overlayColor) {
      _opaqueOverlayColor = _toOpaque(widget.overlayColor);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _notifier.dispose();
    super.dispose();
  }

  /// Strips the alpha from [color] so overlay transparency is driven solely
  /// by `overlayOpacity`, keeping both concerns orthogonal.
  static Color _toOpaque(Color color) => color.withAlpha(255);

  @override
  Widget build(BuildContext context) {
    return VeilScope(
      notifier: _notifier,
      child: AnimatedBuilder(
        animation: _animation,
        // Hoist child so the subtree is not rebuilt on every animation tick.
        child: widget.child,
        builder: (_, child) => _VeilRenderObjectWidget(
          greyAmount: _animation.value * widget.greyOpacity,
          overlayAmount: _animation.value * widget.overlayOpacity,
          overlayColor: _opaqueOverlayColor,
          notifier: _notifier,
          child: child!,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERNAL: _VeilRenderObjectWidget
//
// Bridges the widget tree and `RenderVeil`. Passes updated properties to the
// render object via [updateRenderObject] without triggering a widget rebuild.
// ─────────────────────────────────────────────────────────────────────────────

class _VeilRenderObjectWidget extends SingleChildRenderObjectWidget {
  const _VeilRenderObjectWidget({
    required this.greyAmount,
    required this.overlayAmount,
    required this.overlayColor,
    required this.notifier,
    required super.child,
  });

  final double greyAmount;
  final double overlayAmount;
  final Color overlayColor;
  final VeilNotifier notifier;

  @override
  RenderVeil createRenderObject(BuildContext context) => RenderVeil(
        greyAmount: greyAmount,
        overlayAmount: overlayAmount,
        overlayColor: overlayColor,
        notifier: notifier,
      );

  @override
  void updateRenderObject(BuildContext context, RenderVeil ro) {
    ro
      ..greyAmount = greyAmount
      ..overlayAmount = overlayAmount
      ..overlayColor = overlayColor
      ..notifier = notifier;
  }
}
