import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/reports/presentation/providers/reports_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

import 'package:mobile_books/features/reports/data/models/balance_sheet.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_books/core/theme/app_icons.dart';

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

  Future<void> _exportCSV(BuildContext context, BalanceSheetReport report, DateTime? endDate) async {
    final df = DateFormat('yyyy-MM-dd');
    final String dateLabel = endDate != null ? df.format(endDate) : 'As of Today';

    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Balance Sheet Report');
    csvBuffer.writeln('As of Date: $dateLabel');
    csvBuffer.writeln('');

    csvBuffer.writeln('ASSETS');
    csvBuffer.writeln('Account Code,Account Name,Account Type,Balance');
    for (final acc in report.assets.accounts) {
      csvBuffer.writeln('"${acc.accountCode}","${acc.accountName}","${acc.accountType}",${acc.balance}');
    }
    csvBuffer.writeln('Total Assets,,,${report.assets.total}');
    csvBuffer.writeln('');

    csvBuffer.writeln('LIABILITIES');
    csvBuffer.writeln('Account Code,Account Name,Account Type,Balance');
    for (final acc in report.liabilities.accounts) {
      csvBuffer.writeln('"${acc.accountCode}","${acc.accountName}","${acc.accountType}",${acc.balance}');
    }
    csvBuffer.writeln('Total Liabilities,,,${report.liabilities.total}');
    csvBuffer.writeln('');

    csvBuffer.writeln('EQUITY');
    csvBuffer.writeln('Account Code,Account Name,Account Type,Balance');
    for (final acc in report.equity.accounts) {
      csvBuffer.writeln('"${acc.accountCode}","${acc.accountName}","${acc.accountType}",${acc.balance}');
    }
    csvBuffer.writeln('Total Equity,,,${report.equity.total}');
    csvBuffer.writeln('');

    csvBuffer.writeln('Total Liabilities & Equity,,,${report.liabilities.total + report.equity.total}');

    await Share.shareXFiles(
      [
        XFile.fromData(
          utf8.encode(csvBuffer.toString()),
          name: 'balance_sheet_report.csv',
          mimeType: 'text/csv',
        )
      ],
      subject: 'Balance Sheet ($dateLabel)',
    );
  }

  Future<void> _exportPDF(BuildContext context, BalanceSheetReport report, DateTime? endDate) async {
    final df = DateFormat('yyyy-MM-dd');
    final String dateLabel = endDate != null ? df.format(endDate) : 'As of Today';

    final pdf = pw.Document();

    pdf.addPage(
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
                  pw.Text('Balance Sheet', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateLabel, style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Assets Section
            pw.Text('Assets', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                ...report.assets.accounts.map((acc) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(acc.accountName)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(acc.balance).replaceAll('₹', 'INR'), textAlign: pw.TextAlign.right)),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Assets', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(report.assets.total).replaceAll('₹', 'INR'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Liabilities Section
            pw.Text('Liabilities', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.red700)),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                ...report.liabilities.accounts.map((acc) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(acc.accountName)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(acc.balance).replaceAll('₹', 'INR'), textAlign: pw.TextAlign.right)),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Liabilities', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(report.liabilities.total).replaceAll('₹', 'INR'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Equity Section
            pw.Text('Equity', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                ...report.equity.accounts.map((acc) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(acc.accountName)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(acc.balance).replaceAll('₹', 'INR'), textAlign: pw.TextAlign.right)),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Equity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(report.equity.total).replaceAll('₹', 'INR'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Grand Total Section
            pw.Container(
              color: PdfColors.grey200,
              padding: const pw.EdgeInsets.all(8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Liabilities & Equity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatCurrency(report.liabilities.total + report.equity.total).replaceAll('₹', 'INR'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'balance_sheet_report.pdf',
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
            icon: const Icon(AppIcons.table_chart),
            tooltip: "Export CSV",
            onPressed: () {
              reportState.whenData((report) {
                _exportCSV(context, report, endDate);
              });
            },
          ),
          IconButton(
            icon: const Icon(AppIcons.picture_as_pdf_outlined),
            tooltip: "Export PDF",
            onPressed: () {
              reportState.whenData((report) {
                _exportPDF(context, report, endDate);
              });
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (endDate != null)
                        IconButton(
                          icon: const Icon(AppIcons.clear, size: 20),
                          onPressed: () {
                            ref.read(balanceSheetEndDateProvider.notifier).state = null;
                          },
                        ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                        ),
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
                Widget buildAssets() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionHeader('Assets', Colors.blue.shade700),
                      if (report.assets.accounts.isEmpty)
                        _buildEmptyRow('No assets recorded.')
                      else
                        ...report.assets.accounts.map((acc) => _buildAccountRow(acc.accountName, acc.balance)),
                      _buildTotalRow('Total Assets', report.assets.total),
                    ],
                  );
                }

                Widget buildLiabilitiesAndEquity() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionHeader('Liabilities', Colors.red.shade700),
                      if (report.liabilities.accounts.isEmpty)
                        _buildEmptyRow('No liabilities recorded.')
                      else
                        ...report.liabilities.accounts.map((acc) => _buildAccountRow(acc.accountName, acc.balance)),
                      _buildTotalRow('Total Liabilities', report.liabilities.total),
                      const SizedBox(height: AppSpacing.l),
                      
                      _buildSectionHeader('Equity', Colors.teal.shade700),
                      if (report.equity.accounts.isEmpty)
                        _buildEmptyRow('No equity recorded.')
                      else
                        ...report.equity.accounts.map((acc) => _buildAccountRow(acc.accountName, acc.balance)),
                      _buildTotalRow('Total Equity', report.equity.total),
                      const SizedBox(height: AppSpacing.m),
                      
                      _buildGrandTotalContainer(
                        'Total Liabilities & Equity',
                        report.liabilities.total + report.equity.total,
                      ),
                    ],
                  );
                }

                final isWide = MediaQuery.of(context).size.width > 600;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: buildAssets()),
                            const SizedBox(width: AppSpacing.l),
                            Expanded(child: buildLiabilitiesAndEquity()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buildAssets(),
                            const SizedBox(height: AppSpacing.xl),
                            buildLiabilitiesAndEquity(),
                          ],
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

  Widget _buildSectionHeader(String title, Color accentColor) {
    return Container(
      decoration: const BoxDecoration(
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

  Widget _buildEmptyRow(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: AppSpacing.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondaryLight,
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

  Widget _buildGrandTotalContainer(String label, double total) {
    return Container(
      color: AppColors.primaryBlue.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
