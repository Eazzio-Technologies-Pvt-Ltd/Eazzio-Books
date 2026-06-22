import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/items/presentation/providers/item_provider.dart';

class InventoryMovementsScreen extends ConsumerWidget {
  const InventoryMovementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movementsAsync = ref.watch(allInventoryMovementsProvider);

    return ResponsiveScaffold(
      currentRoute: '/inventory/movements',
      appBar: AppBar(
        title: const Text('Inventory Movements'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/inventory/stock'),
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allInventoryMovementsProvider);
        },
        child: movementsAsync.when(
          data: (movements) {
            if (movements.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      const Text(
                        'No Inventory Movements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        'Record stock-ins, stock-outs or manual adjustments to view them here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      ElevatedButton(
                        onPressed: () => context.push('/inventory/stock'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('+ Record Adjustment'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final width = MediaQuery.of(context).size.width;
            final isWide = width > 600;

            if (isWide) {
              // Show as table/grid on wider screens
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Item Name')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Qty Change')),
                        DataColumn(label: Text('Stock Level')),
                        DataColumn(label: Text('Reason')),
                        DataColumn(label: Text('Reference')),
                      ],
                      rows: movements.map((m) {
                        return DataRow(
                          cells: [
                            DataCell(Text(_formatDate(m.createdAt ?? m.entryDate))),
                            DataCell(Text(
                              m.itemName ?? '—',
                              style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.primaryBlue),
                            )),
                            DataCell(_buildTypeChip(m.transactionType)),
                            DataCell(_buildQtyText(m.quantityChange)),
                            DataCell(Text(m.newStock != null ? '${m.newStock}' : '—')),
                            DataCell(Text(m.description ?? '—')),
                            DataCell(Text(m.referenceNumber ?? '—')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            }

            // Show as list of cards/tiles on mobile screens
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.m),
              itemCount: movements.length,
              itemBuilder: (context, index) {
                final m = movements[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: AppSpacing.m),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                m.itemName ?? 'Unnamed Item',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                            Text(
                              _formatDate(m.createdAt ?? m.entryDate),
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _buildTypeChip(m.transactionType),
                                const SizedBox(width: 8),
                                _buildQtyText(m.quantityChange),
                              ],
                            ),
                            if (m.newStock != null)
                              Text(
                                'New Stock: ${m.newStock}',
                                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                          ],
                        ),
                        if (m.description != null && m.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Reason: ${m.description}',
                            style: const TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ],
                        if (m.referenceNumber != null && m.referenceNumber!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ref: ${m.referenceNumber}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading movements: $err')),
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final localDt = dt.toLocal();
    return '${localDt.year}-${localDt.month.toString().padLeft(2, '0')}-${localDt.day.toString().padLeft(2, '0')} ${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildTypeChip(String? type) {
    final cleanType = (type ?? 'adjustment').toLowerCase();
    Color bgColor = Colors.amber.shade100;
    Color textColor = Colors.amber.shade900;
    String label = 'ADJUSTMENT';

    if (cleanType == 'stock_in') {
      bgColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
      label = 'STOCK IN';
    } else if (cleanType == 'stock_out') {
      bgColor = Colors.red.shade100;
      textColor = Colors.red.shade900;
      label = 'STOCK OUT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildQtyText(double change) {
    final prefix = change > 0 ? '+' : '';
    final color = change > 0 
        ? Colors.green.shade700 
        : change < 0 
            ? Colors.red.shade700 
            : Colors.grey.shade700;
    return Text(
      '$prefix$change',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }
}
