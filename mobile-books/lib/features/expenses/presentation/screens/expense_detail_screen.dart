import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/expenses/presentation/providers/expense_provider.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';

class ExpenseDetailScreen extends ConsumerWidget {
  final int expenseId;

  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(expenseDetailsProvider(expenseId));
    final vendorsState = ref.watch(vendorsProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Expense Details'),
        actions: [
          detailState.when(
            data: (expense) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/expenses/$expenseId/edit'),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          detailState.when(
            data: (expense) => IconButton(
              icon: const Icon(Icons.delete, color: AppColors.danger),
              onPressed: () => _confirmDelete(context, ref, expense.category),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailState.when(
        data: (expense) {
          final dateStr = DateFormat('dd MMM yyyy').format(expense.expenseDate);

          String vendorName = expense.vendorName ?? 'Loading vendor...';
          if (expense.vendorId != null && expense.vendorName == null) {
            vendorsState.whenData((vendors) {
              final vendor = vendors.where((v) => v.id == expense.vendorId).firstOrNull;
              if (vendor != null) {
                vendorName = vendor.displayName;
              } else {
                vendorName = 'Vendor #${expense.vendorId}';
              }
            });
          } else if (expense.vendorId == null) {
            vendorName = 'No Vendor';
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.m),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.category,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        '₹${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: AppSpacing.l),
                      _buildDetailRow('Vendor', vendorName),
                      _buildDetailRow('Expense Date', dateStr),
                      _buildDetailRow('Status', expense.status.toUpperCase(), isStatus: true),
                      if (expense.reference != null) _buildDetailRow('Reference', expense.reference!),
                      if (expense.attachmentUrl != null) ...[
                        const Divider(height: AppSpacing.l),
                        const Text('Attachment / Receipt Path', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          expense.attachmentUrl!,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (expense.description != null && expense.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.m),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Description', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.s),
                        Text(expense.description!),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error.toString(), style: const TextStyle(color: AppColors.danger)),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondaryLight)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isStatus
                  ? (value.toLowerCase() == 'paid' ? AppColors.success : AppColors.warning)
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete this "$category" expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(expensesProvider.notifier).deleteExpense(expenseId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense deleted successfully.')),
                );
                context.pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.danger),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
