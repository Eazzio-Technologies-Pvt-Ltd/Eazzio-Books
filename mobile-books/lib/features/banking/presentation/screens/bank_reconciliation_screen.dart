import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/banking/data/models/bank_account.dart';
import 'package:mobile_books/features/banking/data/models/bank_reconciliation.dart';
import 'package:mobile_books/features/banking/presentation/providers/banking_provider.dart';

class BankReconciliationScreen extends ConsumerStatefulWidget {
  final int bankAccountId;

  const BankReconciliationScreen({
    super.key,
    required this.bankAccountId,
  });

  @override
  ConsumerState<BankReconciliationScreen> createState() => _BankReconciliationScreenState();
}

class _BankReconciliationScreenState extends ConsumerState<BankReconciliationScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  final _openingBalanceController = TextEditingController(text: '0.00');
  final _closingBalanceController = TextEditingController(text: '0.00');
  String _status = 'draft'; // 'draft' or 'reconciled'
  bool _isInitialized = false;

  final Set<int> _reconciledTxIds = {};

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(bankAccountsProvider);
    final transactionsState = ref.watch(bankTransactionsProvider(widget.bankAccountId));

    return ResponsiveScaffold(
      currentRoute: '/banking',
      appBar: AppBar(
        title: const Text('Bank Reconciliation'),
      ),
      body: accountsState.when(
        data: (accounts) {
          final account = accounts.cast<BankAccount?>().firstWhere(
                (a) => a?.id == widget.bankAccountId,
                orElse: () => null,
              );

          if (account == null) {
            return const Center(child: Text('Bank account not found.'));
          }

          if (!_isInitialized) {
            _openingBalanceController.text = account.openingBalance.toStringAsFixed(2);
            _isInitialized = true;
          }

          return transactionsState.when(
            data: (transactions) {
              // Filter transactions in date range
              final dateFilteredTxs = transactions.where((tx) {
                final date = tx.transactionDate;
                final startOnly = DateTime(_startDate.year, _startDate.month, _startDate.day);
                final endOnly = DateTime(_endDate.year, _endDate.month, _endDate.day);
                final txOnly = DateTime(date.year, date.month, date.day);
                return (txOnly.isAfter(startOnly) || txOnly.isAtSameMomentAs(startOnly)) &&
                    (txOnly.isBefore(endOnly) || txOnly.isAtSameMomentAs(endOnly));
              }).toList();

              // Calculate deposits & withdrawals for selected/checked items in range
              double totalDeposits = 0.0;
              double totalWithdrawals = 0.0;

              for (final tx in dateFilteredTxs) {
                if (_reconciledTxIds.contains(tx.id)) {
                  if (tx.transactionType == 'deposit') {
                    totalDeposits += tx.amount;
                  } else {
                    totalWithdrawals += tx.amount;
                  }
                }
              }

              final openingBal = double.tryParse(_openingBalanceController.text) ?? 0.0;
              final closingBal = double.tryParse(_closingBalanceController.text) ?? 0.0;

              // Difference = Closing Balance - (Opening Balance + Deposits - Withdrawals)
              final difference = closingBal - (openingBal + totalDeposits - totalWithdrawals);
              final isDifferenceZero = difference.abs() < 0.01;

              // Enforce Reconciled Status Gate: if difference is not zero, force status to draft
              if (!isDifferenceZero && _status == 'reconciled') {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _status = 'draft';
                  });
                });
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Inputs Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statement Period',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.date_range, size: 16),
                                    label: Text('From: ${DateFormat('yyyy-MM-dd').format(_startDate)}'),
                                    onPressed: () => _selectDate(context, true),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.date_range, size: 16),
                                    label: Text('To: ${DateFormat('yyyy-MM-dd').format(_endDate)}'),
                                    onPressed: () => _selectDate(context, false),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Balance Config Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reconciliation Balances',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppSpacing.s),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _openingBalanceController,
                                    decoration: const InputDecoration(labelText: 'Opening Balance (₹)'),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                    onChanged: (v) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.m),
                                Expanded(
                                  child: TextFormField(
                                    controller: _closingBalanceController,
                                    decoration: const InputDecoration(labelText: 'Closing Balance (₹)'),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                    onChanged: (v) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Summary Calculations Panel
                    Card(
                      color: isDifferenceZero ? Colors.green.shade50 : Colors.amber.shade50,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isDifferenceZero ? Colors.green.shade300 : Colors.amber.shade300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        child: Column(
                          children: [
                            _buildSummaryRow('Statement Deposits (Checked)', '+₹${totalDeposits.toStringAsFixed(2)}', isBold: false),
                            const SizedBox(height: AppSpacing.xs),
                            _buildSummaryRow('Statement Withdrawals (Checked)', '-₹${totalWithdrawals.toStringAsFixed(2)}', isBold: false),
                            const Divider(height: AppSpacing.m),
                            _buildSummaryRow(
                              'Difference',
                              '₹${difference.toStringAsFixed(2)}',
                              isBold: true,
                              valueColor: isDifferenceZero ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                            if (!isDifferenceZero)
                              const Padding(
                                padding: EdgeInsets.only(top: AppSpacing.s),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.amber, size: 16),
                                    SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        'Reconciliation status cannot be set to "reconciled" until difference is exactly 0.00.',
                                        style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Status Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Reconciliation Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: _status,
                          items: [
                            const DropdownMenuItem(value: 'draft', child: Text('Draft')),
                            DropdownMenuItem(
                              value: 'reconciled',
                              // Lock reconciled option if difference is not zero
                              enabled: isDifferenceZero,
                              child: Text(
                                'Reconciled',
                                style: TextStyle(color: isDifferenceZero ? Colors.black : Colors.grey),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _status = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Title
                    Text(
                      'Select Reconciled Transactions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.s),

                    // Grid-like list of transactions
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dateFilteredTxs.length,
                      itemBuilder: (context, index) {
                        final tx = dateFilteredTxs[index];
                        final isChecked = _reconciledTxIds.contains(tx.id);
                        final isDeposit = tx.transactionType == 'deposit';
                        final dateStr = DateFormat('yyyy-MM-dd').format(tx.transactionDate);

                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(tx.description ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('$dateStr  |  ${isDeposit ? 'Deposit' : 'Withdrawal'}', style: const TextStyle(fontSize: 12)),
                          secondary: Text(
                            isDeposit ? '+₹${tx.amount.toStringAsFixed(2)}' : '-₹${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDeposit ? AppColors.success : AppColors.danger,
                            ),
                          ),
                          value: isChecked,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _reconciledTxIds.add(tx.id);
                              } else {
                                _reconciledTxIds.remove(tx.id);
                              }
                            });
                          },
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        ElevatedButton(
                          onPressed: () async {
                            final reconRecord = BankReconciliation(
                              id: 0,
                              userId: 0,
                              bankAccountId: widget.bankAccountId,
                              statementStartDate: _startDate,
                              statementEndDate: _endDate,
                              openingBalance: openingBal,
                              closingBalance: closingBal,
                              totalDeposits: totalDeposits,
                              totalWithdrawals: totalWithdrawals,
                              difference: difference,
                              status: _status,
                            );

                            try {
                              // 1. Bulk reconcile selected transactions
                              final selectedIds = _reconciledTxIds.toList();
                              await ref.read(bankingOperationsProvider.notifier).reconcileBulkTransactions(
                                    widget.bankAccountId,
                                    selectedIds,
                                    true,
                                  );

                              // 2. Un-reconcile transactions not selected in the filtered date range list
                              final unselectedIds = dateFilteredTxs
                                  .where((tx) => !_reconciledTxIds.contains(tx.id))
                                  .map((tx) => tx.id)
                                  .toList();

                              if (unselectedIds.isNotEmpty) {
                                await ref.read(bankingOperationsProvider.notifier).reconcileBulkTransactions(
                                      widget.bankAccountId,
                                      unselectedIds,
                                      false,
                                    );
                              }

                              // 3. Save reconciliation statement record
                              await ref.read(bankingOperationsProvider.notifier).createReconciliation(reconRecord);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Reconciliation saved in status "$_status".')),
                                );
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Save Reconciliation'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading account details: $err')),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {required bool isBold, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.black : Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: valueColor ?? (isBold ? Colors.black : Colors.black87),
          ),
        ),
      ],
    );
  }
}
