import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/vendor_credits/data/models/vendor_credit.dart';
import 'package:mobile_books/features/vendor_credits/presentation/providers/vendor_credit_provider.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

const Map<String, _StatusStyle> _statusStyles = {
  'draft':     _StatusStyle(Color(0xFFF1F5F9), Color(0xFF475569), 'DRAFT', Icons.edit_note),
  'open':      _StatusStyle(Color(0xFFEFF6FF), Color(0xFF1D4ED8), 'OPEN', Icons.lock_open),
  'closed':    _StatusStyle(Color(0xFFF0FDF4), Color(0xFF15803D), 'CLOSED', Icons.check_circle_outline),
  'void':      _StatusStyle(Color(0xFFFEF2F2), Color(0xFFB91C1C), 'VOID', Icons.cancel_outlined),
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

class VendorCreditsListScreen extends ConsumerWidget {
  const VendorCreditsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorCreditsState = ref.watch(filteredVendorCreditsProvider);
    final searchController = TextEditingController(text: ref.read(vendorCreditSearchQueryProvider));

    return ResponsiveScaffold(
      currentRoute: '/vendor-credits',
      appBar: AppBar(
        title: const Text('Vendor Credits'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vendor-credits/new'),
        child: const Icon(Icons.add),
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
              onChanged: (val) => ref.read(vendorCreditSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search vendor credits...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref.read(vendorCreditSearchQueryProvider.notifier).state = '';
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
              onRefresh: () => ref.read(vendorCreditsProvider.notifier).refresh(),
              child: vendorCreditsState.when(
                data: (list) {
                  if (list.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.assignment_return, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No Vendor Credits found',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                'Tap "+" to record a new Vendor Credit',
                                style: TextStyle(color: AppColors.textSecondaryLight),
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
                      final vc = list[index];
                      return _VendorCreditCard(vc: vc);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        ElevatedButton(
                          onPressed: () => ref.read(vendorCreditsProvider.notifier).refresh(),
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

class _VendorCreditCard extends ConsumerWidget {
  final VendorCredit vc;

  const _VendorCreditCard({required this.vc});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsState = ref.watch(vendorsProvider);
    final statusStyle = _getStatusStyle(vc.status);
    final dateStr = DateFormat('dd MMM yyyy').format(vc.vendorCreditDate);

    String vendorName = 'Loading vendor...';
    vendorsState.whenData((vendors) {
      final vendor = vendors.where((v) => v.id == vc.vendorId).firstOrNull;
      if (vendor != null) {
        vendorName = vendor.displayName;
      } else {
        vendorName = 'Vendor #${vc.vendorId}';
      }
    });

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => context.push('/vendor-credits/${vc.id}'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    vc.vendorCreditNumber,
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
                  Text(
                    '₹${vc.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              if (vc.remainingAmount > 0) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Remaining: ₹${vc.remainingAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
