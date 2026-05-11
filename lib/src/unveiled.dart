import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:veil/src/render_veil.dart';
import 'package:veil/veil.dart';

import 'veil_notifier.dart';
import 'veil_scope.dart';

/// Exempts [child] from all visual effects applied by an ancestor [Veil].
///
/// Wrap any widget inside a [Veil] with [Unveiled] to keep it rendering in
/// full colour, unaffected by both the greyscale filter and the colour overlay
/// — even while the [Veil] is animating.
///
/// Multiple [Unveiled] widgets at any depth in the subtree are supported.
/// They do not need to be direct children of [Veil].
///
/// ### How it works
///
/// [Unveiled] places [child] inside a [RepaintBoundary] and registers that
/// boundary's [RenderRepaintBoundary] with the nearest [VeilNotifier]
/// (provided by [VeilScope]). The [RenderVeil] paint pipeline then re-paints
/// each registered boundary on top of the greyscale and overlay layers —
/// unfiltered and undimmed.
///
/// ### Behaviour outside a Veil
///
/// If [Unveiled] is used outside a [Veil], it has no effect and simply
/// renders [child] normally. No errors are thrown.
///
/// ### Example
///
/// ```dart
/// Veil(
///   enable: isDisabled,
///   greyOpacity: 1.0,
///   overlayOpacity: 0.3,
///   child: Card(
///     child: Column(
///       children: [
///         ProductImage(),     // greyscale + dimmed
///         ProductTitle(),     // greyscale + dimmed
///         Unveiled(           // full colour, not dimmed
///           child: ElevatedButton(
///             onPressed: () {},
///             child: Text('Buy Now'),
///           ),
///         ),
///       ],
///     ),
///   ),
/// )
/// ```
class Unveiled extends StatefulWidget {
  /// Creates an [Unveiled] widget.
  const Unveiled({super.key, required this.child});

  /// The widget to exempt from [Veil] effects.
  final Widget child;

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
    final newNotifier = VeilScope.of(context);
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

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(key: _key, child: widget.child);
  }
}
