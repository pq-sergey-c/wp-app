import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef SetCanPop = void Function({required bool canPop});
typedef OnPopAttempt = void Function(SetCanPop);

void useOnPagePop(WidgetRef ref, {OnPopAttempt? onPop, VoidCallback? afterPopped, bool initialCanPop = true}) {
  final context = useContext();
  final route = ModalRoute.of(context);

  useEffect(() {
    if (route == null) return null;
    final popEntry = _PopEntry(onPop: onPop, afterPopped: afterPopped, initialCanPop: initialCanPop);

    bool disposed = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (disposed || !context.mounted) return;
      route.registerPopEntry(popEntry);
    });

    return () {
      disposed = true;
      route.unregisterPopEntry(popEntry);
      popEntry.dispose();
    };
  }, [route, onPop, initialCanPop]);
}

// TODO: assess corretness, things to consider: what happens on push and go, what happen with QR scanner (is it working)
// FIXME: resizing on windows / rotate on android breaks stuff (maybe try to reimplement this whole stuff with always false and manual pop stuff or something - where callback is called from remove and not from isPossibleToRemove)
class _PopEntry extends PopEntry {
  final OnPopAttempt? onPop;
  final VoidCallback? afterPopped;
  final ValueNotifier<bool> _canPopNotifier;
  final ValueNotifier<bool> _canPopNotifierFalse = ValueNotifier(false);

  int initialNotifierReadsCompleted = 0;
  static const amountOfInitialReads = 2;

  _PopEntry({required this.onPop, required this.afterPopped, required bool initialCanPop})
    : _canPopNotifier = ValueNotifier(initialCanPop);

  @override
  ValueListenable<bool> get canPopNotifier {
    if (initialNotifierReadsCompleted < amountOfInitialReads) {
      initialNotifierReadsCompleted++;
      return _canPopNotifierFalse;
    }
    onPop?.call(setCanPop);
    return _canPopNotifier;
  }

  @override
  void onPopInvokedWithResult(bool didPop, dynamic result) {
    if (didPop) afterPopped?.call();
    super.onPopInvokedWithResult(didPop, result);
  }

  void dispose() {
    _canPopNotifier.dispose();
    _canPopNotifierFalse.dispose();
  }

  void setCanPop({required bool canPop}) => _canPopNotifier.value = canPop;
}
