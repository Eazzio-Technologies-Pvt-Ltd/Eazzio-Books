import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_skeleton.dart';
import '../../widgets/common/staggered_fade_in.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(
          'Customers',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => ref.read(customerProvider.notifier).fetchCustomers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textHint, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search customers by name, company, email...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textHint, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
          // Scrollable List Body
          Expanded(
            child: _buildBody(customerState),
          ),
        ],
      ),
      // FAB to Add Customer
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        elevation: 6,
        onPressed: () {
          context.push('/customers/new');
        },
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(CustomerState state) {
    if (state.isLoading && state.customers.isEmpty) {
      return ListView.builder(
        itemCount: 6,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LoadingSkeleton.skeletonListItem(),
        ),
      );
    }

    if (state.errorMessage != null && state.customers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading customers',
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => ref.read(customerProvider.notifier).fetchCustomers(),
                icon: const Icon(Icons.replay),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredCustomers = state.customers.where((customer) {
      final nameMatches = customer.printableName.toLowerCase().contains(_searchQuery);
      final emailMatches = (customer.email ?? '').toLowerCase().contains(_searchQuery);
      final compMatches = (customer.companyName ?? '').toLowerCase().contains(_searchQuery);
      return nameMatches || emailMatches || compMatches;
    }).toList();

    if (filteredCustomers.isEmpty) {
      return SingleChildScrollView(
        child: EmptyState(
          icon: Icons.people_outline,
          title: _searchQuery.isNotEmpty ? 'No matches found' : 'No customers yet',
          description: _searchQuery.isNotEmpty
              ? 'Try modifying your search query or clear the filter.'
              : 'Add customer profiles to link invoices, record payments, and track balances.',
          ctaText: _searchQuery.isNotEmpty ? null : 'Add First Customer',
          onCtaPressed: _searchQuery.isNotEmpty ? null : () => context.push('/customers/new'),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(customerProvider.notifier).fetchCustomers(),
      child: ListView.builder(
        itemCount: filteredCustomers.length,
        padding: const EdgeInsets.all(AppSpacing.md),
        itemBuilder: (context, index) {
          final customer = filteredCustomers[index];
          final delay = Duration(milliseconds: 40 * index);
          final animationDelay = delay.inMilliseconds > 300 ? const Duration(milliseconds: 300) : delay;

          return StaggeredFadeIn(
            delay: animationDelay,
            child: Card(
              color: AppColors.bgCard,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                side: const BorderSide(color: AppColors.border),
              ),
              elevation: 0,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer.printableName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Customer Type indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: customer.customerType == 'Individual'
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        customer.customerType,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10,
                          color: customer.customerType == 'Individual'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFD97706),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    if (customer.companyName != null &&
                        customer.companyName!.isNotEmpty &&
                        customer.companyName != customer.displayName) ...[
                      Text(customer.companyName!, style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        const Icon(Icons.email_outlined, size: 14, color: AppColors.textHint),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            customer.email != null && customer.email!.isNotEmpty ? customer.email! : 'No email added',
                            style: AppTextStyles.caption,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Phone
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 14, color: AppColors.textHint),
                            const SizedBox(width: 6),
                            Text(
                              customer.mobile != null && customer.mobile!.isNotEmpty
                                  ? customer.mobile!
                                  : (customer.phone != null && customer.phone!.isNotEmpty ? customer.phone! : '-'),
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                        // Opening balance
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'OPENING BAL',
                              style: AppTextStyles.caption.copyWith(fontSize: 9),
                            ),
                            Text(
                              AppFormatters.formatCurrency(customer.openingBalance),
                              style: AppTextStyles.numeric.copyWith(
                                fontSize: 13,
                                color: customer.openingBalance > 0 ? AppColors.error : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  context.push('/customers/${customer.id}');
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
