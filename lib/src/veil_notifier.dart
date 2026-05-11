import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'unveiled.dart';
import 'veil.dart';

/// Tracks the set of [RenderRepaintBoundary] objects belonging to [Unveiled]
/// descendants of a single [Veil] widget.
///
/// Notifications are batched via a microtask so that N [Unveiled] widgets
/// mounting in the same frame trigger only one `markNeedsPaint` call instead
/// of N separate repaints.
@internal
class VeilNotifier extends ChangeNotifier {
  /// The live set of opted-out repaint boundaries.
  final Set<RenderRepaintBoundary> boundaries = {};

  bool _pendingNotify = false;

  void _scheduleNotify() {
    if (_pendingNotify) return;
    _pendingNotify = true;
    scheduleMicrotask(() {
      _pendingNotify = false;
      if (hasListeners) notifyListeners();
    });
  }

  /// Registers [boundary] as an unveiled (opted-out) boundary.
  ///
  /// Schedules a batched notification if the set changed.
  void register(RenderRepaintBoundary boundary) {
    if (boundaries.add(boundary)) _scheduleNotify();
  }

  /// Removes [boundary] from the unveiled boundary set.
  ///
  /// Schedules a batched notification if the set changed.
  void unregister(RenderRepaintBoundary boundary) {
    if (boundaries.remove(boundary)) _scheduleNotify();
  }
}
