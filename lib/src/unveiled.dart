import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'unveiled_blur_mode.dart';
import 'veil_notifier.dart';
import 'veil_scope.dart';

/// Exempts [child] from all visual effects applied by an ancestor `Veil`.
///
/// Wrap any widget inside a `Veil` with [Unveiled] to keep it rendering in
/// full colour and unaffected by the colour overlay. Blur behaviour is
/// controlled separately via [UnveiledBlurMode].
///
/// Multiple [Unveiled] widgets at any depth in the subtree are supported.
/// They do not need to be direct children of `Veil`.
///
/// ### Blur control
///
/// When the parent `Veil` has `blurSigma` set, use [blurMode] to
/// control how this specific child handles blur:
///
/// - [UnveiledBlurMode.none] — completely sharp, no blur applied
/// - [UnveiledBlurMode.inherit] — uses parent `Veil`'s sigma (default)
/// - [UnveiledBlurMode.custom] — custom sigma independent of parent
///
/// ### Behaviour outside a Veil
///
/// If [Unveiled] is used outside a `Veil`, it has no effect and simply
/// renders [child] normally. No errors are thrown.
///
/// ### Example
///
/// ```dart
/// Veil(
///   enable: isDisabled,
///   greyOpacity: 1.0,
///   blurSigma: 4.0,
///   overlayOpacity: 0.3,
///   child: Card(
///     child: Column(
///       children: [
///         ProductImage(),
///         Unveiled(
///           blurMode: UnveiledBlurMode.none,
///           child: PriceTag(),
///         ),
///         Unveiled(
///           blurMode: UnveiledBlurMode.custom(sigma: 1.5),
///           child: StatusBadge(),
///         ),
///       ],
///     ),
///   ),
/// )
/// ```
class Unveiled extends StatefulWidget {
  /// Creates an [Unveiled] widget.
  ///
  /// [blurMode] defaults to [UnveiledBlurMode.inherit] — the child inherits
  /// the parent `Veil`'s blur sigma.
  const Unveiled({
    super.key,
    required this.child,
    this.blurMode = UnveiledBlurMode.inherit,
  });

  /// The widget to exempt from `Veil` greyscale and overlay effects.
  final Widget child;

  /// Controls how blur is applied to this child when the parent `Veil`
  /// has `blurSigma` set.
  ///
  /// Defaults to [UnveiledBlurMode.inherit] — uses the parent `Veil`'s sigma.
  final UnveiledBlurMode blurMode;

  @override
  State<Unveiled> createState() => _UnveiledState();
}

class _UnveiledState extends State<Unveiled> {
  final GlobalKey _key = GlobalKey();
  VeilNotifier? _notifier;

  // Cached so dispose() can unregister even after the element is deactivated
  // (at which point _key.currentContext returns null).
  RenderRepaintBoundary? _cachedBoundary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newNotifier = VeilScope.notifierOf(context);
    if (newNotifier != _notifier) {
      _unregister();
      _notifier = newNotifier;
      _scheduleRegister();
    }
  }

  void _scheduleRegister() {
    // Capture the notifier synchronously before the async gap.
    // If dispose() fires before the callback runs, the mounted guard saves us.
    final notifier = _notifier;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || notifier == null) return;
      final ro = _key.currentContext?.findRenderObject();
      if (ro is RenderRepaintBoundary) {
        _cachedBoundary = ro;
        notifier.register(ro);
      }
    });
  }

  void _unregister() {
    if (_cachedBoundary != null) {
      _notifier?.unregister(_cachedBoundary!);
      _cachedBoundary = null;
    }
  }

  @override
  void dispose() {
    // Uses _cachedBoundary — safe even though _key.currentContext is null here.
    _unregister();
    super.dispose();
  }

  /// Resolves the effective blur sigma for this child based on `blurMode`.
  double _resolvedSigma(BuildContext context) {
    final mode = widget.blurMode;
    if (mode == UnveiledBlurMode.none) return 0.0;
    if (mode == UnveiledBlurMode.inherit) {
      return VeilScope.blurSigmaOf(context);
    }
    if (mode is UnveiledBlurCustomMode) return mode.sigma;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final sigma = _resolvedSigma(context);

    // If no blur needed — plain RepaintBoundary for greyscale/overlay opt-out.
    if (sigma <= 0.0) {
      return RepaintBoundary(key: _key, child: widget.child);
    }

    // Apply blur to this specific Unveiled child using ImageFiltered.
    // The RepaintBoundary is still needed for greyscale/overlay opt-out.
    return RepaintBoundary(
      key: _key,
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: TileMode.decal,
        ),
        child: widget.child,
      ),
    );
  }
}
