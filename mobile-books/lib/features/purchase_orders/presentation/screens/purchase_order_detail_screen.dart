import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/purchase_orders/presentation/providers/purchase_order_provider.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile_books/core/network/network_client.dart';

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
                        title: const Text('Purchase Order PDF Link'),
                        content: SelectableText('$baseUrl/purchase-orders/$purchaseOrderId/pdf'),
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
                  onPressed: () => _showSendEmailSheet(context, ref, details.purchaseOrder),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/purchase-orders/$purchaseOrderId/edit'),
                ),
              ],
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

  void _showSendEmailSheet(BuildContext context, WidgetRef ref, dynamic po) {
    final toController = TextEditingController();
    final subjectController = TextEditingController(text: 'Purchase Order ${po.purchaseOrderNumber}');
    final bodyController = TextEditingController(
      text: 'Dear Vendor,\n\nPlease find our purchase order attached.\n\nPO Number: ${po.purchaseOrderNumber}\nTotal Amount: ₹${po.totalAmount.toStringAsFixed(2)}\n\nBest regards.',
    );

    ref.read(vendorsProvider).whenData((vendors) {
      final vendor = vendors.where((v) => v.id == po.vendorId).firstOrNull;
      if (vendor != null && vendor.email != null) {
        toController.text = vendor.email!;
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        bool isSending = false;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: AppSpacing.m,
            right: AppSpacing.m,
            top: AppSpacing.m,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Send Purchase Order via Email',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: toController,
                      decoration: const InputDecoration(
                        labelText: 'To *',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isSending,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isSending,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    TextField(
                      controller: bodyController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Message Body',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isSending,
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSending ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        ElevatedButton(
                          onPressed: isSending
                              ? null
                              : () async {
                                  if (toController.text.trim().isEmpty ||
                                      subjectController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please fill out recipient email and subject.'),
                                        backgroundColor: AppColors.danger,
                                      ),
                                    );
                                    return;
                                  }

                                  setModalState(() {
                                    isSending = true;
                                  });

                                  try {
                                    await ref.read(purchaseOrdersProvider.notifier).sendEmail(
                                      purchaseOrderId,
                                      to: toController.text.trim(),
                                      subject: subjectController.text.trim(),
                                      body: bodyController.text.trim(),
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Purchase Order email sent successfully!')),
                                      );
                                    }
                                  } catch (e) {
                                    setModalState(() {
                                      isSending = false;
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: AppColors.danger),
                                      );
                                    }
                                  }
                                },
                          child: isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Send Email'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),
                  ],
                ),
              );
            }
          ),
        );
      },
    );
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
