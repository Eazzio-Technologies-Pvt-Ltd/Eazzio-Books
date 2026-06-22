import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/transaction_locks/providers/transaction_lock_provider.dart';
import 'package:mobile_books/features/transaction_locks/utils/transaction_lock_validator.dart';

class LockWarningBanner extends ConsumerWidget {
  final TransactionLockModule module;
  final DateTime? date;

  const LockWarningBanner({
    super.key,
    required this.module,
    this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetDate = date ?? DateTime.now();
    final isLocked = ref.watch(transactionLockValidatorProvider).isLocked(module: module, date: targetDate);

    if (!isLocked) return const SizedBox.shrink();

    final activeLockAsync = ref.watch(activeTransactionLockProvider);
    final activeLock = activeLockAsync.value;

    String message = 'This period is locked for ${module.value}. Submissions are disabled.';
    if (activeLock != null) {
      final formattedLockDate = DateFormat('yyyy-MM-dd').format(activeLock.lockDate);
      message = 'All transactions on or before $formattedLockDate are locked for ${module.value}.';
      if (activeLock.reason != null && activeLock.reason!.trim().isNotEmpty) {
        message += '\nReason: ${activeLock.reason}';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.m),
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0),
            child: Icon(Icons.lock, color: AppColors.danger, size: 18.0),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
                fontSize: 13.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
