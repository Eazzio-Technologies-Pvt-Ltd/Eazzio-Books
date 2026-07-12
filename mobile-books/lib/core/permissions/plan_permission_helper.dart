import 'package:mobile_books/core/config/plan_limits.dart';
import 'package:mobile_books/core/permissions/plan_limits_service.dart';

class PlanPermissionHelper {
  static final _service = PlanLimitsService(PlanLimitsConfig.data);

  static bool hasAccess(String planId, String path, {int remainingTrialDays = 0}) {
    if (PlanLimitsConfig.data['_meta']?['enforcement_enabled'] == false) {
      return true;
    }
    final cleanPath = Uri.parse(path).path.toLowerCase();
    
    // Auth routes, dashboard, pricing, logout, support, more, and the lock page are always allowed
    if (cleanPath.startsWith('/login') ||
        cleanPath.startsWith('/register') ||
        cleanPath.startsWith('/forgot-password') ||
        cleanPath.startsWith('/reset-password') ||
        cleanPath.startsWith('/showcase') ||
        cleanPath == '/dashboard' ||
        cleanPath == '/pricing' ||
        cleanPath == '/logout' ||
        cleanPath == '/support' ||
        cleanPath == '/more' ||
        cleanPath.startsWith('/feature-locked')) {
      return true;
    }

    var normalizedPlan = planId.toLowerCase();

    // Active trial accounts get Standard Premium ('premium' / 'standard') access. Expired ones get Free ('free') access.
    if (normalizedPlan == 'trial') {
      if (remainingTrialDays > 0) {
        normalizedPlan = 'standard';
      } else {
        normalizedPlan = 'free';
      }
    }

    // Standardize 'premium' check to 'standard' (since standard premium uses 'standard' config key)
    if (normalizedPlan == 'premium') {
      normalizedPlan = 'standard';
    }

    final plan = _service.getPlan(normalizedPlan);
    final routeAccessMode = plan['route_access_mode'] as String? ?? 'unrestricted';

    if (routeAccessMode == 'allowlist') {
      final allowedRoutes = List<String>.from(plan['allowed_routes'] ?? []);
      return allowedRoutes.any((route) => cleanPath == route || cleanPath.startsWith('$route/'));
    }

    if (routeAccessMode == 'blocklist') {
      final blockedRoutes = List<String>.from(plan['blocked_routes'] ?? []);
      return !blockedRoutes.any((route) => cleanPath == route || cleanPath.startsWith('$route/'));
    }

    return true;
  }

  /// Map route path to its human-readable feature name for UI display
  static String getFeatureName(String path) {
    final cleanPath = Uri.parse(path).path.toLowerCase();
    if (cleanPath.startsWith('/items') || cleanPath.startsWith('/inventory')) return 'Items & Inventory';
    if (cleanPath.startsWith('/quotes')) return 'Quotes';
    if (cleanPath.startsWith('/sales-orders')) return 'Sales Orders';
    if (cleanPath.startsWith('/delivery-challans')) return 'Delivery Challans';
    if (cleanPath.startsWith('/credit-notes')) return 'Credit Notes';
    if (cleanPath.startsWith('/recurring-invoices')) return 'Recurring Invoices';
    if (cleanPath.startsWith('/vendors')) return 'Vendors';
    if (cleanPath.startsWith('/expenses') || cleanPath.startsWith('/recurring-expenses')) return 'Expenses & Recurring Expenses';
    if (cleanPath.startsWith('/purchase-orders')) return 'Purchase Orders';
    if (cleanPath.startsWith('/bills')) return 'Bills';
    if (cleanPath.startsWith('/payments-made')) return 'Payments Made';
    if (cleanPath.startsWith('/vendor-credits')) return 'Vendor Credits';
    if (cleanPath.startsWith('/projects')) return 'Projects';
    if (cleanPath.startsWith('/timesheets')) return 'Timesheets';
    if (cleanPath.startsWith('/banking') || cleanPath == '/reconciliation' || cleanPath == '/bank-rules') return 'Banking';
    if (cleanPath.startsWith('/accounting') || cleanPath == '/transaction-locking' || cleanPath == '/bulk-updates' || cleanPath.startsWith('/taxes') || cleanPath == '/currency-adjustments') return 'Accountant Settings';
    if (cleanPath.startsWith('/reports')) return 'Financial Reports';
    if (cleanPath.startsWith('/documents')) return 'Document Management';
    return 'Premium Feature';
  }
}
