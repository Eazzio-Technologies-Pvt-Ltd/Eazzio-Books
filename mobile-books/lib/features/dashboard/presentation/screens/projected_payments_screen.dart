import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/dashboard/presentation/providers/dashboard_provider.dart';

class ProjectedPaymentsScreen extends ConsumerWidget {
  const ProjectedPaymentsScreen({super.key});

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    return format.format(amount);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d/M/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return const Color(0xFFE5A100);
      case 'sent':
      case 'pending':
        return const Color(0xFF2563EB);
      case 'overdue':
        return const Color(0xFFDC2626);
      case 'partially paid':
      case 'partial':
        return const Color(0xFFF59E0B);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectedAsync = ref.watch(projectedPaymentsProvider);
    final selectedMonth = ref.watch(dashboardMonthProvider);
    final selectedYear = ref.watch(dashboardYearProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveScaffold(
      currentRoute: '/projected-payments',
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard'),
        ),
        title: const Text('Projected Payment'),
      ),
      body: projectedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: AppSpacing.s),
              Text('Failed to load projected payments', style: TextStyle(color: Colors.red[300])),
              const SizedBox(height: AppSpacing.s),
              TextButton(
                onPressed: () => ref.invalidate(projectedPaymentsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final totalProjected = (data['total_projected_payment'] as num?)?.toDouble() ?? 0.0;
          final projMonth = (data['projected_month'] as num?)?.toInt() ?? (DateTime.now().month + 1);
          final projYear = (data['projected_year'] as num?)?.toInt() ?? DateTime.now().year;
          final bills = (data['bills'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          final monthStr = _monthNames[(projMonth - 1).clamp(0, 11)];

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(projectedPaymentsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month/Year Picker Row
                  _buildMonthYearPicker(context, ref, selectedMonth, selectedYear),
                  const SizedBox(height: AppSpacing.m),

                  // Header Row: Title + Total Projected Card
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Projected Payment',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey[400] : AppColors.textSecondaryLight,
                                ),
                                children: [
                                  const TextSpan(text: 'Unpaid and pending invoices projected for '),
                                  TextSpan(
                                    text: '$monthStr $projYear',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      _buildTotalProjectedCard(totalProjected, isDark),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Data Table or Empty State
                  if (bills.isEmpty)
                    _buildEmptyState(isDark, 'No projected payments found.', 'All current invoices are paid.')
                  else
                    _buildBillsTable(context, bills, isDark),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthYearPicker(BuildContext context, WidgetRef ref, int selectedMonth, int selectedYear) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentYear = DateTime.now().year;
    final yearsList = List.generate(5, (i) => currentYear - 2 + i);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, size: 20, color: isDark ? Colors.white70 : AppColors.primaryBlue),
          const SizedBox(width: AppSpacing.s),
          Text('Period:', style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
          )),
          const SizedBox(width: AppSpacing.s),
          DropdownButton<int>(
            value: selectedMonth,
            underline: const SizedBox(),
            isDense: true,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimaryLight),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            onChanged: (val) {
              if (val != null) ref.read(dashboardMonthProvider.notifier).state = val;
            },
            items: List.generate(12, (i) => DropdownMenuItem(
              value: i + 1,
              child: Text(_monthNames[i]),
            )),
          ),
          const SizedBox(width: AppSpacing.s),
          DropdownButton<int>(
            value: selectedYear,
            underline: const SizedBox(),
            isDense: true,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimaryLight),
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            onChanged: (val) {
              if (val != null) ref.read(dashboardYearProvider.notifier).state = val;
            },
            items: yearsList.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalProjectedCard(double total, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'TOTAL PROJECTED',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isDark ? Colors.grey[400] : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(total),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFFDE68A)),
      ),
      child: Column(
        children: [
          Icon(Icons.schedule, size: 40, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: AppSpacing.m),
          Text(title, style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
          )),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : AppColors.textSecondaryLight,
          )),
        ],
      ),
    );
  }

  Widget _buildBillsTable(BuildContext context, List<Map<String, dynamic>> bills, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ),
            dataRowColor: WidgetStateProperty.all(
              isDark ? const Color(0xFF1E293B) : Colors.white,
            ),
            columnSpacing: 20,
            horizontalMargin: 16,
            headingTextStyle: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: isDark ? Colors.grey[400] : AppColors.textSecondaryLight,
            ),
            dataTextStyle: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
            columns: const [
              DataColumn(label: Text('DATE')),
              DataColumn(label: Text('INVOICE NUMBER')),
              DataColumn(label: Text('CUSTOMER NAME')),
              DataColumn(label: Text('DUE DATE')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('TOTAL AMOUNT'), numeric: true),
              DataColumn(label: Text('PENDING AMOUNT'), numeric: true),
            ],
            rows: bills.map((bill) {
              final status = (bill['status'] ?? '').toString();
              final totalAmount = (bill['total_amount'] as num?)?.toDouble() ?? 0.0;
              final pendingAmount = (bill['pending_amount'] as num?)?.toDouble() ?? 0.0;

              return DataRow(cells: [
                DataCell(Text(_formatDate(bill['bill_date']?.toString()))),
                DataCell(
                  GestureDetector(
                    onTap: () {
                      final billId = bill['bill_id'];
                      if (billId != null) {
                        context.push('/invoices/$billId');
                      }
                    },
                    child: Text(
                      bill['bill_number']?.toString() ?? '-',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(bill['vendor_name']?.toString() ?? '-')),
                DataCell(Text(_formatDate(bill['due_date']?.toString()))),
                DataCell(_buildStatusChip(status)),
                DataCell(Text(_formatCurrency(totalAmount))),
                DataCell(Text(
                  _formatCurrency(pendingAmount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
