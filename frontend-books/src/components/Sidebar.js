/**
 * Sidebar.js – Reusable left sidebar navigation (Zoho Books style)
 * Responsive: auto-collapses on mobile, has hamburger toggle on Topbar
 * Dependencies: react-router-dom
 */
import React, { useState, useEffect, useCallback, useRef } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import "./Sidebar.css";

import { 
  Home, Package, ShoppingCart, Receipt, 
  Clock, Landmark, Calculator, BarChart2, FolderOpen 
} from "lucide-react";
import { useAuth } from "../AuthContext";
import { canAccess, MODULES, ACTIONS } from "../utils/permissions";
import { apiRequest } from "../api";

/* ── Sidebar menu definition ── */
const sidebarMenus = [
  { label: "Home", icon: <Home size={18} />, path: "/dashboard", module: MODULES.DASHBOARD },
  {
    label: "Items", icon: <Package size={18} />, module: MODULES.ITEMS,
    children: [
      { label: "Items", path: "/items" },
      { label: "New Item", path: "/items/new" },
      { label: "Stock In / Stock Out", path: "/inventory/stock" },
      { label: "Inventory Movements", path: "/inventory/movements" },
      { label: "Low Stock Alerts", path: "/inventory/low-stock" },
      { label: "Item Valuation Report", path: "/reports/item-valuation" },
    ],
  },
  {
    label: "Sales", icon: <ShoppingCart size={18} />,
    children: [
      { label: "Customers", path: "/customers", module: MODULES.CUSTOMERS },
      { label: "Quotes", path: "/quotes", module: MODULES.QUOTES },
      { label: "Invoices", path: "/invoices", module: MODULES.INVOICES },
      { label: "Sales Orders", path: "/sales-orders" }, // Allow if they have sales access
      { label: "Payments Received", path: "/payments-received" },
      { label: "Delivery Challans", path: "/delivery-challans" },
      { label: "Credit Notes", path: "/credit-notes" },
      { label: "Recurring Invoices", path: "/recurring-invoices" },
    ],
  },
  {
    label: "Purchases", icon: <Receipt size={18} />,
    children: [
      { label: "Vendors", path: "/vendors", module: MODULES.VENDORS },
      { label: "Expenses", path: "/expenses", module: MODULES.EXPENSES },
      { label: "Recurring / Fixed Expenses", path: "/recurring-expenses" },
      { label: "Purchase Orders", path: "/purchase-orders" },
      { label: "Bills", path: "/bills", module: MODULES.BILLS },
      { label: "Payments Made", path: "/payments-made" },
      { label: "Vendor Credits", path: "/vendor-credits" },
    ],
  },
  {
    label: "Time Tracking", icon: <Clock size={18} />,
    children: [
      { label: "Projects", path: "/projects" },
      { label: "Timesheets", path: "/timesheets" },
    ],
  },
  {
    label: "Banking", icon: <Landmark size={18} />, module: MODULES.BANKING,
    children: [
      { label: "Bank Accounts", path: "/bank-accounts" },
      { label: "Petty Cash", path: "/banking/petty-cash" },
      { label: "Undeposited Funds", path: "/banking/undeposited-funds" },
      { label: "Bank Rules", path: "/bank-rules" },
      { label: "Reconciliation", path: "/reconciliation" },
    ],
  },
  {
    label: "Accountant", icon: <Calculator size={18} />, module: MODULES.REPORTS, // Treat accountant tools like reports access for visibility
    children: [
      { label: "Chart of Accounts", path: "/chart-of-accounts" },
      { label: "Manual Journals", path: "/manual-journals" },
      { label: "Transaction Locking", path: "/transaction-locking" },
      { label: "Bulk Updates", path: "/bulk-updates" },
      { label: "Currency Adjustments", path: "/currency-adjustments" },
      { label: "Taxes", path: "/taxes" },
    ],
  },
  {
    label: "Reports", icon: <BarChart2 size={18} />, module: MODULES.REPORTS,
    children: [
      { label: "Profit and Loss", path: "/reports/profit-loss" },
      { label: "Balance Sheet", path: "/reports/balance-sheet" },
      { label: "Cash Flow Statement", path: "/reports/cash-flow" },
      { label: "Trial Balance", path: "/reports/trial-balance" },
    ],
  },
  {
    label: "Documents", icon: <FolderOpen size={18} />,
    children: [
      { label: "All Documents", path: "/documents" },
      { label: "Upload Document", path: "/documents/upload" },
    ],
  },
];

function Sidebar({ onCollapseChange }) {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, setUser } = useAuth();
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [openDropdown, setOpenDropdown] = useState(null);
  const [isMobile, setIsMobile] = useState(window.innerWidth <= 768);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const profileMenuRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (profileMenuRef.current && !profileMenuRef.current.contains(e.target)) {
        setShowProfileMenu(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleLogout = async () => {
    try {
      await apiRequest("/logout", { method: "POST" });
    } catch (err) {
      console.error(err);
    }
    setUser(null);
    navigate("/");
  };

  /* Notify parent of collapse changes */
  const handleCollapse = (val) => {
    setCollapsed(val);
    if (onCollapseChange) onCollapseChange(val);
  };

  /* Listen for resize to auto-collapse on mobile */
  const handleResize = useCallback(() => {
    const mobile = window.innerWidth <= 768;
    setIsMobile(mobile);
    if (mobile) {
      setMobileOpen(false);
      setCollapsed(false);
    }
  }, []);

  useEffect(() => {
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, [handleResize]);

  /* Close mobile sidebar when route changes */
  useEffect(() => {
    if (isMobile) setMobileOpen(false);
  }, [location.pathname, isMobile]);

  /* Toggle dropdown inside sidebar */
  const toggleDropdown = (menuName) => {
    if (collapsed && !isMobile) {
      handleCollapse(false);
      setOpenDropdown(menuName);
      return;
    }
    
    if (openDropdown === menuName) {
      setOpenDropdown(null);
      if (!isMobile) {
        handleCollapse(true);
      }
    } else {
      setOpenDropdown(menuName);
    }
  };

  /* Check if a menu item or any of its children match the current path */
  const isActive = (menu) => {
    if (menu.path && location.pathname === menu.path) return true;
    if (menu.children) {
      return menu.children.some((child) => location.pathname.startsWith(child.path));
    }
    return false;
  };

  /* Determine CSS classes */
  const sidebarClass = [
    "sidebar",
    collapsed && !isMobile ? "collapsed" : "",
    isMobile ? "sidebar-mobile" : "",
    isMobile && mobileOpen ? "sidebar-mobile-open" : "",
  ].filter(Boolean).join(" ");

  const showLabels = isMobile ? true : !collapsed;

  /* Dynamically determine which menus to show based on role */
  const activeMenus = user?.role === 'Super Admin' 
    ? [
        { label: "Control Center", icon: <BarChart2 size={18} />, path: "/super-admin/organizations" }
      ]
    : sidebarMenus;

  return (
    <>
      {/* Mobile hamburger button - rendered via CSS positioning */}
      {isMobile && (
        <button
          className="sidebar-hamburger"
          onClick={() => setMobileOpen(!mobileOpen)}
          aria-label="Toggle navigation"
        >
          {mobileOpen ? "✕" : "☰"}
        </button>
      )}

      {/* Mobile overlay */}
      {isMobile && mobileOpen && (
        <div className="sidebar-overlay" onClick={() => setMobileOpen(false)} />
      )}

      <aside className={sidebarClass}>

        {/* Desktop collapse button */}
        {!isMobile && (
          <button
            className="sidebar-collapse-btn"
            onClick={() => handleCollapse(!collapsed)}
            aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
          >
            {collapsed ? "›" : "‹"}
          </button>
        )}

        {/* Navigation */}
        <nav className="sidebar-nav">
          {activeMenus.map((menu) => {
            // Check top-level permission (Super Admin bypasses this inside canAccess anyway)
            if (menu.module && !canAccess(user?.role, menu.module, ACTIONS.VIEW)) return null;

            // Filter children
            const allowedChildren = menu.children ? menu.children.filter(child => {
              if (child.module) return canAccess(user?.role, child.module, ACTIONS.VIEW);
              // For sales/purchases sub-items without explicit modules mapped,
              // we hide them if they are Staff (for unsupported ones) or Viewer. 
              // To keep it simple, if no module is mapped on the child, we allow it to render,
              // but the actual route will be blocked by ProtectedRoute or backend.
              // We'll hide Sales Orders, etc for Staff by mapping them, but let's just use a simple approach for now.
              return true; 
            }) : [];

            if (menu.children && allowedChildren.length === 0) return null;

            // Specific hide logic for Staff on Accounting
            if (menu.label === "Accountant" && user?.role?.toLowerCase() === "staff") return null;

            return (
            <div key={menu.label} className="sidebar-menu-block">
              <button
                className={`sidebar-menu-btn ${isActive(menu) ? "active" : ""}`}
                onClick={() =>
                  allowedChildren.length > 0
                    ? toggleDropdown(menu.label)
                    : navigate(menu.path)
                }
                title={!showLabels ? menu.label : ""}
              >
                <span className="sidebar-menu-icon">{menu.icon}</span>
                {showLabels && (
                  <>
                    <span className="sidebar-menu-text">{menu.label}</span>
                    {allowedChildren.length > 0 && (
                      <span className={`sidebar-arrow ${openDropdown === menu.label ? "open" : ""}`}>
                        ›
                      </span>
                    )}
                  </>
                )}
              </button>

              {/* Dropdown submenu */}
              {showLabels && allowedChildren.length > 0 && openDropdown === menu.label && (
                <div className="sidebar-submenu">
                  {allowedChildren.map((child) => (
                    <button
                      key={child.label}
                      className={`sidebar-submenu-btn ${location.pathname.startsWith(child.path) ? "active" : ""}`}
                      onClick={() => navigate(child.path)}
                    >
                      {child.label}
                    </button>
                  ))}
                </div>
              )}
            </div>
            );
          })}
        </nav>

        {/* User Info Display */}
        {user && (
          <div className="sidebar-profile-container" ref={profileMenuRef} style={{ marginTop: "auto", position: "relative" }}>
            <div 
              className="sidebar-profile-btn"
              onClick={() => setShowProfileMenu(!showProfileMenu)}
              style={{
                display: "flex", alignItems: "center", gap: "12px",
                padding: "16px 20px", borderTop: "1px solid #283352",
                cursor: "pointer", transition: "background 0.2s"
              }}
              onMouseEnter={(e) => e.currentTarget.style.background = "rgba(47, 128, 237, 0.12)"}
              onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}
            >
              <div style={{
                width: "36px", height: "36px", borderRadius: "50%",
                background: "linear-gradient(135deg, #2563eb, #7c3aed)",
                color: "#fff", display: "flex", alignItems: "center", justifyContent: "center",
                fontWeight: "600", fontSize: "15px", flexShrink: 0
              }}>
                {user.email?.[0]?.toUpperCase() || "U"}
              </div>
              
              {showLabels && (
                <div style={{ overflow: "hidden", flex: 1 }}>
                  <div style={{ fontWeight: "600", color: "#ffffff", fontSize: "14px", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                    {user.email}
                  </div>
                  <div style={{ fontSize: "12px", color: "#8892b0", marginTop: "2px" }}>
                    {user.role || "Admin"}
                  </div>
                </div>
              )}
            </div>

            {showProfileMenu && (
              <div style={{
                position: "absolute", bottom: "100%", left: "16px",
                background: "#fff", width: "240px", borderRadius: "10px",
                boxShadow: "0 -4px 20px rgba(0,0,0,0.12)", padding: "8px 0",
                zIndex: 1000, marginBottom: "8px", border: "1px solid #e2e8f0"
              }}>
                <div style={{ padding: "12px 16px", borderBottom: "1px solid #e2e8f0", marginBottom: "4px" }}>
                  <strong style={{ color: "#0f172a", fontSize: "14px" }}>{user.email}</strong><br/>
                  <span style={{ fontSize: "12px", color: "#475569" }}>Role: {user.role || "Admin"}</span>
                </div>
                
                {user.role === "Admin" && (
                  <>
                    <div 
                      style={{ padding: "10px 16px", cursor: "pointer", fontSize: "14px", color: "#334155" }}
                      onMouseEnter={(e) => e.currentTarget.style.background = "#f1f5f9"}
                      onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}
                      onClick={() => { setShowProfileMenu(false); navigate("/organization-settings"); }}
                    >
                      Organization Settings
                    </div>
                    <div 
                      style={{ padding: "10px 16px", cursor: "pointer", fontSize: "14px", color: "#334155" }}
                      onMouseEnter={(e) => e.currentTarget.style.background = "#f1f5f9"}
                      onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}
                      onClick={() => { setShowProfileMenu(false); navigate("/users-roles"); }}
                    >
                      Users & Roles
                    </div>
                    <div 
                      style={{ padding: "10px 16px", cursor: "pointer", fontSize: "14px", color: "#334155" }}
                      onMouseEnter={(e) => e.currentTarget.style.background = "#f1f5f9"}
                      onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}
                      onClick={() => { setShowProfileMenu(false); navigate("/taxes"); }}
                    >
                      Taxes
                    </div>
                  </>
                )}
                {user.role === "Super Admin" && (
                  <>
                    <div style={{ padding: "0 16px", margin: "4px 0" }}><hr style={{ border: 0, borderTop: "1px solid #e2e8f0" }}/></div>
                    <div 
                      style={{ padding: "10px 16px", cursor: "pointer", fontSize: "14px", color: "#7c3aed", fontWeight: "600" }}
                      onMouseEnter={(e) => e.currentTarget.style.background = "#f1f5f9"}
                      onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}
                      onClick={() => { setShowProfileMenu(false); navigate("/super-admin/organizations"); }}
                    >
                      ⚡ Control Center
                    </div>
                  </>
                )}
                <div style={{ padding: "0 16px", margin: "4px 0" }}><hr style={{ border: 0, borderTop: "1px solid #e2e8f0" }}/></div>
                <div 
                  style={{ padding: "10px 16px", cursor: "pointer", fontSize: "14px", color: "#dc2626", fontWeight: "500" }}
                  onMouseEnter={(e) => e.currentTarget.style.background = "#fef2f2"}
                  onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}
                  onClick={handleLogout}
                >
                  Logout
                </div>
              </div>
            )}
          </div>
        )}

      </aside>
    </>
  );
}

export default Sidebar;
