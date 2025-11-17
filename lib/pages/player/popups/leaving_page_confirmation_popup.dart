part of '../player.page.dart';

void _usePlayerPageLeavingPageConfirmationPopup(BuildContext context, WidgetRef ref, PopupNotifier popup) {
  final canClosePageCallbackIsRunning = useRef<bool>(false);

  final canClosePageCallback = useCallback(() async {
    if (canClosePageCallbackIsRunning.value) return false;
    canClosePageCallbackIsRunning.value = true;

    final toStop = await popup.addPopupYesNo(
      content: PopupContent.text(
        title: "Warning",
        message: const TextSpan(text: "This action will stop streaming the music. Do you want to continue?"),
      ),
      yesText: "Yes",
      noText: "No",
      onForcedClosedCallback: PlayerService().disconnect,
    );
    if (toStop) {
      await PlayerService().disconnect();
    }

    canClosePageCallbackIsRunning.value = false;
    return toStop;
  }, []);

  // confirmation popup for go back (gesture/button)
  useOnPagePop(
    ref,
    onPopAttempt: ({required acknowledgePopForNextTime}) async {
      if (!context.canPop() || !context.mounted) return;

      final canPop = await canClosePageCallback();
      if (!canPop || !context.mounted) return;

      acknowledgePopForNextTime();
      context.pop();
    },
  );

  // confirmation popup for go home button
  useEffect(() {
    GoHomeCallbackProvider? callbackProviderNotifier;
    bool disposed = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      callbackProviderNotifier = ref.read(goHomeCallbackProvider.notifier);
      if (disposed) return;
      callbackProviderNotifier!.set(() async => (canGoHome: await canClosePageCallback()));
    });

    return () {
      disposed = true;
      callbackProviderNotifier?.set(null);
    };
  }, []);
}
