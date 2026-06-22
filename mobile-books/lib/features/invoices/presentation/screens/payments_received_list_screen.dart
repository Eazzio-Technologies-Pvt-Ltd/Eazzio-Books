import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/invoices/presentation/providers/invoice_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

class PaymentsReceivedListScreen extends ConsumerWidget {
  const PaymentsReceivedListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsState = ref.watch(paymentsProvider);

    return ResponsiveScaffold(
      currentRoute: '/payments-received',
      appBar: AppBar(
        title: const Text('Payments Received'),
      ),
      body: paymentsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            err.toString(),
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(paymentsProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.payment, size: 64, color: AppColors.textSecondaryLight),
                        SizedBox(height: AppSpacing.m),
                        Text(
                          'No Payments found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Open an Invoice and log a payment to see records here',
                          style: TextStyle(color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(paymentsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.m),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final payment = list[index];
                final dateStr = DateFormat('dd MMM yyyy').format(payment.paymentDate);

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
                              payment.invoiceNumber != null
                                  ? 'Invoice: ${payment.invoiceNumber}'
                                  : 'Invoice #${payment.invoiceId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.s,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                payment.paymentMode?.toUpperCase() ?? 'CASH',
                                style: const TextStyle(
                                  color: Color(0xFF475569),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          payment.customerName ?? 'Customer #${payment.customerId}',
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
                            Text(
                              '₹${payment.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        if (payment.reference != null && payment.reference!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Ref: ${payment.reference}',
                            style: const TextStyle(
                              color: AppColors.textSecondaryLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
