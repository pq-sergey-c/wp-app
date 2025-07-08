import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wp_player/providers/responsive_layout/fragments/responsive_layout_model.dart';
import 'package:wp_player/styles/app_theme/app_theme.dart';

final mediaQueryProvider = Provider<MediaQueryData>((ref) {
  throw UnimplementedError(); // overridden by ProviderScope
});

final responsiveLayoutProvider = Provider<ResponsiveLayout>((ref) {
  final mediaQuery = ref.watch(mediaQueryProvider);

  return ResponsiveLayout(mediaQuery, AppTheme.baseFontSize);
}, dependencies: [mediaQueryProvider]);
