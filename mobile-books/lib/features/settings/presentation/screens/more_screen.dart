import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/core/permissions/permission_helper.dart';
import 'package:mobile_books/core/theme/app_icons.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final role = authState is AuthAuthenticated ? authState.user.role : 'Admin';

    // Helper to check route permissions
    bool hasPermission(String? path) {
      if (path == null) return false;
      return PermissionHelper.hasRoutePermission(role, path);
    }

    // Build lists with permissions checked
    return ResponsiveScaffold(
      currentRoute: '/more',
      appBar: AppBar(
        title: const Text('More'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(context, ref, authState),
            const Divider(height: AppSpacing.m),
            _buildSectionHeader(context, 'Items & Inventory'),
            _buildMenuItem(
              context: context,
              icon: AppIcons.inventory_2_outlined,
              label: 'Items List',
              path: '/items',
              show: hasPermission('/items'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.add_box_outlined,
              label: 'Stock In / Stock Out',
              path: '/inventory/stock',
              show: hasPermission('/inventory/stock'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.swap_horiz_outlined,
              label: 'Inventory Movements',
              path: '/inventory/movements',
              show: hasPermission('/inventory/movements'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.warning_amber_outlined,
              label: 'Low Stock Alerts',
              path: '/inventory/low-stock',
              show: hasPermission('/inventory/low-stock'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.assessment_outlined,
              label: 'Item Valuation Report',
              path: '/reports/item-valuation',
              show: hasPermission('/reports/item-valuation'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Sales'),
            _buildMenuItem(
              context: context,
              icon: AppIcons.request_quote_outlined,
              label: 'Quotes',
              path: '/quotes',
              show: hasPermission('/quotes'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.shopping_bag_outlined,
              label: 'Sales Orders',
              path: '/sales-orders',
              show: hasPermission('/sales-orders'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.payment_outlined,
              label: 'Payments Received',
              path: '/payments-received',
              show: hasPermission('/payments-received'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.local_shipping_outlined,
              label: 'Delivery Challans',
              path: '/delivery-challans',
              show: hasPermission('/delivery-challans'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.assignment_return_outlined,
              label: 'Credit Notes',
              path: '/credit-notes',
              show: hasPermission('/credit-notes'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.update_outlined,
              label: 'Recurring Invoices',
              path: '/recurring-invoices',
              show: hasPermission('/recurring-invoices'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.person_outline,
              label: 'Salespersons',
              path: '/salespersons',
              show: hasPermission('/salespersons'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Purchases'),
            _buildMenuItem(
              context: context,
              icon: AppIcons.people_outline,
              label: 'Vendors',
              path: '/vendors',
              show: hasPermission('/vendors'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.receipt_long_outlined,
              label: 'Bills',
              path: '/bills',
              show: hasPermission('/bills'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.money_off_outlined,
              label: 'Expenses',
              path: '/expenses',
              show: hasPermission('/expenses'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.timer_outlined,
              label: 'Recurring Expenses',
              path: '/recurring-expenses',
              show: hasPermission('/recurring-expenses'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.shopping_cart_outlined,
              label: 'Purchase Orders',
              path: '/purchase-orders',
              show: hasPermission('/purchase-orders'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.payment_outlined,
              label: 'Payments Made',
              path: '/payments-made',
              show: hasPermission('/payments-made'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.credit_card_off_outlined,
              label: 'Vendor Credits',
              path: '/vendor-credits',
              show: hasPermission('/vendor-credits'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Time Tracking'),
            _buildMenuItem(
              context: context,
              icon: AppIcons.work_outline,
              label: 'Projects',
              path: '/projects',
              show: hasPermission('/projects'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.pending_actions_outlined,
              label: 'Timesheets',
              path: '/timesheets',
              show: hasPermission('/timesheets'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Banking'),
            _buildMenuItem(
              context: context,
              icon: AppIcons.account_balance_wallet_outlined,
              label: 'Bank Accounts',
              path: '/banking',
              show: hasPermission('/banking'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.money_outlined,
              label: 'Petty Cash',
              path: '/banking/petty-cash',
              show: hasPermission('/banking'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.all_inbox_outlined,
              label: 'Undeposited Funds',
              path: '/banking/undeposited-funds',
              show: hasPermission('/banking'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.gavel_outlined,
              label: 'Bank Rules',
              path: '/bank-rules',
              show: hasPermission('/bank-rules'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.compare_arrows_outlined,
              label: 'Reconciliation',
              path: '/reconciliation',
              show: hasPermission('/reconciliation'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Accountant'),
            _buildMenuItem(
              context: context,
              icon: AppIcons.list_alt_outlined,
              label: 'Chart of Accounts',
              path: '/accounting/coa',
              show: hasPermission('/accounting/coa'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.menu_book_outlined,
              label: 'Manual Journals',
              path: '/accounting/journals',
              show: hasPermission('/accounting/journals'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.lock_outline,
              label: 'Transaction Locking',
              path: '/transaction-locking',
              show: hasPermission('/transaction-locking'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.published_with_changes_outlined,
              label: 'Bulk Updates',
              path: '/bulk-updates',
              show: hasPermission('/bulk-updates'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.currency_exchange_outlined,
              label: 'Currency Adjustments',
              path: '/currency-adjustments',
              show: hasPermission('/currency-adjustments'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.percent_outlined,
              label: 'Taxes',
              path: '/taxes',
              show: hasPermission('/taxes'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Reports'),
            _buildMenuItem(
              context: context,
              icon: AppIcons.trending_up_outlined,
              label: 'Profit & Loss',
              path: '/reports/profit-loss',
              show: hasPermission('/reports/profit-loss'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.account_balance_outlined,
              label: 'Balance Sheet',
              path: '/reports/balance-sheet',
              show: hasPermission('/reports/balance-sheet'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.analytics_outlined,
              label: 'Cash Flow',
              path: '/reports/cash-flow',
              show: hasPermission('/reports/cash-flow'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.scale_outlined,
              label: 'Trial Balance',
              path: '/reports/trial-balance',
              show: hasPermission('/reports/trial-balance'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.payments_outlined,
              label: 'Projected Payments',
              path: '/projected-payments',
              show: true,
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.money_off_csred_outlined,
              label: 'Projected Expenses',
              path: '/projected-expenses',
              show: true,
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Documents'),
            _buildMenuItem(
              context: context,
              icon: AppIcons.folder_open_outlined,
              label: 'All Documents',
              path: '/documents',
              show: hasPermission('/documents'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.upload_file_outlined,
              label: 'Upload Documents',
              path: '/documents/upload',
              show: hasPermission('/documents/upload'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Settings'),
            _buildMenuItem(
              context: context,
              icon: AppIcons.business_outlined,
              label: 'Organization Settings',
              path: '/settings/organization',
              show: hasPermission('/settings/organization'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.people_alt_outlined,
              label: 'Users & Roles',
              path: '/settings/users',
              show: hasPermission('/settings/users'),
            ),
            _buildMenuItem(
              context: context,
              icon: AppIcons.workspace_premium_outlined,
              label: 'Pricing Plans',
              path: '/pricing',
              show: true,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.grey[400] : AppColors.textSecondaryLight,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String path,
    required bool show,
  }) {
    if (!show) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.white70 : AppColors.primaryBlue,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
        ),
      ),
      trailing: const Icon(
        AppIcons.chevron_right,
        size: 18,
        color: Colors.grey,
      ),
      dense: true,
      onTap: () {
        context.go(path);
      },
    );
  }

  Widget _buildProfileCard(BuildContext context, WidgetRef ref, AuthState authState) {
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    
    final user = authState.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  user.email.isNotEmpty ? user.email[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.role,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user.planId.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.s),

          
          // Logout Tile
          ListTile(
            leading: const Icon(AppIcons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
            onTap: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}
