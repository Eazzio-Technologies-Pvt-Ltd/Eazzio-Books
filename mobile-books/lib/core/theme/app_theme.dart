// AppTheme extracted from Eazzio Books frontend — do not hardcode values elsewhere
import 'package:flutter/material.dart';

class AppColors {
  // PRIMARY (exact from frontend)
  static const Color primary = Color(0xFF1B2337);
  static const Color primaryLight = Color(0xFF2F80ED);
  static const Color primaryDark = Color(0xFF0F172A);

  // BACKGROUNDS
  static const Color bgPage = Color(0xFFF8FAFC);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgSurface = Color(0xFFF1F5F9);

  // TEXT HIERARCHY (use opacity variations)
  static const Color textPrimary = Color(0xFF0F172A);     // 100% opacity
  static const Color textSecondary = Color(0xFF334155);   // 80% opacity
  static const Color textHint = Color(0xFF64748B);        // 60% opacity

  // SEMANTIC
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);

  // BORDERS
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFCBD5E1);
}

class AppTextStyles {
  // Use font family from frontend
  static const String fontFamily = 'Inter';

  // Font sizes from frontend (converted to Flutter sp)
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30.0,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24.0,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.normal,
    color: AppColors.textHint,
  );

  // For numbers (prices, stats) — monospace feel
  static const TextStyle numeric = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.bold,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

class AppSpacing {
  // 8-point grid — all values divisible by 4 or 8
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Card internal padding
  static const EdgeInsets cardPadding = EdgeInsets.all(24);
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);
}

class AppRadius {
  // From frontend border-radius values
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double pill = 100.0;
}

class AppShadows {
  // Soft shadows — tinted to match background (never pure gray/black)
  static List<BoxShadow> get card => [
    BoxShadow(
      // ignore: deprecated_member_use
      color: AppColors.primary.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> get button => [
    BoxShadow(
      // ignore: deprecated_member_use
      color: AppColors.primary.withOpacity(0.30),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
}
