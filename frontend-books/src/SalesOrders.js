/**
 * SalesOrders.js – Redesigned Sales Orders List UI matching Invoices/Quotes UI
 */
import React, { useEffect, useState, useCallback } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { apiRequest } from "./api";
import { TableSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

const STATUS_COLORS = {
  draft:     { bg: "#f1f5f9", color: "#475569", label: "DRAFT" },
  confirmed: { bg: "#ecfdf5", color: "#047857", label: "CONFIRMED" },
  invoiced:  { bg: "#f0fdfa", color: "#0f766e", label: "INVOICED" },
  cancelled: { bg: "#fef2f2", color: "#b91c1c", label: "CANCELLED" },
};

const ALL_COLUMNS = [
  { key: "checkbox", label: "☐" },
  { key: "sales_order_date", label: "Date" },
  { key: "sales_order_number", label: "Sales Order#" },
  { key: "reference_number", label: "Reference#" },
  { key: "customer_name", label: "Customer Name" },
  { key: "status", label: "Status" },
  { key: "invoiced", label: "Invoiced" },
  { key: "payment", label: "Payment" },
  { key: "expected_shipment_date", label: "Expected Shipment Date" },
  { key: "delivery_method", label: "Delivery Method" },
  { key: "total", label: "Amount" },
];

function SalesOrders() {
  const navigate = useNavigate();
  const location = useLocation();

  const [salesOrders, setSalesOrders] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [favoriteView, setFavoriteView] = useState(() => localStorage.getItem("favSOView") || null);
  const [statusDropdownOpen, setStatusDropdownOpen] = useState(false);
  const [filterSearch, setFilterSearch] = useState("");
  const [selectedIds, setSelectedIds] = useState([]);

  // Dropdown & Sorting States
  const [moreMenuOpen, setMoreMenuOpen] = useState(false);
  const [sortSubMenuOpen, setSortSubMenuOpen] = useState(false);
  const [exportSubMenuOpen, setExportSubMenuOpen] = useState(false);
  const [sortBy, setSortBy] = useState("sales_order_date");
  const [sortOrder, setSortOrder] = useState("desc");
  
  const [showSettings, setShowSettings] = useState(false);
  const [clipText, setClipText] = useState(true);
  const [columnsOpen, setColumnsOpen] = useState(false);
  const [visibleColumns, setVisibleColumns] = useState(
    ALL_COLUMNS.reduce((acc, col) => {
      acc[col.key] = true;
      if (typeof window !== 'undefined' && window.innerWidth < 768 && ['reference_number', 'expected_shipment_date', 'delivery_method'].includes(col.key)) {
        acc[col.key] = false;
      }
      return acc;
    }, {})
  );

  useEffect(() => {
    const h = (e) => {
      if (!e.target.closest('.th-icon-wrapper') && !e.target.closest('.settings-dropdown') && !e.target.closest('.columns-dropdown')) {
        setShowSettings(false);
        setColumnsOpen(false);
      }
      if (!e.target.closest('.view-dropdown-container')) setStatusDropdownOpen(false);
      if (!e.target.closest('.more-dropdown-container')) setMoreMenuOpen(false);
    };
    document.addEventListener('click', h);
    return () => document.removeEventListener('click', h);
  }, []);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      const [soRes, customersRes] = await Promise.all([
        apiRequest("/sales-orders"),
        apiRequest("/customers"),
      ]);
      setSalesOrders(Array.isArray(soRes?.sales_orders) ? soRes.sales_orders : []);
      setCustomers(Array.isArray(customersRes?.customers) ? customersRes.customers : []);
    } catch (err) {
      toast.error("Failed to load Sales Orders");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData, location.state?.refresh]);

  useEffect(() => {
    const fav = localStorage.getItem("favSOView");
    if (fav) {
      setStatusFilter(fav);
    }
  }, []);

  const getCustomerName = (customerId) => {
    if (!customerId) return "—";
    const cust = customers.find((c) => c.id === customerId);
    return cust
      ? cust.display_name ||
          [cust.first_name, cust.last_name].filter(Boolean).join(" ") ||
          cust.email
      : "—";
  };

  const filteredSOs = salesOrders.filter((so) => {
    const matchSearch =
      search === "" ||
      (so.sales_order_number || "").toLowerCase().includes(search.toLowerCase()) ||
      (so.reference_number || "").toLowerCase().includes(search.toLowerCase()) ||
      getCustomerName(so.customer_id).toLowerCase().includes(search.toLowerCase());
    const matchStatus = statusFilter === "all" || so.status === statusFilter;
    return matchSearch && matchStatus;
  });

  const sortedSOs = [...filteredSOs].sort((a, b) => {
    let aVal = a[sortBy];
    let bVal = b[sortBy];

    if (sortBy === "customer_name") {
      aVal = getCustomerName(a.customer_id).toLowerCase();
      bVal = getCustomerName(b.customer_id).toLowerCase();
    } else if (sortBy === "total") {
      aVal = parseFloat(a.total) || 0;
      bVal = parseFloat(b.total) || 0;
    } else if (sortBy === "sales_order_date") {
      aVal = new Date(a.sales_order_date).getTime();
      bVal = new Date(b.sales_order_date).getTime();
    } else if (sortBy === "sales_order_number") {
      aVal = (a.sales_order_number || "").toLowerCase();
      bVal = (b.sales_order_number || "").toLowerCase();
    }

    if (aVal < bVal) return sortOrder === "asc" ? -1 : 1;
    if (aVal > bVal) return sortOrder === "asc" ? 1 : -1;
    return 0;
  });

  const handleSelectAll = (e) => {
    if (e.target.checked) {
      setSelectedIds(sortedSOs.map((s) => s.id));
    } else {
      setSelectedIds([]);
    }
  };

  const handleSelectOne = (id) => {
    setSelectedIds((prev) =>
      prev.includes(id) ? prev.filter((sid) => sid !== id) : [...prev, id],
    );
  };

  const handleDeleteSelected = async () => {
    if (!window.confirm(`Delete the ${selectedIds.length} selected Sales Order(s)?`)) return;
    try {
      await Promise.all(
        selectedIds.map((id) => apiRequest(`/sales-orders/${id}`, { method: "DELETE" }))
      );
      toast.success("Sales Orders deleted successfully");
      setSelectedIds([]);
      fetchData();
    } catch (err) {
      toast.error("Delete failed");
    }
  };

  const statusBadge = (status) => {
    const colors = STATUS_COLORS[status] || STATUS_COLORS.draft;
    return (
      <span style={{
        padding: "3px 8px",
        borderRadius: "4px",
        fontSize: "11px",
        fontWeight: "600",
        background: colors.bg,
        color: colors.color,
        letterSpacing: "0.03em",
        display: "inline-block",
      }}>
        {colors.label}
      </span>
    );
  };

  const getFilterLabel = (filter) => {
    switch (filter) {
      case "all": return "All Sales Orders";
      case "draft": return "Draft Sales Orders";
      case "confirmed": return "Confirmed Sales Orders";
      case "invoiced": return "Invoiced Sales Orders";
      case "cancelled": return "Cancelled Sales Orders";
      default: return "All Sales Orders";
    }
  };

  const allViews = [
    { key: "all", label: "All" },
    { key: "draft", label: "Draft" },
    { key: "confirmed", label: "Confirmed" },
    { key: "invoiced", label: "Invoiced" },
    { key: "cancelled", label: "Cancelled" },
  ];
  
  const filteredViews = allViews.filter(v => v.label.toLowerCase().includes(filterSearch.toLowerCase()));

  const handleExportCSV = () => {
    toast.success("Exported CSV");
  };

  const handleExportJSON = () => {
    toast.success("Exported JSON");
  };

  return (
    <div style={{ background: "#f8fafc", minHeight: "100vh", fontFamily: "system-ui, -apple-system, sans-serif", color: "#1d2939" }}>
      <style>{`
        .premium-input {
          border: 1px solid #d0d5dd;
          transition: border-color 0.15s ease, box-shadow 0.15s ease;
        }
        .premium-input:focus {
          border-color: #006ee6 !important;
          box-shadow: 0 0 0 4px rgba(0, 110, 230, 0.12) !important;
        }
        .full-table-container {
          background: #fff;
          display: flex;
          flex-direction: column;
          height: 100%;
          min-height: calc(100vh - 60px);
          margin: 0;
          font-family: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }
        .full-table-header {
          padding: 15px 30px;
          border-bottom: 1px solid #eaeaea;
          display: flex;
          justify-content: space-between;
          align-items: center;
        }
        .table-actions {
          display: flex;
          gap: 10px;
        }
        .btn-new {
          background: #3b82f6;
          color: white;
          border: none;
          padding: 8px 16px;
          border-radius: 4px;
          font-size: 14px;
          cursor: pointer;
          display: flex;
          align-items: center;
          gap: 5px;
          font-weight: 500;
        }
        .btn-new:hover { background: #2563eb; }
        .btn-more {
          background: #f5f5f5;
          border: 1px solid #ddd;
          color: #555;
          border-radius: 4px;
          padding: 6px 12px;
          cursor: pointer;
          font-weight: bold;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .table-wrapper {
          flex: 1;
          overflow: auto;
        }
        .items-table {
          width: 100%;
          border-collapse: collapse;
          font-size: 13px;
          table-layout: fixed;
        }
        .items-table th {
          text-align: left;
          padding: 12px 15px;
          color: #64748b;
          font-weight: 600;
          border-bottom: 1px solid #e2e8f0;
          background: #ffffff;
          text-transform: uppercase;
          font-size: 11px;
          letter-spacing: 0.5px;
          white-space: nowrap;
          resize: horizontal;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .items-table td {
          padding: 14px 15px;
          border-bottom: 1px solid #f8fafc;
          color: #334155;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .items-table tr:hover {
          background: #f1f5f9;
        }
        .customer-name-link {
          color: #2563eb;
          cursor: pointer;
          font-weight: 500;
        }
        .customer-name-link:hover {
          text-decoration: underline;
        }
        .th-icon-wrapper { overflow: visible !important; }
        .th-icon { display: inline-flex; align-items: center; justify-content: center; color: #aaa; cursor: pointer; transition: color 0.2s; }
        .th-icon:hover, .th-icon.active { color: #007bff; }
        .settings-dropdown { position: absolute; top: 30px; left: 10px; background: #fff; border: 1px solid #e0e0e0; border-radius: 6px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); z-index: 1000; width: 180px; padding: 6px; font-size: 13px; text-transform: none; font-weight: 500; text-align: left; letter-spacing: normal; }
        .dropdown-item { padding: 8px 12px; display: flex; align-items: center; justify-content: flex-start; gap: 10px; border-radius: 4px; cursor: pointer; color: #334155; transition: background 0.2s; }
        .dropdown-item:hover { background: #f1f5f9; color: #0f172a; }
        .dropdown-item svg { width: 16px; height: 16px; min-width: 16px; color: #64748b; }
        .items-table.clip-text td { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }

        .more-dropdown-container { position:relative; }
        .more-dropdown-menu { position:absolute; top:100%; right:0; margin-top:8px; background:#fff; border:1px solid #e2e8f0; border-radius:8px; box-shadow:0 10px 25px rgba(0,0,0,0.1); z-index:1000; width:250px; padding:8px 0; }
        .more-dropdown-item { position:relative; padding:10px 16px; display:flex; align-items:center; gap:12px; cursor:pointer; font-size:14px; color:#334155; transition:background 0.2s; }
        .more-dropdown-item:hover { background:#f8fafc; color:#0f172a; }
        .more-dropdown-item svg { width:16px; height:16px; min-width:16px; color:#64748b; }
        .more-dropdown-divider { height:1px; background:#e2e8f0; margin:4px 0; }
        .more-dropdown-item span { flex:1; }
        .more-dropdown-item .chevron { width:14px; height:14px; }
        .nested-dropdown-menu { display:none; position:absolute; right:100%; top:-8px; margin-right:4px; background:#fff; border:1px solid #e2e8f0; border-radius:8px; box-shadow:0 10px 25px rgba(0,0,0,0.1); z-index:1001; min-width:200px; padding:8px 0; }
        .more-dropdown-item:hover > .nested-dropdown-menu { display:block; }
        
        .view-dropdown-container { position: relative; display: inline-block; }
        .view-dropdown-btn { display: flex; align-items: center; gap: 6px; cursor: pointer; padding: 6px 10px; border-radius: 6px; transition: background 0.2s; font-size: 18px; color: #333; margin: 0; }
        .view-dropdown-btn:hover, .view-dropdown-btn.active { background: #f1f5f9; }
        .view-dropdown-menu { position: absolute; top: 100%; left: 0; margin-top: 4px; background: #fff; border: 1px solid #e2e8f0; border-radius: 8px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); z-index: 1000; width: 220px; padding: 8px 0; max-height: 300px; overflow-y: auto; }
        .view-dropdown-item { padding: 10px 16px; display: flex; align-items: center; justify-content: space-between; cursor: pointer; font-size: 14px; color: #334155; transition: background 0.2s; }
        .view-dropdown-item:hover { background: #f8fafc; }
      `}</style>

      <div className="full-table-container">
        {/* List Header */}
        <div className="full-table-header">
          <div className="view-dropdown-container">
            <h3 className={`view-dropdown-btn ${statusDropdownOpen ? 'active' : ''}`} onClick={() => setStatusDropdownOpen(!statusDropdownOpen)} style={{ fontWeight: 600 }}>
              {getFilterLabel(statusFilter)}
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#2563eb" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" style={{ transform: statusDropdownOpen ? 'rotate(180deg)' : 'none', transition: 'transform 0.2s' }}><polyline points="6 9 12 15 18 9" /></svg>
            </h3>
            {statusDropdownOpen && (
              <div className="view-dropdown-menu">
                <div style={{ padding: "0 12px 10px 12px", borderBottom: "1px solid #f2f4f7", position: "sticky", top: 0, background: "#fff", paddingTop: "8px" }}>
                  <div style={{ position: "relative", width: "100%" }}>
                    <span style={{ position: "absolute", left: "10px", top: "50%", transform: "translateY(-50%)", display: "flex" }}>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#667085" strokeWidth="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
                    </span>
                    <input type="text" placeholder="Search views..." value={filterSearch} onChange={(e) => setFilterSearch(e.target.value)} style={{ width: "100%", padding: "6px 10px 6px 30px", borderRadius: "6px", border: "1px solid #d0d5dd", fontSize: "13px", outline: "none", boxSizing: "border-box" }} onClick={(e) => e.stopPropagation()} />
                  </div>
                </div>
                {filteredViews.length === 0 ? (
                  <div style={{ padding: "12px 16px", color: "#667085", fontSize: "13px", textAlign: "center" }}>No views found</div>
                ) : (
                  filteredViews.map(view => {
                    const isSelected = statusFilter === view.key;
                    const isFav = favoriteView === view.key;
                    return (
                      <div key={view.key} className="view-dropdown-item" onClick={() => { setStatusFilter(view.key); setStatusDropdownOpen(false); }} style={{ background: isSelected ? "#f0f6ff" : "transparent", color: isSelected ? "#006ee6" : "#344054", fontWeight: isSelected ? "500" : "400" }}>
                        <span>{view.label}</span>
                        <span onClick={(e) => { e.stopPropagation(); const newFav = isFav ? null : view.key; setFavoriteView(newFav); if (newFav) { localStorage.setItem("favSOView", newFav); toast.success(`"${view.label}" set as default view`); } else { localStorage.removeItem("favSOView"); toast.success("Default view cleared"); } }} style={{ color: isFav ? "#f59e0b" : "#d0d5dd", fontSize: "14px", padding: "2px 6px" }}>{isFav ? "★" : "☆"}</span>
                      </div>
                    );
                  })
                )}
              </div>
            )}
          </div>
          
          <div className="table-actions">
            <button className="btn-new" onClick={() => navigate("/sales-orders/new")}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="12" y1="5" x2="12" y2="19" /><line x1="5" y1="12" x2="19" y2="12" /></svg>
              New
            </button>
            <div className="more-dropdown-container">
              <button className="btn-more" onClick={() => setMoreMenuOpen(!moreMenuOpen)}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="1" /><circle cx="19" cy="12" r="1" /><circle cx="5" cy="12" r="1" /></svg>
              </button>
              {moreMenuOpen && (
                <div className="more-dropdown-menu">
                  <div className="more-dropdown-item">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 5v14M12 20l-5-5M12 20l5-5"/></svg>
                    <span>Sort by</span>
                    <svg className="chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="9 18 15 12 9 6"/></svg>
                    <div className="nested-dropdown-menu">
                      <div className="more-dropdown-item" onClick={() => { setSortBy("sales_order_date"); setSortOrder("desc"); setMoreMenuOpen(false); }}><span>Date (Newest first)</span></div>
                      <div className="more-dropdown-item" onClick={() => { setSortBy("sales_order_date"); setSortOrder("asc"); setMoreMenuOpen(false); }}><span>Date (Oldest first)</span></div>
                      <div className="more-dropdown-item" onClick={() => { setSortBy("sales_order_number"); setSortOrder("asc"); setMoreMenuOpen(false); }}><span>Order Number (A-Z)</span></div>
                      <div className="more-dropdown-item" onClick={() => { setSortBy("customer_name"); setSortOrder("asc"); setMoreMenuOpen(false); }}><span>Customer Name (A-Z)</span></div>
                      <div className="more-dropdown-item" onClick={() => { setSortBy("total"); setSortOrder("desc"); setMoreMenuOpen(false); }}><span>Amount (High to Low)</span></div>
                    </div>
                  </div>
                  <div className="more-dropdown-item" onClick={() => { setMoreMenuOpen(false); toast("Import functionality coming soon"); }}>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg>
                    <span>Import Sales Orders</span>
                  </div>
                  <div className="more-dropdown-item">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12"/></svg>
                    <span>Export Sales Orders</span>
                    <svg className="chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="9 18 15 12 9 6"/></svg>
                    <div className="nested-dropdown-menu">
                      <div className="more-dropdown-item" onClick={() => { handleExportCSV(); setMoreMenuOpen(false); }}><span>Export as CSV</span></div>
                      <div className="more-dropdown-item" onClick={() => { handleExportJSON(); setMoreMenuOpen(false); }}><span>Export as JSON</span></div>
                    </div>
                  </div>
                  <div className="more-dropdown-divider"></div>
                  <div className="more-dropdown-item" onClick={() => { fetchData(); setMoreMenuOpen(false); }}>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2"/></svg>
                    <span>Refresh List</span>
                  </div>
                  <div className="more-dropdown-item">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16c0 1.1.9 2 2 2h12a2 2 0 0 0 2-2V8l-6-6z"/><path d="M14 3v5h5M10 12v6M8 15h4"/></svg>
                    <span>Reset Column Width</span>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* List Search Bar */}
        <div style={{ padding: "12px 30px", borderBottom: "1px solid #eaeaea", background: "#fdfdfd" }}>
          <div style={{ position: "relative", width: "100%", maxWidth: "400px" }}>
            <span style={{ position: "absolute", left: "14px", top: "50%", transform: "translateY(-50%)", color: "#98a2b3" }}>🔍</span>
            <input
              type="text"
              placeholder="Search in Sales Orders..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{ width: "100%", padding: "10px 12px 10px 42px", borderRadius: "6px", border: "1px solid #d0d5dd", outline: "none", fontSize: "13px", boxSizing: "border-box" }}
              className="premium-input"
            />
          </div>
        </div>

        {/* Bulk Actions Banner */}
        {selectedIds.length > 0 && (
          <div style={{ background: "#f0f6ff", border: "1px solid #bae6fd", borderRadius: "8px", padding: "12px 16px", display: "flex", alignItems: "center", gap: "16px", margin: "20px 30px 0" }}>
            <span style={{ color: "#0369a1", fontWeight: "600", fontSize: "13px" }}>{selectedIds.length} order(s) selected</span>
            <button onClick={handleDeleteSelected} style={{ background: "#d92d20", color: "#ffffff", border: "none", borderRadius: "6px", padding: "6px 12px", cursor: "pointer", fontSize: "12px", fontWeight: "600" }}>Delete Selected</button>
            <button onClick={() => setSelectedIds([])} style={{ background: "none", border: "none", color: "#475569", cursor: "pointer", fontSize: "12px", textDecoration: "underline" }}>Cancel</button>
          </div>
        )}

        {/* Table List Layout */}
        <div className="table-wrapper">
          {loading ? (
            <TableSkeleton rows={8} columns={6} />
          ) : filteredSOs.length === 0 ? (
            <div style={{ padding: "40px 24px", maxWidth: "1000px", margin: "0 auto", color: "#1d2939" }}>
            
            {/* Tour card */}
            <div style={{
              display: "flex",
              alignItems: "center",
              gap: "24px",
              background: "#ffffff",
              border: "1px solid #eaecf0",
              borderRadius: "12px",
              padding: "24px",
              boxShadow: "0 4px 16px rgba(16, 24, 40, 0.04)",
              marginBottom: "40px",
              position: "relative",
              overflow: "hidden"
            }}>
              <div style={{
                position: "relative",
                width: "140px",
                height: "85px",
                background: "#f2f4f7",
                borderRadius: "8px",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                cursor: "pointer",
                border: "1px solid #e4e7ec"
              }}>
                <div style={{
                  width: "40px",
                  height: "40px",
                  background: "#047857",
                  borderRadius: "50%",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  boxShadow: "0 2px 8px rgba(4, 120, 87, 0.3)"
                }}>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="#ffffff">
                    <path d="M8 5v14l11-7z"></path>
                  </svg>
                </div>
                {/* Small Zoho logo text */}
                <div style={{ position: "absolute", bottom: "6px", left: "8px", fontSize: "10px", fontWeight: "600", color: "#98a2b3" }}>Zoho Books</div>
              </div>
              <div>
                <h3 style={{ margin: "0 0 4px 0", fontSize: "15px", fontWeight: "600", color: "#1d2939" }}>Learn how to create a new sales order</h3>
                <p style={{ margin: 0, fontSize: "13px", color: "#667085" }}>Watch a quick 2-minute video overview of the sales order lifecycle and operations.</p>
              </div>
            </div>

            {/* Core Splash Action */}
            <div style={{ textAlign: "center", marginBottom: "60px" }}>
              <h1 style={{ fontSize: "24px", fontWeight: "600", color: "#1d2939", margin: "0 0 8px 0" }}>Start Managing Your Sales Activities!</h1>
              <p style={{ fontSize: "14px", color: "#667085", margin: "0 0 24px 0" }}>Create, customize and send professional Sales Orders.</p>
              
              <button
                onClick={() => navigate("/sales-orders/new")}
                style={{
                  padding: "12px 28px",
                  background: "#006ee6",
                  color: "#ffffff",
                  border: "none",
                  borderRadius: "6px",
                  fontSize: "14px",
                  fontWeight: "600",
                  cursor: "pointer",
                  boxShadow: "0 2px 6px rgba(0, 110, 230, 0.25)",
                  transition: "all 0.15s ease",
                }}
              >
                CREATE SALES ORDER
              </button>

              <div style={{ marginTop: "20px", display: "flex", alignItems: "center", justifyContent: "center", gap: "6px", fontSize: "13px", color: "#475569" }}>
                <span>Convert vendor purchase orders into sales orders via Bilateral Connect.</span>
                <span style={{ color: "#e28743", cursor: "pointer", fontWeight: "500", display: "flex", alignItems: "center", gap: "4px" }}>
                  Setup Now
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                    <polyline points="12 5 19 12 12 19"></polyline>
                  </svg>
                </span>
              </div>
            </div>

            {/* Lifecycle Flowchart */}
            <div style={{ marginBottom: "60px" }}>
              <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "10px", marginBottom: "32px" }}>
                <div style={{ height: "1px", background: "#eaecf0", flex: 1 }}></div>
                <h4 style={{ margin: 0, fontSize: "14px", fontWeight: "700", color: "#800020", textTransform: "uppercase", letterSpacing: "0.1em" }}>Life cycle of a Sales Order</h4>
                <div style={{ height: "1px", background: "#eaecf0", flex: 1 }}></div>
              </div>

              {/* Flowchart Diagrams Grid Layout */}
              <div style={{ display: "flex", flexDirection: "column", gap: "28px", maxWidth: "900px", margin: "0 auto" }}>
                {/* Track A */}
                <div style={{ display: "flex", alignItems: "center", flexWrap: "wrap", gap: "12px", background: "#f8fafc", padding: "16px", borderRadius: "10px", border: "1px dashed #e2e8f0" }}>
                  <div style={{ ...flowCard, background: "#eff6ff", borderColor: "#bfdbfe", color: "#1e40af" }}>
                    <div style={{ fontSize: "10px", fontWeight: "700", opacity: 0.8 }}>CUSTOMER REQUEST</div>
                  </div>
                  <div style={flowArrow}>➔</div>
                  <div style={{ ...flowCard, background: "#ffffff", borderColor: "#006ee6", color: "#006ee6" }}>
                    <div style={{ fontSize: "11px", fontWeight: "600" }}>CREATE SALES ORDER</div>
                  </div>
                  <div style={flowArrow}>➔</div>
                  <div style={{ fontSize: "11px", color: "#667085", fontStyle: "italic" }}>Convert to Open</div>
                  <div style={flowArrow}>➔</div>
                  <div style={{ ...flowCard, background: "#ffffff", borderColor: "#047857", color: "#047857" }}>
                    <div style={{ fontSize: "11px", fontWeight: "600" }}>CONFIRM ORDER</div>
                  </div>
                  <div style={flowArrow}>➔</div>
                  <div style={{ fontSize: "11px", color: "#b91c1c", fontWeight: "600" }}>Low Stock</div>
                  <div style={flowArrow}>➔</div>
                  <div style={{ ...flowCard, background: "#fff1f2", borderColor: "#fecdd3", color: "#be123c" }}>
                    <div style={{ fontSize: "10px", fontWeight: "700" }}>CREATE PURCHASE ORDER</div>
                  </div>
                </div>

                {/* Track B */}
                <div style={{ display: "flex", alignItems: "center", flexWrap: "wrap", gap: "12px", background: "#f8fafc", padding: "16px", borderRadius: "10px", border: "1px dashed #e2e8f0" }}>
                  <div style={{ ...flowCard, background: "#ecfdf5", borderColor: "#a7f3d0", color: "#065f46" }}>
                    <div style={{ fontSize: "10px", fontWeight: "700", opacity: 0.8 }}>ACCEPTED ESTIMATE</div>
                  </div>
                  <div style={flowArrow}>➔</div>
                  <div style={{ ...flowCard, background: "#ffffff", borderColor: "#006ee6", color: "#006ee6" }}>
                    <div style={{ fontSize: "11px", fontWeight: "600" }}>CREATE SALES ORDER</div>
                  </div>
                  <div style={flowArrow}>➔</div>
                  <div style={{ fontSize: "11px", color: "#667085", fontStyle: "italic" }}>Convert to Open</div>
                  <div style={flowArrow}>➔</div>
                  <div style={{ ...flowCard, background: "#ffffff", borderColor: "#047857", color: "#047857" }}>
                    <div style={{ fontSize: "11px", fontWeight: "600" }}>CONFIRM ORDER</div>
                  </div>
                  <div style={flowArrow}>➔</div>
                  <div style={{ ...flowCard, background: "#ffffff", borderColor: "#0f766e", color: "#0f766e" }}>
                    <div style={{ fontSize: "11px", fontWeight: "600" }}>CONVERT TO INVOICE</div>
                  </div>
                  <div style={flowArrow}>➔</div>
                  <div style={{ fontSize: "11px", color: "#667085", fontStyle: "italic" }}>Receive Goods</div>
                  <div style={flowArrow}>➔</div>
                  <div style={{ ...flowCard, background: "#ecfdf5", borderColor: "#a7f3d0", color: "#047857" }}>
                    <div style={{ fontSize: "11px", fontWeight: "700" }}>GET PAID ★</div>
                  </div>
                </div>
              </div>
            </div>

            {/* Checklist */}
            <div style={{ maxWidth: "600px", margin: "0 auto", background: "#fcfcfd", border: "1px solid #eaecf0", borderRadius: "8px", padding: "20px" }}>
              <h5 style={{ margin: "0 0 12px 0", fontSize: "13px", fontWeight: "700", color: "#344054", textTransform: "uppercase" }}>In the Sales Orders module, you can:</h5>
              <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
                <div style={checkRow}>
                  <span style={checkIcon}>✓</span>
                  <span style={checkText}>Create sales orders to follow up a quote or customer request.</span>
                </div>
                <div style={checkRow}>
                  <span style={checkIcon}>✓</span>
                  <span style={checkText}>Convert the sales order into a purchase order if you are low on stock.</span>
                </div>
                <div style={checkRow}>
                  <span style={checkIcon}>✓</span>
                  <span style={checkText}>Convert the sales order into an invoice if the sale goes through.</span>
                </div>
              </div>
            </div>

          </div>
          ) : (
            <table className={`items-table ${clipText ? 'clip-text' : ''}`}>
              <thead>
                <tr>
                  <th style={{ width: '50px', textAlign: 'center', resize: 'none', position: 'relative' }} className="th-icon-wrapper">
                    <span className={`th-icon ${showSettings ? 'active' : ''}`} onClick={() => setShowSettings(!showSettings)}>
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="8" cy="8" r="2"/><line x1="3" y1="8" x2="6" y2="8"/><line x1="10" y1="8" x2="21" y2="8"/><circle cx="14" cy="16" r="2"/><line x1="3" y1="16" x2="12" y2="16"/><line x1="16" y1="16" x2="21" y2="16"/></svg>
                    </span>
                    {showSettings && (
                      <div className="settings-dropdown">
                        <div className="dropdown-item" onClick={() => { setColumnsOpen(!columnsOpen); setShowSettings(false); }}>
                          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2"/><line x1="9" y1="3" x2="9" y2="21"/></svg>
                          Customize Columns
                        </div>
                        <div className="dropdown-item" onClick={() => { setClipText(!clipText); setShowSettings(false); }}>
                          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="4" y1="6" x2="20" y2="6"/><line x1="4" y1="12" x2="14" y2="12"/><line x1="4" y1="18" x2="18" y2="18"/></svg>
                          Clip Text
                        </div>
                      </div>
                    )}
                    
                    {columnsOpen && (
                      <div className="columns-dropdown" style={{ position: "absolute", left: "100%", top: 0, marginLeft: "4px", background: "#ffffff", border: "1px solid #eaecf0", borderRadius: "8px", boxShadow: "0 10px 25px rgba(0,0,0,0.08)", zIndex: 100, minWidth: "180px", padding: "8px 0" }}>
                        {ALL_COLUMNS.filter((c) => c.key !== "checkbox").map((col) => (
                          <label key={col.key} style={{ display: "flex", alignItems: "center", padding: "8px 14px", cursor: "pointer" }}>
                            <input type="checkbox" checked={visibleColumns[col.key] || false} onChange={() => setVisibleColumns((prev) => ({ ...prev, [col.key]: !prev[col.key] }))} />
                            <span style={{ marginLeft: "8px", fontSize: "13px", color: "#344054", fontWeight: 'normal', textTransform: 'none' }}>{col.label}</span>
                          </label>
                        ))}
                      </div>
                    )}
                  </th>
                  <th style={{ width: '40px', textAlign: 'center', resize: 'none' }}>
                    <input type="checkbox" style={{ accentColor: '#4a90e2', margin: 0 }} checked={selectedIds.length === sortedSOs.length && sortedSOs.length > 0} onChange={handleSelectAll} />
                  </th>
                  {ALL_COLUMNS.filter(c => c.key !== "checkbox" && visibleColumns[c.key]).map(col => (
                    <th key={col.key} style={col.key === 'total' ? { textAlign: 'right' } : {}}>{col.label.toUpperCase()}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {sortedSOs.map((s) => {
                  const isInvoiced = s.status === "invoiced";
                  return (
                  <tr key={s.id} onClick={() => navigate(`/sales-orders/${s.id}/document`)} style={{ cursor: "pointer", background: selectedIds.includes(s.id) ? "#fcfcfd" : "" }}>
                    <td style={{ textAlign: 'center' }} onClick={(e) => e.stopPropagation()}></td>
                    <td style={{ textAlign: 'center' }} onClick={(e) => e.stopPropagation()}>
                      <input type="checkbox" style={{ accentColor: '#4a90e2', margin: 0 }} checked={selectedIds.includes(s.id)} onChange={() => handleSelectOne(s.id)} />
                    </td>
                    {visibleColumns.sales_order_date && <td>{new Date(s.sales_order_date).toLocaleDateString("en-GB")}</td>}
                    {visibleColumns.sales_order_number && <td className="customer-name-link">{s.sales_order_number}</td>}
                    {visibleColumns.reference_number && <td>{s.reference_number || "—"}</td>}
                    {visibleColumns.customer_name && <td>{getCustomerName(s.customer_id)}</td>}
                    {visibleColumns.status && <td>{statusBadge(s.status)}</td>}
                    {visibleColumns.invoiced && <td style={{ textAlign: "center" }}><span style={{ width: "8px", height: "8px", borderRadius: "50%", display: "inline-block", background: isInvoiced ? "#0f766e" : "#cbd5e1" }}></span></td>}
                    {visibleColumns.payment && <td style={{ textAlign: "center" }}><span style={{ width: "8px", height: "8px", borderRadius: "50%", display: "inline-block", background: isInvoiced ? "#047857" : "#cbd5e1" }}></span></td>}
                    {visibleColumns.expected_shipment_date && <td>{s.expected_shipment_date ? new Date(s.expected_shipment_date).toLocaleDateString("en-GB") : "—"}</td>}
                    {visibleColumns.delivery_method && <td>{s.delivery_method || "—"}</td>}
                    {visibleColumns.total && <td style={{ textAlign: 'right', fontWeight: "600", color: "#1d2939" }}>₹{parseFloat(s.total).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>}
                  </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}

const flowCard = {
  padding: "8px 16px",
  borderRadius: "6px",
  border: "1px solid",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  minWidth: "120px",
  textAlign: "center",
  boxShadow: "0 1px 2px rgba(16, 24, 40, 0.05)",
};

const flowArrow = {
  color: "#98a2b3",
  fontSize: "14px",
  fontWeight: "700",
  userSelect: "none",
};

// Checklist custom styles
const checkRow = {
  display: "flex",
  alignItems: "flex-start",
  gap: "8px",
};

const checkIcon = {
  color: "#006ee6",
  fontWeight: "bold",
  fontSize: "14px",
};

const checkText = {
  fontSize: "13px",
  color: "#475569",
};

export default SalesOrders;
