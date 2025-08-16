part of '../player.page.dart';

void _usePlayerPageInfoPopup(PopupNotifier popup) {
  useEffect(() {
    unawaited(
      Future.microtask(
        () async => await popup.addPopupNotification(
          content: PopupContent.text(
            title: 'Setup Requirements',
            message: TextSpan(
              children: [
                TextSpan(text: "Internet", style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
                const TextSpan(text: ": Ensure your connection is stable, reliable & reasonably fast"),

                TextSpan(text: "\n\nAudio", style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
                const TextSpan(text: ": Avoid using bluetooth to protect audio quality and playback stability"),

                TextSpan(text: "\n\nBattery", style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
                const TextSpan(
                  text:
                      ": Ensure this device has sufficient battery power and is connected to a charger when running long sessions",
                ),

                TextSpan(text: "\n\nNon-disturb", style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
                const TextSpan(text: ": Ensure this device cannot disrupt the music via calls or app notifications"),

                if (PlayerService().sessionInformation.userRole == UserRole.provider) ...[
                  TextSpan(text: "\n\nStreaming-only", style: TextStyle(fontVariations: [FontVariationWeight.w600()])),
                  const TextSpan(text: ": Use your browser to launch and control sessions"),
                ],
              ],
            ),
          ),
          buttonText: 'I understand',
        ),
      ),
    );
    return;
  }, []);
}
