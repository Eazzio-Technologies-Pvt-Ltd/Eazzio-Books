import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/features/customers/data/models/customer_address.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final int customerId;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure you want to delete this customer? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(customersProvider.notifier).deleteCustomer(customerId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer deleted successfully')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(customerDetailsProvider(customerId));

    return detailState.when(
      data: (customer) => DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(customer.formattedName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.push('/customers/$customerId/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.danger),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Addresses'),
                Tab(text: 'Contacts'),
                Tab(text: 'Activity Log'),
                Tab(text: 'Statement'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _OverviewTab(customer: customer),
              _AddressesTab(addresses: customer.addresses),
              _ContactsTab(customer: customer),
              _ActivityTab(customerId: customerId),
              _StatementTab(customerId: customerId),
            ],
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Text(err.toString(), style: const TextStyle(color: AppColors.danger)),
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Customer customer;

  const _OverviewTab({required this.customer});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Primary Information', style: textTheme.titleMedium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.s),
                  _infoRow('Customer Type', customer.customerType),
                  _infoRow('Display Name', customer.displayName ?? '—'),
                  _infoRow('Email', customer.email ?? '—'),
                  _infoRow('Phone', customer.phone ?? '—'),
                  _infoRow('Work Phone', customer.workPhone ?? '—'),
                  _infoRow('Mobile', customer.mobile ?? '—'),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Financial Settings', style: textTheme.titleMedium),
                  const Divider(),
                  const SizedBox(height: AppSpacing.s),
                  _infoRow('Currency', customer.currency),
                  _infoRow('Opening Balance', '${customer.currency} ${customer.openingBalance.toStringAsFixed(2)}'),
                  _infoRow('Payment Terms', customer.paymentTerms ?? 'Due on receipt'),
                  _infoRow('PAN / Tax Registration', customer.pan ?? '—'),
                ],
              ),
            ),
          ),
          if (customer.remarks != null && customer.remarks!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.m),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Remarks', style: textTheme.titleMedium),
                    const Divider(),
                    const SizedBox(height: AppSpacing.s),
                    Text(customer.remarks!, style: textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}

class _AddressesTab extends StatelessWidget {
  final List<CustomerAddress> addresses;

  const _AddressesTab({required this.addresses});

  @override
  Widget build(BuildContext context) {
    final billing = addresses.where((a) => a.type == 'billing').toList();
    final shipping = addresses.where((a) => a.type == 'shipping').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          _addressCard(context, 'Billing Address', billing),
          const SizedBox(height: AppSpacing.m),
          _addressCard(context, 'Shipping Address', shipping),
        ],
      ),
    );
  }

  Widget _addressCard(BuildContext context, String title, List<CustomerAddress> list) {
    final textTheme = Theme.of(context).textTheme;
    final addr = list.isNotEmpty ? list.first : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium),
            const Divider(),
            const SizedBox(height: AppSpacing.s),
            if (addr == null)
              const Text('No address configured.')
            else ...[
              if (addr.attention != null) Text('Attention: ${addr.attention!}', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (addr.addressLine1 != null) Text(addr.addressLine1!),
              if (addr.addressLine2 != null) Text(addr.addressLine2!),
              Text('${addr.city ?? ''}, ${addr.state ?? ''} ${addr.pinCode ?? ''}'),
              if (addr.country != null) Text(addr.country!),
              if (addr.phone != null) Text('Phone: ${addr.phone!}'),
            ]
          ],
        ),
      ),
    );
  }
}

class _ContactsTab extends StatelessWidget {
  final Customer customer;

  const _ContactsTab({required this.customer});

  @override
  Widget build(BuildContext context) {
    final contacts = customer.contacts;

    if (contacts.isEmpty) {
      return const Center(child: Text('No contact persons recorded.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (context, index) {
        final person = contacts[index];
        return Card(
          child: ListTile(
            title: Text(person.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (person.email != null) Text('Email: ${person.email!}'),
                if (person.mobile != null) Text('Mobile: ${person.mobile!}'),
                if (person.workPhone != null) Text('Work Phone: ${person.workPhone!}'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityTab extends ConsumerWidget {
  final int customerId;

  const _ActivityTab({required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityState = ref.watch(customerActivityProvider(customerId));

    return activityState.when(
      data: (logs) {
        if (logs.isEmpty) return const Center(child: Text('No activity records.'));

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.m),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final dateStr = log.createdAt != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(log.createdAt!.toLocal())
                : '—';

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.description, style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('By: ${log.userEmail ?? 'System'}', style: Theme.of(context).textTheme.bodySmall),
                        Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(err.toString(), style: const TextStyle(color: AppColors.danger))),
    );
  }
}

class _StatementTab extends ConsumerWidget {
  final int customerId;

  const _StatementTab({required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statementState = ref.watch(customerStatementProvider(customerId));
    final dateRange = ref.watch(statementDateRangeProvider(customerId));

    return Column(
      children: [
        // Date Selector Bar
        Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateRange == null
                    ? 'All Time Statement'
                    : 'Statement: ${DateFormat('dd MMM').format(dateRange.start)} - ${DateFormat('dd MMM yyyy').format(dateRange.end)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range, size: 18),
                label: const Text('Filter'),
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: dateRange,
                  );
                  if (range != null) {
                    ref.read(statementDateRangeProvider(customerId).notifier).state = range;
                  }
                },
              )
            ],
          ),
        ),

        // Statement Content
        Expanded(
          child: statementState.when(
            data: (statement) {
              return Column(
                children: [
                  // Summary Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                    child: Row(
                      children: [
                        Expanded(
                          child: _balanceBanner(
                            context,
                            'Opening Balance',
                            statement.openingBalance,
                            AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Expanded(
                          child: _balanceBanner(
                            context,
                            'Closing Balance',
                            statement.closingBalance,
                            AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Ledger Transactions
                  Expanded(
                    child: statement.transactions.isEmpty
                        ? const Center(child: Text('No transactions recorded.'))
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            itemCount: statement.transactions.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final tx = statement.transactions[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(tx.reference, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text(tx.date, style: Theme.of(context).textTheme.bodySmall),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('Balance: ${tx.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.0)),
                                        Text(
                                          '+ ${tx.debit.toStringAsFixed(2)}',
                                          style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text(err.toString(), style: const TextStyle(color: AppColors.danger))),
          ),
        ),
      ],
    );
  }

  Widget _balanceBanner(BuildContext context, String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            amount.toStringAsFixed(2),
            style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
