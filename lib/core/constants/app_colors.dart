import 'package:flutter/material.dart';

class AppColors {
  // Primary — dourado âmbar da logo
  static const Color primary = Color(0xFFD4900A);
  static const Color primaryDark = Color(0xFFA86E00);
  static const Color primaryLight = Color(0xFFE8B040);
  // Accent — marrom cacau da logo
  static const Color accent = Color(0xFF7A1E2E);
  static const Color accentDark = Color(0xFF5A1220);
  static const Color accentLight = Color(0xFF9B3040);
  // Terracota/cobre
  static const Color pink = Color(0xFFC97D30);
  // Neutral
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  // Status
  static const Color success = Color(0xFF5A8A00);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFFD4900A);

  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);
  static Color blackWithOpacity(double opacity) =>
      black.withValues(alpha: opacity);
  static Color whiteWithOpacity(double opacity) =>
      white.withValues(alpha: opacity);
  static Color accentWithOpacity(double opacity) =>
      accent.withValues(alpha: opacity);
}
