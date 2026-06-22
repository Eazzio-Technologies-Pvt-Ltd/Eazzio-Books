import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';

class VendorDetailScreen extends ConsumerWidget {
  final int vendorId;

  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(vendorDetailsProvider(vendorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Details'),
        actions: [
          detailState.when(
            data: (vendor) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/vendors/$vendorId/edit'),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          detailState.when(
            data: (vendor) => IconButton(
              icon: const Icon(Icons.delete, color: AppColors.danger),
              onPressed: () => _confirmDelete(context, ref, vendor.displayName),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailState.when(
        data: (vendor) => ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            // General Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.displayName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (vendor.companyName != null && vendor.companyName!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        vendor.companyName!,
                        style: const TextStyle(fontSize: 16, color: AppColors.textSecondaryLight),
                      ),
                    ],
                    const Divider(height: AppSpacing.l),
                    _buildDetailRow('Email', vendor.email ?? 'Not Provided'),
                    _buildDetailRow('Phone', vendor.phone ?? 'Not Provided'),
                    _buildDetailRow('GSTIN', vendor.gstin ?? 'Not Provided'),
                    _buildDetailRow('PAN', vendor.pan ?? 'Not Provided'),
                    _buildDetailRow('Status', vendor.status.toUpperCase(), isStatus: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // Financial Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Financial & Terms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: AppSpacing.m),
                    _buildDetailRow('Opening Balance', '₹${vendor.openingBalance.toStringAsFixed(2)}'),
                    _buildDetailRow('Payment Terms', vendor.paymentTerms ?? 'Net 0'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // Address Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Address Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: AppSpacing.m),
                    const Text('Billing Address', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(vendor.billingAddress ?? 'Not Provided'),
                    const SizedBox(height: AppSpacing.m),
                    const Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(vendor.shippingAddress ?? 'Not Provided'),
                  ],
                ),
              ),
            ),
            if (vendor.notes != null && vendor.notes!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.m),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(height: AppSpacing.m),
                      Text(vendor.notes!),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error.toString(), style: const TextStyle(color: AppColors.danger)),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondaryLight)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isStatus
                  ? (value.toLowerCase() == 'active' ? AppColors.success : AppColors.textSecondaryLight)
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String vendorName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vendor'),
        content: Text('Are you sure you want to delete vendor "$vendorName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(context); // Dismiss dialog
              try {
                await ref.read(vendorsProvider.notifier).deleteVendor(vendorId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vendor deleted successfully.')),
                );
                context.pop(); // Pop detail page
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete vendor: $e'), backgroundColor: AppColors.danger),
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
