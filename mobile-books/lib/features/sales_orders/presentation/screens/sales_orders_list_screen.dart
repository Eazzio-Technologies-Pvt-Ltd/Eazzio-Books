import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/sales_orders/presentation/providers/sales_order_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

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

class SalesOrdersListScreen extends ConsumerWidget {
  const SalesOrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesOrdersState = ref.watch(filteredSalesOrdersProvider);
    final filter = ref.watch(salesOrdersListFilterProvider);
    final searchController = TextEditingController(text: ref.read(salesOrderSearchQueryProvider));

    return ResponsiveScaffold(
      currentRoute: '/sales-orders',
      appBar: AppBar(
        title: const Text('Sales Orders'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/sales-orders/new'),
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
                  ref.read(salesOrderSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search sales orders...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref.read(salesOrderSearchQueryProvider.notifier).state = '';
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
                  _filterChip(ref, 'confirmed', 'Confirmed', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip(ref, 'invoiced', 'Invoiced', filter),
                  const SizedBox(width: AppSpacing.s),
                  _filterChip(ref, 'cancelled', 'Cancelled', filter),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s),

          // ─── List Content ───────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(salesOrdersProvider.notifier).refresh(),
              child: salesOrdersState.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'No sales orders found.',
                            style: TextStyle(color: AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final statusStyle = _getStatusStyle(order.status);
                      final formattedDate = DateFormat('dd MMM yyyy').format(order.salesOrderDate);
                      final formattedTotal = NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: '₹',
                        decimalDigits: 2,
                      ).format(order.total);

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: AppSpacing.xs,
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.salesOrderNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusStyle.bg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusStyle.icon, size: 12, color: statusStyle.color),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusStyle.label,
                                      style: TextStyle(
                                        color: statusStyle.color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formattedDate,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                ),
                                Text(
                                  formattedTotal,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () => context.push('/sales-orders/${order.id}'),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(WidgetRef ref, String value, String label, String activeValue) {
    final isSelected = value == activeValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(salesOrdersListFilterProvider.notifier).state = value;
        }
      },
      selectedColor: AppColors.primaryBlue.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryBlue : AppColors.textSecondaryLight,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
