import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/delivery_challans/data/models/delivery_challan.dart';
import 'package:mobile_books/features/delivery_challans/presentation/providers/delivery_challan_provider.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

const Map<String, _StatusStyle> _statusStyles = {
  'draft':     _StatusStyle(Color(0xFFF1F5F9), Color(0xFF475569), 'DRAFT', Icons.edit_note),
  'delivered': _StatusStyle(Color(0xFFF0FDF4), Color(0xFF15803D), 'DELIVERED', Icons.check_circle_outline),
  'cancelled': _StatusStyle(Color(0xFFFEF2F2), Color(0xFFB91C1C), 'CANCELLED', Icons.cancel_outlined),
};

class _StatusStyle {
  final Color bg;
  final Color color;
  final String label;
  final IconData icon;
  const _StatusStyle(this.bg, this.color, this.label, this.icon);
}

_StatusStyle _getStatusStyle(String status) {
  return _statusStyles[status.toLowerCase()] ??
      const _StatusStyle(Color(0xFFF1F5F9), Color(0xFF475569), 'UNKNOWN', Icons.help_outline);
}

class DeliveryChallansListScreen extends ConsumerWidget {
  const DeliveryChallansListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challansState = ref.watch(deliveryChallansProvider);

    return ResponsiveScaffold(
      currentRoute: '/delivery-challans',
      appBar: AppBar(
        title: const Text('Delivery Challans'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/delivery-challans/new'),
        child: const Icon(Icons.add),
      ),
      body: challansState.when(
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
              onRefresh: () => ref.read(deliveryChallansProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 64, color: AppColors.textSecondaryLight),
                        SizedBox(height: AppSpacing.m),
                        Text(
                          'No Delivery Challans found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Tap "+" to create a new Challan',
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
            onRefresh: () => ref.read(deliveryChallansProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.m),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final dc = list[index];
                return _ChallanCard(dc: dc);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChallanCard extends ConsumerWidget {
  final DeliveryChallan dc;

  const _ChallanCard({required this.dc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(customersProvider);
    final statusStyle = _getStatusStyle(dc.status);
    final dateStr = DateFormat('dd MMM yyyy').format(dc.challanDate);

    String customerName = 'Loading customer...';
    customersState.whenData((customers) {
      final customer = customers.where((c) => c.id == dc.customerId).firstOrNull;
      if (customer != null) {
        customerName = customer.displayName ??
            '${customer.firstName ?? ""} ${customer.lastName ?? ""}'.trim();
        if (customerName.isEmpty) {
          customerName = customer.email ?? 'Customer #${dc.customerId}';
        }
      } else {
        customerName = 'Customer #${dc.customerId}';
      }
    });

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => context.push('/delivery-challans/${dc.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dc.deliveryChallanNumber,
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
                      color: statusStyle.bg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusStyle.icon, size: 14, color: statusStyle.color),
                        const SizedBox(width: 4),
                        Text(
                          statusStyle.label,
                          style: TextStyle(
                            color: statusStyle.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              Text(
                customerName,
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
                  if (dc.deliveryDate != null)
                    Text(
                      'Delivery: ${DateFormat('dd MMM yyyy').format(dc.deliveryDate!)}',
                      style: const TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
