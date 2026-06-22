import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/accounting/data/models/chart_of_account.dart';
import 'package:mobile_books/features/accounting/presentation/providers/accounting_provider.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  final int? accountId; // If null, create mode; otherwise, edit mode

  const AccountFormScreen({
    super.key,
    this.accountId,
  });

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _openingBalanceController = TextEditingController(text: '0.00');
  final _descriptionController = TextEditingController();

  String _accountType = 'Asset';
  int? _parentAccountId;
  String _status = 'active';
  bool _isLoading = false;
  bool _isEditMode = false;
  ChartOfAccount? _existingAccount;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.accountId != null;
    if (_isEditMode) {
      _loadAccountDetails();
    }
  }

  Future<void> _loadAccountDetails() async {
    setState(() => _isLoading = true);
    try {
      // Fetch details from local list cache or details provider
      final account = await ref.read(coaAccountDetailsProvider(widget.accountId!).future);
      setState(() {
        _existingAccount = account;
        _nameController.text = account.accountName;
        _codeController.text = account.accountCode ?? '';
        _openingBalanceController.text = account.openingBalance.toStringAsFixed(2);
        _descriptionController.text = account.description ?? '';
        _accountType = account.accountType;
        _parentAccountId = account.parentAccountId;
        _status = account.status;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading account: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(coaAccountsProvider);
    final allAccounts = accountsState.value ?? [];

    // Filter potential parent accounts to only show accounts of the same type (excluding self to avoid circular reference)
    final sameTypeAccounts = allAccounts.where((a) {
      final matchesType = a.accountType.toLowerCase() == _accountType.toLowerCase();
      final isSelf = _isEditMode && a.id == widget.accountId;
      return matchesType && !isSelf;
    }).toList();

    return ResponsiveScaffold(
      currentRoute: '/accounting/coa',
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Account' : 'New Account'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Account Name *'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      TextFormField(
                        controller: _codeController,
                        decoration: const InputDecoration(labelText: 'Account Code (optional)'),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      DropdownButtonFormField<String>(
                        initialValue: _accountType,
                        decoration: const InputDecoration(labelText: 'Account Type *'),
                        items: const [
                          DropdownMenuItem(value: 'Asset', child: Text('Asset')),
                          DropdownMenuItem(value: 'Liability', child: Text('Liability')),
                          DropdownMenuItem(value: 'Equity', child: Text('Equity')),
                          DropdownMenuItem(value: 'Income', child: Text('Income')),
                          DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                        ],
                        onChanged: _isEditMode
                            ? null // Type cannot be modified on edit (standard accounting constraint)
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    _accountType = val;
                                    _parentAccountId = null; // reset parent
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: AppSpacing.s),
                      DropdownButtonFormField<int?>(
                        initialValue: _parentAccountId,
                        decoration: const InputDecoration(labelText: 'Parent Account (Nesting)'),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('None (Primary)')),
                          ...sameTypeAccounts.map(
                            (a) => DropdownMenuItem<int?>(
                              value: a.id,
                              child: Text('${a.accountName} (${a.accountCode ?? "No Code"})'),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _parentAccountId = val;
                          });
                        },
                      ),
                      const SizedBox(height: AppSpacing.s),
                      TextFormField(
                        controller: _openingBalanceController,
                        decoration: const InputDecoration(labelText: 'Opening Balance (₹)'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                        // Disable opening balance editing during updates (per database scan)
                        enabled: !_isEditMode,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Description'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Active')),
                          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _status = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => context.pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          ElevatedButton(
                            onPressed: _handleSubmit,
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final double openingBal = double.tryParse(_openingBalanceController.text) ?? 0.0;
      final account = ChartOfAccount(
        id: widget.accountId ?? 0,
        userId: 0,
        accountName: _nameController.text,
        accountCode: _codeController.text.trim().isEmpty ? null : _codeController.text.trim(),
        accountType: _accountType,
        parentAccountId: _parentAccountId,
        openingBalance: openingBal,
        currentBalance: _isEditMode ? (_existingAccount?.currentBalance ?? 0.0) : openingBal,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        status: _status,
        isDeleted: false,
      );

      try {
        if (_isEditMode) {
          final updates = {
            'account_name': account.accountName,
            'account_code': account.accountCode,
            'account_type': account.accountType,
            'parent_account_id': account.parentAccountId,
            'description': account.description,
            'status': account.status,
          };
          await ref.read(coaAccountsProvider.notifier).updateAccount(widget.accountId!, updates);
        } else {
          await ref.read(coaAccountsProvider.notifier).createAccount(account);
        }

        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account saved successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
