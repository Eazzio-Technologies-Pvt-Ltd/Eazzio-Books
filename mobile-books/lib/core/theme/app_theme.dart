import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand Teal Primary & Navy Accent Colors
  static const Color primary = Color(0xFF0CD693);
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFE6FAF4);
  static const Color onPrimaryContainer = Color(0xFF075B3F);
  
  // Admin Panel Green
  static const Color secondary = Color(0xFF22C55E);
  static const Color onSecondary = Colors.white;
  static const Color secondaryContainer = Color(0xFFDCFCE7); // Green-50
  static const Color onSecondaryContainer = Color(0xFF14532D); // Green-900
  
  static const Color tertiary = Color(0xFF0B093E); // Navy Blue Accent
  static const Color onTertiary = Colors.white;
  
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color onError = Colors.white;
  static const Color errorContainer = Color(0xFFFEE2E2); // Red-100
  static const Color onErrorContainer = Color(0xFF7F1D1D); // Red-900
  
  static const Color background = Color(0xFFF8FAFC); // Slate-50
  static const Color onBackground = Color(0xFF0F172A); // Slate-900
  
  static const Color surface = Colors.white;
  static const Color onSurface = Color(0xFF1E293B); // Slate-800
  static const Color onSurfaceVariant = Color(0xFF475569); // Slate-600
  
  static const Color outline = Color(0xFF94A3B8); // Slate-400
  static const Color outlineVariant = Color(0xFFE2E8F0); // Slate-200
  
  // Eazzio Books UI Semantic Colors mapping
  static const Color bgPage = background;
  static const Color bgCard = surface;
  static const Color bgSurface = Color(0xFFF1F5F9);
  static const Color textPrimary = onBackground;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textHint = outline;
  static const Color border = outlineVariant;
  static const Color borderLight = outlineVariant;
  
  // Accent mapping
  static const Color primaryBlue = primary;
  static const Color primaryBlueDark = Color(0xFF60A5FA); // Blue-400
  static const Color primaryLight = primaryBlueDark;
  static const Color success = secondary;
  static const Color danger = error;
  static const Color warning = Color(0xFFF59E0B); // Amber-500
}

class AppTextStyles {
  // Heading: Size 24, Bold
  static TextStyle get h1 => GoogleFonts.inter(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static TextStyle get h2 => GoogleFonts.inter(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Section Title: Size 16, Bold
  static TextStyle get h3 => GoogleFonts.inter(
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Body: Size 14, Regular
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Caption: Size 12, Regular
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  // Tabular Numeric (using body size 14, Bold)
  static TextStyle get numeric => GoogleFonts.inter(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    fontFeatures: [const FontFeature.tabularFigures()],
  );
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  static const EdgeInsets cardPadding = EdgeInsets.all(24);
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double pill = 100.0;
}

class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.02),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> get button => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
}
