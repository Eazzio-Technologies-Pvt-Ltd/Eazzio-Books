import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/banking/data/models/bank_account.dart';
import 'package:mobile_books/features/banking/data/services/banking_service.dart';
import 'package:mobile_books/features/banking/presentation/providers/banking_provider.dart';

class BankAccountsScreen extends ConsumerWidget {
  const BankAccountsScreen({super.key});

  String _maskAccountNumber(String number) {
    if (number.length <= 4) return number;
    return '•••• •••• •••• ${number.substring(number.length - 4)}';
  }

  void _showAddAccountDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final accountNameController = TextEditingController();
    final bankNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final ifscCodeController = TextEditingController();
    final openingBalanceController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Bank Account'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: accountNameController,
                    decoration: const InputDecoration(labelText: 'Account Name *'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextFormField(
                    controller: bankNameController,
                    decoration: const InputDecoration(labelText: 'Bank Name *'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextFormField(
                    controller: accountNumberController,
                    decoration: const InputDecoration(labelText: 'Account Number *'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextFormField(
                    controller: ifscCodeController,
                    decoration: const InputDecoration(labelText: 'IFSC Code *'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.s),
                  TextFormField(
                    controller: openingBalanceController,
                    decoration: const InputDecoration(labelText: 'Opening Balance'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final openingBal = double.tryParse(openingBalanceController.text) ?? 0.0;
                  final newAccount = BankAccount(
                    id: 0,
                    userId: 0,
                    accountName: accountNameController.text,
                    bankName: bankNameController.text,
                    accountNumber: accountNumberController.text,
                    ifscCode: ifscCodeController.text,
                    openingBalance: openingBal,
                    currentBalance: openingBal,
                  );

                  try {
                    await ref.read(bankAccountsProvider.notifier).createAccount(newAccount);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bank account created successfully.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref, BankAccount account) async {
    // Show a loading dialog during transactions checking
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final transactions = await ref.read(bankingServiceProvider).getTransactions(account.id);
      if (context.mounted) Navigator.pop(context); // Dismiss loading spinner

      final hasReconciled = transactions.any((tx) => tx.isReconciled);

      if (context.mounted) {
        if (hasReconciled) {
          // BG-002 block condition triggered
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Delete Blocked'),
                content: const Text(
                  'This bank account has reconciled transactions linked to a closed statement period.\n\n'
                  'In-app deletion is blocked to preserve accounting integrity.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          // Confirm hard delete warning dialog
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Warning: Irreversible Delete'),
                content: Text(
                  'Are you sure you want to delete "${account.accountName}"?\n\n'
                  'This is a hard delete and will permanently remove this bank account and all its transaction logs from the database.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                    onPressed: () async {
                      Navigator.pop(context); // Close warning dialog
                      try {
                        await ref.read(bankAccountsProvider.notifier).deleteAccount(account.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bank account deleted.')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Delete failed: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Permanently Delete', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Dismiss loading spinner
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check account state: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsState = ref.watch(bankAccountsProvider);
    final privacyMode = ref.watch(privacyModeProvider);

    return ResponsiveScaffold(
      currentRoute: '/banking',
      appBar: AppBar(
        title: const Text('Bank Accounts'),
        actions: [
          IconButton(
            icon: Icon(privacyMode ? Icons.visibility_off : Icons.visibility),
            tooltip: privacyMode ? 'Show balances' : 'Hide balances',
            onPressed: () => ref.read(privacyModeProvider.notifier).toggle(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAccountDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(bankAccountsProvider.notifier).refresh(),
        child: accountsState.when(
          data: (accounts) {
            if (accounts.isEmpty) {
              return const Center(child: Text('No bank accounts registered.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.m),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.m),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(AppSpacing.m),
                    title: Text(
                      account.accountName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.xs),
                        Text(account.bankName, style: const TextStyle(fontSize: 14)),
                        Text('IFSC: ${account.ifscCode}', style: const TextStyle(fontSize: 12)),
                        Text(
                          'A/C: ${_maskAccountNumber(account.accountNumber)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Balance', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          privacyMode
                              ? '••••'
                              : '₹${account.currentBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => context.push('/banking/${account.id}'),
                    onLongPress: () => _handleDeleteAccount(context, ref, account),
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
