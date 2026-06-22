import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/purchase_orders/presentation/providers/purchase_order_provider.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';

class PurchaseOrderDetailScreen extends ConsumerWidget {
  final int purchaseOrderId;

  const PurchaseOrderDetailScreen({super.key, required this.purchaseOrderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(purchaseOrderDetailsProvider(purchaseOrderId));
    final vendorsState = ref.watch(vendorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Order Details'),
        actions: [
          detailState.when(
            data: (details) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/purchase-orders/$purchaseOrderId/edit'),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          detailState.when(
            data: (details) => IconButton(
              icon: const Icon(Icons.delete, color: AppColors.danger),
              onPressed: () => _confirmDelete(context, ref, details.purchaseOrder.purchaseOrderNumber),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailState.when(
        data: (details) {
          final po = details.purchaseOrder;
          final items = details.items;
          final dateStr = DateFormat('dd MMM yyyy').format(po.purchaseOrderDate);
          final deliveryDateStr = po.expectedDeliveryDate != null
              ? DateFormat('dd MMM yyyy').format(po.expectedDeliveryDate!)
              : 'Not Specified';

          String vendorName = 'Loading vendor...';
          String vendorAddress = 'Loading address...';
          String vendorGstin = '';
          vendorsState.whenData((vendorsList) {
            final vendor = vendorsList.where((v) => v.id == po.vendorId).firstOrNull;
            if (vendor != null) {
              vendorName = vendor.displayName;
              vendorAddress = vendor.billingAddress ?? 'No address provided';
              vendorGstin = vendor.gstin ?? '';
            } else {
              vendorName = 'Vendor #${po.vendorId}';
              vendorAddress = '';
            }
          });

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.m),
            children: [
              // Conversion banner for convert to bill
              if (po.status.toLowerCase() != 'closed' && po.status.toLowerCase() != 'cancelled') ...[
                Card(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Convert this order to a Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                        ElevatedButton(
                          onPressed: () => _convertToBill(context, ref),
                          child: const Text('Convert'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
              ],

              // Header Details
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
                            po.purchaseOrderNumber,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                          ),
                          Text(
                            po.status.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.l),
                      _buildDetailRow('Vendor', vendorName),
                      if (vendorAddress.isNotEmpty) _buildDetailRow('Billing Address', vendorAddress),
                      if (vendorGstin.isNotEmpty) _buildDetailRow('Vendor GSTIN', vendorGstin),
                      _buildDetailRow('PO Date', dateStr),
                      _buildDetailRow('Expected Delivery', deliveryDateStr),
                      if (po.referenceNumber != null) _buildDetailRow('Reference', po.referenceNumber!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Items Table/List
              const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: AppSpacing.s),
              ...items.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.s),
                    child: ListTile(
                      title: Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Qty: ${item.quantity} × ₹${item.rate.toStringAsFixed(2)}  (Tax: ${item.taxRate}%)'),
                      trailing: Text(
                        '₹${item.lineTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  )),
              const SizedBox(height: AppSpacing.m),

              // Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    children: [
                      _buildDetailRow('Subtotal', '₹${po.subtotal.toStringAsFixed(2)}'),
                      _buildDetailRow('Discount Total', '₹${po.discountTotal.toStringAsFixed(2)}'),
                      _buildDetailRow('Tax Total', '₹${po.taxTotal.toStringAsFixed(2)}'),
                      const Divider(height: AppSpacing.m),
                      _buildDetailRow('Grand Total', '₹${po.totalAmount.toStringAsFixed(2)}', isBold: true),
                    ],
                  ),
                ),
              ),
              if (po.notes != null && po.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.m),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.s),
                        Text(po.notes!),
                      ],
                    ),
                  ),
                ),
              ],
              if (po.termsConditions != null && po.termsConditions!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.m),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: AppSpacing.s),
                        Text(po.termsConditions!),
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

  void _convertToBill(BuildContext context, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ref.read(purchaseOrdersProvider.notifier).convertToBill(purchaseOrderId);
      Navigator.pop(context); // Pop loading spinner
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Converted to Bill successfully.')),
      );
      // Optional navigate: context.push('/bills/$billId');
    } catch (e) {
      Navigator.pop(context); // Pop loading spinner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to convert: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String poNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Purchase Order'),
        content: Text('Are you sure you want to delete Purchase Order "$poNumber"?'),
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
                await ref.read(purchaseOrdersProvider.notifier).deletePurchaseOrder(purchaseOrderId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Purchase Order deleted successfully.')),
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
