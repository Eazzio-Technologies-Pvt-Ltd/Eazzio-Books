import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/reports/presentation/providers/reports_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/reports/presentation/widgets/report_nav_bar.dart';

import 'package:mobile_books/core/network/network_client.dart';

class PnlScreen extends ConsumerWidget {
  const PnlScreen({super.key});

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

  Future<void> _selectDateRange(BuildContext context, WidgetRef ref) async {
    final currentRange = ref.read(pnlDateRangeProvider);
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: currentRange,
    );

    if (pickedRange != null) {
      ref.read(pnlDateRangeProvider.notifier).state = pickedRange;
    }
  }

  void _showExportDialog(BuildContext context, WidgetRef ref, String format, DateTimeRange? dateRange) {
    final df = DateFormat('yyyy-MM-dd');
    final queryParams = <String>[];
    if (dateRange != null) {
      queryParams.add('startDate=${df.format(dateRange.start)}');
      queryParams.add('endDate=${df.format(dateRange.end)}');
    }
    queryParams.add('format=${format.toLowerCase()}');
    final baseUrl = ref.read(networkClientProvider).dio.options.baseUrl;
    final url = '$baseUrl/reports/profit-loss?${queryParams.join('&')}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('P&L Export ${format.toUpperCase()} Link'),
        content: SelectableText(url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(pnlReportProvider);
    final dateRange = ref.watch(pnlDateRangeProvider);

    final df = DateFormat('yyyy-MM-dd');
    final String dateLabel = dateRange != null
        ? '${df.format(dateRange.start)} to ${df.format(dateRange.end)}'
        : 'All Time';

    return ResponsiveScaffold(
      currentRoute: '/reports/profit-loss',
      appBar: AppBar(
        title: const Text('Profit and Loss'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: "Export CSV",
            onPressed: () => _showExportDialog(context, ref, 'CSV', dateRange),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: "Export PDF",
            onPressed: () => _showExportDialog(context, ref, 'PDF', dateRange),
          ),
        ],
      ),
      body: Column(
        children: [
          const ReportNavBar(currentRoute: '/reports/profit-loss'),
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
                            ref.read(pnlDateRangeProvider.notifier).state = null;
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

          Expanded(
            child: reportState.when(
              data: (report) {
                if (report.income.accounts.isEmpty && report.expense.accounts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'No records',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }
                final netProfitColor = report.netProfit >= 0 ? AppColors.success : AppColors.danger;

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  children: [
                    // Operating Income Section
                    _buildSectionHeader('Operating Income', AppColors.success),
                    ...report.income.accounts.map((acc) => _buildAccountRow(acc.accountName, acc.balance)),
                    _buildTotalRow('Total Operating Income', report.income.total),
                    const SizedBox(height: AppSpacing.m),

                    // Gross Profit Banner
                    Container(
                      color: AppColors.primaryBlue.withValues(alpha: 0.05),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Gross Profit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(_formatCurrency(report.income.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Operating Expenses Section
                    _buildSectionHeader('Operating Expenses', AppColors.danger),
                    ...report.expense.accounts.map((acc) => _buildAccountRow(acc.accountName, acc.balance)),
                    _buildTotalRow('Total Operating Expenses', report.expense.total),
                    const SizedBox(height: AppSpacing.xl),

                    // Net Profit Summary Card
                    Card(
                      color: netProfitColor.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: netProfitColor.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              report.netProfit >= 0 ? 'Net Profit' : 'Net Loss',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: netProfitColor),
                            ),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formatCurrency(report.netProfit),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: netProfitColor),
                                ),
                              ),
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

  Widget _buildSectionHeader(String title, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 2)),
      ),
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: accentColor),
      ),
    );
  }

  Widget _buildAccountRow(String name, double balance) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
          Text(_formatCurrency(balance), style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double total) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(_formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
