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
import 'package:mobile_books/widgets/common/loading_skeleton.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/features/dashboard/presentation/providers/deposit_balances_provider.dart';
import 'package:mobile_books/features/organizations/presentation/providers/organization_provider.dart';
import 'package:mobile_books/core/theme/app_icons.dart';

class DashboardSelectedPlanNotifier extends Notifier<String> {
  @override
  String build() => 'premium';
  
  void setPlan(String plan) {
    state = plan;
  }
}

final selectedDashboardUpgradePlanProvider = NotifierProvider<DashboardSelectedPlanNotifier, String>(() {
  return DashboardSelectedPlanNotifier();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Widget _buildGreetingHeader(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final orgState = ref.watch(organizationsProvider);
    String orgName = '';
    if (authState is AuthAuthenticated) {
      orgName = authState.user.organizationName ?? '';
    }
    if (orgName.isEmpty || orgName == 'Your Organization') {
      if (orgState.organizations.isNotEmpty) {
        orgName = orgState.organizations.first.name;
      } else {
        orgName = 'Your Organization';
      }
    }

    final hour = DateTime.now().hour;
    String greeting = 'Good evening';
    if (hour >= 5 && hour < 12) {
      greeting = 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$greeting, ',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            TextSpan(
              text: orgName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(BuildContext context, double amount) {
    final format = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  Widget _buildDashboardSkeleton(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;
    final width = MediaQuery.of(context).size.width;
    final double childAspectRatio = isMobile ? (width < 360 ? 1.05 : 1.3) : 1.5;
    final double metricsAspectRatio = isMobile ? (width < 360 ? 1.35 : 1.7) : 2.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Stat cards grid skeleton
          GridView.count(
            crossAxisCount: isMobile ? 2 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.s,
            mainAxisSpacing: AppSpacing.s,
            childAspectRatio: childAspectRatio,
            children: List.generate(4, (index) => LoadingSkeleton.skeletonCard(height: 100)),
          ),
          const SizedBox(height: AppSpacing.l),

          // 2. Month Overview Header skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 150,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 120,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),

          // 3. Monthly Metrics grid skeleton
          GridView.count(
            crossAxisCount: isMobile ? 2 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSpacing.s,
            mainAxisSpacing: AppSpacing.s,
            childAspectRatio: metricsAspectRatio,
            children: List.generate(4, (index) => LoadingSkeleton.skeletonCard(height: 70)),
          ),
          const SizedBox(height: AppSpacing.l),

          // 4. Projections skeleton
          if (isMobile) ...[
            LoadingSkeleton.skeletonCard(height: 110),
            const SizedBox(height: AppSpacing.s),
            LoadingSkeleton.skeletonCard(height: 110),
            const SizedBox(height: AppSpacing.s),
            LoadingSkeleton.skeletonCard(height: 140),
          ] else ...[
            Row(
              children: [
                Expanded(child: LoadingSkeleton.skeletonCard(height: 110)),
                const SizedBox(width: AppSpacing.s),
                Expanded(child: LoadingSkeleton.skeletonCard(height: 110)),
                const SizedBox(width: AppSpacing.s),
                Expanded(child: LoadingSkeleton.skeletonCard(height: 140)),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.l),

          // 5. Chart 1 skeleton
          LoadingSkeleton.skeletonCard(height: 250),
          const SizedBox(height: AppSpacing.l),

          // 6. Chart 2 skeleton
          LoadingSkeleton.skeletonCard(height: 250),
        ],
      ),
    );
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
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardSummaryProvider.notifier).refresh();
          ref.invalidate(projectedPaymentsProvider);
          ref.invalidate(projectedExpensesProvider);
          ref.invalidate(depositBalancesProvider);
        },
        child: summaryState.when(
          data: (summary) {
            final paymentsAsync = ref.watch(projectedPaymentsProvider);
            final expensesAsync = ref.watch(projectedExpensesProvider);
            final payData = paymentsAsync.value ?? {};
            final expData = expensesAsync.value ?? {};
            final double totalProjIncome = (payData['total_projected_payment'] as num?)?.toDouble() ?? 0.0;
            final double totalProjExpense = (expData['total_projected_expense'] as num?)?.toDouble() ?? 0.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreetingHeader(context, ref),
                  _buildSearchSearchBar(context),
                  const SizedBox(height: 16),

                  // 1. STAT CARDS (Summary Cards)
                  _buildStatCards(context, summary.topSummary),
                  const SizedBox(height: 16),

                  // 2. MONTHLY FILTER BAR & METRICS GRID
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Overview',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<int>(
                                  value: selectedMonth,
                                  isExpanded: true,
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(dashboardMonthProvider.notifier).state = val;
                                    }
                                  },
                                  items: List.generate(12, (index) {
                                    return DropdownMenuItem(
                                      value: index + 1,
                                      child: Text(monthNames[index], style: const TextStyle(fontSize: 12)),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<int>(
                                  value: selectedYear,
                                  isExpanded: true,
                                  onChanged: (val) {
                                    if (val != null) {
                                      ref.read(dashboardYearProvider.notifier).state = val;
                                    }
                                  },
                                  items: yearsList.map((y) {
                                    return DropdownMenuItem(
                                      value: y,
                                      child: Text(y.toString(), style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              ref.read(dashboardSummaryProvider.notifier).refresh();
                            },
                            child: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMonthlyMetricsGrid(context, summary.selectedMonth),
                  const SizedBox(height: 16),

                  // 3. PROJECTED METRICS & CASH BALANCES (Unified 2x2 grid)
                  _buildProjectionsAndCashGrid(
                    context,
                    totalProjIncome,
                    totalProjExpense,
                    monthNames[selectedMonth - 1],
                    selectedYear,
                    ref,
                  ),
                  const SizedBox(height: 16),

                  // 4. SUBSCRIPTION & UPGRADE CARD
                  _buildSubscriptionCard(context, ref),
                  const SizedBox(height: 16),

                  // 5. BANK ACCOUNTS (moved below Subscription)
                  _buildBanksList(context, summary.chartData.banks),
                  const SizedBox(height: 16),

                  // 6. QUICK ACTIONS
                  _buildQuickActions(context),
                ],
              ),
            );
          },
          loading: () => _buildDashboardSkeleton(context),
          error: (error, _) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Error loading dashboard metrics: $error',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, TopSummary top) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final card1 = _buildStatCard(
          context,
          title: 'Total Receivables',
          amount: top.totalReceivables,
          sub: 'Unpaid Invoices',
          icon: AppIcons.currency_rupee,
          iconColor: const Color(0xFFD97706), // Amber
          iconBgColor: const Color(0xFFFEF3C7),
          onTap: () => context.push('/invoices'),
        );
        final card2 = _buildStatCard(
          context,
          title: 'Total Payables',
          amount: top.totalPayables,
          sub: 'Unpaid Bills',
          icon: AppIcons.credit_card,
          iconColor: const Color(0xFFDC2626), // Red
          iconBgColor: const Color(0xFFFEE2E2),
          onTap: () => context.push('/bills'),
        );
        final card3 = _buildStatCard(
          context,
          title: 'Total Income',
          amount: top.totalIncome,
          sub: 'All Time',
          icon: AppIcons.trending_up,
          iconColor: const Color(0xFF059669), // Green
          iconBgColor: const Color(0xFFD1FAE5),
          onTap: () => context.push('/invoices'),
        );
        final card4 = _buildStatCard(
          context,
          title: 'Total Expenses',
          amount: top.totalExpenses,
          sub: 'All Time',
          icon: AppIcons.trending_down,
          iconColor: const Color(0xFF7C3AED), // Purple
          iconBgColor: const Color(0xFFF3E8FF),
          onTap: () => context.push('/expenses'),
        );

        // On mobile use IntrinsicHeight rows (auto-size to content, no overflow)
        // On wide screens use a 4-column row
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: card1),
              const SizedBox(width: 12),
              Expanded(child: card2),
              const SizedBox(width: 12),
              Expanded(child: card3),
              const SizedBox(width: 12),
              Expanded(child: card4),
            ],
          );
        } else {
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: card1),
                    const SizedBox(width: 12),
                    Expanded(child: card2),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: card3),
                    const SizedBox(width: 12),
                    Expanded(child: card4),
                  ],
                ),
              ),
            ],
          );
        }
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
    VoidCallback? onTap,
  }) {
    final mutedIconBg = iconColor.withValues(alpha: 0.08);

    Color tagBgColor = const Color(0xFFFEF3C7);
    Color tagTextColor = const Color(0xFFD97706);
    if (title.contains('Payables')) {
      tagBgColor = const Color(0xFFFEE2E2);
      tagTextColor = const Color(0xFFDC2626);
    } else if (title.contains('Income')) {
      tagBgColor = const Color(0xFFD1FAE5);
      tagTextColor = const Color(0xFF059669);
    } else if (title.contains('Expenses')) {
      tagBgColor = const Color(0xFFFEE2E2);
      tagTextColor = const Color(0xFFDC2626);
    }

    return _buildDecoratedCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: mutedIconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCurrency(context, amount),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: tagBgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Current Financial Year',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: tagTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyMetricsGrid(BuildContext context, SelectedMonthSummary selected) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final card1 = _buildMetricCard(context, 'BUSINESS VALUE', selected.incomeReceived, const Color(0xFF059669));
        final card2 = _buildMetricCard(context, 'EXPENSES', selected.expenses, const Color(0xFFDC2626));
        final card3 = _buildMetricCard(context, 'PROFIT', selected.profit, const Color(0xFF059669));
        final card4 = _buildMetricCard(context, 'NET CASH', selected.netCashPosition, AppColors.primaryBlue);

        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 12),
              Expanded(child: card2),
              const SizedBox(width: 12),
              Expanded(child: card3),
              const SizedBox(width: 12),
              Expanded(child: card4),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 12),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 12),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildIncomeExpenseProgress(BuildContext context, SelectedMonthSummary selected) {
    final double total = selected.incomeReceived + selected.expenses;
    final double incomePercent = total > 0 ? (selected.incomeReceived / total) : 0.5;

    final double totalSum = selected.incomeReceived + selected.expenses == 0 ? 1 : selected.incomeReceived + selected.expenses;
    final String incomePercentageStr = ((selected.incomeReceived / totalSum) * 100).toStringAsFixed(0);
    final String expensePercentageStr = ((selected.expenses / totalSum) * 100).toStringAsFixed(0);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Progress (Income vs Expenses)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Income: $incomePercentageStr%',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                ),
                Text(
                  'Expenses: $expensePercentageStr%',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: incomePercent,
                backgroundColor: const Color(0xFFDC2626), // Red for expenses
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)), // Green for income
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, double value, Color valueColor) {
    return _buildDecoratedCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCurrency(context, value),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor),
              maxLines: 1,
            ),
          ),
        ],
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
    return _buildDecoratedCard(
      padding: const EdgeInsets.all(12),
      onTap: onViewTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title gets full width — wraps to 2 lines if needed
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondaryLight,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // View link on its own row, right-aligned
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'View',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(AppIcons.arrow_right_alt, size: 14, color: AppColors.primaryBlue),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCurrency(context, amount),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: amountColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedNetCashCard(
    BuildContext context, {
    required double amount,
    required bool isPositive,
    required String monthName,
    required int year,
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
            Text(
              'This represents your expected cash position after receiving projected income and paying projected expenses for $monthName $year.',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionsAndCashGrid(
    BuildContext context,
    double totalProjIncome,
    double totalProjExpense,
    String monthStr,
    int selectedYear,
    WidgetRef ref,
  ) {
    final depositBalancesAsync = ref.watch(depositBalancesProvider);
    final localMonthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final selectedMonthIndex = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ].indexOf(monthStr);
    int nextMonthVal = selectedMonthIndex + 1;
    int nextYearVal = selectedYear;
    if (nextMonthVal >= 12) {
      nextMonthVal = 0;
      nextYearVal += 1;
    }
    final nextMonthStr = localMonthNames[nextMonthVal];

    final card1 = _buildProjectionCard(
      context,
      title: 'Projected Income ($nextMonthStr $nextYearVal)',
      amount: totalProjIncome,
      amountColor: const Color(0xFF059669),
      subtext: totalProjIncome == 0 ? 'No projected income.' : 'Expected for $nextMonthStr $nextYearVal.',
      onViewTap: () => context.push('/projected-payments'),
    );

    final card2 = _buildProjectionCard(
      context,
      title: 'Projected Expense ($nextMonthStr $nextYearVal)',
      amount: totalProjExpense,
      amountColor: const Color(0xFFDC2626),
      subtext: totalProjExpense == 0 ? 'No projected expenses.' : 'Expected for $nextMonthStr $nextYearVal.',
      onViewTap: () => context.push('/projected-expenses'),
    );

    return depositBalancesAsync.when(
      data: (balances) {
        final card3 = _buildDecoratedCard(
          onTap: () => context.push('/banking/petty-cash'),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Petty Cash',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(AppIcons.wallet, size: 14, color: const Color(0xFF059669).withValues(alpha: 0.6)),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatCurrency(context, balances.pettyCash),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Click to view ledger →',
                style: TextStyle(fontSize: 8, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        );

        final card4 = _buildDecoratedCard(
          onTap: () => context.push('/banking/undeposited-funds'),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Undeposited',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(AppIcons.business_center, size: 14, color: AppColors.primaryBlue.withValues(alpha: 0.6)),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatCurrency(context, balances.undepositedFunds),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Click to view ledger →',
                style: TextStyle(fontSize: 8, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        );

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: card1),
                const SizedBox(width: 12),
                Expanded(child: card2),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: card3),
                const SizedBox(width: 12),
                Expanded(child: card4),
              ],
            ),
          ],
        );
      },
      loading: () => Container(
        height: 160,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      ),
      error: (e, _) => Container(
        height: 160,
        alignment: Alignment.center,
        child: Text('Error: $e', style: const TextStyle(color: AppColors.danger, fontSize: 12)),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, WidgetRef ref) {
    final selectedPlan = ref.watch(selectedDashboardUpgradePlanProvider);
    final isPremiumSelected = selectedPlan == 'premium';
    final isProfessionalSelected = selectedPlan == 'professional';

    return _buildDecoratedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(AppIcons.payment, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subscription & Upgrade',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                    ),
                    Text(
                      'Manage your current plan',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Current: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Free',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Standard Premium Card
                Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(selectedDashboardUpgradePlanProvider.notifier).setPlan('premium'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPremiumSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
                        border: Border.all(
                          color: isPremiumSelected ? const Color(0xFF0D9488) : Colors.grey.shade200,
                          width: isPremiumSelected ? 1.5 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge Label Chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '★ Popular',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'STANDARD PREMIUM',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '₹749/mo',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                                ),
                              ),
                            ],
                          ),
                          if (isPremiumSelected) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D9488),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                ),
                                onPressed: () => context.push('/pricing'),
                                child: const Text(
                                  '🔒 Upgrade Now',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Professional Card
                Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(selectedDashboardUpgradePlanProvider.notifier).setPlan('professional'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isProfessionalSelected ? const Color(0xFFF5F3FF) : Colors.transparent,
                        border: Border.all(
                          color: isProfessionalSelected ? const Color(0xFF7C3AED) : Colors.grey.shade200,
                          width: isProfessionalSelected ? 1.5 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge Label Chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E8FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'PROFESSIONAL',
                                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'PROFESSIONAL',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '₹1499/mo',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                ),
                              ),
                            ],
                          ),
                          if (isProfessionalSelected) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 36,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () => context.push('/pricing'),
                                child: const Text(
                                  '🔒 Pay & Upgrade Now',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return _buildBanksList(context, data.banks);
  }

  Widget _buildBanksList(BuildContext context, List<BankAccount> banks) {
    return _buildDecoratedCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bank Accounts', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
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
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.08),
                    child: const Icon(AppIcons.account_balance, color: AppColors.primaryBlue, size: 20),
                  ),
                  title: Text(bank.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
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

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'label': 'Invoice', 'icon': AppIcons.description_outlined, 'path': '/invoices/new'},
      {'label': 'Quote', 'icon': AppIcons.request_quote_outlined, 'path': '/quotes/new'},
      {'label': 'Customer', 'icon': AppIcons.people_outline, 'path': '/customers/new'},
      {'label': 'Item', 'icon': AppIcons.inventory_2_outlined, 'path': '/items/new'},
      {'label': 'Bill', 'icon': AppIcons.receipt_long_outlined, 'path': '/bills/new'},
      {'label': 'Expense', 'icon': AppIcons.shopping_bag_outlined, 'path': '/expenses/new'},
      {'label': 'Journal', 'icon': AppIcons.calculate_outlined, 'path': '/accounting/journals/new'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final act = actions[index];
              return SizedBox(
                width: 80,
                child: _buildDecoratedCard(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  onTap: () => context.push(act['path'] as String),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        act['icon'] as IconData,
                        color: AppColors.primaryBlue,
                        size: 20,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        act['label'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDecoratedCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
  }) {
    final Widget cardContent = Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      padding: padding ?? const EdgeInsets.all(12),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: cardContent,
        ),
      );
    }
    return cardContent;
  }

  Widget _buildSearchSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      child: InkWell(
        onTap: () => _showDashboardSearchDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                AppIcons.search,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search customers, items, invoices...',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDashboardSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Global Search'),
              content: SizedBox(
                width: 400,
                height: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search customers, items, invoices, quotes...',
                        prefixIcon: Icon(AppIcons.search),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          query = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (query.trim().isNotEmpty)
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final searchAsync = ref.watch(globalSearchProvider(query));
                            return searchAsync.when(
                              data: (results) {
                                final customers = results['customers'] as List? ?? [];
                                final items = results['items'] as List? ?? [];
                                final invoices = results['invoices'] as List? ?? [];
                                final quotes = results['quotes'] as List? ?? [];
                                
                                if (customers.isEmpty && items.isEmpty && invoices.isEmpty && quotes.isEmpty) {
                                  return const Center(child: Text('No results found.'));
                                }
                                
                                return ListView(
                                  children: [
                                    if (customers.isNotEmpty) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text('CUSTOMERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                                      ),
                                      ...customers.map((c) => ListTile(
                                        title: Text(c['display_name'] ?? c['company_name'] ?? ''),
                                        subtitle: Text(c['email'] ?? ''),
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.push('/customers/${c['id']}');
                                        },
                                      )),
                                      const Divider(),
                                    ],
                                    if (items.isNotEmpty) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text('ITEMS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                                      ),
                                      ...items.map((it) => ListTile(
                                        title: Text(it['name'] ?? ''),
                                        subtitle: Text('SKU: ${it['sku'] ?? ""} | Price: ₹${it['selling_price'] ?? "0"}'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.push('/items/${it['id']}');
                                        },
                                      )),
                                      const Divider(),
                                    ],
                                    if (invoices.isNotEmpty) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text('INVOICES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                                      ),
                                      ...invoices.map((inv) => ListTile(
                                        title: Text(inv['invoice_number'] ?? ''),
                                        subtitle: Text('Total: ₹${inv['total_amount'] ?? "0"} | Status: ${inv['status'] ?? ""}'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.push('/invoices/${inv['id']}');
                                        },
                                      )),
                                      const Divider(),
                                    ],
                                    if (quotes.isNotEmpty) ...[
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 4.0),
                                        child: Text('QUOTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A))),
                                      ),
                                      ...quotes.map((q) => ListTile(
                                        title: Text(q['quote_number'] ?? ''),
                                        subtitle: Text('Total: ₹${q['total_amount'] ?? "0"} | Status: ${q['status'] ?? ""}'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          context.push('/quotes/${q['id']}');
                                        },
                                      )),
                                    ],
                                  ],
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (err, stack) => Center(child: Text('Error: $err')),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
