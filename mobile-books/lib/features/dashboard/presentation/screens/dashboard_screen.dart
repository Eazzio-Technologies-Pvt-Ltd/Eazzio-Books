import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/dashboard/data/models/bank_account.dart';
import 'package:mobile_books/features/dashboard/data/models/dashboard_summary.dart';
import 'package:mobile_books/features/dashboard/presentation/providers/dashboard_provider.dart';

import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _formatCurrency(BuildContext context, double amount) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(dashboardSummaryProvider);
    final selectedMonth = ref.watch(dashboardMonthProvider);
    final selectedYear = ref.watch(dashboardYearProvider);

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final yearsList = [DateTime.now().year - 1, DateTime.now().year, DateTime.now().year + 1];

    return ResponsiveScaffold(
      currentRoute: '/dashboard',
      appBar: AppBar(
        title: const Text('Financial Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardSummaryProvider.notifier).refresh();
              ref.invalidate(projectedPaymentsProvider);
              ref.invalidate(projectedExpensesProvider);
            },
          ),
        ],
      ),
      body: summaryState.when(
        data: (summary) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. STAT CARDS (RECEIVABLES, PAYABLES, INCOME, EXPENSES)
                _buildStatCards(context, summary.topSummary),
                const SizedBox(height: AppSpacing.l),

                // 2. MONTHLY FILTER BAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Overview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        DropdownButton<int>(
                          value: selectedMonth,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(dashboardMonthProvider.notifier).state = val;
                            }
                          },
                          items: List.generate(12, (index) {
                            return DropdownMenuItem(
                              value: index + 1,
                              child: Text(monthNames[index]),
                            );
                          }),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        DropdownButton<int>(
                          value: selectedYear,
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(dashboardYearProvider.notifier).state = val;
                            }
                          },
                          items: yearsList.map((y) {
                            return DropdownMenuItem(
                              value: y,
                              child: Text(y.toString()),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),

                // 3. MONTHLY METRICS GRID
                _buildMonthlyMetricsGrid(context, summary.selectedMonth),
                const SizedBox(height: AppSpacing.l),

                // 4. PROJECTIONS AND EXPECTED SURPLUS
                _buildProjectionsSection(context),
                const SizedBox(height: AppSpacing.l),

                // 5. CASH FLOW LINE CHART (Last 12 months)
                _buildCashFlowChart(context, summary.chartData.cashFlowYearly),
                const SizedBox(height: AppSpacing.l),

                // 6. INCOME VS EXPENSE BAR CHART (Last 6 months)
                _buildBarChart(context, summary.chartData.incomeExpense6Months),
                const SizedBox(height: AppSpacing.l),

                // 7. EXPENSES BY CATEGORY AND BANK ACCOUNTS (Row on large screens, Column on mobile)
                _buildBottomLists(context, summary.chartData),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xxl),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              'Error loading dashboard metrics: $error',
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, TopSummary top) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.s,
          mainAxisSpacing: AppSpacing.s,
          childAspectRatio: 1.4,
          children: [
            _buildStatCard(
              context,
              title: 'Total Receivables',
              amount: top.totalReceivables,
              sub: 'Unpaid Invoices',
              icon: Icons.currency_rupee,
              iconColor: const Color(0xFFD97706), // Amber
              iconBgColor: const Color(0xFFFEF3C7),
            ),
            _buildStatCard(
              context,
              title: 'Total Payables',
              amount: top.totalPayables,
              sub: 'Unpaid Bills',
              icon: Icons.credit_card,
              iconColor: const Color(0xFFDC2626), // Red
              iconBgColor: const Color(0xFFFEE2E2),
            ),
            _buildStatCard(
              context,
              title: 'Total Income',
              amount: top.totalIncome,
              sub: 'All Time',
              icon: Icons.trending_up,
              iconColor: const Color(0xFF059669), // Green
              iconBgColor: const Color(0xFFD1FAE5),
            ),
            _buildStatCard(
              context,
              title: 'Total Expenses',
              amount: top.totalExpenses,
              sub: 'All Time',
              icon: Icons.trending_down,
              iconColor: const Color(0xFF7C3AED), // Purple
              iconBgColor: const Color(0xFFF3E8FF),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required double amount,
    required String sub,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    Color subColor = AppColors.textSecondaryLight;
    if (title.contains('Receivables') || title.contains('Payables')) {
      subColor = const Color(0xFFDC2626); // Red
    } else if (title.contains('Income')) {
      subColor = const Color(0xFF059669); // Green
    } else if (title.contains('Expenses')) {
      subColor = const Color(0xFF7C3AED); // Purple
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              _formatCurrency(context, amount),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              sub,
              style: TextStyle(fontSize: 10, color: subColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyMetricsGrid(BuildContext context, SelectedMonthSummary selected) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.s,
          mainAxisSpacing: AppSpacing.s,
          childAspectRatio: 1.8,
          children: [
            _buildMetricCard(context, 'INCOME', selected.incomeReceived, const Color(0xFF059669)),
            _buildMetricCard(context, 'EXPENSES', selected.expenses, const Color(0xFFDC2626)),
            _buildMetricCard(context, 'PROFIT', selected.profit, selected.profit >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626)),
            _buildMetricCard(context, 'NET CASH', selected.netCashPosition, AppColors.primaryBlue),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, double value, Color valueColor) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatCurrency(context, value),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionCard(
    BuildContext context, {
    required String title,
    required double amount,
    required Color amountColor,
    required String subtext,
    required VoidCallback onViewTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                ),
                GestureDetector(
                  onTap: onViewTap,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View',
                        style: TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.arrow_right_alt, size: 14, color: AppColors.primaryBlue),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              _formatCurrency(context, amount),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: amountColor),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              subtext,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpectedNetCashCard(
    BuildContext context, {
    required double amount,
    required bool isPositive,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expected Net Cash',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              _formatCurrency(context, amount),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626)).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isPositive ? 'PROJECTED SURPLUS' : 'PROJECTED SHORTAGE',
                style: TextStyle(
                  color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            const Text(
              'This represents your expected cash position after receiving projected income and paying projected expenses next month.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionsSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final paymentsAsync = ref.watch(projectedPaymentsProvider);
        final expensesAsync = ref.watch(projectedExpensesProvider);

        if (paymentsAsync.isLoading || expensesAsync.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (paymentsAsync.hasError || expensesAsync.hasError) {
          return const SizedBox.shrink();
        }

        final payData = paymentsAsync.value ?? {};
        final expData = expensesAsync.value ?? {};

        final double totalProjIncome = (payData['total_projected_payment'] as num?)?.toDouble() ?? 0.0;
        final double totalProjExpense = (expData['total_projected_expense'] as num?)?.toDouble() ?? 0.0;
        final double surplus = totalProjIncome - totalProjExpense;
        final isPositive = surplus >= 0;

        final isMobile = MediaQuery.of(context).size.width <= 768;

        final cards = [
          _buildProjectionCard(
            context,
            title: 'Projected Income',
            amount: totalProjIncome,
            amountColor: const Color(0xFF059669),
            subtext: totalProjIncome == 0 ? 'No projected income.' : 'Expected income payments next month.',
            onViewTap: () => context.push('/invoices'),
          ),
          _buildProjectionCard(
            context,
            title: 'Projected Expense',
            amount: totalProjExpense,
            amountColor: const Color(0xFFDC2626),
            subtext: totalProjExpense == 0 ? 'No projected expenses.' : 'Expected expense payments next month.',
            onViewTap: () => context.push('/bills'),
          ),
          _buildExpectedNetCashCard(
            context,
            amount: surplus,
            isPositive: isPositive,
          ),
        ];

        if (isMobile) {
          return Column(
            children: [
              cards[0],
              const SizedBox(height: AppSpacing.s),
              cards[1],
              const SizedBox(height: AppSpacing.s),
              cards[2],
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: AppSpacing.s),
              Expanded(child: cards[1]),
              const SizedBox(width: AppSpacing.s),
              Expanded(child: cards[2]),
            ],
          );
        }
      },
    );
  }

  Widget _buildCashFlowChart(BuildContext context, List<CashFlowPoint> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cash Flow (Last 12 Months)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.l),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final int idx = value.toInt();
                          if (idx >= 0 && idx < data.length) {
                            if (idx % 2 == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  data[idx].name,
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                                ),
                              );
                            }
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 9, color: AppColors.textSecondaryLight),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(data.length, (idx) => FlSpot(idx.toDouble(), data[idx].income)),
                      isCurved: true,
                      color: AppColors.success,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.success.withValues(alpha: 0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: List.generate(data.length, (idx) => FlSpot(idx.toDouble(), data[idx].expense)),
                      isCurved: true,
                      color: AppColors.danger,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.danger.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(context, 'Inflow', AppColors.success),
                const SizedBox(width: AppSpacing.m),
                _buildLegendItem(context, 'Outflow', AppColors.danger),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<CashFlowPoint> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Income and Expenses (Last 6 Months)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.l),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final int idx = value.toInt();
                          if (idx >= 0 && idx < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                data[idx].name,
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${(value / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(fontSize: 9, color: AppColors.textSecondaryLight),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(data.length, (idx) {
                    return BarChartGroupData(
                      x: idx,
                      barRods: [
                        BarChartRodData(toY: data[idx].income, color: AppColors.primaryBlue, width: 8, borderRadius: BorderRadius.circular(4)),
                        BarChartRodData(toY: data[idx].expense, color: AppColors.warning, width: 8, borderRadius: BorderRadius.circular(4)),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(context, 'Income', AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.m),
                _buildLegendItem(context, 'Expense', AppColors.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
      ],
    );
  }

  Widget _buildBottomLists(BuildContext context, DashboardChartData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildBanksList(context, data.banks)),
              const SizedBox(width: AppSpacing.m),
              Expanded(child: _buildTopExpensesList(context, data.topExpenses)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildBanksList(context, data.banks),
              const SizedBox(height: AppSpacing.m),
              _buildTopExpensesList(context, data.topExpenses),
            ],
          );
        }
      },
    );
  }

  Widget _buildBanksList(BuildContext context, List<BankAccount> banks) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bank Accounts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            if (banks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.l),
                child: Center(child: Text('No active bank accounts found.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: banks.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final bank = banks[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(Icons.account_balance, color: AppColors.primaryBlue),
                    ),
                    title: Text(bank.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text('Acct: ${bank.accountNumber}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    trailing: Text(
                      _formatCurrency(context, bank.balance),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopExpensesList(BuildContext context, List<ExpenseCategoryPoint> topExpenses) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Expenses', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            if (topExpenses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.l),
                child: Center(child: Text('No expense categories found.', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: topExpenses.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final expense = topExpenses[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFEF2F2),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(expense.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    trailing: Text(
                      _formatCurrency(context, expense.value),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.danger),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
