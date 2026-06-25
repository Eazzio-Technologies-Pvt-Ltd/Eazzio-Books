import React, { useState, useEffect, useCallback } from "react";
import { apiRequest } from "./api";
import { TableSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

function Banking() {
  const [accounts, setAccounts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [newAccount, setNewAccount] = useState({ account_name: "", bank_name: "", account_number: "", ifsc_code: "", opening_balance: "" });

  // For transactions
  const [selectedAccount, setSelectedAccount] = useState(null);
  const [transactions, setTransactions] = useState([]);
  const [txLoading, setTxLoading] = useState(false);
  const [showTxModal, setShowTxModal] = useState(false);
  const [newTx, setNewTx] = useState({ transaction_date: new Date().toISOString().slice(0, 10), description: "", transaction_type: "deposit", amount: "", reference: "" });
  const [accountSearch, setAccountSearch] = useState("");
  const [txSearch, setTxSearch] = useState("");

  const fetchAccounts = useCallback(async () => {
    try {
      setLoading(true);
      const res = await apiRequest("/bank/accounts");
      setAccounts(res?.accounts || []);
    } catch (err) { toast.error("Failed to load accounts"); }
    finally { setLoading(false); }
  }, []);

  useEffect(() => { fetchAccounts(); }, [fetchAccounts]);

  const addAccount = async () => {
    if (!newAccount.account_name) return toast.error("Account name required");
    try {
      await apiRequest("/bank/accounts", { method: "POST", body: JSON.stringify(newAccount) });
      toast.success("Account created");
      setShowAddModal(false);
      setNewAccount({ account_name: "", bank_name: "", account_number: "", ifsc_code: "", opening_balance: "" });
      fetchAccounts();
    } catch (err) { toast.error("Failed to create account"); }
  };

  const deleteAccount = async (id) => {
    if (!window.confirm("Delete this account?")) return;
    try {
      await apiRequest(`/bank/accounts/${id}`, { method: "DELETE" });
      toast.success("Account deleted");
      if (selectedAccount?.id === id) { setSelectedAccount(null); setTransactions([]); }
      fetchAccounts();
    } catch (err) { toast.error("Delete failed"); }
  };

  const fetchTransactions = async (account) => {
    setSelectedAccount(account);
    setTxLoading(true);
    try {
      const res = await apiRequest(`/bank/accounts/${account.id}/transactions`);
      setTransactions(res?.transactions || []);
    } catch (err) { toast.error("Failed to load transactions"); }
    finally { setTxLoading(false); }
  };

  const addTransaction = async () => {
    if (!newTx.amount) return toast.error("Amount required");
    try {
      await apiRequest(`/bank/accounts/${selectedAccount.id}/transactions`, {
        method: "POST",
        body: JSON.stringify(newTx),
      });
      toast.success("Transaction recorded");
      setShowTxModal(false);
      setNewTx({ transaction_date: new Date().toISOString().slice(0, 10), description: "", transaction_type: "deposit", amount: "", reference: "" });
      fetchAccounts(); // refresh balances
      fetchTransactions(selectedAccount);
    } catch (err) { toast.error("Failed to record transaction"); }
  };

  const filteredAccounts = accounts.filter(acc => {
    const q = accountSearch.toLowerCase();
    return (
      (acc.account_name || "").toLowerCase().includes(q) ||
      (acc.bank_name || "").toLowerCase().includes(q) ||
      (acc.account_number || "").toLowerCase().includes(q)
    );
  });

  const filteredTransactions = transactions.filter(tx => {
    const q = txSearch.toLowerCase();
    return (
      (tx.description || "").toLowerCase().includes(q) ||
      (tx.reference || "").toLowerCase().includes(q) ||
      (tx.transaction_type || "").toLowerCase().includes(q)
    );
  });

  return (
    <div style={{ padding: "30px", maxWidth: "1100px", margin: "auto" }}>
      <style>{`
        .premium-modal-overlay {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(15, 23, 42, 0.45);
          backdrop-filter: blur(6px);
          display: flex;
          justify-content: center;
          align-items: center;
          z-index: 1000;
          animation: fadeInOverlay 0.15s ease-out;
        }
        .premium-modal-content {
          background: #ffffff;
          border-radius: 16px;
          padding: 32px;
          width: 500px;
          max-width: 95%;
          box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
          border: 1px solid #f1f5f9;
          animation: scaleUpModal 0.25s cubic-bezier(0.34, 1.56, 0.64, 1);
        }
        .form-group {
          margin-bottom: 20px;
          display: flex;
          flex-direction: column;
          align-items: flex-start;
          width: 100%;
        }
        .form-row {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 16px;
          margin-bottom: 20px;
          width: 100%;
        }
        .form-label {
          display: block;
          font-size: 13px;
          font-weight: 600;
          color: #334155;
          margin-bottom: 6px;
          text-align: left;
        }
        .form-label .required {
          color: #ef4444;
          margin-left: 3px;
        }
        .form-input {
          width: 100%;
          padding: 10px 14px;
          border-radius: 8px;
          border: 1px solid #cbd5e1;
          background: #ffffff;
          color: #0f172a;
          font-size: 14px;
          box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
          outline: none;
          transition: all 0.2s ease;
          box-sizing: border-box;
        }
        .form-input:focus {
          border-color: #3b82f6;
          box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.15);
        }
        .form-input::placeholder {
          color: #94a3b8;
        }
        .form-select {
          width: 100%;
          padding: 10px 14px;
          border-radius: 8px;
          border: 1px solid #cbd5e1;
          background: #ffffff;
          color: #0f172a;
          font-size: 14px;
          box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
          outline: none;
          transition: all 0.2s ease;
          box-sizing: border-box;
          appearance: none;
          background-image: url("data:image/svg+xml;charset=utf-8,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3E%3Cpath stroke='%2364748b' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='m6 8 4 4 4-4'/%3E%3C/svg%3E");
          background-position: right 12px center;
          background-repeat: no-repeat;
          background-size: 18px;
          padding-right: 40px;
        }
        .form-select:focus {
          border-color: #3b82f6;
          box-shadow: 0 0 0 4px rgba(59, 130, 246, 0.15);
        }
        .btn-cancel {
          padding: 10px 20px;
          background: #f8fafc;
          border: 1px solid #cbd5e1;
          color: #475569;
          font-weight: 600;
          border-radius: 8px;
          cursor: pointer;
          font-size: 14px;
          transition: all 0.2s ease;
        }
        .btn-cancel:hover {
          background: #f1f5f9;
          color: #1e293b;
          border-color: #94a3b8;
        }
        .btn-save {
          padding: 10px 24px;
          background: linear-gradient(135deg, #3b82f6, #2563eb);
          border: none;
          color: #ffffff;
          font-weight: 600;
          border-radius: 8px;
          cursor: pointer;
          font-size: 14px;
          box-shadow: 0 4px 12px rgba(59, 130, 246, 0.25);
          transition: all 0.2s ease;
        }
        .btn-save:hover {
          background: linear-gradient(135deg, #2563eb, #1d4ed8);
          box-shadow: 0 6px 16px rgba(59, 130, 246, 0.35);
          transform: translateY(-1px);
        }
        .btn-save:active {
          transform: translateY(0);
        }
        @keyframes fadeInOverlay {
          from { opacity: 0; }
          to { opacity: 1; }
        }
        @keyframes scaleUpModal {
          from { transform: scale(0.96); opacity: 0; }
          to { transform: scale(1); opacity: 1; }
        }
      `}</style>

      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px", gap: "20px", flexWrap: "wrap" }}>
        <h2 style={{ margin: 0 }}>Banking</h2>
        <div style={{ display: "flex", gap: "10px", alignItems: "center" }}>
          {accounts.length > 0 && (
            <input 
              type="text" 
              placeholder="Search accounts..." 
              value={accountSearch} 
              onChange={e => setAccountSearch(e.target.value)} 
              style={{
                padding: "8px 12px",
                borderRadius: "6px",
                border: "1px solid #cbd5e1",
                fontSize: "14px",
                width: "220px",
                outline: "none",
                transition: "border-color 0.2s"
              }}
              onFocus={(e) => e.target.style.borderColor = "#3b82f6"}
              onBlur={(e) => e.target.style.borderColor = "#cbd5e1"}
            />
          )}
          <button onClick={() => setShowAddModal(true)} style={primaryBtn}>+ Add Account</button>
        </div>
      </div>

      {loading ? <TableSkeleton columns={5} rows={4} /> : accounts.length === 0 ? (
        <p>No bank accounts yet.</p>
      ) : filteredAccounts.length === 0 ? (
        <p style={{ color: "#64748b", fontStyle: "italic" }}>No bank accounts found matching "{accountSearch}".</p>
      ) : (
        <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "14px" }}>
          <thead>
            <tr style={{ background: "#f1f5f9", textAlign: "left" }}>
              <th style={thStyle}>Account Name</th>
              <th style={thStyle}>Bank</th>
              <th style={thStyle}>Account #</th>
              <th style={thStyle}>Current Balance</th>
              <th style={thStyle}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredAccounts.map(acc => (
              <React.Fragment key={acc.id}>
                <tr style={{ borderBottom: "1px solid #e2e8f0", cursor: "pointer", background: selectedAccount?.id === acc.id ? "#f0f4ff" : "transparent" }}
                  onClick={() => fetchTransactions(acc)}>
                  <td style={tdStyle}><span style={{ color: "#4a90e2", textDecoration: "underline" }}>{acc.account_name}</span></td>
                  <td style={tdStyle}>{acc.bank_name || "—"}</td>
                  <td style={tdStyle}>{acc.account_number || "—"}</td>
                  <td style={tdStyle}>₹{parseFloat(acc.current_balance).toFixed(2)}</td>
                  <td style={tdStyle}>
                    <button onClick={(e) => { e.stopPropagation(); fetchTransactions(acc); setShowTxModal(true); }} style={smallBtn}>+ Transaction</button>
                    <button onClick={(e) => { e.stopPropagation(); deleteAccount(acc.id); }} style={deleteBtnStyle}>Delete</button>
                  </td>
                </tr>
              </React.Fragment>
            ))}
          </tbody>
        </table>
      )}

      {/* Transactions panel for selected account */}
      {selectedAccount && (
        <div style={{ marginTop: "30px" }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "15px", gap: "20px", flexWrap: "wrap" }}>
            <h3 style={{ margin: 0 }}>Transactions – {selectedAccount.account_name}</h3>
            {transactions.length > 0 && (
              <input 
                type="text" 
                placeholder="Search transactions..." 
                value={txSearch} 
                onChange={e => setTxSearch(e.target.value)} 
                style={{
                  padding: "8px 12px",
                  borderRadius: "6px",
                  border: "1px solid #cbd5e1",
                  fontSize: "14px",
                  width: "220px",
                  outline: "none",
                  transition: "border-color 0.2s"
                }}
                onFocus={(e) => e.target.style.borderColor = "#3b82f6"}
                onBlur={(e) => e.target.style.borderColor = "#cbd5e1"}
              />
            )}
          </div>
          {txLoading ? <TableSkeleton columns={5} rows={3} /> : transactions.length === 0 ? <p>No transactions yet.</p> : filteredTransactions.length === 0 ? (
            <p style={{ color: "#64748b", fontStyle: "italic" }}>No transactions found matching "{txSearch}".</p>
          ) : (
            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "14px" }}>
              <thead>
                <tr style={{ background: "#f1f5f9", textAlign: "left" }}>
                  <th style={thStyle}>Date</th>
                  <th style={thStyle}>Description</th>
                  <th style={thStyle}>Type</th>
                  <th style={thStyle}>Amount</th>
                  <th style={thStyle}>Reference</th>
                </tr>
              </thead>
              <tbody>
                {filteredTransactions.map(tx => (
                  <tr key={tx.id} style={{ borderBottom: "1px solid #e2e8f0" }}>
                    <td style={tdStyle}>{new Date(tx.transaction_date).toLocaleDateString()}</td>
                    <td style={tdStyle}>{tx.description}</td>
                    <td style={tdStyle}>{tx.transaction_type}</td>
                    <td style={{ ...tdStyle, color: tx.transaction_type === "deposit" ? "green" : "red" }}>₹{parseFloat(tx.amount).toFixed(2)}</td>
                    <td style={tdStyle}>{tx.reference || "—"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Add Account Modal */}
      {showAddModal && (
        <div className="premium-modal-overlay">
          <div className="premium-modal-content">
            <h3 style={{ margin: "0 0 24px 0", color: "#0f172a", fontSize: "20px", fontWeight: "700", textAlign: "left" }}>New Bank Account</h3>
            
            <div className="form-group">
              <label className="form-label">Account Name<span className="required">*</span></label>
              <input 
                type="text" 
                placeholder="e.g. Primary Operating Account" 
                value={newAccount.account_name} 
                onChange={e => setNewAccount({ ...newAccount, account_name: e.target.value })} 
                className="form-input" 
              />
            </div>
            
            <div className="form-group">
              <label className="form-label">Bank Name</label>
              <input 
                type="text" 
                placeholder="e.g. HDFC Bank" 
                value={newAccount.bank_name} 
                onChange={e => setNewAccount({ ...newAccount, bank_name: e.target.value })} 
                className="form-input" 
              />
            </div>

            <div className="form-row">
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Account Number</label>
                <input 
                  type="text" 
                  placeholder="e.g. 50100234567890" 
                  value={newAccount.account_number} 
                  onChange={e => setNewAccount({ ...newAccount, account_number: e.target.value })} 
                  className="form-input" 
                />
              </div>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">IFSC Code</label>
                <input 
                  type="text" 
                  placeholder="e.g. HDFC0000123" 
                  value={newAccount.ifsc_code} 
                  onChange={e => setNewAccount({ ...newAccount, ifsc_code: e.target.value })} 
                  className="form-input" 
                />
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Opening Balance (₹)</label>
              <input 
                type="number" 
                placeholder="e.g. 50000.00" 
                value={newAccount.opening_balance} 
                onChange={e => setNewAccount({ ...newAccount, opening_balance: e.target.value })} 
                className="form-input" 
              />
            </div>

            <div style={{ display: "flex", gap: "12px", justifyContent: "flex-end", marginTop: "28px" }}>
              <button onClick={() => setShowAddModal(false)} className="btn-cancel">Cancel</button>
              <button onClick={addAccount} className="btn-save">Save Account</button>
            </div>
          </div>
        </div>
      )}

      {/* Add Transaction Modal */}
      {showTxModal && (
        <div className="premium-modal-overlay">
          <div className="premium-modal-content">
            <h3 style={{ margin: "0 0 8px 0", color: "#0f172a", fontSize: "20px", fontWeight: "700", textAlign: "left" }}>New Transaction</h3>
            <p style={{ margin: "0 0 24px 0", color: "#64748b", fontSize: "14px", textAlign: "left" }}>Account: <strong>{selectedAccount?.account_name}</strong></p>
            
            <div className="form-row">
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Transaction Date</label>
                <input 
                  type="date" 
                  value={newTx.transaction_date} 
                  onChange={e => setNewTx({ ...newTx, transaction_date: e.target.value })} 
                  className="form-input" 
                />
              </div>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Transaction Type</label>
                <select 
                  value={newTx.transaction_type} 
                  onChange={e => setNewTx({ ...newTx, transaction_type: e.target.value })} 
                  className="form-select"
                >
                  <option value="deposit">Deposit (Inflow)</option>
                  <option value="withdrawal">Withdrawal (Outflow)</option>
                </select>
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Description</label>
              <input 
                type="text" 
                placeholder="e.g. Client payment or Office rent" 
                value={newTx.description} 
                onChange={e => setNewTx({ ...newTx, description: e.target.value })} 
                className="form-input" 
              />
            </div>

            <div className="form-row">
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Amount (₹)<span className="required">*</span></label>
                <input 
                  type="number" 
                  placeholder="0.00" 
                  value={newTx.amount} 
                  onChange={e => setNewTx({ ...newTx, amount: e.target.value })} 
                  className="form-input" 
                />
              </div>
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label">Reference / Tx ID</label>
                <input 
                  type="text" 
                  placeholder="e.g. UPI Ref or Chq No." 
                  value={newTx.reference} 
                  onChange={e => setNewTx({ ...newTx, reference: e.target.value })} 
                  className="form-input" 
                />
              </div>
            </div>

            <div style={{ display: "flex", gap: "12px", justifyContent: "flex-end", marginTop: "28px" }}>
              <button onClick={() => setShowTxModal(false)} className="btn-cancel">Cancel</button>
              <button onClick={addTransaction} className="btn-save">Save Transaction</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

const thStyle = { padding: "10px", borderBottom: "2px solid #cbd5e1", whiteSpace: "nowrap" };
const tdStyle = { padding: "10px" };
const inputStyle = { width: "100%", padding: "8px", borderRadius: "5px", border: "1px solid #ccc", boxSizing: "border-box", marginBottom: "10px" };
const primaryBtn = { padding: "10px 20px", background: "#4a90e2", color: "#fff", border: "none", borderRadius: "5px", cursor: "pointer", fontWeight: "500" };
const cancelBtnStyle = { padding: "10px 20px", background: "#ccc", color: "#333", border: "none", borderRadius: "5px", cursor: "pointer" };
const smallBtn = { padding: "5px 10px", background: "#f0f0f0", color: "#333", border: "1px solid #ccc", borderRadius: "4px", cursor: "pointer", marginRight: "5px" };
const deleteBtnStyle = { padding: "5px 10px", background: "red", color: "#fff", border: "none", borderRadius: "4px", cursor: "pointer" };
const modalOverlay = { position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(0,0,0,0.5)", display: "flex", justifyContent: "center", alignItems: "center", zIndex: 1000 };
const modalContent = { background: "#fff", borderRadius: "8px", padding: "25px", width: "450px", maxWidth: "90%", boxShadow: "0 4px 20px rgba(0,0,0,0.2)" };

export default Banking;