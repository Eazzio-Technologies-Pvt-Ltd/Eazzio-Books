import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/reports/presentation/providers/reports_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

import 'package:mobile_books/features/reports/data/models/trial_balance.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<void> _exportCSV(BuildContext context, TrialBalanceReport report, DateTimeRange? dateRange) async {
    final df = DateFormat('yyyy-MM-dd');
    final String dateLabel = dateRange != null
        ? '${df.format(dateRange.start)} to ${df.format(dateRange.end)}'
        : 'All Time';

    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Trial Balance Report');
    csvBuffer.writeln('Period: $dateLabel');
    csvBuffer.writeln('');
    csvBuffer.writeln('Account Code,Account Name,Account Type,Debit,Credit');

    double totalDebit = 0;
    double totalCredit = 0;
    for (final acc in report.accounts) {
      csvBuffer.writeln('"${acc.accountCode}","${acc.accountName}","${acc.accountType}",${acc.totalDebit},${acc.totalCredit}');
      totalDebit += acc.totalDebit;
      totalCredit += acc.totalCredit;
    }
    csvBuffer.writeln('');
    csvBuffer.writeln('Total,,, $totalDebit,$totalCredit');

    await Share.shareXFiles(
      [
        XFile.fromData(
          utf8.encode(csvBuffer.toString()),
          name: 'trial_balance_report.csv',
          mimeType: 'text/csv',
        )
      ],
      subject: 'Trial Balance Report ($dateLabel)',
    );
  }

  Future<void> _exportPDF(BuildContext context, TrialBalanceReport report, DateTimeRange? dateRange) async {
    final df = DateFormat('yyyy-MM-dd');
    final String dateLabel = dateRange != null
        ? '${df.format(dateRange.start)} to ${df.format(dateRange.end)}'
        : 'All Time';

    final pdf = pw.Document();
    
    double totalDebit = 0;
    double totalCredit = 0;
    for (final acc in report.accounts) {
      totalDebit += acc.totalDebit;
      totalCredit += acc.totalCredit;
    }

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
                  pw.Text('Trial Balance', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateLabel, style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Account Code', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Account Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Debit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Credit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
                ...report.accounts.map((acc) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(acc.accountCode),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(acc.accountName),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(acc.accountType),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(_formatCurrency(acc.totalDebit).replaceAll('₹', 'INR'), textAlign: pw.TextAlign.right),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(_formatCurrency(acc.totalCredit).replaceAll('₹', 'INR'), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  );
                }),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(''),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(_formatCurrency(totalDebit).replaceAll('₹', 'INR'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(_formatCurrency(totalCredit).replaceAll('₹', 'INR'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'trial_balance_report.pdf',
    );
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dateRange != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            ref.read(trialBalanceDateRangeProvider.notifier).state = null;
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
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(AppSpacing.m),
                    padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: AppSpacing.m),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Center(
                      child: Text(
                        'No data found for this period.',
                        style: TextStyle(
                          color: AppColors.textSecondaryLight,
                          fontSize: 14,
                        ),
                      ),
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
