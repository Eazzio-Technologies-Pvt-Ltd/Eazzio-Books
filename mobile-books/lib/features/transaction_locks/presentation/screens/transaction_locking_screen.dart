import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/transaction_locks/providers/transaction_lock_provider.dart';
import 'package:mobile_books/features/transaction_locks/utils/transaction_lock_validator.dart';

class TransactionLockingScreen extends ConsumerStatefulWidget {
  const TransactionLockingScreen({super.key});

  @override
  ConsumerState<TransactionLockingScreen> createState() => _TransactionLockingScreenState();
}

class _TransactionLockingScreenState extends ConsumerState<TransactionLockingScreen> {
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;
  final Set<TransactionLockModule> _selectedModules = Set.from(TransactionLockModule.values);
  bool _isSaving = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _toggleModule(TransactionLockModule module) {
    setState(() {
      if (_selectedModules.contains(module)) {
        _selectedModules.remove(module);
      } else {
        _selectedModules.add(module);
      }
    });
  }

  Future<void> _handleApplyLock(BuildContext context) async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a lock date.')),
      );
      return;
    }
    if (_selectedModules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one module to lock.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      await ref.read(activeTransactionLockProvider.notifier).createTransactionLock(
        lockName: 'Lock to $dateStr',
        lockDate: _selectedDate!,
        reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
        lockedModules: _selectedModules.map((m) => m.value).toList(),
      );

      messenger.showSnackBar(
        const SnackBar(content: Text('Transaction lock applied successfully.')),
      );
      if (mounted) {
        setState(() {
          _selectedDate = null;
          _reasonController.clear();
          _selectedModules.clear();
          _selectedModules.addAll(TransactionLockModule.values);
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to apply lock: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeactivateLock(BuildContext context, int lockId) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Accounting Lock'),
        content: const Text('Are you sure you want to deactivate the active accounting lock? All locked modules will become editable again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(activeTransactionLockProvider.notifier).deactivateLock(lockId);
        messenger.showSnackBar(
          const SnackBar(content: Text('Lock deactivated.')),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to deactivate lock: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeLockAsync = ref.watch(activeTransactionLockProvider);
    final historyAsync = ref.watch(transactionLockHistoryProvider);

    return ResponsiveScaffold(
      currentRoute: '/transaction-locking',
      appBar: AppBar(
        title: const Text('Transaction Locking'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeTransactionLockProvider);
          ref.invalidate(transactionLockHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prevent users from editing, deleting, or cancelling transactions prior to a specific date. This ensures your finalized accounts remain untouched.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: AppSpacing.m),

              // Active Lock Panel
              activeLockAsync.when(
                data: (activeLock) {
                  if (activeLock == null) return const SizedBox.shrink();
                  final dateStr = DateFormat('yyyy-MM-dd').format(activeLock.lockDate);
                  return Card(
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    margin: const EdgeInsets.only(bottom: AppSpacing.m),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(Icons.lock, color: AppColors.primaryBlue, size: 20),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Active Accounting Lock',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'All selected transactions on or before $dateStr are locked.',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                if (activeLock.reason != null && activeLock.reason!.trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Reason: ${activeLock.reason}',
                                      style: TextStyle(fontSize: 13, color: Colors.blue.shade900, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                            onPressed: () => _handleDeactivateLock(context, activeLock.id),
                            child: const Text('Deactivate'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading active lock: $err')),
              ),

              // Lock Config Form Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apply New Transaction Lock',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? 'Lock Date: * (Select Date)'
                                  : 'Lock Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _selectedDate == null ? Colors.red.shade700 : Colors.black,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: const Text('Select Date'),
                            onPressed: () => _selectDate(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      TextFormField(
                        controller: _reasonController,
                        decoration: const InputDecoration(
                          labelText: 'Reason (Optional)',
                          hintText: 'e.g. End of Financial Year 2025',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      const Text(
                        'Modules to Lock',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: 0,
                        children: TransactionLockModule.values.map((mod) {
                          final isChecked = _selectedModules.contains(mod);
                          return FilterChip(
                            label: Text(mod.value, style: const TextStyle(fontSize: 12)),
                            selected: isChecked,
                            onSelected: (_) => _toggleModule(mod),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : () => _handleApplyLock(context),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Apply Lock'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              // Lock History Card
              Text(
                'Lock History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.s),
              historyAsync.when(
                data: (historyList) {
                  if (historyList.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.m),
                        child: Text('No locking history found.'),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: historyList.length,
                    itemBuilder: (context, index) {
                      final item = historyList[index];
                      final dateStr = DateFormat('yyyy-MM-dd').format(item.lockDate);
                      final appliedStr = item.createdAt != null
                          ? DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt!)
                          : 'Unknown';

                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.s),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: item.isActive ? Colors.green.shade100 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: item.isActive ? Colors.green.shade800 : Colors.grey.shade800,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Applied on: $appliedStr'),
                              if (item.reason != null && item.reason!.isNotEmpty)
                                Text('Reason: ${item.reason}', style: const TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading history: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
