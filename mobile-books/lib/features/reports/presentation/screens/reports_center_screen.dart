import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';

import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

class ReportsCenterScreen extends StatelessWidget {
  const ReportsCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reportGroups = [
      _ReportGroup(
        category: 'Business Overview',
        reports: [
          _ReportItem(
            name: 'Profit and Loss',
            description: 'View your income, expenses, and net profit.',
            path: '/reports/profit-loss',
            icon: Icons.pie_chart,
          ),
          _ReportItem(
            name: 'Balance Sheet',
            description: 'A snapshot of your business\'s financial position (assets, liabilities, equity).',
            path: '/reports/balance-sheet',
            icon: Icons.account_balance_wallet,
          ),
          _ReportItem(
            name: 'Cash Flow Statement',
            description: 'Track money moving in and out of your business.',
            path: '/reports/cash-flow',
            icon: Icons.swap_horiz,
          ),
        ],
      ),
      _ReportGroup(
        category: 'Accountant',
        reports: [
          _ReportItem(
            name: 'Trial Balance',
            description: 'View a summary of all your accounts and their balances.',
            path: '/reports/trial-balance',
            icon: Icons.account_balance,
          ),
        ],
      ),
      _ReportGroup(
        category: 'Receivables & Payables',
        reports: [
          _ReportItem(
            name: 'Customer Aging',
            description: 'See which customers are taking a long time to pay.',
            path: '/reports/customer-aging',
            icon: Icons.hourglass_bottom,
          ),
          _ReportItem(
            name: 'Vendor Aging',
            description: 'Track unpaid bills and when they are due.',
            path: '/reports/vendor-aging',
            icon: Icons.hourglass_empty,
          ),
        ],
      ),
    ];

    return ResponsiveScaffold(
      currentRoute: '/reports',
      appBar: AppBar(
        title: const Text('Reports Center'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.m),
        itemCount: reportGroups.length,
        itemBuilder: (context, index) {
          final group = reportGroups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                child: Text(
                  group.category,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...group.reports.map((report) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.s),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.xs,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Icon(report.icon, color: AppColors.primaryBlue),
                    ),
                    title: Text(
                      report.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        report.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(report.path),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.m),
            ],
          );
        },
      ),
    );
  }
}

class _ReportGroup {
  final String category;
  final List<_ReportItem> reports;
  _ReportGroup({required this.category, required this.reports});
}

class _ReportItem {
  final String name;
  final String description;
  final String path;
  final IconData icon;

  _ReportItem({
    required this.name,
    required this.description,
    required this.path,
    required this.icon,
  });
}
