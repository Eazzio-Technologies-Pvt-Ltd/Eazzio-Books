import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/accounting/data/models/journal_entry.dart';
import 'package:mobile_books/features/accounting/presentation/providers/accounting_provider.dart';
import 'package:mobile_books/features/banking/presentation/providers/banking_provider.dart';

class ManualJournalsScreen extends ConsumerWidget {
  const ManualJournalsScreen({super.key});

  void _handleDeleteJournal(BuildContext context, WidgetRef ref, JournalEntry journal) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Journal'),
          content: Text('Are you sure you want to delete "${journal.journalNumber}"?'),
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
                  await ref.read(journalsProvider.notifier).deleteJournal(journal.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Journal deleted successfully.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete journal: $e')),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalsState = ref.watch(journalsProvider);
    final privacyMode = ref.watch(privacyModeProvider);

    return ResponsiveScaffold(
      currentRoute: '/accounting/journals',
      appBar: AppBar(
        title: const Text('Manual Journals'),
        actions: [
          IconButton(
            icon: Icon(privacyMode ? Icons.visibility_off : Icons.visibility),
            onPressed: () => ref.read(privacyModeProvider.notifier).toggle(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/accounting/journals/new'),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(journalsProvider.notifier).refresh(),
        child: journalsState.when(
          data: (journals) {
            if (journals.isEmpty) {
              return const Center(child: Text('No manual journals recorded.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.m),
              itemCount: journals.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final journal = journals[index];
                final dateStr = DateFormat('yyyy-MM-dd').format(journal.journalDate);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  title: Row(
                    children: [
                      Text(
                        journal.journalNumber,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(width: AppSpacing.s),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue.shade200, width: 0.5),
                        ),
                        child: Text(
                          journal.status.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xs),
                      Text('Date: $dateStr', style: const TextStyle(fontSize: 12)),
                      if (journal.referenceNumber != null && journal.referenceNumber!.isNotEmpty)
                        Text('Ref: ${journal.referenceNumber}', style: const TextStyle(fontSize: 12)),
                      if (journal.notes != null && journal.notes!.isNotEmpty)
                        Text(
                          journal.notes!,
                          style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
                          maxLines: 1,
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
                          const Text('Total Debit/Credit', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          Text(
                            privacyMode ? '••••' : '₹${journal.totalDebit.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.s),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => context.push('/accounting/journals/${journal.id}/edit'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 18, color: AppColors.danger),
                        onPressed: () => _handleDeleteJournal(context, ref, journal),
                      ),
                    ],
                  ),
                  onTap: () => context.push('/accounting/journals/${journal.id}'),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
