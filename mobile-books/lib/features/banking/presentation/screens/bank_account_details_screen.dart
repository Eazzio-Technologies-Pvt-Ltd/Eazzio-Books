import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/banking/data/models/bank_account.dart';
import 'package:mobile_books/features/banking/data/models/bank_transaction.dart';
import 'package:mobile_books/features/banking/presentation/providers/banking_provider.dart';
import 'package:mobile_books/features/transaction_locks/presentation/widgets/lock_warning_banner.dart';
import 'package:mobile_books/features/transaction_locks/utils/transaction_lock_validator.dart';

class BankAccountDetailsScreen extends ConsumerStatefulWidget {
  final int accountId;

  const BankAccountDetailsScreen({
    super.key,
    required this.accountId,
  });

  @override
  ConsumerState<BankAccountDetailsScreen> createState() => _BankAccountDetailsScreenState();
}

class _BankAccountDetailsScreenState extends ConsumerState<BankAccountDetailsScreen> {
  void _showAddTransactionDialog(BuildContext context, BankAccount account) {
    showDialog(
      context: context,
      builder: (context) {
        return AddTransactionDialog(
          accountId: account.id,
          account: account,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(bankAccountsProvider);
    final transactionsState = ref.watch(bankTransactionsProvider(widget.accountId));
    final privacyMode = ref.watch(privacyModeProvider);

    return ResponsiveScaffold(
      currentRoute: '/banking',
      appBar: AppBar(
        title: const Text('Account Details'),
        actions: [
          IconButton(
            icon: Icon(privacyMode ? Icons.visibility_off : Icons.visibility),
            onPressed: () => ref.read(privacyModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: accountsState.when(
        data: (accounts) {
          final account = accounts.cast<BankAccount?>().firstWhere(
                (a) => a?.id == widget.accountId,
                orElse: () => null,
              );

          if (account == null) {
            return const Center(child: Text('Account not found.'));
          }

          return Column(
            children: [
              // Header Card
              Card(
                margin: const EdgeInsets.all(AppSpacing.m),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.accountName,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(account.bankName, style: const TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.compare_arrows),
                            label: const Text('Reconcile'),
                            onPressed: () => context.push('/banking/${account.id}/reconcile'),
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.l),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Account Number', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                              Text(
                                '•••• ${account.accountNumber.substring(account.accountNumber.length > 4 ? account.accountNumber.length - 4 : 0)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Authoritative Balance', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                              Text(
                                privacyMode
                                    ? '••••'
                                    : '₹${account.currentBalance.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transactions History',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Transaction'),
                      onPressed: () => _showAddTransactionDialog(context, account),
                    ),
                  ],
                ),
              ),

              // Transactions List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(bankTransactionsProvider(widget.accountId));
                    await ref.read(bankAccountsProvider.notifier).refresh();
                  },
                  child: transactionsState.when(
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return const Center(child: Text('No transactions recorded.'));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                        itemCount: transactions.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final isDeposit = tx.transactionType == 'deposit';
                          final dateStr = DateFormat('yyyy-MM-dd').format(tx.transactionDate);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                            title: Text(
                              tx.description ?? (isDeposit ? 'Deposit' : 'Withdrawal'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Row(
                              children: [
                                Text(dateStr, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: AppSpacing.s),
                                if (tx.reference != null && tx.reference!.isNotEmpty)
                                  Text('Ref: ${tx.reference}', style: const TextStyle(fontSize: 12)),
                                const Spacer(),
                                if (tx.isReconciled)
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: AppColors.success, size: 14),
                                      SizedBox(width: 2),
                                      Text('Reconciled', style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                              ],
                            ),
                            trailing: Text(
                              isDeposit
                                  ? '+₹${tx.amount.toStringAsFixed(2)}'
                                  : '-₹${tx.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDeposit ? AppColors.success : AppColors.danger,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error loading transactions: $err')),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class AddTransactionDialog extends ConsumerStatefulWidget {
  final int accountId;
  final BankAccount account;

  const AddTransactionDialog({
    super.key,
    required this.accountId,
    required this.account,
  });

  @override
  ConsumerState<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  String _transactionType = 'withdrawal'; // default
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check lock validation
    final isLocked = ref.watch(transactionLockValidatorProvider).isLocked(
          module: TransactionLockModule.bankTransactions,
          date: _selectedDate,
        );

    return AlertDialog(
      title: const Text('Record Transaction'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show warning banner if transaction date is in a locked period
              LockWarningBanner(
                module: TransactionLockModule.bankTransactions,
                date: _selectedDate,
              ),
              DropdownButtonFormField<String>(
                initialValue: _transactionType,
                decoration: const InputDecoration(labelText: 'Type *'),
                items: const [
                  DropdownMenuItem(value: 'deposit', child: Text('Deposit')),
                  DropdownMenuItem(value: 'withdrawal', child: Text('Withdrawal')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _transactionType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (₹) *'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final amt = double.tryParse(v);
                  if (amt == null || amt <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description *'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(labelText: 'Reference / Ref Number'),
              ),
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Change'),
                    onPressed: () => _selectDate(context),
                  ),
                ],
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
          // Disable save button if locked
          onPressed: isLocked
              ? null
              : () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final tx = BankTransaction(
                      id: 0,
                      bankAccountId: widget.accountId,
                      userId: 0,
                      transactionDate: _selectedDate,
                      description: _descriptionController.text,
                      transactionType: _transactionType,
                      amount: double.parse(_amountController.text),
                      reference: _referenceController.text,
                      isReconciled: false,
                    );

                    try {
                      await ref.read(bankingOperationsProvider.notifier).addTransaction(widget.accountId, tx);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction recorded successfully.')),
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
  }
}
