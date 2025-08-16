import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/theme_mode/theme_mode.provider.dart';

class VolumeSlider extends HookConsumerWidget {
  final double startVolume;
  final ValueChanged<double> onVolumeChanged;

  const VolumeSlider({required this.startVolume, required this.onVolumeChanged, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeModeProvider);
    final color = themeProvider.themeConfig.text;

    final volume = useState(startVolume);

    void onVolumeChangedInternal(double value) {
      volume.value = value;
      onVolumeChanged(value);
    }

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: color,
        inactiveTrackColor: color.withAlpha(75),
        thumbColor: color,
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onVolumeChangedInternal(0.0),
              child: Icon(Icons.volume_down, color: color, size: 24),
            ),
          ),
          Expanded(
            child: Listener(
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is! PointerScrollEvent) return;
                final double volumeDelta = -pointerSignal.scrollDelta.dy;
                onVolumeChangedInternal((volume.value + volumeDelta * 0.001).clamp(0.0, 1.0));
              },
              child: Slider(value: volume.value, onChanged: onVolumeChangedInternal),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onVolumeChangedInternal(1.0),
              child: Icon(Icons.volume_up, color: color, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
