import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/reports/presentation/providers/reports_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/reports/presentation/widgets/report_nav_bar.dart';
import 'package:mobile_books/features/reports/data/models/pnl_report.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

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

  Future<void> _exportCSV(BuildContext context, ProfitAndLossReport report, DateTimeRange? dateRange) async {
    final df = DateFormat('yyyy-MM-dd');
    final rangeStr = dateRange != null
        ? '${df.format(dateRange.start)}_to_${df.format(dateRange.end)}'
        : 'all_time';

    final revenueAccounts = <PnlAccount>[];
    final otherIncomeAccounts = <PnlAccount>[];
    double totalRevenue = 0.0;
    double totalOtherIncome = 0.0;

    for (final acc in report.income.accounts) {
      final lower = acc.accountName.toLowerCase();
      final isOther = lower.contains('other income') ||
          lower.contains('interest') ||
          lower.contains('dividend') ||
          lower.contains('discount received') ||
          lower.contains('commission') ||
          lower.contains('gain') ||
          lower.contains('rent received') ||
          lower.contains('bad debts') ||
          lower.contains('insurance claim') ||
          lower.contains('scrap') ||
          lower.contains('refund');
      if (isOther) {
        otherIncomeAccounts.add(acc);
        totalOtherIncome += acc.balance;
      } else {
        revenueAccounts.add(acc);
        totalRevenue += acc.balance;
      }
    }

    var csv = "Account Name,Balance (INR)\n";
    csv += "--- A) REVENUE FROM OPERATIONS ---\n";
    for (final acc in revenueAccounts) {
      csv += '"${acc.accountName}",${acc.balance.toStringAsFixed(2)}\n';
    }
    csv += '"Total Revenue from Operations",${totalRevenue.toStringAsFixed(2)}\n\n';

    csv += "--- B) OTHER INCOME ---\n";
    for (final acc in otherIncomeAccounts) {
      csv += '"${acc.accountName}",${acc.balance.toStringAsFixed(2)}\n';
    }
    csv += '"Total Other Income",${totalOtherIncome.toStringAsFixed(2)}\n\n';
    csv += '"Total Incomes (A + B)",${(totalRevenue + totalOtherIncome).toStringAsFixed(2)}\n\n';

    csv += "--- OPERATING EXPENSES ---\n";
    for (final acc in report.expense.accounts) {
      csv += '"${acc.accountName}",${acc.balance.toStringAsFixed(2)}\n';
    }
    csv += '"Total Operating Expenses",${report.expense.total.toStringAsFixed(2)}\n\n';
    csv += '"${report.netProfit >= 0 ? "Net Profit" : "Net Loss"}",${report.netProfit.toStringAsFixed(2)}\n';

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Profit_And_Loss_$rangeStr.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], subject: 'Profit and Loss Report');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _exportPDF(BuildContext context, ProfitAndLossReport report, DateTimeRange? dateRange) async {
    final df = DateFormat('yyyy-MM-dd');
    final rangeStr = dateRange != null
        ? '${df.format(dateRange.start)} to ${df.format(dateRange.end)}'
        : 'All Time';

    final revenueAccounts = <PnlAccount>[];
    final otherIncomeAccounts = <PnlAccount>[];
    double totalRevenue = 0.0;
    double totalOtherIncome = 0.0;

    for (final acc in report.income.accounts) {
      final lower = acc.accountName.toLowerCase();
      final isOther = lower.contains('other income') ||
          lower.contains('interest') ||
          lower.contains('dividend') ||
          lower.contains('discount received') ||
          lower.contains('commission') ||
          lower.contains('gain') ||
          lower.contains('rent received') ||
          lower.contains('bad debts') ||
          lower.contains('insurance claim') ||
          lower.contains('scrap') ||
          lower.contains('refund');
      if (isOther) {
        otherIncomeAccounts.add(acc);
        totalOtherIncome += acc.balance;
      } else {
        revenueAccounts.add(acc);
        totalRevenue += acc.balance;
      }
    }

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Profit and Loss Statement', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(rangeStr, style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Incomes
            pw.Text('Incomes', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#065f46'))),
            pw.Divider(color: PdfColor.fromHex('#e2e8f0')),
            
            pw.Text('A) Revenue from Operations', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0f766e'))),
            pw.SizedBox(height: 5),
            if (revenueAccounts.isEmpty)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No revenue from operations accounts found.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                  pw.Text('0.00'),
                ],
              )
            else
              ...revenueAccounts.map((acc) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(acc.accountName),
                  pw.Text(acc.balance.toStringAsFixed(2)),
                ],
              )),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Revenue from Operations', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('INR ${totalRevenue.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 15),

            pw.Text('B) Other Income', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0f766e'))),
            pw.SizedBox(height: 5),
            if (otherIncomeAccounts.isEmpty)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No other income accounts found.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                  pw.Text('0.00'),
                ],
              )
            else
              ...otherIncomeAccounts.map((acc) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(acc.accountName),
                  pw.Text(acc.balance.toStringAsFixed(2)),
                ],
              )),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Other Income', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('INR ${totalOtherIncome.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 15),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Incomes (A + B)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('INR ${(totalRevenue + totalOtherIncome).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Divider(color: PdfColor.fromHex('#e2e8f0')),
            pw.SizedBox(height: 20),

            // Gross Profit
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Gross Profit', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1d4ed8'))),
                pw.Text('INR ${(totalRevenue + totalOtherIncome).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1d4ed8'))),
              ],
            ),
            pw.Divider(color: PdfColor.fromHex('#e2e8f0')),
            pw.SizedBox(height: 20),

            // Operating Expenses
            pw.Text('Operating Expenses', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#b91c1c'))),
            pw.Divider(color: PdfColor.fromHex('#e2e8f0')),
            if (report.expense.accounts.isEmpty)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No operating expenses accounts found.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                  pw.Text('0.00'),
                ],
              )
            else
              ...report.expense.accounts.map((acc) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(acc.accountName),
                  pw.Text(acc.balance.toStringAsFixed(2)),
                ],
              )),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Operating Expenses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('INR ${report.expense.total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Divider(color: PdfColor.fromHex('#e2e8f0')),
            pw.SizedBox(height: 30),

            // Net Profit/Loss Banner
            pw.Container(
              color: report.netProfit >= 0 ? PdfColor.fromHex('#f0fdf4') : PdfColor.fromHex('#fef2f2'),
              padding: const pw.EdgeInsets.all(12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    report.netProfit >= 0 ? 'Net Profit' : 'Net Loss',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: report.netProfit >= 0 ? PdfColor.fromHex('#15803d') : PdfColor.fromHex('#b91c1c')),
                  ),
                  pw.Text(
                    'INR ${report.netProfit.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: report.netProfit >= 0 ? PdfColor.fromHex('#15803d') : PdfColor.fromHex('#b91c1c')),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    try {
      final pdfBytes = await doc.save();
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Profit_And_Loss_${df.format(dateRange?.start ?? DateTime.now())}_to_${df.format(dateRange?.end ?? DateTime.now())}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print PDF: $e'), backgroundColor: AppColors.danger),
      );
    }
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
            onPressed: () {
              reportState.whenData((report) {
                _exportCSV(context, report, dateRange);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: "Export PDF",
            onPressed: () {
              reportState.whenData((report) {
                _exportPDF(context, report, dateRange);
              });
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dateRange != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            ref.read(pnlDateRangeProvider.notifier).state = null;
                          },
                        ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                        ),
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
                // Split Income into Revenue from Operations and Other Income
                final revenueAccounts = <PnlAccount>[];
                final otherIncomeAccounts = <PnlAccount>[];
                double totalRevenue = 0.0;
                double totalOtherIncome = 0.0;

                for (final acc in report.income.accounts) {
                  final lower = acc.accountName.toLowerCase();
                  final isOther = lower.contains('other income') ||
                      lower.contains('interest') ||
                      lower.contains('dividend') ||
                      lower.contains('discount received') ||
                      lower.contains('commission') ||
                      lower.contains('gain') ||
                      lower.contains('rent received') ||
                      lower.contains('bad debts') ||
                      lower.contains('insurance claim') ||
                      lower.contains('scrap') ||
                      lower.contains('refund');
                  if (isOther) {
                    otherIncomeAccounts.add(acc);
                    totalOtherIncome += acc.balance;
                  } else {
                    revenueAccounts.add(acc);
                    totalRevenue += acc.balance;
                  }
                }

                final netProfitColor = report.netProfit >= 0 ? AppColors.success : AppColors.danger;

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  children: [
                    // Incomes Main Section
                    _buildSectionHeader('Incomes', AppColors.success),
                    
                    // A) Revenue from Operations
                    _buildSubSectionHeader('A) Revenue from Operations'),
                    if (revenueAccounts.isEmpty)
                      _buildEmptyRow('No revenue from operations accounts found.')
                    else
                      ...revenueAccounts.map((acc) => _buildAccountRow(acc.accountName, acc.balance)),
                    _buildTotalRow('Total Revenue from Operations', totalRevenue),
                    const SizedBox(height: AppSpacing.m),

                    // B) Other Income
                    _buildSubSectionHeader('B) Other Income'),
                    if (otherIncomeAccounts.isEmpty)
                      _buildEmptyRow('No other income accounts found.')
                    else
                      ...otherIncomeAccounts.map((acc) => _buildAccountRow(acc.accountName, acc.balance)),
                    _buildTotalRow('Total Other Income', totalOtherIncome),
                    const SizedBox(height: AppSpacing.m),

                    // Total Incomes (A + B)
                    _buildGrandTotalRow('Total Incomes (A + B)', totalRevenue + totalOtherIncome),
                    const SizedBox(height: AppSpacing.l),

                    // Gross Profit Section
                    _buildSectionHeader('Gross Profit', Colors.blue.shade700),
                    _buildTotalRow('Total Gross Profit', totalRevenue + totalOtherIncome),
                    const SizedBox(height: AppSpacing.l),

                    // Operating Expenses Section
                    _buildSectionHeader('Operating Expenses', AppColors.danger),
                    if (report.expense.accounts.isEmpty)
                      _buildEmptyRow('No operating expenses accounts found.')
                    else
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
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Text(_formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSubSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.teal.shade700,
        ),
      ),
    );
  }

  Widget _buildEmptyRow(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: AppSpacing.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
          const Text(
            '0.00',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrandTotalRow(String label, double total) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
          bottom: BorderSide(color: AppColors.borderLight, width: 2),
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Text(
            _formatCurrency(total),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
