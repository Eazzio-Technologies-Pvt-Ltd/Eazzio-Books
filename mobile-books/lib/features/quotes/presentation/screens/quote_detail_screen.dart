import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/quotes/data/models/quote.dart';
import 'package:mobile_books/features/quotes/data/models/quote_item.dart';
import 'package:mobile_books/features/quotes/presentation/providers/quote_provider.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/features/settings/data/services/settings_service.dart';

/// Status badge color configuration (duplicated from QuotesScreen for standalone use)
const Map<String, _StatusStyle> _statusStyles = {
  'draft':    _StatusStyle(Color(0xFFF1F5F9), Color(0xFF475569), 'DRAFT',    Icons.edit_note),
  'sent':     _StatusStyle(Color(0xFFFFFBEB), Color(0xFFB45309), 'SENT',     Icons.send),
  'accepted': _StatusStyle(Color(0xFFECFDF5), Color(0xFF047857), 'ACCEPTED', Icons.check_circle_outline),
  'declined': _StatusStyle(Color(0xFFFEF2F2), Color(0xFFB91C1C), 'DECLINED', Icons.cancel_outlined),
  'expired':  _StatusStyle(Color(0xFFFFF1F2), Color(0xFFBE123C), 'EXPIRED',  Icons.timer_off),
  'invoiced': _StatusStyle(Color(0xFFF0FDFA), Color(0xFF0F766E), 'INVOICED', Icons.receipt_long),
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

class QuoteDetailScreen extends ConsumerWidget {
  final int quoteId;

  const QuoteDetailScreen({
    super.key,
    required this.quoteId,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote'),
        content: const Text(
            'Are you sure you want to delete this quote? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(quotesProvider.notifier).deleteQuote(quoteId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quote deleted successfully')),
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

  Future<void> _confirmConvertToInvoice(
      BuildContext context, WidgetRef ref, Quote quote) async {
    if (quote.status.toLowerCase() == 'invoiced') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'This quote has already been converted to an invoice.'),
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
            'Convert this quote to an invoice? A new draft invoice will be created.'),
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
            .read(quotesProvider.notifier)
            .convertToInvoice(quoteId);
        if (context.mounted) {
          final invoiceId = result['invoiceId'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Quote converted to invoice${invoiceId != null ? " #$invoiceId" : ""} successfully!'),
            ),
          );
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

  void _showSendEmailSheet(
      BuildContext context, WidgetRef ref, Quote quote) {
    final toController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    // Prefill customer email
    ref.read(customersProvider).whenData((customers) {
      final customer = customers.where((c) => c.id == quote.customerId).firstOrNull;
      if (customer != null) {
        if (customer.email != null) {
          toController.text = customer.email!;
        }
        final customerName = customer.formattedName;
        subjectController.text = 'Quote ${quote.quoteNumber} - awaiting your approval';
        
        // Prefill organization name from active settings
        ref.read(settingsServiceProvider).getOrganizationSettings().then((settings) {
          final orgName = settings.organizationName;
          bodyController.text = 'Dear $customerName,\n\n'
              'Thank you for considering $orgName. We have prepared a quote for you.\n\n'
              'Quote Number: ${quote.quoteNumber}\n'
              'Date: ${DateFormat('dd/MM/yyyy').format(quote.quoteDate)}\n'
              'Total: ₹${quote.totalAmount.toStringAsFixed(2)}\n\n'
              'Please review the attached quote and let us know if you have any questions.\n\n'
              'Best regards,\n$orgName';
        }).catchError((_) {
          bodyController.text = 'Dear $customerName,\n\n'
              'Thank you for your business. We have prepared a quote for you.\n\n'
              'Quote Number: ${quote.quoteNumber}\n'
              'Total: ₹${quote.totalAmount.toStringAsFixed(2)}\n\n'
              'Please review the attached quote and let us know if you have any questions.\n\n'
              'Best regards,';
        });
      }
    });

    bool isSending = false;

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
        child: StatefulBuilder(
          builder: (sheetContext, setModalState) {

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Email Composer',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: isSending ? null : () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextField(
                    controller: toController,
                    decoration: const InputDecoration(
                      labelText: 'To *',
                      hintText: 'recipient@example.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isSending,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject *',
                      prefixIcon: Icon(Icons.subject),
                    ),
                    enabled: !isSending,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  TextField(
                    controller: bodyController,
                    decoration: const InputDecoration(
                      labelText: 'Message Body',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 8,
                    enabled: !isSending,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file_rounded, color: AppColors.primaryBlue),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: Text(
                            'Quote PDF Statement Attached',
                            style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.m),
                      ),
                      icon: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: isSending ? const Text('Sending...') : const Text('✉️ Send Email'),
                      onPressed: isSending
                          ? null
                          : () async {
                              if (toController.text.trim().isEmpty || subjectController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter recipient email and subject.'),
                                    backgroundColor: AppColors.warning,
                                  ),
                                );
                                return;
                              }
                              setModalState(() {
                                isSending = true;
                              });
                              try {
                                await ref
                                    .read(quotesProvider.notifier)
                                    .sendEmail(quoteId,
                                  to: toController.text.trim(),
                                  subject: subjectController.text.trim(),
                                  body: bodyController.text.trim(),
                                );
                                if (context.mounted) {
                                  Navigator.pop(sheetContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Email sent & quote marked as sent')),
                                  );
                                }
                              } catch (e) {
                                setModalState(() {
                                  isSending = false;
                                });
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: AppColors.danger),
                                  );
                                }
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(quoteDetailsProvider(quoteId));

    return detailState.when(
      data: (details) {
        final quote = details.quote;
        final items = details.items;
        final style = _getStatusStyle(quote.status);
        final isInvoiced = quote.status.toLowerCase() == 'invoiced';
        final isDeclined = quote.status.toLowerCase() == 'declined';
        final canConvert = !isInvoiced && !isDeclined;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Text(quote.quoteNumber),
              actions: [
                // Mark as Sent action
                if (quote.status.toLowerCase() == 'draft')
                  IconButton(
                    icon: const Icon(Icons.mark_email_read_outlined),
                    tooltip: 'Mark as Sent',
                    onPressed: () async {
                      try {
                        await ref.read(quotesProvider.notifier).markAsSent(quoteId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Quote marked as sent successfully.')),
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
                // Send email action
                IconButton(
                  icon: const Icon(Icons.email_outlined),
                  tooltip: 'Send Quote via Email',
                  onPressed: () =>
                      _showSendEmailSheet(context, ref, quote),
                ),
                // PDF view document preview action
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'Preview Document',
                  onPressed: () => context.push('/quotes/$quoteId/document'),
                ),
                // Convert to invoice action
                if (canConvert)
                  IconButton(
                    icon: const Icon(Icons.receipt_long_outlined),
                    tooltip: 'Convert to Invoice',
                    onPressed: () =>
                        _confirmConvertToInvoice(context, ref, quote),
                  ),
                // Edit action
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      context.push('/quotes/$quoteId/edit'),
                ),
                // Delete action
                IconButton(
                  icon:
                      const Icon(Icons.delete, color: AppColors.danger),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Items'),
                  Tab(text: 'Activity Logs'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _OverviewTab(quote: quote, style: style),
                _ItemsTab(items: items, quote: quote),
                _ActivityLogsTab(quote: quote),
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
                Text(err.toString(),
                    style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: AppSpacing.m),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(quoteDetailsProvider(quoteId)),
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

// ─────────────────────────────────────────────────────────────
// Overview Tab
// ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Quote quote;
  final _StatusStyle style;

  const _OverviewTab({required this.quote, required this.style});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('dd MMM yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Status Banner ───────────────────────────────
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
                      'Quote ${quote.quoteNumber}',
                      style: TextStyle(
                        color: style.color.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '₹${quote.totalAmount.toStringAsFixed(2)}',
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

          // ─── Quote Details Card ──────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quote Information', style: textTheme.titleMedium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.s),
                  _infoRow('Quote Number', quote.quoteNumber),
                  _infoRow('Quote Date', dateFormat.format(quote.quoteDate)),
                  _infoRow(
                    'Expiry Date',
                    quote.expiryDate != null
                        ? dateFormat.format(quote.expiryDate!)
                        : '—',
                  ),
                  _infoRow('Status', style.label),
                  _infoRow('Customer ID', quote.customerId.toString()),
                  _infoRow(
                    'Salesperson ID',
                    quote.salespersonId?.toString() ?? '—',
                  ),
                  _infoRow(
                    'Project ID',
                    quote.projectId?.toString() ?? '—',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // ─── Financial Summary Card ──────────────────────
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
                    '₹${quote.totalAmount.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // ─── Notes & Terms Card ──────────────────────────
          if ((quote.notes != null && quote.notes!.isNotEmpty) ||
              (quote.terms != null && quote.terms!.isNotEmpty))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes & Terms', style: textTheme.titleMedium),
                    const Divider(),
                    const SizedBox(height: AppSpacing.s),
                    if (quote.notes != null && quote.notes!.isNotEmpty) ...[
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(quote.notes!),
                      const SizedBox(height: AppSpacing.m),
                    ],
                    if (quote.terms != null && quote.terms!.isNotEmpty) ...[
                      const Text(
                        'Terms & Conditions',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(quote.terms!),
                    ],
                  ],
                ),
              ),
            ),

          // ─── Timestamps Card ─────────────────────────────
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
                    quote.createdAt != null
                        ? DateFormat('dd MMM yyyy, hh:mm a')
                            .format(quote.createdAt!.toLocal())
                        : '—',
                  ),
                  _infoRow(
                    'Last Updated',
                    quote.updatedAt != null
                        ? DateFormat('dd MMM yyyy, hh:mm a')
                            .format(quote.updatedAt!.toLocal())
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

// ─────────────────────────────────────────────────────────────
// Items Tab (Line Items Table)
// ─────────────────────────────────────────────────────────────

class _ItemsTab extends StatelessWidget {
  final List<QuoteItem> items;
  final Quote quote;

  const _ItemsTab({required this.items, required this.quote});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.l),
          child: Text(
            'No line items found for this quote.',
            style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    // Calculate subtotal from items
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
        // ─── Items list ────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.m),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _QuoteItemCard(item: item, index: index);
            },
          ),
        ),

        // ─── Summary Footer ───────────────────────────────
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
                '₹${quote.totalAmount.toStringAsFixed(2)}',
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
            style: labelStyle ??
                const TextStyle(color: AppColors.textSecondaryLight),
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

// ─────────────────────────────────────────────────────────────
// Individual Line Item Card
// ─────────────────────────────────────────────────────────────

class _QuoteItemCard extends StatelessWidget {
  final QuoteItem item;
  final int index;

  const _QuoteItemCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final lineBase = item.quantity * item.unitPrice;
    final discountAmt = item.discountType == 'percent'
        ? lineBase * (item.discount / 100)
        : item.discount;
    final afterDiscount = lineBase - discountAmt;
    final taxAmt = afterDiscount * (item.taxRate / 100);
    final lineTotal = afterDiscount + taxAmt;

    final discountLabel = item.discount > 0
        ? item.discountType == 'percent'
            ? '${item.discount}%'
            : '₹${item.discount.toStringAsFixed(2)}'
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: item name + line total
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
                      if (item.description != null &&
                          item.description!.isNotEmpty)
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

            // Detail chips row
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
                if (item.hsnCode != null && item.hsnCode!.isNotEmpty)
                  _detailChip('HSN: ${item.hsnCode}', AppColors.textSecondaryLight),
                if (item.unit != null && item.unit!.isNotEmpty)
                  _detailChip(item.unit!, AppColors.textSecondaryLight),
                if (item.taxRate > 0)
                  _detailChip('Tax: ${item.taxRate}%', AppColors.success),
                if (discountLabel != null)
                  _detailChip('Disc: $discountLabel', AppColors.danger),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActivityLogsTab extends StatelessWidget {
  final Quote quote;

  const _ActivityLogsTab({required this.quote});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Activity History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.m),
              _buildTimelineTile(
                context,
                title: 'Quote marked as ${quote.status.toUpperCase()}',
                subtitle: 'Status changed in the system',
                time: 'Today',
                isLast: false,
              ),
              _buildTimelineTile(
                context,
                title: 'Quote Created',
                subtitle: 'Quote ${quote.quoteNumber} generated',
                time: quote.createdAt != null 
                    ? DateFormat('dd MMM yyyy').format(quote.createdAt!.toLocal())
                    : DateFormat('dd MMM yyyy').format(quote.quoteDate),
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String time,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppColors.borderLight,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$subtitle • $time',
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
            ],
          ),
        ),
      ],
    );
  }
}
