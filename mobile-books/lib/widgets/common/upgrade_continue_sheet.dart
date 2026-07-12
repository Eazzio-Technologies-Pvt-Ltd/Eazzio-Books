import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';

class UpgradeContinueSheet extends StatelessWidget {
  final String title;
  final String description;
  final String ctaText;

  const UpgradeContinueSheet({
    super.key,
    required this.title,
    required this.description,
    this.ctaText = 'Upgrade Plan',
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String description,
    String ctaText = 'Upgrade Plan',
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => UpgradeContinueSheet(
        title: title,
        description: description,
        ctaText: ctaText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.l),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/pricing');
                    },
                    child: Text(ctaText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
