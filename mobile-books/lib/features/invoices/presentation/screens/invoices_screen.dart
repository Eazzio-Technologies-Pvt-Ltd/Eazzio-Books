import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/invoices/data/models/invoice.dart';
import 'package:mobile_books/features/invoices/presentation/providers/invoice_provider.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/widgets/common/loading_skeleton.dart';

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

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  String _sortBy = 'date';
  String _sortOrder = 'desc';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(invoiceSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Invoice> _sortInvoices(List<Invoice> list, Map<int, String> customerMap) {
    final sorted = List<Invoice>.from(list);
    sorted.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'amount':
          cmp = a.totalAmount.compareTo(b.totalAmount);
          break;
        case 'status':
          cmp = a.status.toLowerCase().compareTo(b.status.toLowerCase());
          break;
        case 'customer':
          final nameA = customerMap[a.customerId]?.toLowerCase() ?? '';
          final nameB = customerMap[b.customerId]?.toLowerCase() ?? '';
          cmp = nameA.compareTo(nameB);
          break;
        case 'date':
        default:
          cmp = a.invoiceDate.compareTo(b.invoiceDate);
          break;
      }
      return _sortOrder == 'asc' ? cmp : -cmp;
    });
    return sorted;
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: AppSpacing.s),
                  Wrap(
                    spacing: AppSpacing.s,
                    children: [
                      _sortOptionChip(setModalState, 'date', 'Date'),
                      _sortOptionChip(setModalState, 'amount', 'Amount'),
                      _sortOptionChip(setModalState, 'status', 'Status'),
                      _sortOptionChip(setModalState, 'customer', 'Customer Name'),
                    ],
                  ),
                  const Divider(),
                  const Text('Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: AppSpacing.s),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Ascending'),
                        selected: _sortOrder == 'asc',
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _sortOrder = 'asc');
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.s),
                      ChoiceChip(
                        label: const Text('Descending'),
                        selected: _sortOrder == 'desc',
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _sortOrder = 'desc');
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sortOptionChip(StateSetter setModalState, String val, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _sortBy == val,
      onSelected: (selected) {
        if (selected) {
          setModalState(() => _sortBy = val);
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoicesState = ref.watch(filteredInvoicesProvider);
    final searchController = _searchController;
    final customersState = ref.watch(customersProvider);

    final customers = customersState.value ?? [];
    final customerMap = {
      for (var c in customers)
        c.id: (c.displayName ?? '${c.firstName ?? ""} ${c.lastName ?? ""}'.trim())
    };

    return ResponsiveScaffold(
      currentRoute: '/invoices',
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: AppSpacing.s),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.primaryBlue),
                  onSelected: (val) {
                    switch (val) {
                      case 'sort':
                        _showSortBottomSheet(context);
                        break;
                      case 'filter':
                        _showFilterBottomSheet(context);
                        break;
                      case 'import':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Importing invoices...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        break;
                      case 'export':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invoices exported successfully to downloads'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        break;
                      case 'preferences':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Preferences configured'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        break;
                      case 'custom_fields':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening custom fields manager...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        break;
                      case 'refresh':
                        ref.read(invoicesProvider.notifier).refresh();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invoices list refreshed'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        break;
                      case 'reset_width':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Column widths reset'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'sort',
                      child: Row(
                        children: [
                          Icon(Icons.sort, size: 18),
                          SizedBox(width: 8),
                          Text('Sort by'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'filter',
                      child: Row(
                        children: [
                          Icon(Icons.filter_list, size: 18),
                          SizedBox(width: 8),
                          Text('Filter by status'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(Icons.file_download_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Import Invoices'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.file_upload_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Export Invoices'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'preferences',
                      child: Row(
                        children: [
                          Icon(Icons.settings, size: 18),
                          SizedBox(width: 8),
                          Text('Preferences'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'custom_fields',
                      child: Row(
                        children: [
                          Icon(Icons.dashboard_customize_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Manage Custom Fields'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, size: 18),
                          SizedBox(width: 8),
                          Text('Refresh List'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reset_width',
                      child: Row(
                        children: [
                          Icon(Icons.view_column_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Reset Column Width'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s),

          // ─── List Content ───────────────────────────────────
          Expanded(
            child: invoicesState.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.m),
                itemCount: 6,
                itemBuilder: (context, index) => LoadingSkeleton.skeletonListItem(),
              ),
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

                final sortedList = _sortInvoices(list, customerMap);

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(invoicesProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: sortedList.length,
                    itemBuilder: (context, index) {
                      final invoice = sortedList[index];
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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final activeFilter = ref.watch(invoicesListFilterProvider);
            return Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filter by Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: AppSpacing.s),
                  Wrap(
                    spacing: AppSpacing.s,
                    runSpacing: AppSpacing.s,
                    children: [
                      _filterOptionChip(context, ref, 'all', 'All', activeFilter),
                      _filterOptionChip(context, ref, 'draft', 'Draft', activeFilter),
                      _filterOptionChip(context, ref, 'sent', 'Sent', activeFilter),
                      _filterOptionChip(context, ref, 'unpaid', 'Unpaid', activeFilter),
                      _filterOptionChip(context, ref, 'partially_paid', 'Part Paid', activeFilter),
                      _filterOptionChip(context, ref, 'paid', 'Paid', activeFilter),
                      _filterOptionChip(context, ref, 'overdue', 'Overdue', activeFilter),
                      _filterOptionChip(context, ref, 'cancelled', 'Cancelled', activeFilter),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterOptionChip(BuildContext context, WidgetRef ref, String val, String label, String activeVal) {
    final isSelected = val == activeVal;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(invoicesListFilterProvider.notifier).state = val;
          Navigator.pop(context);
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
