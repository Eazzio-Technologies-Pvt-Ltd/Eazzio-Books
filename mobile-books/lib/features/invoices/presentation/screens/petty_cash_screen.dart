import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/invoices/presentation/providers/invoice_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/invoices/data/models/payment.dart';
import 'package:mobile_books/widgets/common/loading_skeleton.dart';

class PettyCashScreen extends ConsumerStatefulWidget {
  const PettyCashScreen({super.key});

  @override
  ConsumerState<PettyCashScreen> createState() => _PettyCashScreenState();
}

class _PettyCashScreenState extends ConsumerState<PettyCashScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date';
  String _sortOrder = 'desc';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Payment> _filterAndSort(List<Payment> list) {
    // 1. Filter by deposit_to = Petty Cash
    var result = list.where((p) => p.depositTo == 'Petty Cash').toList();

    // 2. Search query filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) {
        final custMatch = (p.customerName ?? '').toLowerCase().contains(q);
        final refMatch = (p.reference ?? '').toLowerCase().contains(q);
        final invMatch = (p.invoiceNumber ?? '').toLowerCase().contains(q);
        return custMatch || refMatch || invMatch;
      }).toList();
    }

    // 3. Sort
    result.sort((a, b) {
      int cmp = 0;
      switch (_sortBy) {
        case 'amount':
          cmp = a.amount.compareTo(b.amount);
          break;
        case 'name':
          final nameA = a.customerName ?? '';
          final nameB = b.customerName ?? '';
          cmp = nameA.toLowerCase().compareTo(nameB.toLowerCase());
          break;
        case 'date':
        default:
          cmp = a.paymentDate.compareTo(b.paymentDate);
          break;
      }
      return _sortOrder == 'asc' ? cmp : -cmp;
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final paymentsState = ref.watch(paymentsProvider);

    return ResponsiveScaffold(
      currentRoute: '/banking/petty-cash',
      appBar: AppBar(
        title: const Text('Petty Cash Ledger'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search petty cash ledger...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primaryBlue),
                  onPressed: () {
                    ref.read(paymentsProvider.notifier).refresh();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: paymentsState.when(
              data: (list) {
                final filtered = _filterAndSort(list);
                final totalBalance = filtered.fold<double>(0, (sum, item) => sum + item.amount);
                final formattedBalance = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(totalBalance);

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(AppSpacing.s),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Balance',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                          Text(
                            formattedBalance,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matching transactions in Petty Cash ledger.'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final p = filtered[index];
                                final formattedAmount = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(p.amount);
                                final formattedDate = DateFormat('dd/MM/yyyy').format(p.paymentDate);

                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
                                  child: ListTile(
                                    leading: const CircleAvatar(
                                      backgroundColor: Colors.greenAccent,
                                      child: Icon(Icons.arrow_downward, color: Colors.black),
                                    ),
                                    title: Text(
                                      p.customerName ?? 'Source Unknown',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      'Ref: ${p.reference ?? "N/A"} • Date: $formattedDate',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      formattedAmount,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) => LoadingSkeleton.skeletonListItem(),
              ),
              error: (err, stack) => Center(child: Text('Error loading payments: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
