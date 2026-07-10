import React, { useEffect, useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { apiRequest } from "./api";
import { TableSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";
import { ArrowLeft } from "lucide-react";

const ALL_COLUMNS = [
  { key: "payment_date", label: "Date" },
  { key: "payment_number", label: "Payment #" },
  { key: "customer_name", label: "Customer / Source" },
  { key: "reference", label: "Reference" },
  { key: "amount", label: "Amount In" },
];

function UndepositedFunds() {
  const navigate = useNavigate();
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  
  const [selectedIds, setSelectedIds] = useState([]);
  const [showSettings, setShowSettings] = useState(false);
  const [clipText, setClipText] = useState(true);
  const [columnsOpen, setColumnsOpen] = useState(false);
  const [visibleColumns, setVisibleColumns] = useState(
    ALL_COLUMNS.reduce((acc, col) => ({ ...acc, [col.key]: true }), {})
  );

  useEffect(() => {
    const h = (e) => {
      if (!e.target.closest('.th-icon-wrapper') && !e.target.closest('.settings-dropdown') && !e.target.closest('.columns-dropdown')) {
        setShowSettings(false);
        setColumnsOpen(false);
      }
    };
    document.addEventListener('click', h);
    return () => document.removeEventListener('click', h);
  }, []);

  const fetchData = useCallback(async () => {
    try {
      setLoading(true);
      const res = await apiRequest("/payments");
      const filtered = (res?.payments || []).filter(p => p.deposit_to === "Undeposited Funds");
      setPayments(filtered);
    } catch (err) {
      toast.error("Failed to load undeposited funds ledger");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const filteredPayments = payments.filter((p) => {
    const term = search.toLowerCase();
    const custName = p.customer_name?.toLowerCase() || "";
    const invNum = p.invoice_number?.toLowerCase() || "";
    const ref = p.reference?.toLowerCase() || "";
    return search === "" || custName.includes(term) || invNum.includes(term) || ref.includes(term);
  });

  const totalBalance = filteredPayments.reduce((acc, curr) => acc + parseFloat(curr.amount || 0), 0);

  const handleSelectAll = (e) => {
    if (e.target.checked) setSelectedIds(filteredPayments.map(p => p.id));
    else setSelectedIds([]);
  };

  const handleSelectOne = (id) => {
    setSelectedIds(prev => prev.includes(id) ? prev.filter(pid => pid !== id) : [...prev, id]);
  };

  return (
    <div style={{ background: "#f8fafc", minHeight: "100vh", fontFamily: "system-ui, -apple-system, sans-serif", color: "#1d2939" }}>
      <style>{`
        .items-table { width: 100%; border-collapse: collapse; font-size: 13px; table-layout: fixed; }
        .items-table th { text-align: left; padding: 12px 15px; color: #64748b; font-weight: 600; border-bottom: 1px solid #e2e8f0; background: #ffffff; text-transform: uppercase; font-size: 11px; letter-spacing: 0.5px; white-space: nowrap; resize: horizontal; overflow: hidden; text-overflow: ellipsis; }
        .items-table td { padding: 14px 15px; border-bottom: 1px solid #e2e8f0; color: #334155; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .items-table tr:hover { background: #f1f5f9; }
        .th-icon-wrapper { overflow: visible !important; }
        .th-icon { display: inline-flex; align-items: center; justify-content: center; color: #aaa; cursor: pointer; transition: color 0.2s; }
        .th-icon:hover, .th-icon.active { color: #007bff; }
        .settings-dropdown { position: absolute; top: 30px; left: 10px; background: #fff; border: 1px solid #e0e0e0; border-radius: 6px; box-shadow: 0 4px 12px rgba(0,0,0,0.1); z-index: 1000; width: 180px; padding: 6px; font-size: 13px; text-transform: none; font-weight: 500; text-align: left; letter-spacing: normal; }
        .dropdown-item { padding: 8px 12px; display: flex; align-items: center; justify-content: flex-start; gap: 10px; border-radius: 4px; cursor: pointer; color: #334155; transition: background 0.2s; }
        .dropdown-item:hover { background: #f1f5f9; color: #0f172a; }
        .dropdown-item svg { width: 16px; height: 16px; min-width: 16px; color: #64748b; }
        .items-table.clip-text td { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
      `}</style>
      <div className="full-table-container" style={{ background: "#fff", display: "flex", flexDirection: "column", height: "100%", minHeight: "calc(100vh - 60px)" }}>
        <div style={{ padding: "15px 30px", borderBottom: "1px solid #eaeaea", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            <button onClick={() => navigate("/dashboard")} style={{ background: "none", border: "none", cursor: "pointer", color: "#64748b", display: "flex", alignItems: "center" }}>
              <ArrowLeft size={20} />
            </button>
            <h3 style={{ margin: 0, fontWeight: 600, fontSize: "18px" }}>Undeposited Funds Ledger</h3>
          </div>
          <div style={{ background: "#eff6ff", color: "#1e40af", padding: "8px 16px", borderRadius: "8px", fontWeight: "600", border: "1px solid #bfdbfe" }}>
            Total Balance: ₹{totalBalance.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </div>
        </div>

        <div style={{ padding: "12px 30px", borderBottom: "1px solid #eaeaea", background: "#fdfdfd" }}>
          <div style={{ position: "relative", width: "100%", maxWidth: "400px" }}>
            <span style={{ position: "absolute", left: "14px", top: "50%", transform: "translateY(-50%)", color: "#98a2b3" }}>🔍</span>
            <input
              type="text"
              placeholder="Search undeposited funds transactions..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              style={{ width: "100%", padding: "10px 12px 10px 42px", borderRadius: "6px", border: "1px solid #d0d5dd", outline: "none", fontSize: "13px", boxSizing: "border-box" }}
            />
          </div>
        </div>
        
        {selectedIds.length > 0 && (
          <div style={{ background: "#f0f6ff", border: "1px solid #bae6fd", borderRadius: "8px", padding: "12px 16px", display: "flex", alignItems: "center", gap: "16px", margin: "20px 30px 0" }}>
            <span style={{ color: "#0369a1", fontWeight: "600", fontSize: "13px" }}>{selectedIds.length} item(s) selected</span>
            <button onClick={() => setSelectedIds([])} style={{ background: "none", border: "none", color: "#475569", cursor: "pointer", fontSize: "12px", textDecoration: "underline" }}>Clear Selection</button>
          </div>
        )}

        <div style={{ flex: 1, overflow: "auto" }}>
          {loading ? (
            <div style={{ padding: "20px" }}><TableSkeleton rows={5} columns={5} /></div>
          ) : filteredPayments.length === 0 ? (
            <div style={{ textAlign: "center", padding: "60px", color: "#667085", background: "#f9fafb", borderRadius: "8px", margin: "24px", border: "1px dashed #d0d5dd" }}>
              <p style={{ margin: "0 0 16px 0", fontSize: "14px" }}>No transactions found for Undeposited Funds.</p>
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
                        {ALL_COLUMNS.map((col) => (
                          <label key={col.key} style={{ display: "flex", alignItems: "center", padding: "8px 14px", cursor: "pointer" }}>
                            <input type="checkbox" checked={visibleColumns[col.key] || false} onChange={() => setVisibleColumns((prev) => ({ ...prev, [col.key]: !prev[col.key] }))} />
                            <span style={{ marginLeft: "8px", fontSize: "13px", color: "#344054", fontWeight: 'normal', textTransform: 'none' }}>{col.label}</span>
                          </label>
                        ))}
                      </div>
                    )}
                  </th>
                  <th style={{ width: '40px', textAlign: 'center', resize: 'none' }}>
                    <input type="checkbox" style={{ accentColor: '#4a90e2', margin: 0 }} checked={selectedIds.length === filteredPayments.length && filteredPayments.length > 0} onChange={handleSelectAll} />
                  </th>
                  {ALL_COLUMNS.filter(c => visibleColumns[c.key]).map(col => (
                    <th key={col.key} style={col.key === 'amount' ? { textAlign: 'right' } : {}}>{col.label.toUpperCase()}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {filteredPayments.map(payment => (
                  <tr key={payment.id} onClick={() => navigate(`/payments-received/${payment.id}`)} style={{ cursor: "pointer", background: selectedIds.includes(payment.id) ? "#fcfcfd" : "" }}>
                    <td style={{ textAlign: 'center' }} onClick={(e) => e.stopPropagation()}></td>
                    <td style={{ textAlign: 'center' }} onClick={(e) => e.stopPropagation()}>
                      <input type="checkbox" style={{ accentColor: '#4a90e2', margin: 0 }} checked={selectedIds.includes(payment.id)} onChange={() => handleSelectOne(payment.id)} />
                    </td>
                    {visibleColumns.payment_date && <td>{payment.payment_date ? new Date(payment.payment_date).toLocaleDateString("en-GB") : "—"}</td>}
                    {visibleColumns.payment_number && <td style={{ color: "#2563eb", fontWeight: "500" }}>{payment.id || "—"}</td>}
                    {visibleColumns.customer_name && <td style={{ color: "#344054" }}>{payment.customer_name || "—"}</td>}
                    {visibleColumns.reference && <td>{payment.reference || "—"}</td>}
                    {visibleColumns.amount && <td style={{ textAlign: "right", fontWeight: "600", color: "#3b82f6" }}>+ ₹{parseFloat(payment.amount || 0).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>}
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

export default UndepositedFunds;
