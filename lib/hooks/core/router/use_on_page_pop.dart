import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void useOnPagePop(WidgetRef ref, {required VoidCallback onPop}) {
  final context = useContext();

  final subscribedRoute = useRef<ModalRoute?>(null);
  final route = ModalRoute.of(context);

  useEffect(() {
    if (route == null || subscribedRoute.value == route) return null;
    subscribedRoute.value = route;

    final popEntry = _PopEntry(onPop: onPop);
    route.registerPopEntry(popEntry);
    return () => route.unregisterPopEntry(popEntry);
  }, [route]);
}

class _PopEntry extends PopEntry {
  final VoidCallback onPop;
  final ValueNotifier<bool> _canPopNotifier = ValueNotifier(true);

  _PopEntry({required this.onPop});

  @override
  void onPopInvokedWithResult(bool didPop, dynamic result) {
    if (didPop) onPop();
    super.onPopInvokedWithResult(didPop, result);
  }

  @override
  ValueListenable<bool> get canPopNotifier => _canPopNotifier;

  void dispose() {
    _canPopNotifier.dispose();
  }
}
