import 'package:hooks_riverpod/hooks_riverpod.dart';

final goHomeCallbackProvider = StateProvider<Future<({bool canGoHome})> Function()?>((ref) => null);
