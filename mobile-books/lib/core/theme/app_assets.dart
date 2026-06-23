import 'package:flutter/material.dart';

class AppAssets {
  static Widget walletLogo({double? width, double? height, Color? color}) {
    final size = height ?? width ?? 32.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFF2563EB)).withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.account_balance_wallet_rounded,
        size: size * 0.65,
        color: color ?? const Color(0xFF2563EB),
      ),
    );
  }
}
