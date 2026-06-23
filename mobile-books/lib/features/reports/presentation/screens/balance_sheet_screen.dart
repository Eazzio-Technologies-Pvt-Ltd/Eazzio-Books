import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/reports/presentation/providers/reports_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/reports/presentation/widgets/report_nav_bar.dart';

import 'package:mobile_books/core/network/network_client.dart';

class BalanceSheetScreen extends ConsumerWidget {
  const BalanceSheetScreen({super.key});

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    ).format(amount);
  }

  Future<void> _selectEndDate(BuildContext context, WidgetRef ref) async {
    final currentDate = ref.read(balanceSheetEndDateProvider);
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDate: currentDate ?? DateTime.now(),
    );

    if (pickedDate != null) {
      ref.read(balanceSheetEndDateProvider.notifier).state = pickedDate;
    }
  }

  void _showExportDialog(BuildContext context, WidgetRef ref, String format, DateTime? endDate) {
    final df = DateFormat('yyyy-MM-dd');
    final queryParams = <String>[];
    if (endDate != null) {
      queryParams.add('endDate=${df.format(endDate)}');
    }
    queryParams.add('format=${format.toLowerCase()}');
    final baseUrl = ref.read(networkClientProvider).dio.options.baseUrl;
    final url = '$baseUrl/reports/balance-sheet?${queryParams.join('&')}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Balance Sheet Export ${format.toUpperCase()} Link'),
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
    final reportState = ref.watch(balanceSheetReportProvider);
    final endDate = ref.watch(balanceSheetEndDateProvider);

    final df = DateFormat('yyyy-MM-dd');
    final String dateLabel = endDate != null ? df.format(endDate) : 'As of Today';

    return ResponsiveScaffold(
      currentRoute: '/reports/balance-sheet',
      appBar: AppBar(
        title: const Text('Balance Sheet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: "Export CSV",
            onPressed: () => _showExportDialog(context, ref, 'CSV', endDate),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: "Export PDF",
            onPressed: () => _showExportDialog(context, ref, 'PDF', endDate),
          ),
        ],
      ),
      body: Column(
        children: [
          const ReportNavBar(currentRoute: '/reports/balance-sheet'),
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
                      if (endDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            ref.read(balanceSheetEndDateProvider.notifier).state = null;
                          },
                        ),
                      ElevatedButton(
                        onPressed: () => _selectEndDate(context, ref),
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
                if (report.assets.accounts.isEmpty &&
                    report.liabilities.accounts.isEmpty &&
                    report.equity.accounts.isEmpty) {
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
                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  children: [
                    // Assets
                    _buildSectionHeader('Assets', AppColors.success),
                    if (report.assets.accounts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No assets recorded.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      )
                    else
                      ...report.assets.accounts.map((acc) => _buildAccountRow(acc.accountName, acc.balance)),
                    _buildTotalRow('Total Assets', report.assets.total),
                    const SizedBox(height: AppSpacing.l),

                    // Liabilities
                    _buildSectionHeader('Liabilities', AppColors.danger),
                    if (report.liabilities.accounts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No liabilities recorded.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      )
                    else
                      ...report.liabilities.accounts.map((acc) => _buildAccountRow(acc.accountName, acc.balance)),
                    _buildTotalRow('Total Liabilities', report.liabilities.total),
                    const SizedBox(height: AppSpacing.l),

                    // Equities
                    _buildSectionHeader('Equity', AppColors.primaryBlue),
                    if (report.equity.accounts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No equity recorded.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      )
                    else
                      ...report.equity.accounts.map((acc) => _buildAccountRow(acc.accountName, acc.balance)),
                    _buildTotalRow('Total Equity', report.equity.total),
                    const SizedBox(height: AppSpacing.xl),

                    // Total Liabilities and Equity Double-Check Banner
                    Container(
                      color: AppColors.primaryBlue.withValues(alpha: 0.05),
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Liabilities and Equity',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            _formatCurrency(report.liabilities.total + report.equity.total),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
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
