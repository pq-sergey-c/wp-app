import 'package:flutter/material.dart';
import 'package:wp_player/layout/go_home/fragments/go_home_button.dart';

class GoHomeButtonLayout extends StatelessWidget {
  final Widget child;

  const GoHomeButtonLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [child, const GoHomeButton()]);
  }
}
