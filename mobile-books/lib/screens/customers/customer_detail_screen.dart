import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/common/app_button.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer record? This will soft-delete their database entry.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      final success = await ref.read(customerProvider.notifier).removeCustomer(widget.customerId);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer deleted successfully'), backgroundColor: AppColors.success),
          );
          context.pop();
        }
      } else {
        setState(() => _isDeleting = false);
        if (mounted) {
          final error = ref.read(customerProvider).errorMessage ?? 'Failed to delete customer';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    final customer = customerState.customers.firstWhere(
      (c) => c.id == widget.customerId,
      orElse: () => CustomerModel(
        id: 0,
        customerType: 'Business',
        currency: 'INR',
        openingBalance: 0.0,
      ),
    );

    if (customer.id == 0) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.primary),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(customer.printableName, style: AppTextStyles.h3.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => context.push('/customers/${customer.id}/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _isDeleting ? null : _handleDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            _buildSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          customer.printableName,
                          style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: customer.customerType == 'Individual'
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          customer.customerType,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: customer.customerType == 'Individual'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (customer.companyName != null && customer.companyName!.isNotEmpty)
                    Text('Company: ${customer.companyName!}', style: AppTextStyles.bodyMedium),
                  const Divider(height: 24, color: AppColors.border),
                  _buildHeaderBalance('OUTSTANDING BALANCE', customer.openingBalance, customer.currency),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Contact details Card
            _buildSectionCard(
              title: 'CONTACT DETAILS',
              child: Column(
                children: [
                  _buildRowItem('Email Address', customer.email ?? '-'),
                  _buildRowItem('Phone Work', customer.phone ?? '-'),
                  _buildRowItem('Mobile Phone', customer.mobile ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Invoicing configuration details
            _buildSectionCard(
              title: 'FINANCIAL CONFIGURATIONS',
              child: Column(
                children: [
                  _buildRowItem('Preferred Currency', customer.currency),
                  _buildRowItem('Tax Registration (PAN)', customer.pan ?? '-'),
                  _buildRowItem('Payment Terms', customer.paymentTerms ?? 'Due on receipt'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Remarks / remarks
            if (customer.remarks != null && customer.remarks!.isNotEmpty) ...[
              _buildSectionCard(
                title: 'REMARKS / NOTES',
                child: Text(
                  customer.remarks!,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
                ),
              ),
              const SizedBox(height: 24),
            ],
            AppButton(
              text: 'Edit Customer Info',
              onPressed: () => context.push('/customers/${customer.id}/edit'),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Delete Customer',
              variant: AppButtonVariant.ghost,
              onPressed: _isDeleting ? null : _handleDelete,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({String? title, required Widget child}) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const Divider(height: 20, color: AppColors.border),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildHeaderBalance(String label, double value, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        const SizedBox(height: 4),
        Text(
          AppFormatters.formatCurrency(value, symbol: currency == 'INR' ? '₹' : '$currency '),
          style: AppTextStyles.numeric.copyWith(
            fontSize: 20,
            color: value > 0 ? AppColors.error : AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildRowItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
