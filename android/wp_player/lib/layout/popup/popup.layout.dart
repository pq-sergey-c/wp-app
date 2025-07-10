import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:wp_player/providers/popup/popup.provider.dart';
import 'package:wp_player/providers/popup/types/popup_config.dart';
import 'package:wp_player/providers/responsive_layout/fragments/responsive_layout_model.dart';
import 'package:wp_player/providers/responsive_layout/responsive_layout.provider.dart';

class PopupLayout extends ConsumerWidget {
  final Widget child;

  const PopupLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popups = ref.watch(popupProvider);
    final layout = ref.watch(responsiveLayoutProvider);

    final int? keyOrNull = _findKeyOfPopupWithBackgroundOverlay(layout, popups);
    return Stack(
      children: [
        child,
        ...popups.entries.map((entry) => entry.value.build(withBackgroundOverlay: entry.key == keyOrNull)),
      ],
    );
  }

  int? _findKeyOfPopupWithBackgroundOverlay(
    final ResponsiveLayout layout,
    final LinkedHashMap<int, PopupBaseConfig> popups,
  ) {
    final isEligibleForOverlay = _filterToSkipPopupOverlay(layout);
    return popups.keys.cast<int?>().firstWhere((key) => isEligibleForOverlay(popups[key]!), orElse: () => null);
  }

  bool Function(PopupBaseConfig) _filterToSkipPopupOverlay(final ResponsiveLayout layout) {
    return (PopupBaseConfig config) => true;
  }
}
