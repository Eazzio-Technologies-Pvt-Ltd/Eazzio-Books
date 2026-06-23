import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/bills/presentation/providers/bill_provider.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile_books/core/network/network_client.dart';

class BillDetailScreen extends ConsumerWidget {
  final int billId;

  const BillDetailScreen({super.key, required this.billId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(billDetailsProvider(billId));
    final vendorsState = ref.watch(vendorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Details'),
        actions: [
          detailState.when(
            data: (details) => Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'Export PDF',
                  onPressed: () {
                    final baseUrl = ref.read(networkClientProvider).dio.options.baseUrl;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Bill PDF Link'),
                        content: SelectableText('$baseUrl/bills/$billId/pdf'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.email_outlined),
                  tooltip: 'Email Statement',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email coming soon for Bills')),
                    );
                  },
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          detailState.when(
            data: (details) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/bills/$billId/edit'),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          detailState.when(
            data: (details) => IconButton(
              icon: const Icon(Icons.delete, color: AppColors.danger),
              onPressed: () => _confirmDelete(context, ref, details.bill.billNumber),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailState.when(
        data: (details) {
          final bill = details.bill;
          final items = details.items;
          final dateStr = DateFormat('dd MMM yyyy').format(bill.billDate);
          final dueDateStr = bill.dueDate != null
              ? DateFormat('dd MMM yyyy').format(bill.dueDate!)
              : 'Not Specified';

          String vendorName = 'Loading vendor...';
          String vendorAddress = 'Loading address...';
          String vendorGstin = '';
          vendorsState.whenData((vendorsList) {
            final vendor = vendorsList.where((v) => v.id == bill.vendorId).firstOrNull;
            if (vendor != null) {
              vendorName = vendor.displayName;
              vendorAddress = vendor.billingAddress ?? 'No address provided';
              vendorGstin = vendor.gstin ?? '';
            } else {
              vendorName = 'Vendor #${bill.vendorId}';
              vendorAddress = '';
            }
          });

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.m),
            children: [
              // Record Payment Banner
              if (bill.balanceDue > 0 && bill.status.toLowerCase() != 'void') ...[
                Card(
                  color: AppColors.success.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Outstanding Balance', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('₹${bill.balanceDue.toStringAsFixed(2)} due', style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                          ],
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                          onPressed: () => context.push('/bills/$billId/record-payment?balanceDue=${bill.balanceDue}'),
                          child: const Text('Record Payment'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
              ],

              // Header Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            bill.billNumber,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                          ),
                          Text(
                            bill.status.toUpperCase().replaceAll('_', ' '),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.l),
                      _buildDetailRow('Vendor', vendorName),
                      if (vendorAddress.isNotEmpty) _buildDetailRow('Billing Address', vendorAddress),
                      if (vendorGstin.isNotEmpty) _buildDetailRow('Vendor GSTIN', vendorGstin),
                      _buildDetailRow('Bill Date', dateStr),
                      _buildDetailRow('Due Date', dueDateStr),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Items
              const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: AppSpacing.s),
              ...items.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.s),
                    child: ListTile(
                      title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Qty: ${item.quantity} × ₹${item.unitPrice.toStringAsFixed(2)}  (Tax: ${item.taxRate}%)'),
                      trailing: Text(
                        '₹${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  )),
              const SizedBox(height: AppSpacing.m),

              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    children: [
                      _buildDetailRow('Subtotal', '₹${bill.subtotal.toStringAsFixed(2)}'),
                      _buildDetailRow('Discount Total', '₹${bill.discountAmount.toStringAsFixed(2)}'),
                      _buildDetailRow('Tax Total', '₹${bill.taxAmount.toStringAsFixed(2)}'),
                      const Divider(height: AppSpacing.m),
                      _buildDetailRow('Grand Total', '₹${bill.totalAmount.toStringAsFixed(2)}', isBold: true),
                    ],
                  ),
                ),
              ),
              if (bill.notes != null && bill.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.m),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.s),
                        Text(bill.notes!),
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

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondaryLight)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: isBold ? AppColors.primaryBlue : AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String billNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text('Are you sure you want to delete Bill "$billNumber"?'),
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
                await ref.read(billsProvider.notifier).deleteBill(billId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bill deleted successfully.')),
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
