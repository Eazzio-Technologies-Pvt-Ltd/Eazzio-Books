import 'package:flutter/material.dart';
import 'package:mobile_books/core/theme/app_icons.dart';

class AppAssets {
  static Widget walletLogo({double? width, double? height, Color? color}) {
    final size = height ?? width ?? 32.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: Image.asset(
        'assets/images/app_icon.jpeg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Graceful fallback to material wallet icon if asset loading fails
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: (color ?? const Color(0xFF0CD693)).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(size * 0.3),
            ),
            alignment: Alignment.center,
            child: Icon(
              AppIcons.account_balance_wallet_rounded,
              size: size * 0.65,
              color: color ?? const Color(0xFF0CD693),
            ),
          );
        },
      ),
    );
  }
}
