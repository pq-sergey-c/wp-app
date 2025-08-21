import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/core/deep_linking/deep_linking_resolver.dart';
import 'package:wp_player/core/permissions/request_notification_permissions.dart';
import 'package:wp_player/core/router/app_router.dart';
import 'package:wp_player/providers/popup/popup.provider.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/services/foreground_kotlin/foreground/foreground_kotlin.foreground_channel.dart';
import 'package:wp_player/services/network/network.service.dart';
import 'package:wp_player/services/player.native_lib/player.native_lib.dart';
import 'package:wp_player/styles/app_theme/app_theme.dart';

void main() {
  // side effect: construction of NativeLibraryPlayer
  // TODO: maybe change to static + volume to be set on start or something?
  NativeLibraryPlayer().setNetworkCallbacks(NetworkService().onNetworkRequest, NetworkService().onNetworkCancel);
  NativeLibraryPlayer().volume = 0.75;

  runApp(const ProviderScope(child: App()));
}

class App extends HookConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popup = ref.read(popupProvider.notifier);
    RequestNotificationPermissions.setup(popup.addPopupYesNo);

    // To prevent router rebuild due to ref caused rebuilds
    final router = useMemoized(() => AppRouter.getRouter(ref), []);

    return ProviderScope(
      overrides: [mediaQueryProvider.overrideWithValue(MediaQuery.of(context))],
      child: DeepLinkingResolver(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ref.watch(themeModeProvider).mode,
          routerConfig: router,
        ),
      ),
    );
  }
}

// --------------------------------------------------------------
// other entry points - required to be here and have unique names

@pragma('vm:entry-point')
void kotlinForegroundEntryPointMain() => realKotlinForegroundEntryPointMain();
