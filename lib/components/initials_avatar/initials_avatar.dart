import 'package:flutter/material.dart';
import 'package:wp_player/styles/fonts/fonts.dart';
import 'package:wp_player/types/font_variation/font_variation_weight.dart';

/// A widget that displays an avatar with initials when no image is available
class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const InitialsAvatar({
    required this.name,
    required this.size,
    this.backgroundColor,
    this.textColor,
    super.key,
  });

  /// Extracts initials from a name (max 2 characters)
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final parts = name.trim().split(RegExp(r'\s+'));
    
    if (parts.length >= 2) {
      // Take first letter of first two words
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      // Take first letter of single word
      return parts.first[0].toUpperCase();
    }
  }

  /// Generates a consistent color based on the name
  Color _getBackgroundColor(String name) {
    if (backgroundColor != null) return backgroundColor!;
    
    // Generate a consistent color from the name
    final hash = name.hashCode;
    final hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.5, 0.65).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final bgColor = _getBackgroundColor(name);
    final fgColor = textColor ?? Colors.white;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.4, // Scale font size relative to avatar size
            fontVariations: [FontVariationWeight.w600()],
            fontFamily: Fonts.inter,
            color: fgColor,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
