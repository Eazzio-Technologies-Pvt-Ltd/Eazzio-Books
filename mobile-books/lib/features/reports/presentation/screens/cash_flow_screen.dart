import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/reports/presentation/providers/reports_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

import 'package:mobile_books/features/reports/data/models/cash_flow.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_books/core/theme/app_icons.dart';

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

  Future<void> _exportCSV(BuildContext context, CashFlowReport report, DateTimeRange? dateRange) async {
    final df = DateFormat('yyyy-MM-dd');
    final String dateLabel = dateRange != null
        ? '${df.format(dateRange.start)} to ${df.format(dateRange.end)}'
        : 'All Time';

    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Cash Flow Report');
    csvBuffer.writeln('Period: $dateLabel');
    csvBuffer.writeln('');
    csvBuffer.writeln('Description,Amount');

    for (final activity in report.operatingActivities) {
      csvBuffer.writeln('"${activity.description}",${activity.amount}');
    }
    csvBuffer.writeln('');
    csvBuffer.writeln('Net Cash Flow,${report.netCashFlow}');

    await Share.shareXFiles(
      [
        XFile.fromData(
          utf8.encode(csvBuffer.toString()),
          name: 'cash_flow_report.csv',
          mimeType: 'text/csv',
        )
      ],
      subject: 'Cash Flow Report ($dateLabel)',
    );
  }

  Future<void> _exportPDF(BuildContext context, CashFlowReport report, DateTimeRange? dateRange) async {
    final df = DateFormat('yyyy-MM-dd');
    final String dateLabel = dateRange != null
        ? '${df.format(dateRange.start)} to ${df.format(dateRange.end)}'
        : 'All Time';

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
                  pw.Text('Cash Flow Statement', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(dateLabel, style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Operating Activities', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal700)),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                ...report.operatingActivities.map((activity) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(activity.description)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(_formatCurrency(activity.amount).replaceAll('₹', 'INR'), textAlign: pw.TextAlign.right)),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              color: PdfColors.grey200,
              padding: const pw.EdgeInsets.all(8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Net Cash Flow', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(_formatCurrency(report.netCashFlow).replaceAll('₹', 'INR'), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'cash_flow_report.pdf',
    );
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
        actions: [
          IconButton(
            icon: const Icon(AppIcons.table_chart),
            tooltip: "Export CSV",
            onPressed: () {
              reportState.whenData((report) {
                _exportCSV(context, report, dateRange);
              });
            },
          ),
          IconButton(
            icon: const Icon(AppIcons.picture_as_pdf_outlined),
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
                          icon: const Icon(AppIcons.clear, size: 20),
                          onPressed: () {
                            ref.read(cashFlowDateRangeProvider.notifier).state = null;
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

          // Cash Flow Data
          Expanded(
            child: reportState.when(
              data: (report) {
                final flowColor = report.netCashFlow >= 0 ? AppColors.success : AppColors.danger;

                return ListView(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  children: [
                    // Operating Activities
                    _buildSectionHeader('Cash Flow from Operating Activities'),
                    if (report.operatingActivities.isEmpty)
                      _buildEmptyRow('No operating activities recorded.')
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
                    const SizedBox(height: AppSpacing.l),

                    // Investing Activities
                    _buildSectionHeader('Cash Flow from Investing Activities'),
                    _buildEmptyRow('No investing activities recorded.'),
                    const SizedBox(height: AppSpacing.l),

                    // Financing Activities
                    _buildSectionHeader('Cash Flow from Financing Activities'),
                    _buildEmptyRow('No financing activities recorded.'),
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
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formatCurrency(report.netCashFlow),
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: flowColor),
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

  Widget _buildSectionHeader(String title) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 2)),
      ),
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppColors.primaryBlue,
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
}
