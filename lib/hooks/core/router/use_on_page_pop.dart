import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

SkipPopInterception useOnPagePop(WidgetRef ref, {OnPopAttempt? onPopAttempt, VoidCallback? afterPopped}) {
  final context = useContext();
  final route = ModalRoute.of(context);

  final skipPop = _useOnPagePopInterceptAttempts(context, route, onPopAttempt);
  _useOnPagePopAfterPopped(route, afterPopped);

  return skipPop;
}

SkipPopInterception _useOnPagePopInterceptAttempts(
  BuildContext context,
  ModalRoute<Object?>? route,
  OnPopAttempt? onPopAttempt,
) {
  final popEntry = useRef<_PopEntry?>(null);
  final isToSkipPopInterception = useRef<bool>(false);

  useEffect(() {
    if (route == null || onPopAttempt == null) return null;
    popEntry.value = _PopEntry(onPopAttempt);
    popEntry.value!.skipPopInterception(isToSkip: isToSkipPopInterception.value);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted || popEntry.value == null) return;
      route.registerPopEntry(popEntry.value!);
    });

    return () {
      if (popEntry.value != null) route.unregisterPopEntry(popEntry.value!);
      popEntry.value?.dispose();
      popEntry.value = null;
    };
  }, [route, onPopAttempt]);

  // wrapper is used because popEntry is constructed in useEffect
  void skipPopWrapper({required bool isToSkip}) {
    isToSkipPopInterception.value = isToSkip;
    popEntry.value?.skipPopInterception(isToSkip: isToSkip);
  }

  return skipPopWrapper;
}

void _useOnPagePopAfterPopped(ModalRoute<Object?>? route, VoidCallback? afterPopped) {
  useEffect(() {
    if (route == null || afterPopped == null) return null;

    bool disposed = false;
    final subscription = route.popped.asStream().listen((_) {
      if (!disposed) afterPopped.call();
    });

    return () {
      disposed = true;
      unawaited(subscription.cancel());
    };
  }, [route, afterPopped]);
}

// ----------------------------------------

/// use as ack() function - call to give permission
typedef AllowPopOnNextTime = void Function();
typedef OnPopAttempt = void Function({required AllowPopOnNextTime acknowledgePopForNextTime});
typedef SkipPopInterception = void Function({required bool isToSkip});

class _PopEntry extends PopEntry {
  final OnPopAttempt _onPopAttempt;
  final ValueNotifier<bool> _canPopNotifier = ValueNotifier(false);
  bool _isToSkipPopInterception = false;
  bool _canPop = false;

  _PopEntry(this._onPopAttempt);

  @override
  ValueListenable<bool> get canPopNotifier => _canPopNotifier;

  @override
  void onPopInvokedWithResult(bool didPop, dynamic result) {
    if (!didPop && !_isToSkipPopInterception) _onPopAttempt.call(acknowledgePopForNextTime: _allowPop);
    super.onPopInvokedWithResult(didPop, result);
  }

  void dispose() => _canPopNotifier.dispose();
  void skipPopInterception({required bool isToSkip}) {
    _isToSkipPopInterception = isToSkip;
    if (isToSkip) {
      _canPopNotifier.value = true;
    } else {
      _canPopNotifier.value = _canPop;
    }
  }

  void _allowPop() {
    _canPopNotifier.value = true;
    _canPop = true;
  }
}
