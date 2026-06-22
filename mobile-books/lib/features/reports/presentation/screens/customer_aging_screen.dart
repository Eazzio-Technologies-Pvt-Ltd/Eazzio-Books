import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/reports/presentation/providers/reports_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

class CustomerAgingScreen extends ConsumerStatefulWidget {
  const CustomerAgingScreen({super.key});

  @override
  ConsumerState<CustomerAgingScreen> createState() => _CustomerAgingScreenState();
}

class _CustomerAgingScreenState extends ConsumerState<CustomerAgingScreen> {
  String _searchQuery = '';

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

  Future<void> _selectAsOfDate(BuildContext context) async {
    final currentDate = ref.read(customerAgingAsOfDateProvider);
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDate: currentDate ?? DateTime.now(),
    );

    if (pickedDate != null) {
      ref.read(customerAgingAsOfDateProvider.notifier).state = pickedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(customerAgingReportProvider);
    final asOfDate = ref.watch(customerAgingAsOfDateProvider);

    final df = DateFormat('yyyy-MM-dd');
    final String dateLabel = asOfDate != null ? df.format(asOfDate) : 'Today';

    return ResponsiveScaffold(
      currentRoute: '/reports/customer-aging',
      appBar: AppBar(
        title: const Text('Customer Aging Summary'),
      ),
      body: Column(
        children: [
          // Filter Card
          Card(
            margin: const EdgeInsets.all(AppSpacing.m),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'As of Date',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              dateLabel,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (asOfDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                ref.read(customerAgingAsOfDateProvider.notifier).state = null;
                              },
                            ),
                          ElevatedButton(
                            onPressed: () => _selectAsOfDate(context),
                            child: const Text('As of Date'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search customer by name...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Horizontal scrollable table container
          Expanded(
            child: reportState.when(
              data: (report) {
                final filtered = report.entries.where((e) {
                  return e.name.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching aging balances found.',
                      style: TextStyle(color: AppColors.textSecondaryLight),
                    ),
                  );
                }

                // Compute column aggregates
                double totalCurrent = 0;
                double total30 = 0;
                double total60 = 0;
                double total90 = 0;
                double total90Plus = 0;
                double grandTotal = 0;

                for (final e in filtered) {
                  totalCurrent += e.current;
                  total30 += e.days1To30;
                  total60 += e.days31To60;
                  total90 += e.days61To90;
                  total90Plus += e.days90Plus;
                  grandTotal += e.totalDue;
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                    child: SizedBox(
                      width: 900,
                      child: Table(
                        columnWidths: const {
                          0: FixedColumnWidth(180),
                          1: FixedColumnWidth(110),
                          2: FixedColumnWidth(110),
                          3: FixedColumnWidth(110),
                          4: FixedColumnWidth(110),
                          5: FixedColumnWidth(110),
                          6: FixedColumnWidth(130),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 2)),
                            ),
                            children: const [
                              TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold)))),
                              TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Current', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right))),
                              TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('1-30 Days', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right))),
                              TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('31-60 Days', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right))),
                              TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('61-90 Days', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right))),
                              TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('90+ Days', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right))),
                              TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Text('Total Due', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right))),
                            ],
                          ),
                          ...filtered.map((e) {
                            return TableRow(
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                              ),
                              children: [
                                TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)))),
                                TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text(_formatCurrency(e.current), textAlign: TextAlign.right))),
                                TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text(_formatCurrency(e.days1To30), textAlign: TextAlign.right, style: TextStyle(color: e.days1To30 > 0 ? AppColors.warning : null)))),
                                TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text(_formatCurrency(e.days31To60), textAlign: TextAlign.right, style: TextStyle(color: e.days31To60 > 0 ? AppColors.warning : null)))),
                                TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text(_formatCurrency(e.days61To90), textAlign: TextAlign.right, style: TextStyle(color: e.days61To90 > 0 ? AppColors.danger : null)))),
                                TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text(_formatCurrency(e.days90Plus), textAlign: TextAlign.right, style: TextStyle(color: e.days90Plus > 0 ? AppColors.danger : null, fontWeight: e.days90Plus > 0 ? FontWeight.bold : null)))),
                                TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10.0), child: Text(_formatCurrency(e.totalDue), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)))),
                              ],
                            );
                          }),
                          TableRow(
                            decoration: const BoxDecoration(
                              color: AppColors.backgroundLight,
                              border: Border(top: BorderSide(color: AppColors.borderLight, width: 2)),
                            ),
                            children: [
                              const TableCell(child: Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)))),
                              TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text(_formatCurrency(totalCurrent), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)))),
                              TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text(_formatCurrency(total30), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)))),
                              TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text(_formatCurrency(total60), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)))),
                              TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text(_formatCurrency(total90), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)))),
                              TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text(_formatCurrency(total90Plus), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)))),
                              TableCell(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text(_formatCurrency(grandTotal), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
