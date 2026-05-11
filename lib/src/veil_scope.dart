import 'package:flutter/widgets.dart';
import 'package:veil/veil.dart';

import 'veil_notifier.dart';

/// Carries a [VeilNotifier] down the widget tree so that any [Unveiled]
/// descendant can register itself without needing a direct reference to the
/// ancestor [Veil] widget.
///
/// The notifier identity never changes after creation, so [updateShouldNotify]
/// only returns `true` on a key-forced State replacement — which is extremely
/// rare in practice.
class VeilScope extends InheritedWidget {
  /// Creates a [VeilScope].
  const VeilScope({
    super.key,
    required this.notifier,
    required super.child,
  });

  /// The [VeilNotifier] shared across this subtree.
  final VeilNotifier notifier;

  /// Returns the nearest [VeilNotifier] from the widget tree, or `null` if
  /// this widget is not inside a [VeilScope].
  static VeilNotifier? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VeilScope>()?.notifier;

  @override
  bool updateShouldNotify(VeilScope old) => notifier != old.notifier;
}
