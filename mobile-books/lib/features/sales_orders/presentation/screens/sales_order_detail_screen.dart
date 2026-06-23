import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/sales_orders/data/models/sales_order.dart';
import 'package:mobile_books/features/sales_orders/data/models/sales_order_item.dart';
import 'package:mobile_books/features/sales_orders/presentation/providers/sales_order_provider.dart';

const Map<String, _StatusStyle> _statusStyles = {
  'draft':     _StatusStyle(Color(0xFFF1F5F9), Color(0xFF475569), 'DRAFT',     Icons.edit_note),
  'confirmed': _StatusStyle(Color(0xFFEFF6FF), Color(0xFF1D4ED8), 'CONFIRMED', Icons.check_circle_outline),
  'invoiced':  _StatusStyle(Color(0xFFECFDF5), Color(0xFF047857), 'INVOICED',  Icons.receipt_long),
  'cancelled': _StatusStyle(Color(0xFFFEF2F2), Color(0xFFB91C1C), 'CANCELLED', Icons.cancel_outlined),
};

class _StatusStyle {
  final Color bg;
  final Color color;
  final String label;
  final IconData icon;
  const _StatusStyle(this.bg, this.color, this.label, this.icon);
}

_StatusStyle _getStatusStyle(String status) {
  return _statusStyles[status.toLowerCase()] ??
      const _StatusStyle(Color(0xFFF1F5F9), Color(0xFF475569), 'UNKNOWN', Icons.help_outline);
}

class SalesOrderDetailScreen extends ConsumerWidget {
  final int salesOrderId;

  const SalesOrderDetailScreen({
    super.key,
    required this.salesOrderId,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sales Order'),
        content: const Text(
            'Are you sure you want to delete this sales order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(salesOrdersProvider.notifier).deleteSalesOrder(salesOrderId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sales order deleted successfully')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmConvertToInvoice(
      BuildContext context, WidgetRef ref, SalesOrder order) async {
    if (order.status.toLowerCase() == 'invoiced') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This sales order has already been invoiced.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Invoice'),
        content: const Text(
            'Convert this sales order to an invoice? A new draft invoice will be created.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Convert'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await ref
            .read(salesOrdersProvider.notifier)
            .convertToInvoice(salesOrderId);
        if (context.mounted) {
          final invoiceId = result['invoiceId'] ?? result['invoice_id'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Sales order converted to invoice${invoiceId != null ? " #$invoiceId" : ""} successfully!'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  void _showSendEmailSheet(
      BuildContext context, WidgetRef ref, SalesOrder order) {
    final toController = TextEditingController();
    final subjectController =
        TextEditingController(text: 'Sales Order ${order.salesOrderNumber}');
    final bodyController = TextEditingController(
      text:
          'Dear Customer,\n\nPlease find your Sales Order attached.\n\nSales Order Number: ${order.salesOrderNumber}\nTotal: ₹${order.total.toStringAsFixed(2)}\n\nThank you for your business.',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.m,
          right: AppSpacing.m,
          top: AppSpacing.m,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.m,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Send Sales Order via Email',
                    style: Theme.of(sheetContext)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: toController,
                decoration: const InputDecoration(
                  labelText: 'To (Email Address)',
                  hintText: 'customer@example.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.subject),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Message Body',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: AppSpacing.l),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text('Send Email'),
                  onPressed: () async {
                    if (toController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter recipient email.'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }
                    try {
                      await ref
                          .read(salesOrdersProvider.notifier)
                          .sendEmail(salesOrderId, {
                        'to': toController.text.trim(),
                        'subject': subjectController.text.trim(),
                        'body': bodyController.text.trim(),
                      });
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Sales order email sent successfully!')),
                        );
                      }
                    } catch (e) {
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.s),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(salesOrderDetailsProvider(salesOrderId));

    return detailState.when(
      data: (details) {
        final order = details.salesOrder;
        final items = details.items;
        final style = _getStatusStyle(order.status);
        final isInvoiced = order.status.toLowerCase() == 'invoiced';
        final isCancelled = order.status.toLowerCase() == 'cancelled';
        final canConvert = !isInvoiced && !isCancelled;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(order.salesOrderNumber),
              actions: [
                if (order.status.toLowerCase() == 'draft')
                  IconButton(
                    icon: const Icon(Icons.mark_email_read_outlined),
                    tooltip: 'Mark as Sent',
                    onPressed: () async {
                      try {
                        await ref.read(salesOrdersProvider.notifier).markAsSent(salesOrderId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sales Order confirmed/marked as sent successfully.')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.email_outlined),
                  tooltip: 'Send Sales Order via Email',
                  onPressed: () => _showSendEmailSheet(context, ref, order),
                ),
                if (canConvert)
                  IconButton(
                    icon: const Icon(Icons.receipt_long_outlined),
                    tooltip: 'Convert to Invoice',
                    onPressed: () => _confirmConvertToInvoice(context, ref, order),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.push('/sales-orders/$salesOrderId/edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.danger),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Items'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _OverviewTab(order: order, style: style),
                _ItemsTab(items: items, order: order),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(err.toString(), style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: AppSpacing.m),
                ElevatedButton(
                  onPressed: () => ref.invalidate(salesOrderDetailsProvider(salesOrderId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final SalesOrder order;
  final _StatusStyle style;

  const _OverviewTab({required this.order, required this.style});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: style.bg,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: style.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(style.icon, color: style.color, size: 28),
                const SizedBox(width: AppSpacing.m),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      style.label,
                      style: TextStyle(
                        color: style.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Sales Order ${order.salesOrderNumber}',
                      style: TextStyle(
                        color: style.color.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '₹${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: style.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Information', style: textTheme.titleMedium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.s),
                  _infoRow('Order Number', order.salesOrderNumber),
                  _infoRow('Order Date', dateFormat.format(order.salesOrderDate)),
                  _infoRow(
                    'Expected Shipment Date',
                    order.expectedShipmentDate != null
                        ? dateFormat.format(order.expectedShipmentDate!)
                        : '—',
                  ),
                  _infoRow(
                    'Reference Number',
                    order.referenceNumber ?? '—',
                  ),
                  _infoRow('Status', style.label),
                  _infoRow('Customer ID', order.customerId.toString()),
                  _infoRow(
                    'Salesperson ID',
                    order.salespersonId?.toString() ?? '—',
                  ),
                  _infoRow(
                    'Project ID',
                    order.projectId?.toString() ?? '—',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Financial Summary', style: textTheme.titleMedium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.s),
                  _infoRow(
                    'Total Amount',
                    '₹${order.total.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          if ((order.notes != null && order.notes!.isNotEmpty) ||
              (order.terms != null && order.terms!.isNotEmpty))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes & Terms', style: textTheme.titleMedium),
                    const Divider(),
                    const SizedBox(height: AppSpacing.s),
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(order.notes!),
                      const SizedBox(height: AppSpacing.m),
                    ],
                    if (order.terms != null && order.terms!.isNotEmpty) ...[
                      const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(order.terms!),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.m),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Activity', style: textTheme.titleMedium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.s),
                  _infoRow(
                    'Created At',
                    order.createdAt != null
                        ? DateFormat('dd MMM yyyy, hh:mm a')
                            .format(order.createdAt!.toLocal())
                        : '—',
                  ),
                  _infoRow(
                    'Last Updated',
                    order.updatedAt != null
                        ? DateFormat('dd MMM yyyy, hh:mm a')
                            .format(order.updatedAt!.toLocal())
                        : '—',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _ItemsTab extends StatelessWidget {
  final List<SalesOrderItem> items;
  final SalesOrder order;

  const _ItemsTab({required this.items, required this.order});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.l),
          child: Text(
            'No line items found for this sales order.',
            style: TextStyle(
                color: AppColors.textSecondaryLight, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    double subtotal = 0;
    double totalDiscount = 0;
    double totalTax = 0;

    for (final item in items) {
      final lineBase = item.quantity * item.unitPrice;
      final discountAmt = item.discountType == 'percent'
          ? lineBase * (item.discount / 100)
          : item.discount;
      final afterDiscount = lineBase - discountAmt;
      final taxAmt = afterDiscount * (item.taxRate / 100);

      subtotal += lineBase;
      totalDiscount += discountAmt;
      totalTax += taxAmt;
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.m),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _SalesOrderItemCard(item: item, index: index);
            },
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            border: const Border(
              top: BorderSide(color: AppColors.borderLight, width: 1),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            children: [
              _summaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
              if (totalDiscount > 0)
                _summaryRow(
                  'Total Discount',
                  '- ₹${totalDiscount.toStringAsFixed(2)}',
                  valueColor: AppColors.danger,
                ),
              if (totalTax > 0)
                _summaryRow(
                  'Total Tax',
                  '+ ₹${totalTax.toStringAsFixed(2)}',
                  valueColor: AppColors.success,
                ),
              const Divider(),
              _summaryRow(
                'Grand Total',
                '₹${order.total.toStringAsFixed(2)}',
                isBold: true,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
    TextStyle? labelStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: labelStyle ?? const TextStyle(color: AppColors.textSecondaryLight),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesOrderItemCard extends StatelessWidget {
  final SalesOrderItem item;
  final int index;

  const _SalesOrderItemCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final lineBase = item.quantity * item.unitPrice;
    final discountAmt = item.discountType == 'percent'
        ? lineBase * (item.discount / 100)
        : item.discount;
    final afterDiscount = lineBase - discountAmt;
    final taxAmt = afterDiscount * (item.taxRate / 100);
    final lineTotal = afterDiscount + taxAmt;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName ?? 'Item #${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (item.description != null && item.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '₹${lineTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.xs,
              children: [
                _detailChip(
                  'Qty: ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2)}',
                  AppColors.primaryBlue,
                ),
                _detailChip(
                  '@ ₹${item.unitPrice.toStringAsFixed(2)}',
                  AppColors.primaryBlue,
                ),
                if (item.discount > 0)
                  _detailChip(
                    'Disc: ${item.discountType == 'percent' ? "${item.discount}%" : "₹${item.discount.toStringAsFixed(2)}"}',
                    AppColors.danger,
                  ),
                if (item.taxRate > 0)
                  _detailChip(
                    'Tax: ${item.taxRate}%',
                    AppColors.success,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
