import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/common/app_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(
          user?.organizationName ?? 'Eazzio Books',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(dashboardProvider.notifier).fetchDashboardData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(dashboardProvider.notifier).fetchDashboardData();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Widget Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user?.fullName ?? 'User'}!',
                        style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Role: ${user?.role ?? 'Admin'}  |  Email: ${user?.email ?? '-'}',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Module Navigator Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'CORE ACCOUNTING MODULES',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                              ),
                              icon: const Icon(Icons.inventory_2_outlined, size: 18),
                              label: const Text('Items / Stock'),
                              onPressed: () => context.push('/items'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                              ),
                              icon: const Icon(Icons.people_alt_outlined, size: 18),
                              label: const Text('Customers'),
                              onPressed: () => context.push('/customers'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Main Stats Header
                Text(
                  'Financial Performance Summary',
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                if (dashboardState.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (dashboardState.errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        'Error loading dashboard: ${dashboardState.errorMessage}',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  // 4 summary cards (Receivables, Payables, Income, Expenses)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      _buildStatCard(
                        title: 'RECEIVABLES',
                        amount: _formatCurrency(
                          dashboardState.data?.totalReceivables ?? 0.0,
                        ),
                        color: const Color(0xFFD97706),
                        bgColor: const Color(0xFFFEF3C7),
                        icon: Icons.arrow_downward,
                      ),
                      _buildStatCard(
                        title: 'PAYABLES',
                        amount: _formatCurrency(
                          dashboardState.data?.totalPayables ?? 0.0,
                        ),
                        color: const Color(0xFFDC2626),
                        bgColor: const Color(0xFFFEE2E2),
                        icon: Icons.arrow_upward,
                      ),
                      _buildStatCard(
                        title: 'NET PROFIT',
                        amount: _formatCurrency(
                          dashboardState.data?.netProfit ?? 0.0,
                        ),
                        color: const Color(0xFF16A34A),
                        bgColor: const Color(0xFFDCFCE7),
                        icon: Icons.trending_up,
                      ),
                      _buildStatCard(
                        title: 'EXPENSES',
                        amount: _formatCurrency(
                          dashboardState.data?.totalExpenses ?? 0.0,
                        ),
                        color: const Color(0xFF7E22CE),
                        bgColor: const Color(0xFFF3E8FF),
                        icon: Icons.account_balance_wallet_outlined,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                AppButton(
                  text: 'Log Out',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String amount,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: AppTextStyles.numeric.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
