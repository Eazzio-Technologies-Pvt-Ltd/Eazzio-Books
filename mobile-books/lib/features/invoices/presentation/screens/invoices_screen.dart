import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/invoices/data/models/invoice.dart';
import 'package:mobile_books/features/invoices/presentation/providers/invoice_provider.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

const Map<String, _StatusStyle> _statusStyles = {
  'draft':          _StatusStyle(Color(0xFFF1F5F9), Color(0xFF475569), 'DRAFT',          Icons.edit_note),
  'sent':           _StatusStyle(Color(0xFFFFFBEB), Color(0xFFB45309), 'SENT',           Icons.send),
  'unpaid':         _StatusStyle(Color(0xFFFFFBEB), Color(0xFFB45309), 'UNPAID',         Icons.money_off),
  'partially_paid': _StatusStyle(Color(0xFFEFF6FF), Color(0xFF1D4ED8), 'PARTIALLY PAID', Icons.hourglass_bottom),
  'paid':           _StatusStyle(Color(0xFFF0FDF4), Color(0xFF15803D), 'PAID',           Icons.check_circle_outline),
  'overdue':        _StatusStyle(Color(0xFFFEF2F2), Color(0xFFB91C1C), 'OVERDUE',        Icons.warning_amber),
  'cancelled':      _StatusStyle(Color(0xFFF1F5F9), Color(0xFF475569), 'CANCELLED',      Icons.cancel_outlined),
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

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesState = ref.watch(filteredInvoicesProvider);
    final filter = ref.watch(invoicesListFilterProvider);
    final searchController = TextEditingController(text: ref.read(invoiceSearchQueryProvider));

    return ResponsiveScaffold(
      currentRoute: '/invoices',
      appBar: AppBar(
        title: const Text('Invoices'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/invoices/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // ─── Search Bar ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            child: TextField(
              controller: searchController,
              onChanged: (val) =>
                  ref.read(invoiceSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search by invoice number, notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref.read(invoiceSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),

          // ─── Status Filter Chips ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(ref, 'all', 'All', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip(ref, 'draft', 'Draft', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip(ref, 'sent', 'Sent', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip(ref, 'unpaid', 'Unpaid', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip(ref, 'partially_paid', 'Part Paid', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip(ref, 'paid', 'Paid', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip(ref, 'overdue', 'Overdue', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip(ref, 'cancelled', 'Cancelled', filter),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),

          // ─── List Content ───────────────────────────────────
          Expanded(
            child: invoicesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  err.toString(),
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(invoicesProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No Invoices found',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                'Tap "+" to create a new Invoice',
                                style: TextStyle(color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(invoicesProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final invoice = list[index];
                      return _InvoiceCard(invoice: invoice);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
      WidgetRef ref, String key, String label, String currentSelection) {
    final isSelected = key == currentSelection;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          ref.read(invoicesListFilterProvider.notifier).state = key;
        }
      },
    );
  }
}

class _InvoiceCard extends ConsumerWidget {
  final Invoice invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(customersProvider);
    final statusStyle = _getStatusStyle(invoice.status);
    final dateStr = DateFormat('dd MMM yyyy').format(invoice.invoiceDate);

    String customerName = 'Loading customer...';
    customersState.whenData((customers) {
      final customer = customers.where((c) => c.id == invoice.customerId).firstOrNull;
      if (customer != null) {
        customerName = customer.displayName ??
            '${customer.firstName ?? ""} ${customer.lastName ?? ""}'.trim();
        if (customerName.isEmpty) {
          customerName = customer.email ?? 'Customer #${invoice.customerId}';
        }
      } else {
        customerName = 'Customer #${invoice.customerId}';
      }
    });

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => context.push('/invoices/${invoice.id}'),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryBlue,
                    ),
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
                        Icon(statusStyle.icon,
                            size: 14, color: statusStyle.color),
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
              const SizedBox(height: AppSpacing.s),
              Text(
                customerName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: $dateStr',
                    style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '₹${invoice.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (invoice.balanceDue > 0) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Due: ₹${invoice.balanceDue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
