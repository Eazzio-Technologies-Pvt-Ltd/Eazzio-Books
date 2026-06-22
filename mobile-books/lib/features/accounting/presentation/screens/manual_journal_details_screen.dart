import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/accounting/presentation/providers/accounting_provider.dart';
import 'package:mobile_books/features/banking/presentation/providers/banking_provider.dart';

class ManualJournalDetailsScreen extends ConsumerWidget {
  final int journalId;

  const ManualJournalDetailsScreen({
    super.key,
    required this.journalId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalState = ref.watch(journalDetailsProvider(journalId));
    final privacyMode = ref.watch(privacyModeProvider);

    return ResponsiveScaffold(
      currentRoute: '/accounting/journals',
      appBar: AppBar(
        title: const Text('Journal Details'),
        actions: [
          IconButton(
            icon: Icon(privacyMode ? Icons.visibility_off : Icons.visibility),
            onPressed: () => ref.read(privacyModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: journalState.when(
        data: (journal) {
          final dateStr = DateFormat('yyyy-MM-dd').format(journal.journalDate);
          final lines = journal.lines ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Journal Details Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              journal.journalNumber,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue.shade200, width: 0.5),
                              ),
                              child: Text(
                                journal.status.toUpperCase(),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),
                        _buildDetailRow('Date', dateStr),
                        if (journal.referenceNumber != null && journal.referenceNumber!.isNotEmpty)
                          _buildDetailRow('Reference Number', journal.referenceNumber!),
                        if (journal.notes != null && journal.notes!.isNotEmpty)
                          _buildDetailRow('Notes/Narration', journal.notes!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                // Journal Lines List
                Text(
                  'Journal Posting Lines',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.s),

                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s, horizontal: AppSpacing.s),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Account & Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 1, child: Text('Debit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 1, child: Text('Credit', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    ],
                  ),
                ),

                // Lines list builder
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: lines.length,
                  itemBuilder: (context, index) {
                    final line = lines[index];
                    final acctName = line.accountName ?? 'Account ID: ${line.accountId}';
                    final acctCode = line.accountCode != null ? '[${line.accountCode}] ' : '';

                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s, horizontal: AppSpacing.s),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$acctCode$acctName',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                if (line.description != null && line.description!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      line.description!,
                                      style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 11),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              line.debit > 0
                                  ? (privacyMode ? '••••' : '₹${line.debit.toStringAsFixed(2)}')
                                  : '—',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              line.credit > 0
                                  ? (privacyMode ? '••••' : '₹${line.credit.toStringAsFixed(2)}')
                                  : '—',
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 13, color: AppColors.danger, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Table Totals
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.m, horizontal: AppSpacing.s),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Text(
                          'Total',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          privacyMode ? '••••' : '₹${journal.totalDebit.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          privacyMode ? '••••' : '₹${journal.totalCredit.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading journal details: $err')),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
