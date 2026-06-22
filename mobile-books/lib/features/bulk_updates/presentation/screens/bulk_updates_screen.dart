import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/bulk_updates/data/models/bulk_update_log.dart';
import 'package:mobile_books/features/bulk_updates/data/services/bulk_update_service.dart';
import 'package:mobile_books/features/bulk_updates/presentation/providers/bulk_update_provider.dart';

class BulkUpdatesScreen extends ConsumerStatefulWidget {
  const BulkUpdatesScreen({super.key});

  @override
  ConsumerState<BulkUpdatesScreen> createState() => _BulkUpdatesScreenState();
}

class _BulkUpdatesScreenState extends ConsumerState<BulkUpdatesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form selections
  String _selectedModule = '';
  String _selectedAction = '';
  final Map<String, dynamic> _payload = {};
  final Set<int> _selectedRecordIds = {};

  // Form states
  bool _submitting = false;
  
  // Controllers
  final _taxRateController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _categoryController = TextEditingController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _taxRateController.dispose();
    _reorderLevelController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _selectedModule = '';
      _selectedAction = '';
      _payload.clear();
      _selectedRecordIds.clear();
      _selectedStatus = null;
      _taxRateController.clear();
      _reorderLevelController.clear();
      _categoryController.clear();
    });
    ref.read(selectedBulkUpdateModuleProvider.notifier).state = '';
  }

  void _onModuleChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedModule = val;
      _selectedAction = '';
      _selectedRecordIds.clear();
      _payload.clear();
      _selectedStatus = null;
      _taxRateController.clear();
      _reorderLevelController.clear();
      _categoryController.clear();
    });
    ref.read(selectedBulkUpdateModuleProvider.notifier).state = val;
  }

  void _onActionChanged(String? val) {
    if (val == null) return;
    setState(() {
      _selectedAction = val;
      _payload.clear();
      _selectedStatus = null;
      _taxRateController.clear();
      _reorderLevelController.clear();
      _categoryController.clear();
    });
  }

  Widget _buildPayloadFields() {
    if (_selectedAction == 'setStatus') {
      List<String> options = ['Active', 'Inactive'];
      if (_selectedModule == 'Invoices') {
        options = ['sent', 'paid', 'void'];
      }
      return DropdownButtonFormField<String>(
        initialValue: _selectedStatus,
        decoration: const InputDecoration(
          labelText: 'New Status *',
          border: OutlineInputBorder(),
        ),
        items: options.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (val) {
          setState(() {
            _selectedStatus = val;
            if (val != null) {
              _payload['status'] = val;
            }
          });
        },
      );
    } else if (_selectedAction == 'setTaxRate') {
      return TextFormField(
        controller: _taxRateController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'New Tax Rate (%) *',
          border: OutlineInputBorder(),
          hintText: 'e.g. 18',
        ),
        onChanged: (val) {
          _payload['tax_rate'] = val;
        },
      );
    } else if (_selectedAction == 'setReorderLevel') {
      return TextFormField(
        controller: _reorderLevelController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'New Reorder Level *',
          border: OutlineInputBorder(),
          hintText: 'e.g. 10',
        ),
        onChanged: (val) {
          _payload['reorder_level'] = val;
        },
      );
    } else if (_selectedAction == 'setCategory') {
      return TextFormField(
        controller: _categoryController,
        decoration: const InputDecoration(
          labelText: 'New Category *',
          border: OutlineInputBorder(),
          hintText: 'e.g. Meals and Entertainment',
        ),
        onChanged: (val) {
          _payload['category'] = val;
        },
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _handlePreview() async {
    if (_selectedRecordIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one record')),
      );
      return;
    }
    if (_selectedAction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an action')),
      );
      return;
    }
    
    // Simple validation for payload
    if (_selectedAction == 'setStatus' && _selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select status')),
      );
      return;
    }
    if (_selectedAction == 'setTaxRate' && _taxRateController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter tax rate')),
      );
      return;
    }
    if (_selectedAction == 'setReorderLevel' && _reorderLevelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter reorder level')),
      );
      return;
    }
    if (_selectedAction == 'setCategory' && _categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter category')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final results = await ref.read(bulkUpdateServiceProvider).previewBulkUpdate(
        moduleName: _selectedModule,
        actionType: _selectedAction,
        records: _selectedRecordIds.toList(),
        payload: _payload,
      );

      if (!mounted) return;

      _showPreviewDialog(results);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preview failed: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _showPreviewDialog(Map<String, dynamic> results) {
    final successList = results['success'] as List? ?? [];
    final failedList = results['failed'] as List? ?? [];

    showDialog(
      context: context,
      barrierDismissible: !_submitting,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Preview Bulk Update'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.m),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${successList.length}',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.success),
                                  ),
                                  const Text('Ready to Update', style: TextStyle(fontSize: 12, color: AppColors.success)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.m),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.m),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${failedList.length}',
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.danger),
                                  ),
                                  const Text('Will Fail', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),
                      if (failedList.isNotEmpty) ...[
                        const Text(
                          'Failed Records (Won\'t be updated)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(6),
                            color: AppColors.danger.withValues(alpha: 0.05),
                          ),
                          padding: const EdgeInsets.all(AppSpacing.s),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: failedList.length,
                            itemBuilder: (c, idx) {
                              final f = failedList[idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'Record #${f['id']}: ${f['reason']}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.danger),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _submitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _submitting || successList.isEmpty
                      ? null
                      : () async {
                          setDialogState(() => _submitting = true);
                          try {
                            await ref.read(bulkUpdateServiceProvider).applyBulkUpdate(
                              moduleName: _selectedModule,
                              actionType: _selectedAction,
                              records: _selectedRecordIds.toList(),
                              payload: _payload,
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bulk update applied successfully'), backgroundColor: AppColors.success),
                              );
                              _resetForm();
                              ref.read(bulkUpdateLogsProvider.notifier).refresh();
                              _tabController.animateTo(1);
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to apply update: $e'), backgroundColor: AppColors.danger),
                              );
                            }
                          } finally {
                            setDialogState(() => _submitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                  child: Text(_submitting ? 'Applying...' : 'Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUpdateTab() {
    final modulesAsync = ref.watch(bulkUpdateModulesProvider);
    final recordsAsync = ref.watch(bulkUpdateModuleRecordsProvider);

    return modulesAsync.when(
      data: (modulesList) {
        final currentModConfig = modulesList.firstWhere(
          (m) => m['name'] == _selectedModule,
          orElse: () => <String, dynamic>{},
        );
        final actions = currentModConfig['actions'] as List? ?? [];

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Target Module & Action', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.m),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedModule.isEmpty ? null : _selectedModule,
                      decoration: const InputDecoration(
                        labelText: 'Module *',
                        border: OutlineInputBorder(),
                      ),
                      items: modulesList.map((m) {
                        return DropdownMenuItem<String>(
                          value: m['name'] as String,
                          child: Text(m['name'] as String),
                        );
                      }).toList(),
                      onChanged: _onModuleChanged,
                    ),
                    if (_selectedModule.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.m),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAction.isEmpty ? null : _selectedAction,
                        decoration: const InputDecoration(
                          labelText: 'Action *',
                          border: OutlineInputBorder(),
                        ),
                        items: actions.map((a) {
                          return DropdownMenuItem<String>(
                            value: a['value'] as String,
                            child: Text(a['label'] as String),
                          );
                        }).toList(),
                        onChanged: _onActionChanged,
                      ),
                    ],
                    if (_selectedAction.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.m),
                      _buildPayloadFields(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            if (_selectedModule.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Records (${_selectedRecordIds.length} selected)',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.m),
                      recordsAsync.when(
                        data: (recordsList) {
                          if (recordsList.isEmpty) {
                            return const Center(child: Text('No records found for this module.'));
                          }
                          final allSelected = recordsList.every((r) => _selectedRecordIds.contains(r['id'] as int));
                          return Column(
                            children: [
                              CheckboxListTile(
                                value: allSelected,
                                controlAffinity: ListTileControlAffinity.leading,
                                title: const Text('Select All', style: TextStyle(fontWeight: FontWeight.bold)),
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedRecordIds.addAll(recordsList.map((r) => r['id'] as int));
                                    } else {
                                      _selectedRecordIds.clear();
                                    }
                                  });
                                },
                              ),
                              const Divider(),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: recordsList.length,
                                itemBuilder: (c, idx) {
                                  final r = recordsList[idx];
                                  final id = r['id'] as int;
                                  final name = r['display_name'] ??
                                      r['name'] ??
                                      r['invoice_number'] ??
                                      r['bill_number'] ??
                                      'Record #$id';
                                  final isChecked = _selectedRecordIds.contains(id);
                                  return CheckboxListTile(
                                    value: isChecked,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    title: Text(name.toString()),
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedRecordIds.add(id);
                                        } else {
                                          _selectedRecordIds.remove(id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                            ],
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error loading records: $err')),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              ElevatedButton(
                onPressed: _selectedRecordIds.isEmpty || _selectedAction.isEmpty || _submitting
                    ? null
                    : _handlePreview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _submitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Preview Updates', style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildLogsTab() {
    final logsAsync = ref.watch(bulkUpdateLogsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(bulkUpdateLogsProvider.notifier).refresh(),
      child: logsAsync.when(
        data: (logsList) {
          if (logsList.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 64, color: AppColors.textSecondaryLight),
                      SizedBox(height: AppSpacing.m),
                      Text('No bulk updates performed yet.', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.m),
            itemCount: logsList.length,
            itemBuilder: (c, idx) {
              final BulkUpdateLog log = logsList[idx];
              final dateStr = DateFormat.yMMMd().add_jm().format(log.createdAt);
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.m),
                child: ListTile(
                  title: Text('${log.moduleName} - ${log.actionType}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Date: $dateStr'),
                      const SizedBox(height: 2),
                      Text('Selected: ${log.selectedRecordCount}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'S: ${log.successCount}',
                          style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: log.failedCount > 0
                              ? AppColors.danger.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'F: ${log.failedCount}',
                          style: TextStyle(
                            color: log.failedCount > 0 ? AppColors.danger : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading logs: $err')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentRoute: '/bulk-updates',
      appBar: AppBar(
        title: const Text('Bulk Updates'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'New Update'),
            Tab(text: 'Update Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpdateTab(),
          _buildLogsTab(),
        ],
      ),
    );
  }
}
