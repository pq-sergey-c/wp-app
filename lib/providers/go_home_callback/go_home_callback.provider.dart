import 'package:hooks_riverpod/hooks_riverpod.dart';

typedef GoHomeProviderCallbackType = Future<({bool canGoHome})> Function();

class GoHomeCallbackProvider extends Notifier<GoHomeProviderCallbackType?> {
  @override
  Null build() => null;

  void set(GoHomeProviderCallbackType? newValue) => state = newValue;
  GoHomeProviderCallbackType? get() => state;
}

final goHomeCallbackProvider = NotifierProvider<GoHomeCallbackProvider, GoHomeProviderCallbackType?>(
  GoHomeCallbackProvider.new,
);
