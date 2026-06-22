import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/quotes/data/models/quote.dart';
import 'package:mobile_books/features/quotes/presentation/providers/quote_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

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

class QuotesScreen extends ConsumerWidget {
  const QuotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotesState = ref.watch(filteredQuotesProvider);
    final filter = ref.watch(quotesListFilterProvider);
    final searchController = TextEditingController(text: ref.read(quoteSearchQueryProvider));

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
                  _filterChip(ref, 'accepted', 'Accepted', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip(ref, 'declined', 'Declined', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip(ref, 'expired', 'Expired', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip(ref, 'invoiced', 'Invoiced', filter),
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
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: quotes.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final quote = quotes[index];
                      return _QuoteListTile(quote: quote);
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
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
    WidgetRef ref,
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
