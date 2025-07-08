import 'package:flutter/material.dart';
import 'package:wp_player/layout/theme_control/fragments/theme_toggle_button.dart';

class ThemeControlLayout extends StatelessWidget {
  final Widget child;

  const ThemeControlLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [child, const ThemeToggleButton()]);
  }
}
