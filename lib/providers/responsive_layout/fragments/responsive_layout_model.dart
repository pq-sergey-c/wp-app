import 'package:flutter/material.dart';
import 'package:wp_player/providers/responsive_layout/types/enums/responsive_layout_text_sizes.dart';

class ResponsiveLayout {
  final double screenWidth;
  final double screenHeight;
  final double paddingTop;
  final double paddingBottom;

  final double baseFontSize;

  ResponsiveLayout(MediaQueryData mediaData, this.baseFontSize)
    : screenWidth = mediaData.size.width,
      screenHeight = mediaData.size.height,
      paddingTop = mediaData.padding.top,
      paddingBottom = mediaData.padding.bottom;

  // --------------------------------------------------------------------------

  bool get isMobile => screenWidth <= 480;
  bool get isTablet => screenWidth <= 768 && !isMobile;
  bool get isDesktop => screenWidth > 768;

  bool get isLandscape => screenWidth >= screenHeight;
  bool get isPortrait => screenWidth <= screenHeight;

  // --------------------------------------------------------------------------

  double getClampedWidth({required double percent, double? min, double? max}) {
    final value = screenWidth * percent / 100;
    return value.clamp(min ?? double.negativeInfinity, max ?? double.infinity);
  }

  double getClampedHeight({required double percent, double? min, double? max, bool withTopPadding = false}) {
    final offset = withTopPadding ? paddingTop : 0;

    final value = (screenHeight - offset) * percent / 100 + offset;
    return value.clamp(min ?? double.negativeInfinity, max ?? double.infinity);
  }

  double getHeightWithTopPadding(double height) {
    return height + paddingTop;
  }

  // --------------------------------------------------------------------------

  A widthBreakpoints<A>(List<({double maxWidth, A item})> breakpoints, {A? fallback}) {
    if (breakpoints.isEmpty && fallback == null) {
      throw FlutterError('Responsive layout (widthBreakpoints): Breakpoints list cannot be empty');
    }
    breakpoints.sort((a, b) => a.maxWidth.compareTo(b.maxWidth)); // smallest to largest
    final int index = breakpoints.indexWhere((({double maxWidth, A item}) entry) => entry.maxWidth >= screenWidth);

    // too large
    if (index == -1) return fallback ?? breakpoints.last.item;

    return breakpoints[index].item;
  }

  A heightBreakpoints<A>(List<({double maxHeight, A item})> breakpoints, {A? fallback}) {
    if (breakpoints.isEmpty && fallback == null) {
      throw FlutterError('Responsive layout (heightBreakpoints): Breakpoints list cannot be empty');
    }
    breakpoints.sort((a, b) => a.maxHeight.compareTo(b.maxHeight)); // smallest to largest
    final int index = breakpoints.indexWhere((({double maxHeight, A item}) entry) => entry.maxHeight >= screenHeight);

    // too large
    if (index == -1) return fallback ?? breakpoints.last.item;

    return breakpoints[index].item;
  }

  /// Fallbacks from larger to smaller
  /// Requires at least one of [mobile], [tablet], or [desktop] to be non-null.
  A selectByScreenType<A>({A? mobile, A? tablet, A? desktop, A? orElse}) {
    if (mobile == null && tablet == null && desktop == null && orElse == null) {
      throw FlutterError(
        'Responsive layout (selectByScreenType): At least one of mobile, tablet, desktop, or orElse must be provided.',
      );
    }

    if (isMobile) return mobile ?? orElse ?? tablet ?? desktop!;
    if (isTablet) return tablet ?? orElse ?? mobile ?? desktop!;
    return desktop ?? orElse ?? tablet ?? mobile!;
  }

  // --------------------------------------------------------------------------

  double getTextSize(TextSizes size) => size.fontSize(baseFontSize);
}
