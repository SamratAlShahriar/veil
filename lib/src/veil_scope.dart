import 'package:flutter/widgets.dart';

import 'veil_notifier.dart';

/// Carries a [VeilNotifier] and the current blur sigma down the widget tree
/// so that any `Unveiled` descendant can register itself and read the
/// parent `Veil`'s blur configuration without needing a direct reference.
///
/// The notifier identity never changes after creation, so [updateShouldNotify]
/// only returns `true` when either the notifier or [blurSigma] changes.
class VeilScope extends InheritedWidget {
  /// Creates a [VeilScope].
  const VeilScope({
    super.key,
    required this.notifier,
    required this.blurSigma,
    required super.child,
  });

  /// The [VeilNotifier] shared across this subtree.
  final VeilNotifier notifier;

  /// The current animated blur sigma from the parent `Veil`.
  ///
  /// `0.0` means no blur is active. `Unveiled` children read this to
  /// determine how much blur to apply based on their `blurMode`.
  final double blurSigma;

  /// Returns the nearest [VeilScope] from the widget tree, or `null`
  /// if this widget is not inside a `Veil`.
  static VeilScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VeilScope>();

  /// Returns the nearest [VeilNotifier], or `null` if not inside a `Veil`.
  static VeilNotifier? notifierOf(BuildContext context) =>
      of(context)?.notifier;

  /// Returns the current blur sigma, or `0.0` if not inside a `Veil`.
  static double blurSigmaOf(BuildContext context) =>
      of(context)?.blurSigma ?? 0.0;

  @override
  bool updateShouldNotify(VeilScope old) =>
      notifier != old.notifier || blurSigma != old.blurSigma;
}
