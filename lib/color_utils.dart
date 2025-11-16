import 'package:flutter/material.dart';

Color parseColorHex(String? hexString, Color defaultColor) {
  if (hexString == null || hexString.isEmpty) {
    return defaultColor;
  }

  String cleanHex = hexString.startsWith('#') ? hexString.substring(1) : hexString;

  // Handle single character "0" or other non-standard small strings by returning default
  if (cleanHex.length < 3) {
    // Optionally log a warning for unexpected format if not "0"
    // debugPrint('Unexpected short hex color string "$hexString", using default.');
    return defaultColor;
  }

  if (cleanHex.length == 3) {
    cleanHex = cleanHex.split('').map((char) => char * 2).join();
  }

  if (cleanHex.length == 6) {
    try {
      return Color(int.parse(cleanHex, radix: 16) + 0xFF000000);
    } catch (e) {
      debugPrint('Error parsing hex color "$hexString": $e');
      return defaultColor;
    }
  }
  return defaultColor;
}

/// Calculates a contrasting text color (black or white) for a given background color.
/// This is used to ensure text is readable on a colored background.
Color getContrastingTextColor(Color backgroundColor) {
  // Formula to determine luminance (YIQ color space).
  // Using the new recommended properties for color components (r, g, b) which are 0.0-1.0.
  double luminance = (0.299 * backgroundColor.r + 0.587 * backgroundColor.g + 0.114 * backgroundColor.b) * 255.0;
  // Return black for light backgrounds, white for dark backgrounds.
  return luminance > 128 ? Colors.black : Colors.white;
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}