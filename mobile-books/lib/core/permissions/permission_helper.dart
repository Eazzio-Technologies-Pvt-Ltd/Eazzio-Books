class PermissionHelper {
  // Roles
  static const String superAdmin = 'Super Admin';
  static const String admin = 'Admin';
  static const String accountant = 'Accountant';
  static const String staff = 'Staff';
  static const String viewer = 'Viewer';

  // Modules
  static const String customers = 'customers';
  static const String vendors = 'vendors';
  static const String items = 'items';
  static const String quotes = 'quotes';
  static const String invoices = 'invoices';
  static const String bills = 'bills';
  static const String expenses = 'expenses';
  static const String banking = 'banking';
  static const String reports = 'reports';
  static const String settings = 'settings';
  static const String users = 'users';
  static const String dashboard = 'dashboard';
  static const String organizations = 'organizations';

  // Actions
  static const String view = 'view';
  static const String create = 'create';
  static const String edit = 'edit';
  static const String delete = 'delete';
  static const String send = 'send';
  static const String export = 'export';
  static const String import = 'import';
  static const String manage = 'manage';

  // Matrix mappings
  static const Map<String, Map<String, List<String>>> matrix = {
    accountant: {
      customers: [view, create, edit, delete],
      vendors: [view, create, edit, delete],
      items: [view, create, edit, delete],
      quotes: [view, create, edit, delete, send, export],
      invoices: [view, create, edit, delete, send, export],
      bills: [view, create, edit, delete],
      expenses: [view, create, edit, delete],
      banking: [view, create, edit, delete, import, manage],
      reports: [view, export],
      settings: [view],
      users: [view],
    },
    staff: {
      customers: [view, create, edit],
      quotes: [view, create, edit, send],
      invoices: [view, create, edit, send],
      expenses: [view, create, edit],
      items: [view],
      reports: [view],
    },
    viewer: {
      customers: [view],
      vendors: [view],
      items: [view],
      quotes: [view],
      invoices: [view],
      bills: [view],
      expenses: [view],
      banking: [view],
      reports: [view],
      settings: [],
      users: [],
    },
  };

  /// Check if a user role is allowed to access a specific module and action
  static bool canAccess(String? role, String module, String action) {
    if (role == null || role.isEmpty) return false;

    // Normalise role casing
    String normalizedRole = role.trim();
    if (normalizedRole.toLowerCase() == 'super admin') {
      normalizedRole = superAdmin;
    } else {
      normalizedRole = normalizedRole[0].toUpperCase() + normalizedRole.substring(1).toLowerCase();
    }

    // Super Admin has access to everything
    if (normalizedRole == superAdmin) return true;

    // Admin has access to everything EXCEPT global organizations
    if (normalizedRole == admin) {
      if (module == organizations) return false;
      return true;
    }

    final rolePermissions = matrix[normalizedRole];
    if (rolePermissions == null) return false;

    final modulePermissions = rolePermissions[module];
    if (modulePermissions == null) return false;

    return modulePermissions.contains(action);
  }

  /// Map route path to its permission requirements
  static bool hasRoutePermission(String? role, String path) {
    if (role == null || role.isEmpty) return false;

    final cleanPath = Uri.parse(path).path;

    // Dashboard is always accessible
    if (cleanPath == '/dashboard') return true;

    // Items module
    if (cleanPath.startsWith('/items') || cleanPath.startsWith('/inventory')) {
      if (cleanPath == '/items' || 
          (cleanPath.startsWith('/items/') && !cleanPath.endsWith('/edit') && !cleanPath.endsWith('/new')) ||
          cleanPath == '/inventory/movements' || 
          cleanPath == '/inventory/low-stock') {
        return canAccess(role, items, view);
      }
      return canAccess(role, items, edit);
    }

    // Customers module
    if (cleanPath.startsWith('/customers')) {
      if (cleanPath == '/customers' || 
          (cleanPath.startsWith('/customers/') && !cleanPath.endsWith('/edit') && !cleanPath.endsWith('/new'))) {
        return canAccess(role, customers, view);
      }
      return canAccess(role, customers, edit);
    }

    // Salespersons (mapped under Settings / view)
    if (cleanPath.startsWith('/salespersons')) {
      return canAccess(role, settings, view);
    }

    // Quotes module
    if (cleanPath.startsWith('/quotes')) {
      if (cleanPath == '/quotes' || 
          (cleanPath.startsWith('/quotes/') && !cleanPath.endsWith('/edit') && !cleanPath.endsWith('/new'))) {
        return canAccess(role, quotes, view);
      }
      return canAccess(role, quotes, edit);
    }

    // Invoices and credit notes, etc.
    if (cleanPath.startsWith('/invoices') || 
        cleanPath.startsWith('/credit-notes') || 
        cleanPath.startsWith('/delivery-challans') || 
        cleanPath.startsWith('/recurring-invoices') || 
        cleanPath.startsWith('/payments-received')) {
      if (cleanPath == '/invoices' || 
          cleanPath == '/credit-notes' || 
          cleanPath == '/delivery-challans' || 
          cleanPath == '/recurring-invoices' || 
          cleanPath == '/payments-received' || 
          (cleanPath.startsWith('/invoices/') && !cleanPath.endsWith('/edit') && !cleanPath.endsWith('/new') && !cleanPath.endsWith('/record-payment')) ||
          (cleanPath.startsWith('/credit-notes/') && !cleanPath.endsWith('/edit') && !cleanPath.endsWith('/new'))) {
        return canAccess(role, invoices, view);
      }
      return canAccess(role, invoices, edit);
    }

    // Vendors module
    if (cleanPath.startsWith('/vendors')) {
      if (cleanPath == '/vendors' || 
          (cleanPath.startsWith('/vendors/') && !cleanPath.endsWith('/edit') && !cleanPath.endsWith('/new'))) {
        return canAccess(role, vendors, view);
      }
      return canAccess(role, vendors, edit);
    }

    // Bills module
    if (cleanPath.startsWith('/bills') || 
        cleanPath.startsWith('/payments-made') || 
        cleanPath.startsWith('/vendor-credits')) {
      if (cleanPath == '/bills' || 
          cleanPath == '/payments-made' || 
          cleanPath == '/vendor-credits' || 
          (cleanPath.startsWith('/bills/') && !cleanPath.endsWith('/edit') && !cleanPath.endsWith('/new') && !cleanPath.endsWith('/record-payment')) ||
          (cleanPath.startsWith('/vendor-credits/') && !cleanPath.endsWith('/edit') && !cleanPath.endsWith('/new'))) {
        return canAccess(role, bills, view);
      }
      return canAccess(role, bills, edit);
    }

    // Expenses module
    if (cleanPath.startsWith('/expenses') || cleanPath.startsWith('/recurring-expenses')) {
      if (cleanPath == '/expenses' || 
          cleanPath == '/recurring-expenses' || 
          (cleanPath.startsWith('/expenses/') && !cleanPath.endsWith('/edit') && !cleanPath.endsWith('/new')) ||
          (cleanPath.startsWith('/recurring-expenses/') && !cleanPath.endsWith('/edit') && !cleanPath.endsWith('/new'))) {
        return canAccess(role, expenses, view);
      }
      return canAccess(role, expenses, edit);
    }

    // Banking module
    if (cleanPath.startsWith('/banking') || cleanPath == '/reconciliation' || cleanPath == '/bank-rules') {
      if (cleanPath == '/banking') {
        return canAccess(role, banking, view);
      }
      return canAccess(role, banking, manage);
    }

    // Projects and Timesheets
    if (cleanPath.startsWith('/projects') || cleanPath.startsWith('/timesheets')) {
      final normalized = role.trim().toLowerCase();
      if (normalized == 'viewer') {
        if (cleanPath.endsWith('/new') || cleanPath.endsWith('/edit')) return false;
      }
      return true;
    }

    // Reports module
    if (cleanPath.startsWith('/reports')) {
      return canAccess(role, reports, view);
    }

    // Settings module
    if (cleanPath.startsWith('/settings')) {
      return canAccess(role, settings, view);
    }

    // Documents
    if (cleanPath.startsWith('/documents')) {
      final normalized = role.trim().toLowerCase();
      if (normalized == 'viewer') {
        if (cleanPath == '/documents/upload') return false;
      }
      return true;
    }

    // Accountant group (Chart of Accounts, journals, locking, bulk updates, taxes, currency adjustments)
    if (cleanPath.startsWith('/accounting') || 
        cleanPath == '/transaction-locking' || 
        cleanPath == '/bulk-updates' || 
        cleanPath.startsWith('/taxes') || 
        cleanPath == '/currency-adjustments') {
      final normalized = role.trim().toLowerCase();
      if (normalized == 'accountant' || normalized == 'admin' || normalized == 'super admin') {
        if (cleanPath.startsWith('/taxes') && (cleanPath.endsWith('/new') || cleanPath.endsWith('/edit'))) {
          return normalized != 'accountant'; // Settings is view-only for Accountant
        }
        return true;
      }
      return false;
    }

    return true;
  }
}
