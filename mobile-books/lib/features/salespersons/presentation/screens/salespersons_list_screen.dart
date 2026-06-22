import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/salespersons/presentation/providers/salesperson_provider.dart';

class SalespersonsListScreen extends ConsumerStatefulWidget {
  const SalespersonsListScreen({super.key});

  @override
  ConsumerState<SalespersonsListScreen> createState() => _SalespersonsListScreenState();
}

class _SalespersonsListScreenState extends ConsumerState<SalespersonsListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salespersonsState = ref.watch(salespersonsListProvider);

    return ResponsiveScaffold(
      currentRoute: '/salespersons',
      appBar: AppBar(
        title: const Text('Salespersons'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/salespersons/new'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),

          // List content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(salespersonsListProvider.notifier).refresh(),
              child: salespersonsState.when(
                data: (list) {
                  final filteredList = list.where((sp) {
                    final nameMatch = sp.name.toLowerCase().contains(_searchQuery);
                    final emailMatch = (sp.email ?? '').toLowerCase().contains(_searchQuery);
                    return nameMatch || emailMatch;
                  }).toList();

                  if (filteredList.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No salespersons found.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final sp = filteredList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.m),
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                            child: Text(
                              sp.name.isNotEmpty ? sp.name[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            sp.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              if (sp.email != null && sp.email!.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.email_outlined, size: 14, color: AppColors.textSecondaryLight),
                                    const SizedBox(width: 4),
                                    Text(sp.email!),
                                  ],
                                ),
                              if (sp.phone != null && sp.phone!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondaryLight),
                                    const SizedBox(width: 4),
                                    Text(sp.phone!),
                                  ],
                                ),
                              ],
                              if (sp.employeeId != null && sp.employeeId!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Employee ID: ${sp.employeeId!}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Text('Error: $err'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
