import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/quotes/data/models/quote.dart';
import 'package:mobile_books/features/quotes/presentation/providers/quote_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/widgets/common/loading_skeleton.dart';

/// Status badge color configuration matching the web frontend QuoteDetail.js
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

class QuotesScreen extends ConsumerStatefulWidget {
  const QuotesScreen({super.key});

  @override
  ConsumerState<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends ConsumerState<QuotesScreen> {
  String _sortBy = 'date';
  String _sortOrder = 'desc';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(quoteSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Quote> _sortQuotes(List<Quote> quotes, Map<int, String> customerMap) {
    final sorted = List<Quote>.from(quotes);
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
          cmp = a.quoteDate.compareTo(b.quoteDate);
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
    final quotesState = ref.watch(filteredQuotesProvider);
    final filter = ref.watch(quotesListFilterProvider);
    final searchController = _searchController;
    final customersState = ref.watch(customersProvider);

    final customers = customersState.value ?? [];
    final customerMap = {for (var c in customers) c.id: c.displayName ?? ''};

    return ResponsiveScaffold(
      currentRoute: '/quotes',
      appBar: AppBar(
        title: const Text('Quotes'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/quotes/new'),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
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
                        ref.read(quoteSearchQueryProvider.notifier).state = val,
                    decoration: InputDecoration(
                      hintText: 'Search by quote number, notes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                ref.read(quoteSearchQueryProvider.notifier).state = '';
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
                      case 'import':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Importing quotes...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        break;
                      case 'export':
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Quotes exported successfully to downloads'),
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
                        ref.read(quotesProvider.notifier).refresh();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Quotes list refreshed'),
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
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(Icons.file_download_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Import Quotes'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.file_upload_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Export Quotes'),
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

          // Inline Sorting Chips
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.xs,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    'Sort by: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ChoiceChip(
                    label: const Text('Date'),
                    selected: _sortBy == 'date',
                    onSelected: (val) {
                      if (val) setState(() => _sortBy = 'date');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    label: const Text('Amount'),
                    selected: _sortBy == 'amount',
                    onSelected: (val) {
                      if (val) setState(() => _sortBy = 'amount');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    label: const Text('Status'),
                    selected: _sortBy == 'status',
                    onSelected: (val) {
                      if (val) setState(() => _sortBy = 'status');
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    label: const Text('Customer'),
                    selected: _sortBy == 'customer',
                    onSelected: (val) {
                      if (val) setState(() => _sortBy = 'customer');
                    },
                  ),
                  const SizedBox(width: AppSpacing.s),
                  IconButton(
                    icon: Icon(
                      _sortOrder == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                    onPressed: () {
                      setState(() {
                        _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
                      });
                    },
                    tooltip: _sortOrder == 'asc' ? 'Ascending' : 'Descending',
                  ),
                ],
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
                  _filterChip('all', 'All', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip('draft', 'Draft', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip('sent', 'Sent', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip('accepted', 'Accepted', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip('declined', 'Declined', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip('expired', 'Expired', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip('invoiced', 'Invoiced', filter),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),

          // ─── List Content ───────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(quotesProvider.notifier).refresh(),
              child: quotesState.when(
                data: (quotes) {
                  if (quotes.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'No quotes found.',
                            style: TextStyle(color: AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    );
                  }
                  final sortedQuotes = _sortQuotes(quotes, customerMap);
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: sortedQuotes.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final quote = sortedQuotes[index];
                      return _QuoteListTile(quote: quote);
                    },
                  );
                },
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  itemCount: 6,
                  itemBuilder: (context, index) => LoadingSkeleton.skeletonListItem(),
                ),
                error: (error, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 100),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.l),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              error.toString(),
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(color: AppColors.danger),
                            ),
                            const SizedBox(height: AppSpacing.m),
                            ElevatedButton(
                              onPressed: () => ref
                                  .read(quotesProvider.notifier)
                                  .refresh(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    String value,
    String label,
    String currentFilter,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: currentFilter == value,
      onSelected: (val) {
        if (val) {
          ref.read(quotesListFilterProvider.notifier).state = value;
        }
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Individual Quote List Tile
// ─────────────────────────────────────────────────────────────

class _QuoteListTile extends StatelessWidget {
  final Quote quote;

  const _QuoteListTile({required this.quote});

  @override
  Widget build(BuildContext context) {
    final style = _getStatusStyle(quote.status);
    final dateStr = DateFormat('dd MMM yyyy').format(quote.quoteDate);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xs,
        horizontal: AppSpacing.s,
      ),
      title: Text(
        quote.quoteNumber,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 16.0,
            ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateStr,
              style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 4),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s,
                vertical: AppSpacing.xs / 2,
              ),
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(style.icon, size: 12, color: style.color),
                  const SizedBox(width: 4),
                  Text(
                    style.label,
                    style: TextStyle(
                      color: style.color,
                      fontSize: 9.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₹${quote.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
          ),
          const Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 10.0,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
      onTap: () => context.push('/quotes/${quote.id}'),
    );
  }
}
