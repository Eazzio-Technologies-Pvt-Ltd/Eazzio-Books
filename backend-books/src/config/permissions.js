// src/config/permissions.js

// Define available roles
const ROLES = {
  SUPER_ADMIN: 'Super Admin',
  ADMIN: 'Admin',
  ACCOUNTANT: 'Accountant',
  STAFF: 'Staff',
  VIEWER: 'Viewer',
};

// Define modules
const MODULES = {
  CUSTOMERS: 'customers',
  VENDORS: 'vendors',
  ITEMS: 'items',
  QUOTES: 'quotes',
  INVOICES: 'invoices',
  BILLS: 'bills',
  EXPENSES: 'expenses',
  BANKING: 'banking',
  REPORTS: 'reports',
  SETTINGS: 'settings',
  USERS: 'users',
  DASHBOARD: 'dashboard',
  ORGANIZATIONS: 'organizations'
};

// Define actions
const ACTIONS = {
  VIEW: 'view',
  CREATE: 'create',
  EDIT: 'edit',
  DELETE: 'delete',
  SEND: 'send',
  EXPORT: 'export',
  IMPORT: 'import',
  MANAGE: 'manage',
};

// Map roles to their allowed permissions
const PERMISSIONS = {
  [ROLES.SUPER_ADMIN]: {
    _all: true
  },
  [ROLES.ADMIN]: {
    _all: true
  },
  [ROLES.ACCOUNTANT]: {
    [MODULES.CUSTOMERS]: [ACTIONS.VIEW, ACTIONS.CREATE, ACTIONS.EDIT, ACTIONS.DELETE],
    [MODULES.VENDORS]: [ACTIONS.VIEW, ACTIONS.CREATE, ACTIONS.EDIT, ACTIONS.DELETE],
    [MODULES.ITEMS]: [ACTIONS.VIEW, ACTIONS.CREATE, ACTIONS.EDIT, ACTIONS.DELETE],
    [MODULES.QUOTES]: [ACTIONS.VIEW, ACTIONS.CREATE, ACTIONS.EDIT, ACTIONS.DELETE, ACTIONS.SEND, ACTIONS.EXPORT],
    [MODULES.INVOICES]: [ACTIONS.VIEW, ACTIONS.CREATE, ACTIONS.EDIT, ACTIONS.DELETE, ACTIONS.SEND, ACTIONS.EXPORT],
    [MODULES.BILLS]: [ACTIONS.VIEW, ACTIONS.CREATE, ACTIONS.EDIT, ACTIONS.DELETE],
    [MODULES.EXPENSES]: [ACTIONS.VIEW, ACTIONS.CREATE, ACTIONS.EDIT, ACTIONS.DELETE],
    [MODULES.BANKING]: [ACTIONS.VIEW, ACTIONS.CREATE, ACTIONS.EDIT, ACTIONS.DELETE, ACTIONS.IMPORT, ACTIONS.MANAGE],
    [MODULES.REPORTS]: [ACTIONS.VIEW, ACTIONS.EXPORT],
    [MODULES.SETTINGS]: [ACTIONS.VIEW], // View only, no manage
    [MODULES.USERS]: [ACTIONS.VIEW] // View only, no manage
  },
  [ROLES.STAFF]: {
    [MODULES.CUSTOMERS]: [ACTIONS.VIEW, ACTIONS.CREATE, ACTIONS.EDIT],
    [MODULES.QUOTES]: [ACTIONS.VIEW, ACTIONS.CREATE, ACTIONS.EDIT, ACTIONS.SEND],
    [MODULES.INVOICES]: [ACTIONS.VIEW, ACTIONS.CREATE, ACTIONS.EDIT, ACTIONS.SEND],
    [MODULES.EXPENSES]: [ACTIONS.VIEW, ACTIONS.CREATE, ACTIONS.EDIT],
    [MODULES.ITEMS]: [ACTIONS.VIEW],
    [MODULES.REPORTS]: [ACTIONS.VIEW], // Safe reports view
  },
  [ROLES.VIEWER]: {
    [MODULES.CUSTOMERS]: [ACTIONS.VIEW],
    [MODULES.VENDORS]: [ACTIONS.VIEW],
    [MODULES.ITEMS]: [ACTIONS.VIEW],
    [MODULES.QUOTES]: [ACTIONS.VIEW],
    [MODULES.INVOICES]: [ACTIONS.VIEW],
    [MODULES.BILLS]: [ACTIONS.VIEW],
    [MODULES.EXPENSES]: [ACTIONS.VIEW],
    [MODULES.BANKING]: [ACTIONS.VIEW],
    [MODULES.REPORTS]: [ACTIONS.VIEW],
    [MODULES.SETTINGS]: [],
    [MODULES.USERS]: []
  }
};

/**
 * Check if a role has access to a specific module and action
 * @param {string} role - User role (e.g., 'Admin')
 * @param {string} module - Module name (e.g., 'invoices')
 * @param {string} action - Action name (e.g., 'create')
 * @returns {boolean} True if allowed, false otherwise
 */
const canAccess = (role, module, action) => {
  if (!role) return false;
  
  // Convert role to standard case (capitalized first letter)
  let normalizedRole = role.charAt(0).toUpperCase() + role.slice(1).toLowerCase();
  
  // Handle Super Admin capitalization properly
  if (role.toLowerCase() === 'super admin') {
    normalizedRole = ROLES.SUPER_ADMIN;
  }

  // Super Admin has access to everything globally
  if (normalizedRole === ROLES.SUPER_ADMIN) return true;

  // Org Admin has access to everything EXCEPT the global organizations module
  if (normalizedRole === ROLES.ADMIN) {
    if (module === MODULES.ORGANIZATIONS) return false;
    return true;
  }

  const rolePermissions = PERMISSIONS[normalizedRole];
  if (!rolePermissions) return false;

  const modulePermissions = rolePermissions[module];
  if (!modulePermissions) return false;

  return modulePermissions.includes(action);
};

module.exports = {
  ROLES,
  MODULES,
  ACTIONS,
  canAccess,
  PERMISSIONS
};
