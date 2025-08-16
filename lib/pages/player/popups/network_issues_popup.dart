part of '../player.page.dart';

void _usePlayerPageNetworkIssuesPopup(PopupNotifier popup) {
  final closeNetworkIssuePopup = useRef<void Function()?>(null);
  useEffect(() {
    void onConnectionChanged() {
      final isInterrupted = PlayerService().isConnectionInterruptedListenable?.value ?? false;
      final hasPopup = closeNetworkIssuePopup.value != null;

      if (!isInterrupted && hasPopup) {
        closeNetworkIssuePopup.value!();
        closeNetworkIssuePopup.value = null;
      } else if (isInterrupted && !hasPopup) {
        closeNetworkIssuePopup.value = popup.addPopupNetworkIssues(
          content: PopupContent.text(
            title: "Trying to reconnect...",
            message: TextSpan(
              text: "Encountered network error. Please recheck your ",
              children: [
                TextSpan(text: "internet signal", style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
              ],
            ),
          ),
        );
      }
    }

    final listenable = PlayerService().isConnectionInterruptedListenable?..addListener(onConnectionChanged);
    return () => listenable?.removeListener(onConnectionChanged);
  }, []);
}
