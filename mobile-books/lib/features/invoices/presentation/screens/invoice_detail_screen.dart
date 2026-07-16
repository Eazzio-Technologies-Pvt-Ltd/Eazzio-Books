import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/invoices/data/models/invoice.dart';
import 'package:mobile_books/features/invoices/data/models/invoice_item.dart';
import 'package:mobile_books/features/invoices/data/models/payment.dart';
import 'package:mobile_books/features/invoices/data/models/payment_schedule.dart';
import 'package:mobile_books/features/invoices/presentation/providers/invoice_provider.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/features/quotes/presentation/providers/quote_provider.dart'; // For salespersons & projects

import 'package:mobile_books/core/utils/sharing_helper.dart';
import 'package:mobile_books/features/settings/presentation/providers/settings_providers.dart';
import 'package:mobile_books/core/theme/app_icons.dart';

const Map<String, _StatusStyle> _statusStyles = {
  'draft':          _StatusStyle(Color(0xFFF1F5F9), Color(0xFF475569), 'DRAFT',          AppIcons.edit_note),
  'sent':           _StatusStyle(Color(0xFFFFFBEB), Color(0xFFB45309), 'SENT',           AppIcons.send),
  'unpaid':         _StatusStyle(Color(0xFFFFFBEB), Color(0xFFB45309), 'UNPAID',         AppIcons.money_off),
  'partially_paid': _StatusStyle(Color(0xFFEFF6FF), Color(0xFF1D4ED8), 'PARTIALLY PAID', AppIcons.hourglass_bottom),
  'paid':           _StatusStyle(Color(0xFFF0FDF4), Color(0xFF15803D), 'PAID',           AppIcons.check_circle_outline),
  'overdue':        _StatusStyle(Color(0xFFFEF2F2), Color(0xFFB91C1C), 'OVERDUE',        AppIcons.warning_amber),
  'cancelled':      _StatusStyle(Color(0xFFF1F5F9), Color(0xFF475569), 'CANCELLED',      AppIcons.cancel_outlined),
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
      const _StatusStyle(Color(0xFFF1F5F9), Color(0xFF475569), 'UNKNOWN', AppIcons.help_outline);
}

class InvoiceDetailScreen extends ConsumerWidget {
  final int invoiceId;

  const InvoiceDetailScreen({
    super.key,
    required this.invoiceId,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: const Text(
            'Are you sure you want to delete this invoice? This action cannot be undone.'),
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
        await ref.read(invoicesProvider.notifier).deleteInvoice(invoiceId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice deleted successfully')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString()),
                backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  void _showSendEmailSheet(BuildContext context, WidgetRef ref, Invoice invoice) {
    final toController = TextEditingController();
    final subjectController = TextEditingController(text: 'Tax Invoice ${invoice.invoiceNumber}');
    final bodyController = TextEditingController(
      text: 'Dear Customer,\n\nPlease find your tax invoice attached.\n\nInvoice Number: ${invoice.invoiceNumber}\nTotal: ₹${invoice.totalAmount.toStringAsFixed(2)}\nBalance Due: ₹${invoice.balanceDue.toStringAsFixed(2)}\n\nThank you for your business.',
    );

    ref.read(customersProvider).whenData((customers) {
      final customer = customers.where((c) => c.id == invoice.customerId).firstOrNull;
      if (customer != null && customer.email != null) {
        toController.text = customer.email!;
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
                      'Send Invoice via Email',
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
                                    await ref.read(invoicesProvider.notifier).sendEmail(
                                      invoiceId,
                                      to: toController.text.trim(),
                                      subject: subjectController.text.trim(),
                                      body: bodyController.text.trim(),
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Invoice email sent successfully!')),
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
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsState = ref.watch(invoiceDetailsProvider(invoiceId));
    final paymentsState = ref.watch(invoicePaymentsProvider(invoiceId));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Invoice Details'),
        actions: [
          detailsState.when(
            loading: () => const SizedBox(),
            error: (err, stack) => const SizedBox(),
            data: (details) {
              final invoice = details.invoice;
              return Row(
                children: [
                  if (invoice.status.toLowerCase() == 'draft')
                    IconButton(
                      icon: const Icon(AppIcons.mark_email_read_outlined),
                      tooltip: 'Mark as Sent',
                      onPressed: () async {
                        try {
                          await ref.read(invoicesProvider.notifier).markAsSent(invoiceId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invoice marked as sent successfully.')),
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
                    icon: const Icon(AppIcons.email_outlined),
                    tooltip: 'Email Statement',
                    onPressed: () => _showSendEmailSheet(context, ref, invoice),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.chat_outlined),
                    tooltip: 'WhatsApp Reminder',
                    onPressed: () async {
                      final customers = ref.read(customersProvider).value ?? [];
                      final customer = customers.where((c) => c.id == invoice.customerId).firstOrNull;
                      final phone = customer?.mobile ?? customer?.phone ?? customer?.workPhone ?? '';
                      if (phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Phone number not available'), backgroundColor: AppColors.danger),
                        );
                        return;
                      }
                      final businessName = ref.read(organizationSettingsProvider).value?.organizationName ?? 'our business';
                      final customerName = customer != null ? (customer.displayName ?? '${customer.firstName ?? ""} ${customer.lastName ?? ""}'.trim()) : 'Customer';
                      final totalAmt = invoice.totalAmount.toStringAsFixed(2);
                      final msg = "Dear $customerName, please find your invoice ${invoice.invoiceNumber} from $businessName. Total: ₹$totalAmt. Thank you for your business. Regards, $businessName.";
                      await SharingHelper.sendWhatsApp(phone: phone, message: msg);
                    },
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.sms_outlined),
                    tooltip: 'SMS Reminder',
                    onPressed: () async {
                      final customers = ref.read(customersProvider).value ?? [];
                      final customer = customers.where((c) => c.id == invoice.customerId).firstOrNull;
                      final phone = customer?.mobile ?? customer?.phone ?? customer?.workPhone ?? '';
                      if (phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Phone number not available'), backgroundColor: AppColors.danger),
                        );
                        return;
                      }
                      final businessName = ref.read(organizationSettingsProvider).value?.organizationName ?? 'our business';
                      final customerName = customer != null ? (customer.displayName ?? '${customer.firstName ?? ""} ${customer.lastName ?? ""}'.trim()) : 'Customer';
                      final totalAmt = invoice.totalAmount.toStringAsFixed(2);
                      final msg = "Dear $customerName, please find your invoice ${invoice.invoiceNumber} from $businessName. Total: ₹$totalAmt. Thank you for your business. Regards, $businessName.";
                      await SharingHelper.sendSMS(phone: phone, message: msg);
                    },
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.picture_as_pdf_outlined),
                    tooltip: 'Preview Document',
                    onPressed: () => context.push('/invoices/$invoiceId/document'),
                  ),
                  if (invoice.balanceDue > 0 && invoice.status.toLowerCase() != 'cancelled')
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: const Icon(AppIcons.payment, color: Colors.white, size: 18),
                        label: const Text('PAY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () => context.push('/invoices/${invoice.id}/record-payment?balanceDue=${invoice.balanceDue}'),
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'edit') {
                        context.push('/invoices/$invoiceId/edit');
                      } else if (val == 'delete') {
                        _confirmDelete(context, ref);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(AppIcons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Invoice'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(AppIcons.delete, color: AppColors.danger, size: 18),
                            SizedBox(width: 8),
                            Text('Delete Invoice', style: TextStyle(color: AppColors.danger)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: detailsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            err.toString(),
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        data: (details) {
          final invoice = details.invoice;
          final items = details.items;

          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Items'),
                    Tab(text: 'Payments'),
                    Tab(text: 'Instalments'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _OverviewTab(invoice: invoice),
                      _ItemsTab(items: items),
                      _PaymentsTab(paymentsState: paymentsState),
                      _SchedulesTab(schedules: invoice.paymentSchedules),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final Invoice invoice;

  const _OverviewTab({required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(customersProvider);
    final salespersonsState = ref.watch(salespersonsProvider);
    final projectsState = ref.watch(projectsProvider);

    final statusStyle = _getStatusStyle(invoice.status);
    final dateStr = DateFormat('dd MMM yyyy').format(invoice.invoiceDate);
    final dueDateStr = invoice.dueDate != null ? DateFormat('dd MMM yyyy').format(invoice.dueDate!) : '—';

    String customerName = 'Loading customer...';
    customersState.whenData((customers) {
      final customer = customers.where((c) => c.id == invoice.customerId).firstOrNull;
      if (customer != null) {
        customerName = customer.displayName ??
            '${customer.firstName ?? ""} ${customer.lastName ?? ""}'.trim();
        if (customerName.isEmpty) customerName = customer.email ?? 'Customer #${invoice.customerId}';
      }
    });

    String salespersonName = '—';
    if (invoice.salespersonId != null) {
      salespersonsState.whenData((list) {
        final sp = list.where((s) => s.id == invoice.salespersonId).firstOrNull;
        if (sp != null) salespersonName = sp.name;
      });
    }

    String projectName = '—';
    if (invoice.projectId != null) {
      projectsState.whenData((list) {
        final prj = list.where((p) => p.id == invoice.projectId).firstOrNull;
        if (prj != null) projectName = prj.projectName;
      });
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      invoice.invoiceNumber,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: statusStyle.bg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusStyle.icon, size: 14, color: statusStyle.color),
                          const SizedBox(width: 4),
                          Text(
                            statusStyle.label,
                            style: TextStyle(
                              color: statusStyle.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.l),
                _infoRow('Customer', customerName),
                _infoRow('Date', dateStr),
                _infoRow('Due Date', dueDateStr),
                _infoRow('Salesperson', salespersonName),
                _infoRow('Project', projectName),
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
                const Text(
                  'Tax & GST Details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Divider(height: AppSpacing.l),
                _infoRow('GST Type', invoice.gstType == 'intra_state' ? 'Intra-State GST' : (invoice.gstType == 'inter_state' ? 'Inter-State GST' : '—')),
                _infoRow('Customer GSTIN', invoice.customerGstin ?? '—'),
                _infoRow('Place of Supply', invoice.placeOfSupply ?? '—'),
                _infoRow('Supplier State', invoice.supplierState ?? '—'),
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
                const Text(
                  'Amount Summary',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Divider(height: AppSpacing.l),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '₹${invoice.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Balance Due', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
                    Text(
                      '₹${invoice.balanceDue.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.danger),
                    ),
                  ],
                ),
                if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                  const Divider(height: AppSpacing.l),
                  const Text('Customer Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(invoice.notes!, style: const TextStyle(color: AppColors.textSecondaryLight)),
                ],
                if (invoice.terms != null && invoice.terms!.isNotEmpty) ...[
                  const Divider(height: AppSpacing.l),
                  const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(invoice.terms!, style: const TextStyle(color: AppColors.textSecondaryLight)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsTab extends StatelessWidget {
  final List<InvoiceItem> items;

  const _ItemsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.m),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.itemName ?? 'Unnamed Item',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (item.description != null && item.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.description!, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                ],
                const Divider(height: AppSpacing.m),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Qty: ${item.quantity.toStringAsFixed(0)} ${item.unit ?? ""}'),
                    Text('Rate: ₹${item.unitPrice.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Discount: ${item.discount.toStringAsFixed(0)}${item.discountType == "percent" ? "%" : " flat"}'),
                    Text('Taxable Value: ₹${item.taxableValue.toStringAsFixed(2)}'),
                  ],
                ),
                if (item.cgstAmount > 0 || item.sgstAmount > 0 || item.igstAmount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (item.cgstAmount > 0)
                        Text('CGST: ${item.cgstRate}% (₹${item.cgstAmount.toStringAsFixed(2)})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      if (item.sgstAmount > 0)
                        Text('SGST: ${item.sgstRate}% (₹${item.sgstAmount.toStringAsFixed(2)})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                      if (item.igstAmount > 0)
                        Text('IGST: ${item.igstRate}% (₹${item.igstAmount.toStringAsFixed(2)})', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Line Total: ₹${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final AsyncValue<List<Payment>> paymentsState;

  const _PaymentsTab({required this.paymentsState});

  @override
  Widget build(BuildContext context) {
    return paymentsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(err.toString(), style: const TextStyle(color: AppColors.danger)),
      ),
      data: (payments) {
        if (payments.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.payment, size: 48, color: AppColors.textSecondaryLight),
                SizedBox(height: AppSpacing.s),
                Text('No payments recorded yet for this invoice.'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.m),
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            final dateStr = DateFormat('dd MMM yyyy').format(payment.paymentDate);

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.m),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${payment.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.m),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mode: ${payment.paymentMode ?? "cash"}'),
                        if (payment.reference != null && payment.reference!.isNotEmpty)
                          Text('Ref: ${payment.reference}'),
                      ],
                    ),
                    if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Notes: ${payment.notes}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SchedulesTab — displays instalment / payment-schedule entries
// ─────────────────────────────────────────────────────────────────────────────
class _SchedulesTab extends StatelessWidget {
  final List<PaymentSchedule> schedules;

  const _SchedulesTab({required this.schedules});

  Color _statusColor(PaymentSchedule s) {
    if (s.isPaid) return AppColors.success;
    if (s.isOverdue) return AppColors.danger;
    return AppColors.warning;
  }

  IconData _statusIcon(PaymentSchedule s) {
    if (s.isPaid) return AppIcons.check_circle_outline;
    if (s.isOverdue) return AppIcons.warning_amber_rounded;
    return AppIcons.schedule;
  }

  String _statusLabel(PaymentSchedule s) {
    if (s.isPaid) return 'PAID';
    if (s.isOverdue) return 'OVERDUE';
    if (s.status == 'partial') return 'PARTIAL';
    return 'PENDING';
  }

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.calendar_today, size: 48, color: AppColors.textSecondaryLight),
            SizedBox(height: AppSpacing.s),
            Text(
              'No instalment schedule for this invoice.',
              style: TextStyle(color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4),
            Text(
              'Add a schedule when creating or editing the invoice.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final totalDue = schedules.fold(0.0, (sum, s) => sum + s.dueAmount);
    final totalPaid = schedules.fold(0.0, (sum, s) => sum + s.paidAmount);
    final progress = totalDue > 0 ? (totalPaid / totalDue).clamp(0.0, 1.0) : 0.0;
    final paidCount = schedules.where((s) => s.isPaid).length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.m),
      children: [
        // ── Summary card ──
        Card(
          color: AppColors.primaryBlue.withValues(alpha: 0.07),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Instalment Progress',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '$paidCount / ${schedules.length} paid',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.textSecondaryLight.withValues(alpha: 0.2),
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: ₹${totalDue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                    Text(
                      'Collected: ₹${totalPaid.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        // ── Instalment rows ──
        ...schedules.asMap().entries.map((entry) {
          final idx = entry.key;
          final s = entry.value;
          final dueDateStr = s.dueDate != null
              ? DateFormat('dd MMM yyyy').format(s.dueDate!)
              : '—';
          final statusColor = _statusColor(s);

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.s),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Instalment ${idx + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(s), size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              _statusLabel(s),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppSpacing.m),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Due Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          Text(dueDateStr, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Due Amount', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          Text(
                            '₹${s.dueAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Paid', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          Text(
                            '₹${s.paidAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: s.paidAmount > 0 ? AppColors.success : null,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Balance', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          Text(
                            '₹${s.balanceAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: s.balanceAmount > 0 ? AppColors.danger : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
