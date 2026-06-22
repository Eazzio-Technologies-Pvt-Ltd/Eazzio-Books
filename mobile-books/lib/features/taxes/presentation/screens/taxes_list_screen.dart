import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/taxes/data/models/tax_rate.dart';
import 'package:mobile_books/features/taxes/presentation/providers/tax_provider.dart';

class TaxesListScreen extends ConsumerWidget {
  const TaxesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxesList = ref.watch(filteredTaxesProvider);
    final taxesState = ref.watch(taxesProvider);
    final searchController = TextEditingController(text: ref.read(taxSearchQueryProvider));

    return ResponsiveScaffold(
      currentRoute: '/taxes',
      appBar: AppBar(
        title: const Text('Taxes & GST Config'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/taxes/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Filters & Search
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (val) => ref.read(taxSearchQueryProvider.notifier).state = val,
                  decoration: InputDecoration(
                    hintText: 'Search tax name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              ref.read(taxSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: ref.watch(taxTypeFilterProvider),
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Types')),
                          DropdownMenuItem(value: 'GST', child: Text('GST')),
                          DropdownMenuItem(value: 'IGST', child: Text('IGST')),
                          DropdownMenuItem(value: 'CGST', child: Text('CGST')),
                          DropdownMenuItem(value: 'SGST', child: Text('SGST')),
                          DropdownMenuItem(value: 'CESS', child: Text('CESS')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(taxTypeFilterProvider.notifier).state = val;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: ref.watch(taxStatusFilterProvider),
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                          DropdownMenuItem(value: 'active', child: Text('Active')),
                          DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(taxStatusFilterProvider.notifier).state = val;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Taxes List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(taxesProvider.notifier).refresh(),
              child: taxesState.when(
                data: (_) {
                  if (taxesList.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.percent, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No taxes found.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                    itemCount: taxesList.length,
                    itemBuilder: (context, index) {
                      final tax = taxesList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.m),
                        child: ListTile(
                          title: Text(tax.taxName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Type: ${tax.taxType}  •  Rate: ${tax.rate.toStringAsFixed(2)}%'),
                              if (tax.description != null && tax.description!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  tax.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: tax.status == 'active'
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tax.status == 'active' ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: tax.status == 'active' ? AppColors.success : Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () => context.push('/taxes/${tax.id}/edit'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: AppColors.danger),
                                onPressed: () => _confirmDelete(context, ref, tax),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TaxRate tax) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Tax Rate'),
        content: Text('Are you sure you want to delete ${tax.taxName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(taxesProvider.notifier).deleteTax(tax.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tax rate deleted successfully'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
