import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/reports/presentation/providers/reports_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

class CashFlowScreen extends ConsumerWidget {
  const CashFlowScreen({super.key});

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final currentRange = ref.read(cashFlowDateRangeProvider);
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: currentRange,
    );

    if (pickedRange != null) {
      ref.read(cashFlowDateRangeProvider.notifier).state = pickedRange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(cashFlowReportProvider);
    final dateRange = ref.watch(cashFlowDateRangeProvider);

    final df = DateFormat('yyyy-MM-dd');
    final String dateLabel = dateRange != null
        ? '${df.format(dateRange.start)} to ${df.format(dateRange.end)}'
        : 'All Time';

    return ResponsiveScaffold(
      currentRoute: '/reports/cash-flow',
      appBar: AppBar(
        title: const Text('Cash Flow Statement'),
      ),
      body: Column(
        children: [
          // Filter Card
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
                            ref.read(cashFlowDateRangeProvider.notifier).state = null;
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

          // Cash Flow Data
          Expanded(
            child: reportState.when(
              data: (report) {
                final flowColor = report.netCashFlow >= 0 ? AppColors.success : AppColors.danger;

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 2)),
                      ),
                      padding: const EdgeInsets.only(bottom: AppSpacing.s),
                      margin: const EdgeInsets.only(bottom: AppSpacing.s),
                      child: const Text(
                        'Operating Activities',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryBlue),
                      ),
                    ),
                    if (report.operatingActivities.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.l),
                        child: Center(
                          child: Text(
                            'No transaction flows found.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ),
                      )
                    else
                      ...report.operatingActivities.map((activity) {
                        final isPositive = activity.amount >= 0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  activity.description,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                _formatCurrency(activity.amount),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? AppColors.success : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: AppSpacing.xl),

                    // Net Cash Flow summary banner
                    Card(
                      color: flowColor.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: flowColor.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Net Cash Flow',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: flowColor),
                            ),
                            Text(
                              _formatCurrency(report.netCashFlow),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: flowColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
