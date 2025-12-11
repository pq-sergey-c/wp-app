import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';
import 'package:wp_player/styles/colors/colors.dart';

class PlayerPlayStopButton extends HookConsumerWidget {
  final VoidCallback onPlayPausePressed;
  final bool isPlaying;

  const PlayerPlayStopButton({
    required this.onPlayPausePressed,
    required this.isPlaying,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final pendingFallbackTimer = useRef<Timer?>(null);
    final isPending = useState(false);
    final previousIsPlaying = usePrevious(isPlaying);

    useEffect(() {
      if (isPending.value &&
          previousIsPlaying != null &&
          previousIsPlaying != isPlaying) {
        pendingFallbackTimer.value?.cancel();
        isPending.value = false;
      }
      return null;
    }, [isPlaying, previousIsPlaying]);

    useEffect(() {
      return () {
        pendingFallbackTimer.value?.cancel();
      };
    }, const []);

    void triggerPendingState() {
      pendingFallbackTimer.value?.cancel();
      isPending.value = true;
      // Fallback so the button won't stay pending if playback state fails to change.
      pendingFallbackTimer.value = Timer(const Duration(seconds: 2), () {
        if (isPending.value) {
          isPending.value = false;
        }
      });
    }

    void handleTap() {
      unawaited(HapticFeedback.mediumImpact());
      triggerPendingState();
      onPlayPausePressed();
    }

    return Center(
      child: InkWell(
        onTap: handleTap,
        customBorder: const CircleBorder(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double superWidgetWidth = constraints.maxWidth;
            final double width = (superWidgetWidth * 0.4).clamp(50, 140);
            final double iconSize = width / 2;
            final double scale = isPending.value ? 0.9 : 1;
            final double opacity = isPending.value ? 0.7 : 1;
            final Widget controlVisual =
                isPending.value
                    ? LoadingAnimationWidget.staggeredDotsWave(
                      key: const ValueKey('play-pause-loading'),
                      color: themeMode.getColorByMode(
                        dark: AppColors.blueIron,
                        light: AppColors.white,
                      ),
                      size: iconSize,
                    )
                    : Icon(
                      key: ValueKey(isPlaying),
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: iconSize,
                      color: themeMode.getColorByMode(
                        dark: AppColors.blueIron,
                        light: AppColors.white,
                      ),
                    );

            return AnimatedScale(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              scale: scale,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: opacity,
                child: Container(
                  width: width,
                  height: width,
                  decoration: BoxDecoration(
                    color: themeMode.getColorByMode(
                      dark: AppColors.white.withAlpha(185),
                      light: AppColors.blueIron,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: controlVisual,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
