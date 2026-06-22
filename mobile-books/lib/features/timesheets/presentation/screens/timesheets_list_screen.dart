import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/timesheets/presentation/providers/timesheet_provider.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';

class TimesheetsListScreen extends ConsumerWidget {
  const TimesheetsListScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'Draft':
        return AppColors.warning;
      case 'Approved':
        return AppColors.success;
      case 'Invoiced':
        return AppColors.primaryBlue;
      case 'Cancelled':
        return AppColors.textSecondaryLight;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timesheetsState = ref.watch(filteredTimesheetsProvider);
    final searchController = TextEditingController(text: ref.read(timesheetSearchQueryProvider));

    return ResponsiveScaffold(
      currentRoute: '/timesheets',
      appBar: AppBar(
        title: const Text('Timesheets'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/timesheets/new'),
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
              onChanged: (val) => ref.read(timesheetSearchQueryProvider.notifier).state = val,
              decoration: InputDecoration(
                hintText: 'Search timesheets...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          ref.read(timesheetSearchQueryProvider.notifier).state = '';
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
              onRefresh: () => ref.read(timesheetsProvider.notifier).refresh(),
              child: timesheetsState.when(
                data: (timesheets) {
                  if (timesheets.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.timer_outlined, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No timesheets found.',
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
                    itemCount: timesheets.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final ts = timesheets[index];
                      final statusColor = _statusColor(ts.status);

                      final dateStr = DateFormat('dd MMM yyyy').format(ts.workDate);
                      final titleStr = ts.projectName ?? 'Unknown Project';
                      final titleSuffix = ts.timesheetNumber != null ? ' (${ts.timesheetNumber})' : '';

                      final subtitleParts = <String>[];
                      subtitleParts.add(dateStr);
                      subtitleParts.add('${ts.hours.toStringAsFixed(1)}h');
                      if (ts.staffName != null && ts.staffName!.isNotEmpty) {
                        subtitleParts.add(ts.staffName!);
                      }

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                          horizontal: AppSpacing.s,
                        ),
                        title: Text(
                          '$titleStr$titleSuffix',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(subtitleParts.join(' • ')),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            ts.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () => context.push('/timesheets/${ts.id}/edit'),
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
                          onPressed: () => ref.read(timesheetsProvider.notifier).refresh(),
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
