import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? ctaText;
  final VoidCallback? onCtaPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.ctaText,
    this.onCtaPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon badge in primary 20% opacity circle
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 38,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Heading
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (ctaText != null && onCtaPressed != null) ...[
            const SizedBox(height: 32),
            // CTA Button
            Center(
              child: AppButton(
                text: ctaText!,
                onPressed: onCtaPressed,
                width: 220,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
