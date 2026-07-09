class PlanPermissionHelper {
  /// Check if a plan has access to a specific route path
  static bool hasAccess(String planId, String path) {
    final cleanPath = Uri.parse(path).path.toLowerCase();
    
    // Auth routes, dashboard, pricing, logout, support, and the lock page are always allowed
    if (cleanPath.startsWith('/login') ||
        cleanPath.startsWith('/register') ||
        cleanPath.startsWith('/forgot-password') ||
        cleanPath.startsWith('/reset-password') ||
        cleanPath.startsWith('/showcase') ||
        cleanPath == '/dashboard' ||
        cleanPath == '/pricing' ||
        cleanPath == '/logout' ||
        cleanPath == '/support' ||
        cleanPath.startsWith('/feature-locked')) {
      return true;
    }

    final normalizedPlan = planId.toLowerCase();

    // Enterprise and Professional have access to everything
    if (normalizedPlan == 'enterprise' || normalizedPlan == 'professional') {
      return true;
    }

    // Premium plan restrictions
    if (normalizedPlan == 'premium') {
      // Blocked: projects, timesheets, P&L/Balance Sheet/Cash Flow reports, and recurring invoices
      if (cleanPath.startsWith('/projects') || 
          cleanPath.startsWith('/timesheets') ||
          cleanPath.startsWith('/recurring-invoices') ||
          cleanPath.startsWith('/reports/profit-loss') ||
          cleanPath.startsWith('/reports/balance-sheet') ||
          cleanPath.startsWith('/reports/cash-flow') ||
          cleanPath.startsWith('/reports/trial-balance')) {
        return false;
      }
      return true;
    }

    // Free / Trial plan limits (only allowed: Invoices, Payments Received, Customers, Manual journals, Dashboard overview)
    if (normalizedPlan == 'free' || normalizedPlan == 'trial') {
      if (cleanPath == '/customers' ||
          cleanPath.startsWith('/customers/') ||
          cleanPath == '/invoices' ||
          cleanPath.startsWith('/invoices/') ||
          cleanPath == '/payments-received' ||
          cleanPath.startsWith('/payments-received/') ||
          cleanPath == '/accounting/journals' ||
          cleanPath.startsWith('/accounting/journals/')) {
        return true;
      }
      return false;
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
