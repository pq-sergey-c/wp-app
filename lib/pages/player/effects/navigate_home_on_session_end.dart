part of '../player.page.dart';

void _usePlayerPageNavigateHomeOnSessionEnd(BuildContext context, WidgetRef ref) {
  final sessionEndedListenable = PlayerService().sessionEndedListenable;
  final hasNavigatedRef = useRef(false);

  useEffect(() {
    if (sessionEndedListenable == null) {
      hasNavigatedRef.value = false;
      return null;
    }

    void handleSessionEnded() {
      if (hasNavigatedRef.value) return;
      if (!sessionEndedListenable.value) return;
      if (!context.mounted) return;

      hasNavigatedRef.value = true;
      ref.read(goHomeCallbackProvider.notifier).state = null;

      context.go('/');
      unawaited(Future.microtask(() => PlayerService().disconnect()));
    }

    sessionEndedListenable.addListener(handleSessionEnded);
    handleSessionEnded();

    return () {
      sessionEndedListenable.removeListener(handleSessionEnded);
      hasNavigatedRef.value = false;
    };
  }, [context, sessionEndedListenable]);
}
