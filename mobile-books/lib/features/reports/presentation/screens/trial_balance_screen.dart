import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/reports/presentation/providers/reports_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

class TrialBalanceScreen extends ConsumerWidget {
  const TrialBalanceScreen({super.key});

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final currentRange = ref.read(trialBalanceDateRangeProvider);
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: currentRange,
    );

    if (pickedRange != null) {
      ref.read(trialBalanceDateRangeProvider.notifier).state = pickedRange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(trialBalanceReportProvider);
    final dateRange = ref.watch(trialBalanceDateRangeProvider);

    final df = DateFormat('yyyy-MM-dd');
    final String dateLabel = dateRange != null
        ? '${df.format(dateRange.start)} to ${df.format(dateRange.end)}'
        : 'All Time';

    return ResponsiveScaffold(
      currentRoute: '/reports/trial-balance',
      appBar: AppBar(
        title: const Text('Trial Balance'),
      ),
      body: Column(
        children: [
          // Filter card
          Card(
            margin: const EdgeInsets.all(AppSpacing.m),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date Range',
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
                      if (dateRange != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            ref.read(trialBalanceDateRangeProvider.notifier).state = null;
                          },
                        ),
                      ElevatedButton(
                        onPressed: () => _selectDateRange(context, ref),
                        child: const Text('Filter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Report Table Headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: const [
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 2)),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Account Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Debit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Credit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Report Data
          Expanded(
            child: reportState.when(
              data: (report) {
                if (report.accounts.isEmpty) {
                  return const Center(
                    child: Text(
                      'No entries found.',
                      style: TextStyle(color: AppColors.textSecondaryLight),
                    ),
                  );
                }

                double totalDebit = 0;
                double totalCredit = 0;
                for (final acc in report.accounts) {
                  totalDebit += acc.totalDebit;
                  totalCredit += acc.totalCredit;
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                  itemCount: report.accounts.length + 1, // +1 for Total row
                  itemBuilder: (context, index) {
                    if (index == report.accounts.length) {
                      // Total Row
                      return Container(
                        decoration: const BoxDecoration(
                          color: AppColors.backgroundLight,
                          border: Border(
                            top: BorderSide(color: AppColors.borderLight, width: 2),
                            bottom: BorderSide(color: AppColors.borderLight, width: 2),
                          ),
                        ),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(2),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(1),
                          },
                          children: [
                            TableRow(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text(
                                    _formatCurrency(totalDebit),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text(
                                    _formatCurrency(totalCredit),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    final acc = report.accounts[index];
                    return Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: AppColors.borderLight)),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Text(
                                acc.accountName,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Text(
                                acc.totalDebit > 0 ? _formatCurrency(acc.totalDebit) : '—',
                                style: const TextStyle(fontSize: 13),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Text(
                                acc.totalCredit > 0 ? _formatCurrency(acc.totalCredit) : '—',
                                style: const TextStyle(fontSize: 13),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
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
