import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';

class ReportNavBar extends StatelessWidget {
  final String currentRoute;
  const ReportNavBar({required this.currentRoute, super.key});

  @override
  Widget build(BuildContext context) {
    final reports = [
      ('P&L', '/reports/profit-loss'),
      ('Balance Sheet', '/reports/balance-sheet'),
      ('Cash Flow', '/reports/cash-flow'),
      ('Trial Balance', '/reports/trial-balance'),
      ('Cust. Aging', '/reports/customer-aging'),
      ('Vendor Aging', '/reports/vendor-aging'),
    ];
    return Container(
      color: AppColors.surfaceLight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        child: Row(
          children: reports.map((r) {
            final isActive = currentRoute == r.$2;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s),
              child: ChoiceChip(
                label: Text(r.$1),
                selected: isActive,
                onSelected: (_) => context.go(r.$2),
                selectedColor: AppColors.primaryBlue,
                labelStyle: TextStyle(
                  color: isActive ? Colors.white : AppColors.textSecondaryLight,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
