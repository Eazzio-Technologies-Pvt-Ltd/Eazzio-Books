import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile_books/features/invoices/presentation/providers/invoice_provider.dart';
import 'package:mobile_books/features/expenses/presentation/providers/expense_provider.dart';
import 'package:mobile_books/features/quotes/presentation/providers/quote_provider.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile_books/features/accounting/presentation/providers/accounting_provider.dart';
import 'package:mobile_books/features/settings/presentation/providers/users_provider.dart';
import 'package:mobile_books/core/permissions/plan_limits_service.dart';
import 'package:mobile_books/core/permissions/plan_permission_helper.dart';

class PlanGateService {
  final String planId;
  final Map<String, int> counts;
  final PlanLimitsService _limitsService;
  final int remainingTrialDays;

  PlanGateService({
    required this.planId,
    required this.counts,
    required PlanLimitsService limitsService,
    this.remainingTrialDays = 0,
  }) : _limitsService = limitsService;

  bool isFeatureEnabled(String featureKey) {
    var effectivePlan = planId;
    if (effectivePlan.toLowerCase() == 'trial') {
      effectivePlan = remainingTrialDays > 0 ? 'standard' : 'free';
    }
    return _limitsService.isFeatureEnabled(effectivePlan, featureKey);
  }

  bool isPathEnabled(String path) {
    return PlanPermissionHelper.hasAccess(planId, path, remainingTrialDays: remainingTrialDays);
  }

  int getUsageCount(String resourceType) {
    return counts[resourceType] ?? 0;
  }

  int? getMaxLimit(String resourceType) {
    var effectivePlan = planId;
    if (effectivePlan.toLowerCase() == 'trial') {
      effectivePlan = remainingTrialDays > 0 ? 'standard' : 'free';
    }
    
    String configKey = resourceType.toLowerCase();
    if (!configKey.startsWith('max_')) {
      if (configKey == 'invoice') configKey = 'max_invoices';
      else if (configKey == 'expense') configKey = 'max_expenses';
      else if (configKey == 'quote') configKey = 'max_quotes';
      else if (configKey == 'customer') configKey = 'max_customers';
      else if (configKey == 'vendor') configKey = 'max_vendors';
      else if (configKey == 'journal_entry' || configKey == 'journal') configKey = 'max_journal_entries';
      else if (configKey == 'user') configKey = 'max_users';
    }
    
    final limit = _limitsService.getLimit(effectivePlan, configKey);
    return limit as int?;
  }

  bool canCreate(String resourceType) {
    var effectivePlan = planId;
    if (effectivePlan.toLowerCase() == 'trial') {
      effectivePlan = remainingTrialDays > 0 ? 'standard' : 'free';
    }
    final count = getUsageCount(resourceType);
    final check = _limitsService.checkCanCreate(effectivePlan, resourceType, count);
    return check.allowed;
  }

  int? remaining(String resourceType) {
    var effectivePlan = planId;
    if (effectivePlan.toLowerCase() == 'trial') {
      effectivePlan = remainingTrialDays > 0 ? 'standard' : 'free';
    }
    final count = getUsageCount(resourceType);
    final check = _limitsService.checkCanCreate(effectivePlan, resourceType, count);
    return check.remaining;
  }
}

final planGateProvider = Provider<PlanGateService>((ref) {
  final authState = ref.watch(authNotifierProvider);
  String planId = 'free';
  int remainingTrialDays = 0;
  if (authState is AuthAuthenticated) {
    final user = authState.user;
    planId = user.planId;
    remainingTrialDays = user.remainingTrialDays;
    
    // Gracefully downgrade trial if expired
    if (planId.toLowerCase() == 'trial' && remainingTrialDays <= 0) {
      planId = 'free';
    }
  }

  final invoicesCount = ref.watch(invoicesProvider).value?.length ?? 0;
  final expensesCount = ref.watch(expensesProvider).value?.length ?? 0;
  final quotesCount = ref.watch(quotesProvider).value?.length ?? 0;
  final customersCount = ref.watch(customersProvider).value?.length ?? 0;
  final vendorsCount = ref.watch(vendorsProvider).value?.length ?? 0;
  final journalsCount = ref.watch(journalsProvider).value?.length ?? 0;
  final teamMembersCount = ref.watch(teamMembersProvider).value?.length ?? 0;

  final counts = {
    'invoice': invoicesCount,
    'expense': expensesCount,
    'quote': quotesCount,
    'customer': customersCount,
    'vendor': vendorsCount,
    'journal_entry': journalsCount,
    'user': teamMembersCount,
  };

  final limitsService = ref.watch(planLimitsServiceProvider);

  return PlanGateService(
    planId: planId,
    counts: counts,
    limitsService: limitsService,
    remainingTrialDays: remainingTrialDays,
  );
});
