import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/config/plan_limits.dart';

class PlanCreateCheck {
  final bool allowed;
  final int? remaining;
  final bool isUnlimited;

  const PlanCreateCheck({
    required this.allowed,
    required this.remaining,
    required this.isUnlimited,
  });
}

class PlanLimitsService {
  final Map<String, dynamic> _config;

  PlanLimitsService(this._config);

  Map<String, dynamic> getPlan(String planId) {
    var normalized = planId.toLowerCase();
    
    // Standardize 'premium' check to 'standard' (since standard premium uses 'standard' config key)
    if (normalized == 'premium') {
      normalized = 'standard';
    }

    if (normalized == 'trial') {
      final trialMap = _config['_meta']?['trial_maps_to_plan_id'] as String? ?? 'standard';
      return _config[trialMap] as Map<String, dynamic>? ?? _config['free'] as Map<String, dynamic>;
    }

    return _config[normalized] as Map<String, dynamic>? ?? _config['free'] as Map<String, dynamic>;
  }

  dynamic getLimit(String planId, String key) {
    final plan = getPlan(planId);
    return plan[key];
  }

  bool isFeatureEnabled(String planId, String featureKey) {
    final plan = getPlan(planId);
    
    // Check both standard boolean keys and enabled keys
    final keyWithSuffix = featureKey.endsWith('_enabled') ? featureKey : '${featureKey}_enabled';
    final val = plan[keyWithSuffix] ?? plan[featureKey];
    
    if (val is bool) {
      return val;
    }
    if (val is String) {
      return val != 'false'; // e.g. reports_enabled is "basic" or "advanced"
    }
    return false;
  }

  PlanCreateCheck checkCanCreate(String planId, String entityType, int currentCount) {
    String configKey = entityType.toLowerCase();
    
    // Map resource type to configuration max fields
    if (!configKey.startsWith('max_')) {
      if (configKey == 'invoice') configKey = 'max_invoices';
      else if (configKey == 'expense') configKey = 'max_expenses';
      else if (configKey == 'quote') configKey = 'max_quotes';
      else if (configKey == 'customer') configKey = 'max_customers';
      else if (configKey == 'vendor') configKey = 'max_vendors';
      else if (configKey == 'journal_entry' || configKey == 'journal') configKey = 'max_journal_entries';
      else if (configKey == 'user') configKey = 'max_users';
    }

    final limit = getLimit(planId, configKey) as int?;
    if (limit == null) {
      return const PlanCreateCheck(allowed: true, remaining: null, isUnlimited: true);
    }

    final remaining = limit - currentCount;
    return PlanCreateCheck(
      allowed: remaining > 0,
      remaining: remaining < 0 ? 0 : remaining,
      isUnlimited: false,
    );
  }
}

final planLimitsServiceProvider = Provider<PlanLimitsService>((ref) {
  return PlanLimitsService(PlanLimitsConfig.data);
});
