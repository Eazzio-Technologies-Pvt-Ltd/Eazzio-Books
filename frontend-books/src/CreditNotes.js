/**
 * CreditNotes.js – Redesigned list view matching Quotes UI
 */
import React, { useEffect, useState, useCallback } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { apiRequest } from "./api";
import { TableSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";
import { useAuth } from "./AuthContext";
const STATUS_COLORS = {
  draft:     { bg: "#f1f5f9", color: "#475569", label: "DRAFT" },
  open:      { bg: "#eff6ff", color: "#1d4ed8", label: "OPEN" },
  applied:   { bg: "#ecfdf5", color: "#047857", label: "APPLIED" },
  cancelled: { bg: "#fef2f2", color: "#b91c1c", label: "CANCELLED" },
};

const ALL_COLUMNS = [
  { key: "checkbox", label: "☐" },

  { key: "credit_note_date", label: "Date" },
  { key: "credit_note_number", label: "Credit Note Number" },
  { key: "reference_number", label: "Reference Number" },
  { key: "customer_name", label: "Customer Name" },
  { key: "status", label: "Status" },
  { key: "total", label: "Amount" },
  { key: "remaining_amount", label: "Remaining Amount" },

];

function CreditNotes() {
  const navigate = useNavigate();
  const location = useLocation();
  const { user } = useAuth();

  const [creditNotes, setCreditNotes] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [favoriteView, setFavoriteView] = useState(() => localStorage.getItem("favCreditNotesView") || null);
  const [statusDropdownOpen, setStatusDropdownOpen] = useState(false);
  const [filterSearch, setFilterSearch] = useState("");
  const [selectedIds, setSelectedIds] = useState([]);

  // Dropdown & Sorting States
  const [moreMenuOpen, setMoreMenuOpen] = useState(false);
  const [sortSubMenuOpen, setSortSubMenuOpen] = useState(false);
  const [exportSubMenuOpen, setExportSubMenuOpen] = useState(false);
  const [sortBy, setSortBy] = useState("credit_note_date");
  const [sortOrder, setSortOrder] = useState("desc");
  
  const [showSettings, setShowSettings] = useState(false);
  const [clipText, setClipText] = useState(true);
  const [columnsOpen, setColumnsOpen] = useState(false);
  const [visibleColumns, setVisibleColumns] = useState(
    ALL_COLUMNS.reduce((acc, col) => {
      acc[col.key] = true;
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
      const [dataRes, customersRes] = await Promise.all([
        apiRequest("/credit-notes"),
        apiRequest("/customers"),
      ]);
      setCreditNotes(Array.isArray(dataRes?.credit_notes) ? dataRes.credit_notes : []);
      setCustomers(Array.isArray(customersRes?.customers) ? customersRes.customers : []);
    } catch (err) {
      toast.error("Failed to load data");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData, location.state?.refresh]);

  useEffect(() => {
    const fav = localStorage.getItem("favCreditNotesView");
    if (fav) {
      setStatusFilter(fav);
    }
  }, []);

  const getCustomerName = (customerId) => {
    if (!customerId) return "—";
    const cust = customers.find((c) => String(c.id) === String(customerId));
    return cust
      ? cust.display_name ||
          [cust.first_name, cust.last_name].filter(Boolean).join(" ") ||
          cust.email
      : "—";
  };

  const filteredData = creditNotes.filter((q) => {
    const searchTerms = [
      q.credit_note_number || "",
      q.reference_number || "",
      q.profile_name || "",
      getCustomerName(q.customer_id)
    ].join(" ").toLowerCase();
    
    const matchSearch = search === "" || searchTerms.includes(search.toLowerCase());
    const matchStatus = statusFilter === "all" || q.status?.toLowerCase() === statusFilter.toLowerCase();
    return matchSearch && matchStatus;
  });

  const sortedData = [...filteredData].sort((a, b) => {
    let aVal = a[sortBy];
    let bVal = b[sortBy];

    if (sortBy === "customer_name") {
      aVal = getCustomerName(a.customer_id).toLowerCase();
      bVal = getCustomerName(b.customer_id).toLowerCase();
    } else if (sortBy === "total" || sortBy === "amount") {
      aVal = parseFloat(a.total) || 0;
      bVal = parseFloat(b.total) || 0;
    } else if (sortBy.includes("date")) {
      aVal = new Date(a[sortBy]).getTime();
      bVal = new Date(b[sortBy]).getTime();
    } else if (typeof aVal === "string") {
      aVal = aVal.toLowerCase();
      bVal = (bVal || "").toLowerCase();
    }

    if (aVal < bVal) return sortOrder === "asc" ? -1 : 1;
    if (aVal > bVal) return sortOrder === "asc" ? 1 : -1;
    return 0;
  });

  const handleSelectAll = (e) => {
    if (e.target.checked) {
      setSelectedIds(sortedData.map((q) => q.id));
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
    if (!window.confirm(`Delete the ${selectedIds.length} selected item(s)?`)) return;
    try {
      await Promise.all(
        selectedIds.map((id) => apiRequest(`/credit-notes/${id}`, { method: "DELETE" }))
      );
      toast.success("Deleted successfully");
      setSelectedIds([]);
      fetchData();
    } catch (err) { toast.error(err.message || "Delete failed"); }
  };

  const statusBadge = (status) => {
    const s = status ? status.toLowerCase() : "draft";
    const colors = STATUS_COLORS[s] || STATUS_COLORS.draft || { bg: "#f1f5f9", color: "#475569", label: "DRAFT" };
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
        textTransform: "uppercase"
      }}>
        {colors.label || "DRAFT"}
      </span>
    );
  };

  const allViews = [
  { key: "all", label: "All Credit Notes" },
  { key: "draft", label: "Draft" },
  { key: "open", label: "Open" },
  { key: "applied", label: "Applied" },
  { key: "cancelled", label: "Cancelled" }
];
  const filteredViews = allViews.filter(v => v.label.toLowerCase().includes(filterSearch.toLowerCase()));

  return (
    <div style={{ background: "#f8fafc", minHeight: "100vh", fontFamily: "system-ui, -apple-system, sans-serif", color: "#1d2939" }}>
      <style>{`
        .premium-input { border: 1px solid #d0d5dd; transition: border-color 0.15s ease, box-shadow 0.15s ease; }
        .premium-input:focus { border-color: #006ee6 !important; box-shadow: 0 0 0 4px rgba(0, 110, 230, 0.12) !important; }
        .full-table-container { background: #fff; display: flex; flex-direction: column; height: 100%; min-height: calc(100vh - 60px); margin: 0; font-family: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
        .full-table-header { padding: 15px 30px; border-bottom: 1px solid #eaeaea; display: flex; justify-content: space-between; align-items: center; }
        .table-actions { display: flex; gap: 10px; }
        .btn-new { background: #3b82f6; color: white; border: none; padding: 8px 16px; border-radius: 4px; font-size: 14px; cursor: pointer; display: flex; align-items: center; gap: 5px; font-weight: 500; }
        .btn-new:hover { background: #2563eb; }
        .btn-more { background: #f5f5f5; border: 1px solid #ddd; color: #555; border-radius: 4px; padding: 6px 12px; cursor: pointer; font-weight: bold; display: flex; align-items: center; justify-content: center; }
        .table-wrapper { flex: 1; overflow: auto; }
        .items-table { width: 100%; border-collapse: collapse; font-size: 13px; table-layout: fixed; }
        .items-table th { text-align: left; padding: 12px 15px; color: #64748b; font-weight: 600; border-bottom: 1px solid #e2e8f0; background: #ffffff; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; white-space: nowrap; resize: horizontal; overflow: hidden; text-overflow: ellipsis; }
        .items-table td { padding: 14px 15px; border-bottom: 1px solid #f8fafc; color: #334155; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .items-table tr:hover { background: #f1f5f9; }
        .customer-name-link { color: #2563eb; cursor: pointer; font-weight: 500; }
        .customer-name-link:hover { text-decoration: underline; }
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
        <div className="full-table-header">
          <div className="view-dropdown-container">
            <h3 className={`view-dropdown-btn ${statusDropdownOpen ? 'active' : ''}`} onClick={() => setStatusDropdownOpen(!statusDropdownOpen)} style={{ fontWeight: 600 }}>
              {allViews.find(v => v.key === statusFilter)?.label || "All"}
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
                        <span onClick={(e) => { e.stopPropagation(); const newFav = isFav ? null : view.key; setFavoriteView(newFav); if (newFav) { localStorage.setItem("favCreditNotesView", newFav); toast.success(`"${view.label}" set as default view`); } else { localStorage.removeItem("favCreditNotesView"); toast.success("Default view cleared"); } }} style={{ color: isFav ? "#f59e0b" : "#d0d5dd", fontSize: "14px", padding: "2px 6px" }}>{isFav ? "★" : "☆"}</span>
                      </div>
                    );
                  })
                )}
              </div>
            )}
          </div>
          
          <div className="table-actions">
            <button className="btn-new" onClick={() => navigate("/credit-notes/new")}>
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
                                            <div className="more-dropdown-item" onClick={() => { setSortBy("credit_note_date"); setSortOrder("desc"); setMoreMenuOpen(false); }}><span>Date (Newest first)</span></div>
                      <div className="more-dropdown-item" onClick={() => { setSortBy("credit_note_number"); setSortOrder("asc"); setMoreMenuOpen(false); }}><span>Credit Note Number (A-Z)</span></div>
                      <div className="more-dropdown-item" onClick={() => { setSortBy("customer_name"); setSortOrder("asc"); setMoreMenuOpen(false); }}><span>Customer Name (A-Z)</span></div>
                      <div className="more-dropdown-item" onClick={() => { setSortBy("total"); setSortOrder("desc"); setMoreMenuOpen(false); }}><span>Amount (High to Low)</span></div>

                    </div>
                  </div>
                  <div className="more-dropdown-item" onClick={() => { setMoreMenuOpen(false); toast("Import functionality coming soon"); }}>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3"/></svg>
                    <span>Import CreditNotes</span>
                  </div>
                  <div className="more-dropdown-item">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M17 8l-5-5-5 5M12 3v12"/></svg>
                    <span>Export CreditNotes</span>
                    <svg className="chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="9 18 15 12 9 6"/></svg>
                    <div className="nested-dropdown-menu">
                      <div className="more-dropdown-item" onClick={() => { toast("Exported CSV"); setMoreMenuOpen(false); }}><span>Export as CSV</span></div>
                      <div className="more-dropdown-item" onClick={() => { toast("Exported JSON"); setMoreMenuOpen(false); }}><span>Export as JSON</span></div>
                    </div>
                  </div>
                  <div className="more-dropdown-divider"></div>
                  <div className="more-dropdown-item" onClick={() => { fetchData(); setMoreMenuOpen(false); }}>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2"/></svg>
                    <span>Refresh List</span>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        <div style={{ padding: "12px 30px", borderBottom: "1px solid #eaeaea", background: "#fdfdfd" }}>
          <div style={{ position: "relative", width: "100%", maxWidth: "400px" }}>
            <span style={{ position: "absolute", left: "14px", top: "50%", transform: "translateY(-50%)", color: "#98a2b3" }}>🔍</span>
            <input
              type="text"
              placeholder="Search..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{ width: "100%", padding: "10px 12px 10px 42px", borderRadius: "6px", border: "1px solid #d0d5dd", outline: "none", fontSize: "13px", boxSizing: "border-box" }}
              className="premium-input"
            />
          </div>
        </div>

        {selectedIds.length > 0 && (
          <div style={{ background: "#f0f6ff", border: "1px solid #bae6fd", borderRadius: "8px", padding: "12px 16px", display: "flex", alignItems: "center", gap: "16px", margin: "20px 30px 0" }}>
            <span style={{ color: "#0369a1", fontWeight: "600", fontSize: "13px" }}>{selectedIds.length} item(s) selected</span>
            <button onClick={handleDeleteSelected} style={{ background: "#d92d20", color: "#ffffff", border: "none", borderRadius: "6px", padding: "6px 12px", cursor: "pointer", fontSize: "12px", fontWeight: "600" }}>Delete Selected</button>
            <button onClick={() => setSelectedIds([])} style={{ background: "none", border: "none", color: "#475569", cursor: "pointer", fontSize: "12px", textDecoration: "underline" }}>Cancel</button>
          </div>
        )}

        <div className="table-wrapper">
          {loading ? (
            <TableSkeleton rows={8} columns={6} />
          ) : filteredData.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '80px 20px', color: '#98a2b3' }}>
              <div style={{ fontSize: '48px', marginBottom: '16px' }}>📄</div>
              <h3 style={{ color: '#1d2939', marginBottom: '8px', fontSize: "16px", fontWeight: "600" }}>No items found</h3>
              <p style={{ marginBottom: '20px', fontSize: "13px" }}>{search ? 'No items match your search.' : 'Start by creating your first item.'}</p>
              <button className="btn-new" onClick={() => navigate('/credit-notes/new')} style={{ margin: "0 auto" }}>+ New Item</button>
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
                    <input type="checkbox" style={{ accentColor: '#4a90e2', margin: 0 }} checked={selectedIds.length === sortedData.length && sortedData.length > 0} onChange={handleSelectAll} />
                  </th>
                  {ALL_COLUMNS.filter(c => c.key !== "checkbox" && visibleColumns[c.key]).map(col => (
                    <th key={col.key} style={col.key.includes('amount') || col.key.includes('total') ? { textAlign: 'right' } : {}}>{col.label.toUpperCase()}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {sortedData.map((q) => (
                  <tr key={q.id} onClick={() => navigate(`/credit-notes/${q.id}`)} style={{ cursor: "pointer", background: selectedIds.includes(q.id) ? "#fcfcfd" : "" }}>
                    <td style={{ textAlign: 'center' }} onClick={(e) => e.stopPropagation()}></td>
                    <td style={{ textAlign: 'center' }} onClick={(e) => e.stopPropagation()}>
                      <input type="checkbox" style={{ accentColor: '#4a90e2', margin: 0 }} checked={selectedIds.includes(q.id)} onChange={() => handleSelectOne(q.id)} />
                    </td>

                    {visibleColumns.credit_note_date && <td>{new Date(q.credit_note_date).toLocaleDateString("en-GB")}</td>}
                    {visibleColumns.credit_note_number && <td className="customer-name-link">{q.credit_note_number}</td>}
                    {visibleColumns.reference_number && <td>{q.reference_number || "—"}</td>}
                    {visibleColumns.customer_name && <td>{getCustomerName(q.customer_id)}</td>}
                    {visibleColumns.status && <td>{statusBadge(q.status)}</td>}
                    {visibleColumns.total && <td style={{ textAlign: 'right', fontWeight: "600", color: "#1d2939" }}>₹{parseFloat(q.total).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>}
                    {visibleColumns.remaining_amount && <td style={{ textAlign: 'right' }}>₹{parseFloat(q.remaining_amount).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>}

                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}

export default CreditNotes;
