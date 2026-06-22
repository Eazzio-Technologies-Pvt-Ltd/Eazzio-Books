import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/projects/presentation/providers/project_provider.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not Set';
    return DateFormat('dd MMM yyyy').format(date);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'On Hold':
        return AppColors.warning;
      case 'Completed':
        return AppColors.primaryBlue;
      case 'Cancelled':
        return AppColors.textSecondaryLight;
      default:
        return AppColors.textSecondaryLight;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(projectDetailsProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Details'),
        actions: [
          detailState.when(
            data: (project) => IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/projects/$projectId/edit'),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          detailState.when(
            data: (project) => IconButton(
              icon: const Icon(Icons.delete, color: AppColors.danger),
              onPressed: () => _confirmDelete(context, ref, project.projectName),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailState.when(
        data: (project) => ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            // Card 1 - General Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.projectName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (project.projectCode != null && project.projectCode!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        project.projectCode!,
                        style: const TextStyle(fontSize: 16, color: AppColors.textSecondaryLight),
                      ),
                    ],
                    const Divider(height: AppSpacing.l),
                    _buildDetailRow('Customer', project.customerName ?? 'Not Assigned'),
                    _buildDetailRow('Company', project.customerCompany ?? 'Not Provided'),
                    _buildStatusRow('Status', project.status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // Card 2 - Dates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: AppSpacing.m),
                    _buildDetailRow('Start Date', _formatDate(project.startDate)),
                    _buildDetailRow('End Date', _formatDate(project.endDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // Card 3 - Financial
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Financial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: AppSpacing.m),
                    _buildDetailRow('Billing Type', project.billingType),
                    if (project.billingType == 'Hourly')
                      _buildDetailRow('Hourly Rate', '₹${project.hourlyRate.toStringAsFixed(2)}'),
                    _buildDetailRow('Budget', '₹${project.budget.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.m),

            // Card 4 - Profitability (async)
            _buildProfitabilityCard(ref),

            // Card 5 - Description
            if (project.description != null && project.description!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.m),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(height: AppSpacing.m),
                      Text(project.description!),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error.toString(), style: const TextStyle(color: AppColors.danger)),
        ),
      ),
    );
  }

  Widget _buildProfitabilityCard(WidgetRef ref) {
    final profitState = ref.watch(projectProfitabilityProvider(projectId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profitability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(height: AppSpacing.m),
            profitState.when(
              data: (profit) {
                final totalInvoiced = (profit['total_invoiced'] as num? ?? 0).toDouble();
                final totalExpenses = (profit['total_expenses'] as num? ?? 0).toDouble();
                final profitLoss = (profit['profit_loss'] as num? ?? 0).toDouble();
                final budgetUsage = (profit['budget_usage_percent'] as num? ?? 0).toDouble();
                final billableHours = (profit['total_billable_hours'] as num? ?? 0).toDouble();
                final nonBillableHours = (profit['total_non_billable_hours'] as num? ?? 0).toDouble();

                return Column(
                  children: [
                    _buildDetailRow('Total Invoiced', '₹${totalInvoiced.toStringAsFixed(2)}'),
                    _buildDetailRow('Total Expenses', '₹${totalExpenses.toStringAsFixed(2)}'),
                    _buildDetailRow(
                      'Profit / Loss',
                      '₹${profitLoss.toStringAsFixed(2)}',
                      valueColor: profitLoss >= 0 ? AppColors.success : AppColors.danger,
                    ),
                    _buildDetailRow('Budget Usage', '${budgetUsage.toStringAsFixed(1)}%'),
                    _buildDetailRow('Billable Hours', billableHours.toStringAsFixed(1)),
                    _buildDetailRow('Non-Billable Hours', nonBillableHours.toStringAsFixed(1)),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                child: Text(
                  'Failed to load profitability: $error',
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondaryLight)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String status) {
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondaryLight)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String projectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete project "$projectName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(context); // Dismiss dialog
              try {
                await ref.read(projectsProvider.notifier).deleteProject(projectId);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project deleted successfully.')),
                );
                if (!context.mounted) return;
                context.pop(); // Pop detail page
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete project: $e'), backgroundColor: AppColors.danger),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
