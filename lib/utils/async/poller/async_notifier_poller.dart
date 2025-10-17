import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:wp_player/utils/logger/logger.dart';

class AsyncNotifierPoller<A> {
  final FutureOr<A?> Function() getValueFunction;
  final Duration interval;
  final String name;

  final ValueNotifier<A?> _listenable = ValueNotifier(null);
  Timer? _timer;
  bool _disposed = false;

  AsyncNotifierPoller({required this.getValueFunction, required this.interval, required this.name}) {
    if (interval == Duration.zero) {
      throw ArgumentError.value(interval, 'interval', 'must be greater than zero');
    }
  }

  void start() {
    if (_timer != null || _disposed) return;

    bool isRunningLockFlag = false; // reliance on one threaded execution
    _timer = Timer.periodic(interval, (timer) async {
      if (isRunningLockFlag) return;
      isRunningLockFlag = true;
      try {
        final value = await getValueFunction();
        if (!_disposed) _listenable.value = value;
      } catch (error) {
        stop();
        logConsole.e("Error in $name ($AsyncNotifierPoller): $error");
      } finally {
        isRunningLockFlag = false;
      }
    });
  }

  void stop() {
    _listenable.value = null;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _disposed = true;
    stop();
    _listenable.dispose();
  }

  ValueNotifier<A?> get listenable => this._listenable;
}
