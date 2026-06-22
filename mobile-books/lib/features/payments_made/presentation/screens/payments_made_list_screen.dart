import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/payments_made/data/models/payment_made.dart';
import 'package:mobile_books/features/payments_made/presentation/providers/payment_made_provider.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';

class PaymentsMadeListScreen extends ConsumerWidget {
  const PaymentsMadeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsState = ref.watch(filteredPaymentsMadeProvider);
    final searchController = TextEditingController(text: ref.read(paymentMadeSearchQueryProvider));

    return ResponsiveScaffold(
      currentRoute: '/payments-made',
      appBar: AppBar(
        title: const Text('Payments Made'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            child: TextField(
              controller: searchController,
              onChanged: (val) => ref.read(paymentMadeSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search payments...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref.read(paymentMadeSearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // List Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(paymentsMadeProvider.notifier).refresh(),
              child: paymentsState.when(
                data: (list) {
                  if (list.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.payment, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No payments recorded.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final pm = list[index];
                      return _PaymentMadeCard(pm: pm);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        ElevatedButton(
                          onPressed: () => ref.read(paymentsMadeProvider.notifier).refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMadeCard extends ConsumerWidget {
  final PaymentMade pm;

  const _PaymentMadeCard({required this.pm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsState = ref.watch(vendorsProvider);
    final dateStr = DateFormat('dd MMM yyyy').format(pm.paymentDate);

    String vendorName = pm.vendorName ?? 'Loading vendor...';
    if (pm.vendorId != null && pm.vendorName == null) {
      vendorsState.whenData((vendors) {
        final vendor = vendors.where((v) => v.id == pm.vendorId).firstOrNull;
        if (vendor != null) {
          vendorName = vendor.displayName;
        } else {
          vendorName = 'Vendor #${pm.vendorId}';
        }
      });
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pm.billNumber != null ? 'Bill: ${pm.billNumber}' : 'Payment Reference',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.primaryBlue,
                  ),
                ),
                Text(
                  '₹${pm.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              vendorName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date: $dateStr',
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
                if (pm.paymentMode != null)
                  Text(
                    pm.paymentMode!.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
