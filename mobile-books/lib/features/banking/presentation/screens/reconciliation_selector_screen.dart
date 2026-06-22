import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/banking/presentation/providers/banking_provider.dart';

class ReconciliationSelectorScreen extends ConsumerWidget {
  const ReconciliationSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(bankAccountsProvider);

    return ResponsiveScaffold(
      currentRoute: '/reconciliation',
      appBar: AppBar(
        title: const Text('Select Account for Reconciliation'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(bankAccountsProvider.notifier).refresh(),
        child: accountsState.when(
          data: (accounts) {
            if (accounts.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'No bank accounts registered.\nPlease add a bank account first under the Bank Accounts screen.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.m),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.m),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.m),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.account_balance, color: Colors.white),
                    ),
                    title: Text(
                      account.accountName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xs),
                        Text(account.bankName, style: const TextStyle(fontSize: 14)),
                        Text('A/C: ${account.accountNumber}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/banking/${account.id}/reconcile');
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error loading accounts: $err')),
        ),
      ),
    );
  }
}
