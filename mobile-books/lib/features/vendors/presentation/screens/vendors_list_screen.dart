import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

class VendorsListScreen extends ConsumerWidget {
  const VendorsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsState = ref.watch(filteredVendorsProvider);
    final searchController = TextEditingController(text: ref.read(vendorSearchQueryProvider));

    return ResponsiveScaffold(
      currentRoute: '/vendors',
      appBar: AppBar(
        title: const Text('Vendors'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vendors/new'),
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
              onChanged: (val) => ref.read(vendorSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search vendors...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref.read(vendorSearchQueryProvider.notifier).state = '';
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
              onRefresh: () => ref.read(vendorsProvider.notifier).refresh(),
              child: vendorsState.when(
                data: (vendors) {
                  if (vendors.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No vendors found.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: vendors.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final vendor = vendors[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                          horizontal: AppSpacing.s,
                        ),
                        title: Text(
                          vendor.displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (vendor.companyName != null && vendor.companyName!.isNotEmpty)
                              Text(vendor.companyName!),
                            if (vendor.email != null && vendor.email!.isNotEmpty)
                              Text(vendor.email!),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: vendor.status == 'active'
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.textSecondaryLight.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            vendor.status.toUpperCase(),
                            style: TextStyle(
                              color: vendor.status == 'active' ? AppColors.success : AppColors.textSecondaryLight,
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () => context.push('/vendors/${vendor.id}'),
                      );
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
                          onPressed: () => ref.read(vendorsProvider.notifier).refresh(),
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
