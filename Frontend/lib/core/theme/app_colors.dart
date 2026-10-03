import 'package:flutter/material.dart';

class AppColors {
  // Brand Accents
  static const primary = Color(0xFF00D26A);
  static const primaryDark = Color(0xFF00B058);
  static const danger = Color(0xFFFF4D4F);
  static const warning = Color(0xFFFAAD14);
  static const info = Color(0xFF1890FF);

  // Static constants (Dark theme default)
  static const background = Color(0xFF0D1117);
  static const card = Color(0xFF161B22);
  static const text = Colors.white;
  static const secondaryText = Color(0xFF8B949E);
  static const border = Color(0xFF30363D);

  // Theme-aware dynamic color getters
  static Color getBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0D1117)
          : const Color(0xFFF6F8FA);

  static Color getCard(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF161B22)
          : Colors.white;

  static Color getText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF1E293B);

  static Color getSecondaryText(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF8B949E)
          : const Color(0xFF64748B);

  static Color getBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF30363D)
          : const Color(0xFFE2E8F0);
}