import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'app_button.dart';

class UnsavedChangesDialog extends StatelessWidget {
  const UnsavedChangesDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UnsavedChangesDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Unsaved Changes',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        'You have unsaved changes. Are you sure you want to discard them and exit?',
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      actionsPadding: const EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        bottom: 24.0,
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Cancel',
                variant: AppButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: AppButton(
                text: 'Discard',
                variant: AppButtonVariant.primary,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class UnsavedChangesWrapper extends StatelessWidget {
  final Widget child;
  final bool hasChanges;

  const UnsavedChangesWrapper({
    super.key,
    required this.child,
    required this.hasChanges,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await UnsavedChangesDialog.show(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: child,
    );
  }
}
