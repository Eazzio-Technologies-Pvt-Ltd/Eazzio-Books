/**
 * ChartOfAccounts.js – Modernized Zoho-style Chart of Accounts management
 */
import React, { useState, useEffect } from "react";
import { apiRequest } from "./api";
import { TableSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

function ChartOfAccounts() {
  const [accounts, setAccounts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [typeFilter, setTypeFilter] = useState("All");
  const [statusFilter, setStatusFilter] = useState("All");

  // Modal State
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState(null);
  
  // Form State
  const [accountName, setAccountName] = useState("");
  const [accountCode, setAccountCode] = useState("");
  const [accountType, setAccountType] = useState("Asset");
  const [openingBalance, setOpeningBalance] = useState("0");
  const [description, setDescription] = useState("");
  const [status, setStatus] = useState("active");

  useEffect(() => {
    fetchAccounts();
  }, []);

  const fetchAccounts = async () => {
    try {
      setLoading(true);
      const res = await apiRequest("/accounting/coa");
      setAccounts(res?.accounts || []);
    } catch (err) {
      toast.error("Failed to load accounts");
    } finally {
      setLoading(false);
    }
  };

  const handleOpenModal = (account = null) => {
    if (account) {
      setEditingId(account.id);
      setAccountName(account.account_name);
      setAccountCode(account.account_code || "");
      setAccountType(account.account_type);
      setOpeningBalance(account.opening_balance || "0");
      setDescription(account.description || "");
      setStatus(account.status || "active");
    } else {
      setEditingId(null);
      setAccountName("");
      setAccountCode("");
      setAccountType("Asset");
      setOpeningBalance("0");
      setDescription("");
      setStatus("active");
    }
    setShowModal(true);
  };

  const handleSave = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        account_name: accountName,
        account_code: accountCode,
        account_type: accountType,
        opening_balance: parseFloat(openingBalance) || 0,
        description,
        status
      };

      if (editingId) {
        await apiRequest(`/accounting/coa/${editingId}`, {
          method: "PUT",
          body: JSON.stringify(payload)
        });
        toast.success("Account updated");
      } else {
        await apiRequest("/accounting/coa", {
          method: "POST",
          body: JSON.stringify(payload)
        });
        toast.success("Account created");
      }
      setShowModal(false);
      fetchAccounts();
    } catch (err) {
      toast.error("Failed to save account");
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Are you sure you want to delete this account?")) return;
    try {
      await apiRequest(`/accounting/coa/${id}`, { method: "DELETE" });
      toast.success("Account deleted");
      fetchAccounts();
    } catch (err) {
      toast.error("Failed to delete account");
    }
  };

  const filteredAccounts = accounts.filter(acc => {
    const matchesSearch = (acc.account_name?.toLowerCase().includes(search.toLowerCase())) || 
                          (acc.account_code?.toLowerCase().includes(search.toLowerCase()));
    const matchesType = typeFilter === "All" || acc.account_type === typeFilter;
    const matchesStatus = statusFilter === "All" || acc.status === statusFilter;
    return matchesSearch && matchesType && matchesStatus;
  });

  const labelStyle = { display: "block", marginBottom: "6px", fontSize: "13px", fontWeight: "500", color: "#344054" };
  const thStyle = { padding: "12px 18px", color: "#475569", fontWeight: "600", fontSize: "12px", borderBottom: "1px solid #eaecf0", letterSpacing: "0.02em" };
  const tdStyle = { padding: "14px 18px", verticalAlign: "middle", borderBottom: "1px solid #eaecf0" };

  return (
    <div style={{ padding: "30px", maxWidth: "1200px", margin: "auto", fontFamily: "system-ui, -apple-system, sans-serif" }}>
      
      {/* Dynamic Style Injection */}
      <style dangerouslySetInnerHTML={{__html: `
        .premium-input {
          width: 100%;
          padding: 10px 14px;
          border: 1px solid #d0d5dd;
          border-radius: 6px;
          font-size: 13px;
          color: #344054;
          background: #ffffff;
          box-sizing: border-box;
          outline: none;
          transition: all 0.15s ease;
        }
        .premium-input:hover { border-color: #98a2b3; }
        .premium-input:focus { border-color: #006ee6; box-shadow: 0 0 0 3px rgba(0, 110, 230, 0.1); }
        
        select.premium-input {
          appearance: none;
          background-image: url("data:image/svg+xml;charset=utf-8,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3E%3Cpath stroke='%23667085' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3E%3C/svg%3E");
          background-position: right 12px center;
          background-repeat: no-repeat;
          background-size: 18px;
          padding-right: 36px;
        }
        
        .action-link {
          background: none;
          border: none;
          color: #006ee6;
          cursor: pointer;
          font-weight: 600;
          font-size: 13px;
          padding: 0;
          transition: color 0.15s ease;
        }
        .action-link:hover { color: #0056b3; text-decoration: underline; }
        
        .delete-link {
          background: none;
          border: none;
          color: #d92d20;
          cursor: pointer;
          font-weight: 600;
          font-size: 13px;
          padding: 0;
          margin-left: 12px;
          transition: color 0.15s ease;
        }
        .delete-link:hover { color: #b91c1c; text-decoration: underline; }
        
        .status-pill-active {
          padding: 4px 10px;
          background: #d1fae5;
          color: #065f46;
          border-radius: 12px;
          font-size: 12px;
          font-weight: 600;
          display: inline-block;
        }
        .status-pill-inactive {
          padding: 4px 10px;
          background: #f1f5f9;
          color: #475569;
          border-radius: 12px;
          font-size: 12px;
          font-weight: 600;
          display: inline-block;
        }
        .primary-btn {
          padding: 10px 18px;
          background: #006ee6;
          color: #ffffff;
          border: none;
          border-radius: 6px;
          cursor: pointer;
          font-weight: 600;
          font-size: 13px;
          transition: background 0.15s ease;
        }
        .primary-btn:hover { background: #0056b3; }
        
        .secondary-btn {
          padding: 10px 18px;
          background: #ffffff;
          color: #344054;
          border: 1px solid #d0d5dd;
          border-radius: 6px;
          cursor: pointer;
          font-weight: 600;
          font-size: 13px;
          transition: all 0.15s ease;
        }
        .secondary-btn:hover { background: #f9fafb; border-color: #98a2b3; }
      `}} />

      {/* Header section */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "24px" }}>
        <div>
          <h2 style={{ margin: 0, fontSize: "24px", fontWeight: "700", color: "#1d2939" }}>Chart of Accounts</h2>
          <p style={{ margin: "4px 0 0 0", fontSize: "14px", color: "#667085" }}>Manage your ledger accounts, types, and opening balances.</p>
        </div>
        <button onClick={() => handleOpenModal()} className="primary-btn">+ New Account</button>
      </div>

      {/* Filters Bar */}
      <div style={{ display: "flex", gap: "16px", marginBottom: "24px", background: "#ffffff", padding: "18px 24px", borderRadius: "10px", border: "1px solid #eaecf0", boxShadow: "0 1px 3px rgba(16, 24, 40, 0.05)", alignItems: "center" }}>
        <div style={{ position: "relative", flex: 1, maxWidth: "320px" }}>
          <input 
            type="text" 
            placeholder="Search by name or code..." 
            value={search} 
            onChange={e => setSearch(e.target.value)} 
            className="premium-input"
            style={{ paddingLeft: "14px" }}
          />
        </div>
        <select value={typeFilter} onChange={e => setTypeFilter(e.target.value)} className="premium-input" style={{ maxWidth: "160px", cursor: "pointer" }}>
          <option value="All">All Types</option>
          <option value="Asset">Asset</option>
          <option value="Liability">Liability</option>
          <option value="Equity">Equity</option>
          <option value="Income">Income</option>
          <option value="Expense">Expense</option>
        </select>
        <select value={statusFilter} onChange={e => setStatusFilter(e.target.value)} className="premium-input" style={{ maxWidth: "160px", cursor: "pointer" }}>
          <option value="All">All Statuses</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>
      </div>

      {/* Table Container */}
      {loading ? (
        <TableSkeleton columns={7} rows={6} />
      ) : accounts.length === 0 ? (
        <div style={{ textAlign: "center", padding: "50px", color: "#667085", background: "#f9fafb", borderRadius: "8px", border: "1px solid #eaecf0" }}>
          <p style={{ margin: 0, fontSize: "14px" }}>No accounts found. Start by creating a new account.</p>
        </div>
      ) : (
        <div style={{ border: "1px solid #eaecf0", borderRadius: "10px", overflow: "hidden", boxShadow: "0 1px 3px rgba(16, 24, 40, 0.05)", background: "#ffffff" }}>
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "13px", textAlign: "left" }}>
            <thead>
              <tr style={{ background: "#f9fafb" }}>
                <th style={thStyle}>Code</th>
                <th style={thStyle}>Account Name</th>
                <th style={thStyle}>Type</th>
                <th style={thStyle}>Description</th>
                <th style={{ ...thStyle, textAlign: "right" }}>Balance</th>
                <th style={thStyle}>Status</th>
                <th style={thStyle}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredAccounts.length > 0 ? filteredAccounts.map(acc => (
                <tr key={acc.id} style={{ transition: "background 0.2s" }} onMouseOver={e => e.currentTarget.style.background = "#f9fafb"} onMouseOut={e => e.currentTarget.style.background = "transparent"}>
                  <td style={{ ...tdStyle, color: "#475569", fontWeight: "500" }}>{acc.account_code || "—"}</td>
                  <td style={{ ...tdStyle, fontWeight: "600", color: "#1d2939" }}>{acc.account_name}</td>
                  <td style={{ ...tdStyle, color: "#475569" }}>{acc.account_type}</td>
                  <td style={{ ...tdStyle, color: "#667085" }}>{acc.description || "—"}</td>
                  <td style={{ ...tdStyle, textAlign: "right", fontWeight: "700", color: "#1d2939" }}>
                    ₹{parseFloat(acc.current_balance || acc.opening_balance || 0).toFixed(2)}
                  </td>
                  <td style={tdStyle}>
                    <span className={acc.status === 'active' ? "status-pill-active" : "status-pill-inactive"}>
                      {acc.status === 'active' ? "Active" : "Inactive"}
                    </span>
                  </td>
                  <td style={tdStyle}>
                    <button onClick={() => handleOpenModal(acc)} className="action-link">Edit</button>
                    <button onClick={() => handleDelete(acc.id)} className="delete-link">Delete</button>
                  </td>
                </tr>
              )) : (
                <tr>
                  <td colSpan={7} style={{ textAlign: "center", padding: "30px", color: "#667085", fontStyle: "italic" }}>
                    No accounts match your filters.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal Dialog */}
      {showModal && (
        <div style={{ position: "fixed", top: 0, left: 0, width: "100%", height: "100%", background: "rgba(16, 24, 40, 0.4)", backdropFilter: "blur(4px)", display: "flex", justifyContent: "center", alignItems: "center", zIndex: 1000 }}>
          <div style={{ background: "#ffffff", padding: "32px", borderRadius: "12px", width: "100%", maxWidth: "580px", boxShadow: "0 20px 24px -4px rgba(16, 24, 40, 0.08), 0 8px 8px -4px rgba(16, 24, 40, 0.03)", border: "1px solid #eaecf0", overflow: "hidden" }}>
            <h3 style={{ margin: "0 0 4px 0", fontSize: "18px", fontWeight: "700", color: "#1d2939" }}>
              {editingId ? "Edit Account" : "New Account"}
            </h3>
            <p style={{ margin: "0 0 24px 0", fontSize: "14px", color: "#667085" }}>
              {editingId ? "Update ledger account details" : "Add a new ledger account to your chart of accounts."}
            </p>
            <form onSubmit={handleSave}>
              <div style={{ display: "grid", gridTemplateColumns: "1.2fr 0.8fr", gap: "16px", marginBottom: "16px" }}>
                <div>
                  <label style={labelStyle}>Account Name *</label>
                  <input type="text" value={accountName} onChange={e => setAccountName(e.target.value)} className="premium-input" placeholder="e.g. Sales Income" required />
                </div>
                <div>
                  <label style={labelStyle}>Account Code</label>
                  <input type="text" value={accountCode} onChange={e => setAccountCode(e.target.value)} className="premium-input" placeholder="e.g. 4000" />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px", marginBottom: "16px" }}>
                <div>
                  <label style={labelStyle}>Account Type *</label>
                  <select value={accountType} onChange={e => setAccountType(e.target.value)} className="premium-input" style={{ cursor: "pointer" }} required>
                    <option value="Asset">Asset</option>
                    <option value="Liability">Liability</option>
                    <option value="Equity">Equity</option>
                    <option value="Income">Income</option>
                    <option value="Expense">Expense</option>
                  </select>
                </div>
                <div>
                  <label style={labelStyle}>Opening Balance (₹)</label>
                  <input type="number" step="0.01" value={openingBalance} onChange={e => setOpeningBalance(e.target.value)} disabled={!!editingId} style={editingId ? { background: "#f9fafb", cursor: "not-allowed" } : {}} className="premium-input" placeholder="0.00" />
                </div>
              </div>

              <div style={{ marginBottom: "16px" }}>
                <label style={labelStyle}>Description</label>
                <textarea value={description} onChange={e => setDescription(e.target.value)} rows={3} className="premium-input" placeholder="Enter account description..." style={{ resize: "none" }}></textarea>
              </div>

              <div style={{ marginBottom: "24px" }}>
                <label style={labelStyle}>Status</label>
                <div style={{ display: "flex", gap: "20px", alignItems: "center" }}>
                  <label style={{ display: "flex", alignItems: "center", gap: "8px", fontSize: "14px", color: "#344054", cursor: "pointer" }}>
                    <input type="radio" value="active" checked={status === "active"} onChange={e => setStatus(e.target.value)} style={{ width: "16px", height: "16px", cursor: "pointer", accentColor: "#006ee6" }} /> 
                    Active
                  </label>
                  <label style={{ display: "flex", alignItems: "center", gap: "8px", fontSize: "14px", color: "#344054", cursor: "pointer" }}>
                    <input type="radio" value="inactive" checked={status === "inactive"} onChange={e => setStatus(e.target.value)} style={{ width: "16px", height: "16px", cursor: "pointer", accentColor: "#006ee6" }} /> 
                    Inactive
                  </label>
                </div>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "12px", borderTop: "1px solid #eaecf0", padding: "16px 32px", margin: "24px -32px -32px -32px", background: "#f9fafb", borderBottomLeftRadius: "12px", borderBottomRightRadius: "12px" }}>
                <button type="button" onClick={() => setShowModal(false)} className="secondary-btn">Cancel</button>
                <button type="submit" className="primary-btn">Save Account</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default ChartOfAccounts;
