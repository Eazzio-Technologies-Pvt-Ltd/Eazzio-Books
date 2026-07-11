import React, { useState, useEffect, useRef } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "../AuthContext";
import { useTheme } from "../ThemeContext";
import { apiRequest } from "../api";
import "./Topbar.css";
import CreateOrganizationForm from "./CreateOrganizationForm";
import { Search, RefreshCw, Users, Plus, Bell } from "lucide-react";

function Topbar() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, setUser } = useAuth();
  const { theme, toggleTheme } = useTheme();
  
  const [showOrgMenu, setShowOrgMenu] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const [showCreateOrg, setShowCreateOrg] = useState(false);

  const searchParams = new URLSearchParams(location.search);
  const currentSearch = searchParams.get("search") || "";
  
  const [globalResults, setGlobalResults] = useState(null);
  const searchTimeout = useRef(null);
  const searchRef = useRef(null);
  const orgMenuRef = useRef(null);
  const profileMenuRef = useRef(null);
  const notificationMenuRef = useRef(null);

  const [notifications, setNotifications] = useState([]);
  const [showNotifications, setShowNotifications] = useState(false);
  const [selectedNotification, setSelectedNotification] = useState(null);

  const [organizations, setOrganizations] = useState([]);
  


  useEffect(() => {
    const fetchOrgs = async () => {
      try {
        if (user && user.role === "Admin") {
          const res = await apiRequest("/my-organizations");
          if (res && res.organizations) {
            setOrganizations(res.organizations);
          }
        }
      } catch(e) {
        console.error("Failed to fetch orgs:", e);
      }
    };
    fetchOrgs();
  }, [user]);

  useEffect(() => {
    const fetchNotifications = async () => {
      try {
        if (user) {
          const res = await apiRequest("/accounts/projected-payments");
          if (res && res.bills) {
            const pending = res.bills.filter(p => p.status !== 'Paid' && p.status !== 'PAID');
            setNotifications(pending);
          }
        }
      } catch(e) {
        console.error("Failed to fetch notifications:", e);
      }
    };
    fetchNotifications();
  }, [user]);

  const handleSwitchOrg = async (orgId) => {
    try {
      await apiRequest(`/switch-organization/${orgId}`, { method: "POST" });
      window.location.reload();
    } catch(e) {
      console.error("Failed to switch org");
    }
  };

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (searchRef.current && !searchRef.current.contains(e.target)) {
        setGlobalResults(null);
      }
      if (orgMenuRef.current && !orgMenuRef.current.contains(e.target)) {
        setShowOrgMenu(false);
      }
      if (profileMenuRef.current && !profileMenuRef.current.contains(e.target)) {
        setShowProfileMenu(false);
      }
      if (notificationMenuRef.current && !notificationMenuRef.current.contains(e.target)) {
        setShowNotifications(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSearchChange = (e) => {
    const val = e.target.value;
    const newParams = new URLSearchParams(location.search);
    if (val) {
      newParams.set("search", val);
    } else {
      newParams.delete("search");
    }
    navigate({ search: newParams.toString() }, { replace: true });

    if (searchTimeout.current) clearTimeout(searchTimeout.current);
    if (!val.trim()) {
      setGlobalResults(null);
      return;
    }
    
    searchTimeout.current = setTimeout(async () => {
      try {
        const res = await fetch(`http://localhost:5000/api/search?q=${encodeURIComponent(val)}`, { credentials: 'include' });
        if(res.ok) {
          const data = await res.json();
          setGlobalResults(data);
        }
      } catch(e) {
        console.error(e);
      }
    }, 300);
  };

  /* Logout handler */
  const handleLogout = async () => {
    try {
      await apiRequest("/logout", {
        method: "POST"
      });
    } catch (err) {
      console.error(err);
    }
    setUser(null);
    navigate("/");
  };

  return (
    <>
      <header className="topbar">
        <div className="topbar-left">
          {/* Brand Logo */}
          <div className="topbar-brand" style={{ display: "flex", alignItems: "center", marginRight: "16px" }}>
            <img src="/logo.png" alt="Logo" style={{ height: "30px", objectFit: "contain" }} />
          </div>

          {/* Refresh icon */}
          <button className="topbar-icon-btn" aria-label="Refresh" onClick={() => window.location.reload()}>
            <RefreshCw size={18} />
          </button>

          {/* Search bar */}
          <div className="topbar-search" ref={searchRef}>
            <span className="topbar-search-icon"><Search size={16} /></span>
            <input
              type="text"
              placeholder="Search customers, items, invoices..."
              className="topbar-search-input"
              value={currentSearch}
              onChange={handleSearchChange}
              onFocus={(e) => {
                if (e.target.value.trim() && !globalResults) {
                  handleSearchChange(e);
                }
              }}
            />
            
            {/* Global Search Dropdown */}
            {globalResults && (globalResults.customers?.length > 0 || globalResults.items?.length > 0 || globalResults.invoices?.length > 0 || globalResults.quotes?.length > 0) && (
              <div className="global-search-dropdown">
                {globalResults.customers?.length > 0 && (
                  <div className="global-search-group">
                    <div className="global-search-group-title">Customers</div>
                    {globalResults.customers.map(c => (
                      <div key={`c-${c.id}`} className="global-search-item" onClick={() => { setGlobalResults(null); navigate(`/customers?search=${encodeURIComponent(c.display_name || c.company_name)}`); }}>
                        <span className="global-search-item-primary">{c.display_name || c.first_name || c.company_name}</span>
                        <span className="global-search-item-secondary">{c.email}</span>
                      </div>
                    ))}
                  </div>
                )}
                {globalResults.items?.length > 0 && (
                  <div className="global-search-group">
                    <div className="global-search-group-title">Items</div>
                    {globalResults.items.map(i => (
                      <div key={`i-${i.id}`} className="global-search-item" onClick={() => { setGlobalResults(null); navigate(`/items?search=${encodeURIComponent(i.name)}`); }}>
                        <span className="global-search-item-primary">{i.name}</span>
                        <span className="global-search-item-secondary">SKU: {i.sku || 'N/A'}</span>
                      </div>
                    ))}
                  </div>
                )}
                {globalResults.invoices?.length > 0 && (
                  <div className="global-search-group">
                    <div className="global-search-group-title">Invoices</div>
                    {globalResults.invoices.map(inv => (
                      <div key={`inv-${inv.id}`} className="global-search-item" onClick={() => { setGlobalResults(null); navigate(`/invoices?search=${encodeURIComponent(inv.invoice_number)}`); }}>
                        <span className="global-search-item-primary">INV-{inv.invoice_number}</span>
                        <span className="global-search-item-secondary">{inv.customer_name}</span>
                      </div>
                    ))}
                  </div>
                )}
                {globalResults.quotes?.length > 0 && (
                  <div className="global-search-group">
                    <div className="global-search-group-title">Quotes</div>
                    {globalResults.quotes.map(q => (
                      <div key={`q-${q.id}`} className="global-search-item" onClick={() => { setGlobalResults(null); navigate(`/quotes?search=${encodeURIComponent(q.quote_number)}`); }}>
                        <span className="global-search-item-primary">QT-{q.quote_number}</span>
                        <span className="global-search-item-secondary">{q.customer_name}</span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        </div>

        {/* Right-side actions */}
        <div className="topbar-actions">
          <button
            id="topbar-professional-edition-btn"
            className="topbar-trial-text"
            onClick={() => navigate("/pricing")}
            title="View Pricing Plans"
            style={{
              background: "#2563eb", // Eazzio Blue
              border: "1px solid #2563eb",
              padding: "6px 14px",
              cursor: "pointer",
              color: "#fff",
              fontWeight: "700",
              letterSpacing: "0.5px",
              fontSize: "13px",
              borderRadius: "999px", // Pill shape
              transition: "all 0.2s cubic-bezier(0.4, 0, 0.2, 1)",
              display: "inline-flex",
              alignItems: "center",
              gap: "6px",
              boxShadow: "0 2px 8px rgba(37, 99, 235, 0.25)",
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = "#1d4ed8";
              e.currentTarget.style.borderColor = "#1d4ed8";
              e.currentTarget.style.transform = "translateY(-1px)";
              e.currentTarget.style.boxShadow = "0 4px 12px rgba(37, 99, 235, 0.35)";
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = "#2563eb";
              e.currentTarget.style.borderColor = "#2563eb";
              e.currentTarget.style.transform = "translateY(0)";
              e.currentTarget.style.boxShadow = "0 2px 8px rgba(37, 99, 235, 0.25)";
            }}
          >
            <svg
              width="14"
              height="14"
              viewBox="0 0 24 24"
              fill="currentColor"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M2 4l3 12h14l3-12-6 7-4-7-4 7-6-7zm3 16h14" />
            </svg>
            Upgrade
          </button>
          <span className="topbar-separator">|</span>

          {/* Organization Dropdown */}
          <div className="topbar-dropdown-container" ref={orgMenuRef}>
            <button 
              className="topbar-org-name" 
              onClick={() => {
                setShowOrgMenu(!showOrgMenu);
                setShowProfileMenu(false);
              }}
            >
              {user?.organization_name || user?.business_type || "My Organization"} ▾
            </button>
            
            {showOrgMenu && (
              <div className="topbar-dropdown-menu org-menu">
                <div className="dropdown-header">Organizations</div>
                {organizations.length > 0 ? (
                  organizations.map(org => (
                    <div 
                      key={org.id}
                      className={`dropdown-item ${user?.organization_id === org.id ? 'active' : ''}`}
                      onClick={() => {
                        setShowOrgMenu(false);
                        if (user?.organization_id !== org.id) {
                          handleSwitchOrg(org.id);
                        }
                      }}
                    >
                      {org.name}
                      {user?.organization_id === org.id && <span className="dropdown-check">✓</span>}
                    </div>
                  ))
                ) : (
                  <div className="dropdown-item active">
                    {user?.organization_name || "Primary Organization"}
                    <span className="dropdown-check">✓</span>
                  </div>
                )}
                
                <div className="dropdown-divider"></div>
                <div 
                  className="dropdown-item"
                  onClick={() => { setShowOrgMenu(false); navigate("/organization-settings"); }}
                >
                  ⚙ Manage Organization
                </div>
                {user?.role === "Admin" && (
                  <div 
                    className="dropdown-item"
                    onClick={() => { setShowOrgMenu(false); setShowCreateOrg(true); }}
                  >
                    + Create New Organization
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Plus / Create button */}
          <button className="topbar-plus-btn" aria-label="Create new" onClick={() => navigate("/invoices/new")}>
            <Plus size={20} />
          </button>



          <div className="topbar-dropdown-container" ref={notificationMenuRef}>
            <button className="topbar-icon-btn" aria-label="Notifications" onClick={() => setShowNotifications(!showNotifications)}>
              <Bell size={18} />
              {notifications.length > 0 && (
                <span style={{ position: "absolute", top: "2px", right: "2px", background: "#ef4444", color: "#fff", fontSize: "10px", fontWeight: "bold", padding: "2px 6px", borderRadius: "10px", lineHeight: 1 }}>
                  {notifications.length}
                </span>
              )}
            </button>
            {showNotifications && (
              <div className="topbar-dropdown-menu" style={{ width: "320px", right: 0, padding: "0" }}>
                <div style={{ padding: "12px 16px", borderBottom: "1px solid #eaecf0", fontWeight: "600", fontSize: "14px" }}>
                  Notifications
                </div>
                <div style={{ maxHeight: "300px", overflowY: "auto" }}>
                  {notifications.length === 0 ? (
                    <div style={{ padding: "24px 16px", textAlign: "center", color: "#667085", fontSize: "13px" }}>
                      No new notifications
                    </div>
                  ) : (
                    notifications.map(n => (
                      <div 
                        key={n.id} 
                        style={{ padding: "12px 16px", borderBottom: "1px solid #eaecf0", cursor: "pointer", transition: "background 0.2s" }}
                        onClick={() => { setSelectedNotification(n); setShowNotifications(false); }}
                        onMouseEnter={(e) => e.currentTarget.style.background = "#f8fafc"}
                        onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}
                      >
                        <div style={{ fontSize: "13px", fontWeight: "500", color: "#1d2939", marginBottom: "4px" }}>
                          Installment Due: {n.bill_number}
                        </div>
                        <div style={{ fontSize: "12px", color: "#475569" }}>
                          ₹{parseFloat(n.pending_amount).toLocaleString('en-IN', {minimumFractionDigits: 2})} due from {n.vendor_name}
                        </div>
                        <div style={{ fontSize: "11px", color: "#dc2626", marginTop: "4px", fontWeight: "500" }}>
                          Due Date: {new Date(n.due_date).toLocaleDateString("en-GB")}
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>
            )}
          </div>

          <button className="topbar-icon-btn" aria-label="Users" onClick={() => navigate("/users-roles")}>
            <Users size={18} />
          </button>

          {/* Profile Dropdown */}
          <div className="topbar-dropdown-container" ref={profileMenuRef}>
            <button 
              className="topbar-account-btn" 
              aria-label="Account"
              onClick={() => {
                setShowProfileMenu(!showProfileMenu);
                setShowOrgMenu(false);
              }}
            >
              {user?.email?.[0]?.toUpperCase() || "U"}
            </button>

            {showProfileMenu && (
              <div className="topbar-dropdown-menu profile-menu">
                <div className="profile-header">
                  <strong>{user?.email}</strong>
                  <br/>
                  <span className="profile-role">Role: {user?.role || "Admin"}</span>
                </div>
                <div className="dropdown-divider"></div>
                <div className="dropdown-item" onClick={() => { setShowProfileMenu(false); navigate("/organization-settings"); }}>
                  Organization Settings
                </div>
                <div className="dropdown-item" onClick={() => { setShowProfileMenu(false); navigate("/users-roles"); }}>
                  Users & Roles
                </div>
                <div className="dropdown-item" onClick={() => { setShowProfileMenu(false); navigate("/taxes"); }}>
                  Taxes
                </div>
                {user?.role === "Super Admin" && (
                  <>
                    <div className="dropdown-divider"></div>
                    <div className="dropdown-item" style={{ color: "#7c3aed", fontWeight: "600" }} onClick={() => { setShowProfileMenu(false); navigate("/super-admin/organizations"); }}>
                      ⚡ Control Center
                    </div>
                  </>
                )}
                <div className="dropdown-divider"></div>
                <div className="dropdown-item" onClick={toggleTheme}>
                  {theme === 'light' ? '🌙 Dark Mode' : '☀️ Light Mode'}
                </div>
                <div className="dropdown-divider"></div>
                <div className="dropdown-item text-danger" onClick={handleLogout}>
                  Logout
                </div>
              </div>
            )}
          </div>
        </div>
      </header>

      {/* Create Organization Modal */}
      {showCreateOrg && (
        <CreateOrganizationForm onClose={() => setShowCreateOrg(false)} />
      )}

      {/* Quick Action Modal for Notifications */}
      {selectedNotification && (
        <div style={{ position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(16,24,40,0.5)", zIndex: 9999, display: "flex", alignItems: "center", justifyContent: "center" }}>
          <div style={{ background: "#ffffff", width: "400px", borderRadius: "8px", boxShadow: "0 20px 25px -5px rgba(0,0,0,0.1), 0 10px 10px -5px rgba(0,0,0,0.04)", overflow: "hidden" }}>
            <div style={{ padding: "16px 20px", borderBottom: "1px solid #eaecf0", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <h3 style={{ margin: 0, fontSize: "16px", fontWeight: "600", color: "#1d2939" }}>Pending Installment Action</h3>
              <button onClick={() => setSelectedNotification(null)} style={{ background: "none", border: "none", fontSize: "20px", color: "#98a2b3", cursor: "pointer" }}>&times;</button>
            </div>
            
            <div style={{ padding: "20px" }}>
              <div style={{ marginBottom: "16px" }}>
                <div style={{ fontSize: "13px", color: "#475569", marginBottom: "4px" }}>Customer</div>
                <div style={{ fontSize: "14px", fontWeight: "500", color: "#1d2939" }}>{selectedNotification.vendor_name}</div>
              </div>
              <div style={{ marginBottom: "16px", display: "flex", gap: "20px" }}>
                <div>
                  <div style={{ fontSize: "13px", color: "#475569", marginBottom: "4px" }}>Invoice</div>
                  <div style={{ fontSize: "14px", fontWeight: "500", color: "#1d2939" }}>{selectedNotification.bill_number}</div>
                </div>
                <div>
                  <div style={{ fontSize: "13px", color: "#475569", marginBottom: "4px" }}>Pending Amount</div>
                  <div style={{ fontSize: "14px", fontWeight: "600", color: "#dc2626" }}>₹{parseFloat(selectedNotification.pending_amount).toLocaleString('en-IN', {minimumFractionDigits: 2})}</div>
                </div>
              </div>
              
              <div style={{ borderTop: "1px solid #eaecf0", margin: "20px -20px", paddingTop: "20px", paddingLeft: "20px", paddingRight: "20px", display: "flex", flexDirection: "column", gap: "10px" }}>
                <button 
                  onClick={() => {
                    const msg = `Dear ${selectedNotification.vendor_name}, your installment of Rs.${parseFloat(selectedNotification.pending_amount).toFixed(2)} for Invoice ${selectedNotification.bill_number} is due on ${new Date(selectedNotification.due_date).toLocaleDateString("en-GB")}. Please remit payment.`;
                    const phone = (selectedNotification.customer_phone || selectedNotification.customer_mobile) ? String(selectedNotification.customer_phone || selectedNotification.customer_mobile).replace(/\D/g, "") : "";
                    const target = phone.length === 10 ? `91${phone}` : phone;
                    if (!target) {
                      alert("Customer phone number is missing.");
                      return;
                    }
                    window.open(`https://wa.me/${target}?text=${encodeURIComponent(msg)}`, "_blank");
                  }}
                  style={{ width: "100%", background: "#25D366", color: "#fff", border: "none", padding: "10px", borderRadius: "6px", fontWeight: "600", fontSize: "13px", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: "8px" }}
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"></path></svg>
                  Send to WhatsApp
                </button>
                <button 
                  onClick={() => {
                    const msg = `Dear ${selectedNotification.vendor_name},\n\nThis is a reminder that your installment of Rs.${parseFloat(selectedNotification.pending_amount).toFixed(2)} for Invoice ${selectedNotification.bill_number} is due on ${new Date(selectedNotification.due_date).toLocaleDateString("en-GB")}.\n\nPlease remit payment at your earliest convenience.\n\nThank you!`;
                    if (!selectedNotification.customer_email) {
                      alert("Customer email is missing.");
                      return;
                    }
                    window.location.href = `mailto:${selectedNotification.customer_email}?subject=Payment Reminder: Invoice ${selectedNotification.bill_number}&body=${encodeURIComponent(msg)}`;
                  }}
                  style={{ width: "100%", background: "#006ee6", color: "#fff", border: "none", padding: "10px", borderRadius: "6px", fontWeight: "600", fontSize: "13px", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", gap: "8px" }}
                >
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path><polyline points="22,6 12,13 2,6"></polyline></svg>
                  Send to Email
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

    </>
  );
}

export default Topbar;
