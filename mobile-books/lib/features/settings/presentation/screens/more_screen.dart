import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/core/permissions/permission_helper.dart';

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
            _buildSectionHeader(context, 'Items & Inventory'),
            _buildMenuItem(
              context: context,
              icon: Icons.inventory_2_outlined,
              label: 'Items List',
              path: '/items',
              show: hasPermission('/items'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.add_box_outlined,
              label: 'Stock In / Stock Out',
              path: '/inventory/stock',
              show: hasPermission('/inventory/stock'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.swap_horiz_outlined,
              label: 'Inventory Movements',
              path: '/inventory/movements',
              show: hasPermission('/inventory/movements'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.warning_amber_outlined,
              label: 'Low Stock Alerts',
              path: '/inventory/low-stock',
              show: hasPermission('/inventory/low-stock'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.assessment_outlined,
              label: 'Item Valuation Report',
              path: '/reports/item-valuation',
              show: hasPermission('/reports/item-valuation'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Sales'),
            _buildMenuItem(
              context: context,
              icon: Icons.request_quote_outlined,
              label: 'Quotes',
              path: '/quotes',
              show: hasPermission('/quotes'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.shopping_bag_outlined,
              label: 'Sales Orders',
              path: '/sales-orders',
              show: hasPermission('/sales-orders'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.payment_outlined,
              label: 'Payments Received',
              path: '/payments-received',
              show: hasPermission('/payments-received'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.local_shipping_outlined,
              label: 'Delivery Challans',
              path: '/delivery-challans',
              show: hasPermission('/delivery-challans'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.assignment_return_outlined,
              label: 'Credit Notes',
              path: '/credit-notes',
              show: hasPermission('/credit-notes'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.update_outlined,
              label: 'Recurring Invoices',
              path: '/recurring-invoices',
              show: hasPermission('/recurring-invoices'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.person_outline,
              label: 'Salespersons',
              path: '/salespersons',
              show: hasPermission('/salespersons'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Purchases'),
            _buildMenuItem(
              context: context,
              icon: Icons.people_outline,
              label: 'Vendors',
              path: '/vendors',
              show: hasPermission('/vendors'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.receipt_long_outlined,
              label: 'Bills',
              path: '/bills',
              show: hasPermission('/bills'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.money_off_outlined,
              label: 'Expenses',
              path: '/expenses',
              show: hasPermission('/expenses'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.timer_outlined,
              label: 'Recurring Expenses',
              path: '/recurring-expenses',
              show: hasPermission('/recurring-expenses'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.shopping_cart_outlined,
              label: 'Purchase Orders',
              path: '/purchase-orders',
              show: hasPermission('/purchase-orders'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.payment_outlined,
              label: 'Payments Made',
              path: '/payments-made',
              show: hasPermission('/payments-made'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.credit_card_off_outlined,
              label: 'Vendor Credits',
              path: '/vendor-credits',
              show: hasPermission('/vendor-credits'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Time Tracking'),
            _buildMenuItem(
              context: context,
              icon: Icons.work_outline,
              label: 'Projects',
              path: '/projects',
              show: hasPermission('/projects'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.pending_actions_outlined,
              label: 'Timesheets',
              path: '/timesheets',
              show: hasPermission('/timesheets'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Banking'),
            _buildMenuItem(
              context: context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Bank Accounts',
              path: '/banking',
              show: hasPermission('/banking'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.gavel_outlined,
              label: 'Bank Rules',
              path: '/bank-rules',
              show: hasPermission('/bank-rules'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.compare_arrows_outlined,
              label: 'Reconciliation',
              path: '/reconciliation',
              show: hasPermission('/reconciliation'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Accountant'),
            _buildMenuItem(
              context: context,
              icon: Icons.list_alt_outlined,
              label: 'Chart of Accounts',
              path: '/accounting/coa',
              show: hasPermission('/accounting/coa'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.menu_book_outlined,
              label: 'Manual Journals',
              path: '/accounting/journals',
              show: hasPermission('/accounting/journals'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.lock_outline,
              label: 'Transaction Locking',
              path: '/transaction-locking',
              show: hasPermission('/transaction-locking'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.published_with_changes_outlined,
              label: 'Bulk Updates',
              path: '/bulk-updates',
              show: hasPermission('/bulk-updates'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.currency_exchange_outlined,
              label: 'Currency Adjustments',
              path: '/currency-adjustments',
              show: hasPermission('/currency-adjustments'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.percent_outlined,
              label: 'Taxes',
              path: '/taxes',
              show: hasPermission('/taxes'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Reports'),
            _buildMenuItem(
              context: context,
              icon: Icons.trending_up_outlined,
              label: 'Profit & Loss',
              path: '/reports/profit-loss',
              show: hasPermission('/reports/profit-loss'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.account_balance_outlined,
              label: 'Balance Sheet',
              path: '/reports/balance-sheet',
              show: hasPermission('/reports/balance-sheet'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.analytics_outlined,
              label: 'Cash Flow',
              path: '/reports/cash-flow',
              show: hasPermission('/reports/cash-flow'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.scale_outlined,
              label: 'Trial Balance',
              path: '/reports/trial-balance',
              show: hasPermission('/reports/trial-balance'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Documents'),
            _buildMenuItem(
              context: context,
              icon: Icons.folder_open_outlined,
              label: 'All Documents',
              path: '/documents',
              show: hasPermission('/documents'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.upload_file_outlined,
              label: 'Upload Documents',
              path: '/documents/upload',
              show: hasPermission('/documents/upload'),
            ),

            const Divider(height: AppSpacing.l),
            _buildSectionHeader(context, 'Settings'),
            _buildMenuItem(
              context: context,
              icon: Icons.business_outlined,
              label: 'Organization Settings',
              path: '/settings/organization',
              show: hasPermission('/settings/organization'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.people_alt_outlined,
              label: 'Users & Roles',
              path: '/settings/users',
              show: hasPermission('/settings/users'),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.workspace_premium_outlined,
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
        Icons.chevron_right,
        size: 18,
        color: Colors.grey,
      ),
      dense: true,
      onTap: () {
        context.go(path);
      },
    );
  }
}
