import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/accounting/data/models/chart_of_account.dart';
import 'package:mobile_books/features/accounting/presentation/providers/accounting_provider.dart';
import 'package:mobile_books/features/banking/presentation/providers/banking_provider.dart';
import 'package:mobile_books/widgets/common/loading_skeleton.dart';

class ChartOfAccountsScreen extends ConsumerWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(coaAccountsProvider);
    final privacyMode = ref.watch(privacyModeProvider);

    return DefaultTabController(
      length: 5,
      child: ResponsiveScaffold(
        currentRoute: '/accounting/coa',
        appBar: AppBar(
          title: const Text('Chart of Accounts'),
          actions: [
            IconButton(
              icon: Icon(privacyMode ? Icons.visibility_off : Icons.visibility),
              onPressed: () => ref.read(privacyModeProvider.notifier).toggle(),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Assets'),
              Tab(text: 'Liabilities'),
              Tab(text: 'Equity'),
              Tab(text: 'Income'),
              Tab(text: 'Expenses'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/accounting/coa/new'),
          child: const Icon(Icons.add),
        ),
        body: accountsState.when(
          data: (accounts) {
            final assets = accounts.where((a) => a.accountType.toLowerCase() == 'asset').toList();
            final liabilities = accounts.where((a) => a.accountType.toLowerCase() == 'liability').toList();
            final equity = accounts.where((a) => a.accountType.toLowerCase() == 'equity').toList();
            final income = accounts.where((a) => a.accountType.toLowerCase() == 'income').toList();
            final expenses = accounts.where((a) => a.accountType.toLowerCase() == 'expense').toList();

            return TabBarView(
              children: [
                _buildAccountsList(context, ref, assets, privacyMode),
                _buildAccountsList(context, ref, liabilities, privacyMode),
                _buildAccountsList(context, ref, equity, privacyMode),
                _buildAccountsList(context, ref, income, privacyMode),
                _buildAccountsList(context, ref, expenses, privacyMode),
              ],
            );
          },
          loading: () => ListView.builder(
            itemCount: 6,
            itemBuilder: (context, index) => LoadingSkeleton.skeletonListItem(),
          ),
          error: (err, _) => Center(child: Text('Error loading COA: $err')),
        ),
      ),
    );
  }

  Widget _buildAccountsList(
    BuildContext context,
    WidgetRef ref,
    List<ChartOfAccount> list,
    bool privacyMode,
  ) {
    if (list.isEmpty) {
      return const Center(child: Text('No accounts in this category.'));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(coaAccountsProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.m),
        itemCount: list.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final account = list[index];
          final isSystemAccount = _isSystemAccount(account.accountCode);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            title: Text(
              account.accountName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (account.accountCode != null)
                  Text('Code: ${account.accountCode}', style: const TextStyle(fontSize: 12)),
                if (account.description != null && account.description!.isNotEmpty)
                  Text(
                    account.description!,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Balance', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                    Text(
                      privacyMode ? '••••' : '₹${account.currentBalance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.s),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => context.push('/accounting/coa/${account.id}/edit'),
                ),
                // Only allow deleting custom accounts (not system/default accounts)
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: isSystemAccount ? Colors.grey : AppColors.danger),
                  onPressed: isSystemAccount
                      ? null
                      : () => _handleDeleteAccount(context, ref, account),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isSystemAccount(String? code) {
    // Basic codes pre-created by default schema setup
    final systemCodes = {'1001', '1002', '1200', '1300', '2000', '2200', '3000', '4000', '5000'};
    return code != null && systemCodes.contains(code);
  }

  void _handleDeleteAccount(BuildContext context, WidgetRef ref, ChartOfAccount account) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Text('Are you sure you want to delete "${account.accountName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await ref.read(coaAccountsProvider.notifier).deleteAccount(account.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account deleted successfully.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete account: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
