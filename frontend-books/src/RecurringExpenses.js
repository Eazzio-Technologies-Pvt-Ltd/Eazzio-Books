import React, { useState, useEffect } from "react";
import { apiRequest } from "./api";
import toast from "react-hot-toast";

function RecurringExpenses() {
  const [expenses, setExpenses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("All");

  const [showModal, setShowModal] = useState(false);
  const [isEditing, setIsEditing] = useState(false);
  const [formData, setFormData] = useState({
    id: null,
    expense_name: "",
    category: "",
    amount: "",
    frequency: "Monthly",
    due_day: "",
    start_date: "",
    end_date: "",
    status: "Active",
    notes: ""
  });

  useEffect(() => {
    fetchExpenses();
  }, []);

  const fetchExpenses = async () => {
    setLoading(true);
    try {
      const res = await apiRequest("/recurring-expenses");
      setExpenses(res?.recurringExpenses || []);
    } catch (err) {
      toast.error("Failed to load recurring expenses");
    } finally {
      setLoading(false);
    }
  };

  const handleOpenAdd = () => {
    setFormData({
      id: null,
      expense_name: "",
      category: "",
      amount: "",
      frequency: "Monthly",
      due_day: "",
      start_date: new Date().toISOString().split('T')[0],
      end_date: "",
      status: "Active",
      notes: ""
    });
    setIsEditing(false);
    setShowModal(true);
  };

  const handleOpenEdit = (exp) => {
    setFormData({
      id: exp.id,
      expense_name: exp.expense_name,
      category: exp.category,
      amount: exp.amount,
      frequency: exp.frequency,
      due_day: exp.due_day,
      start_date: new Date(exp.start_date).toISOString().split('T')[0],
      end_date: exp.end_date ? new Date(exp.end_date).toISOString().split('T')[0] : "",
      status: exp.status,
      notes: exp.notes || ""
    });
    setIsEditing(true);
    setShowModal(true);
  };

  const handleCloseModal = () => {
    setShowModal(false);
  };

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.expense_name || !formData.category || !formData.amount || !formData.due_day || !formData.start_date) {
      toast.error("Please fill all required fields");
      return;
    }
    try {
      if (isEditing) {
        await apiRequest(`/recurring-expenses/${formData.id}`, {
          method: "PUT",
          body: JSON.stringify(formData)
        });
        toast.success("Recurring expense updated");
      } else {
        await apiRequest("/recurring-expenses", {
          method: "POST",
          body: JSON.stringify(formData)
        });
        toast.success("Recurring expense added");
      }
      setShowModal(false);
      fetchExpenses();
    } catch (err) {
      toast.error(err.message || "Failed to save recurring expense");
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Are you sure you want to delete this recurring expense?")) return;
    try {
      await apiRequest(`/recurring-expenses/${id}`, { method: "DELETE" });
      toast.success("Recurring expense deleted");
      fetchExpenses();
    } catch (err) {
      toast.error("Failed to delete");
    }
  };

  const handleStatusUpdate = async (id, action) => {
    try {
      await apiRequest(`/recurring-expenses/${id}/${action}`, { method: "PATCH" });
      toast.success(`Expense ${action}d successfully`);
      fetchExpenses();
    } catch (err) {
      toast.error(`Failed to ${action} expense`);
    }
  };

  const filteredExpenses = expenses.filter(exp => {
    const matchesSearch = exp.expense_name.toLowerCase().includes(search.toLowerCase());
    const matchesStatus = statusFilter === "All" || exp.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const getStatusColor = (status) => {
    if (status === "Active") return { bg: "#dcfce7", text: "#166534" };
    if (status === "Paused") return { bg: "#fef08a", text: "#854d0e" };
    if (status === "Stopped") return { bg: "#fee2e2", text: "#991b1b" };
    return { bg: "#f1f5f9", text: "#475569" };
  };

  return (
    <div style={{ padding: "40px", maxWidth: "1200px", margin: "0 auto", background: "#f8fafc", minHeight: "100vh" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "30px" }}>
        <div>
          <h2 style={{ fontSize: "24px", fontWeight: "700", color: "#0f172a", margin: "0 0 4px 0" }}>Recurring Expenses</h2>
          <p style={{ color: "#64748b", margin: 0, fontSize: "14px" }}>Manage your automated, fixed, or scheduled expenses.</p>
        </div>
        <button onClick={handleOpenAdd} style={primaryBtn}>
          <span style={{ marginRight: "6px" }}>+</span> New Recurring Expense
        </button>
      </div>

      <div style={{ display: "flex", gap: "16px", marginBottom: "24px", background: "#fff", padding: "16px", borderRadius: "12px", boxShadow: "0 1px 3px rgba(0,0,0,0.05)" }}>
        <div style={{ flex: 1, position: "relative" }}>
          <span style={{ position: "absolute", left: "14px", top: "50%", transform: "translateY(-50%)", color: "#94a3b8" }}>🔍</span>
          <input
            type="text"
            placeholder="Search by Expense Name..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            style={{ ...inputStyle, paddingLeft: "40px" }}
          />
        </div>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} style={{ ...inputStyle, width: "200px", cursor: "pointer", appearance: "none" }}>
          <option value="All">All Statuses</option>
          <option value="Active">Active</option>
          <option value="Paused">Paused</option>
          <option value="Stopped">Stopped</option>
        </select>
      </div>

      <div style={{ background: "#fff", borderRadius: "12px", boxShadow: "0 4px 6px -1px rgba(0,0,0,0.05), 0 2px 4px -2px rgba(0,0,0,0.05)", overflow: "hidden", border: "1px solid #e2e8f0" }}>
        {loading ? (
          <div style={{ padding: "60px", textAlign: "center", color: "#64748b" }}>
            <div style={{ fontSize: "24px", marginBottom: "16px" }}>⏳</div>
            Loading recurring expenses...
          </div>
        ) : filteredExpenses.length === 0 ? (
          <div style={{ padding: "80px 20px", textAlign: "center", color: "#64748b" }}>
            <div style={{ fontSize: "48px", marginBottom: "16px", opacity: 0.5 }}>🔄</div>
            <h3 style={{ margin: "0 0 8px 0", color: "#1e293b", fontSize: "18px" }}>No recurring expenses found</h3>
            <p style={{ margin: "0 0 24px 0", fontSize: "14px" }}>You don't have any automated expenses matching this criteria.</p>
            <button onClick={handleOpenAdd} style={{ ...primaryBtn, background: "#fff", color: "#006ee6", border: "1px solid #006ee6", boxShadow: "none" }}>Add First Expense</button>
          </div>
        ) : (
          <div style={{ overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse", whiteSpace: "nowrap" }}>
              <thead>
                <tr style={{ background: "#f8fafc", textAlign: "left" }}>
                  <th style={thStyle}>Expense Name</th>
                  <th style={thStyle}>Category</th>
                  <th style={thStyle}>Amount</th>
                  <th style={thStyle}>Frequency</th>
                  <th style={thStyle}>Due Day</th>
                  <th style={thStyle}>Status</th>
                  <th style={thStyle}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {filteredExpenses.map((exp) => {
                  const statusColor = getStatusColor(exp.status);
                  return (
                    <tr key={exp.id} style={{ transition: "background 0.2s" }} onMouseEnter={(e) => e.currentTarget.style.background = "#f8fafc"} onMouseLeave={(e) => e.currentTarget.style.background = "transparent"}>
                      <td style={{ ...tdStyle, fontWeight: "600", color: "#0f172a" }}>{exp.expense_name}</td>
                      <td style={tdStyle}>
                        <span style={{ display: "inline-block", background: "#f1f5f9", padding: "4px 10px", borderRadius: "6px", fontSize: "13px", color: "#475569", fontWeight: "500" }}>
                          {exp.category}
                        </span>
                      </td>
                      <td style={{ ...tdStyle, fontWeight: "700", color: "#1e293b" }}>₹{parseFloat(exp.amount).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</td>
                      <td style={{ ...tdStyle, color: "#64748b" }}>{exp.frequency}</td>
                      <td style={{ ...tdStyle, color: "#64748b" }}>Day {exp.due_day}</td>
                      <td style={tdStyle}>
                        <span style={{
                          background: statusColor.bg, color: statusColor.text,
                          padding: "6px 12px", borderRadius: "20px", fontSize: "12px", fontWeight: "600", display: "inline-flex", alignItems: "center", gap: "6px"
                        }}>
                          <span style={{ width: "6px", height: "6px", borderRadius: "50%", background: "currentColor" }}></span>
                          {exp.status}
                        </span>
                      </td>
                      <td style={tdStyle}>
                        <div style={{ display: "flex", gap: "8px" }}>
                          <button onClick={() => handleOpenEdit(exp)} style={actionBtn}>Edit</button>
                          
                          {exp.status === "Active" && (
                            <button onClick={() => handleStatusUpdate(exp.id, "pause")} style={{ ...actionBtn, color: "#b45309", borderColor: "#fef08a", background: "#fef9c3" }}>Pause</button>
                          )}
                          {exp.status === "Paused" && (
                            <button onClick={() => handleStatusUpdate(exp.id, "resume")} style={{ ...actionBtn, color: "#15803d", borderColor: "#bbf7d0", background: "#dcfce7" }}>Resume</button>
                          )}
                          {(exp.status === "Active" || exp.status === "Paused") && (
                            <button onClick={() => handleStatusUpdate(exp.id, "stop")} style={{ ...actionBtn, color: "#b91c1c", borderColor: "#fecaca", background: "#fee2e2" }}>Stop</button>
                          )}

                          <button onClick={() => handleDelete(exp.id)} style={{ ...actionBtn, color: "#b91c1c", background: "none", border: "none", padding: "6px", marginLeft: "4px" }}>
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"></path><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path></svg>
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {showModal && (
        <div style={modalOverlay}>
          <div style={modalContent}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "24px", borderBottom: "1px solid #f1f5f9", paddingBottom: "16px" }}>
              <h3 style={{ margin: 0, fontSize: "20px", fontWeight: "700", color: "#0f172a" }}>
                {isEditing ? "Edit Recurring Expense" : "New Recurring Expense"}
              </h3>
              <button onClick={handleCloseModal} style={{ background: "#f8fafc", border: "none", fontSize: "18px", color: "#64748b", cursor: "pointer", width: "32px", height: "32px", borderRadius: "50%", display: "flex", alignItems: "center", justifyContent: "center", transition: "background 0.2s" }} onMouseEnter={(e)=>e.currentTarget.style.background="#f1f5f9"} onMouseLeave={(e)=>e.currentTarget.style.background="#f8fafc"}>✕</button>
            </div>
            
            <form onSubmit={handleSubmit} style={{ display: "grid", gap: "15px", gridTemplateColumns: "1fr 1fr" }}>
              <div style={{ gridColumn: "span 2" }}>
                <label style={labelStyle}>Expense Name *</label>
                <input type="text" name="expense_name" value={formData.expense_name} onChange={handleChange} style={inputStyle} required />
              </div>
              
              <div>
                <label style={labelStyle}>Category *</label>
                <input type="text" name="category" value={formData.category} onChange={handleChange} style={inputStyle} required />
              </div>
              
              <div>
                <label style={labelStyle}>Amount *</label>
                <input type="number" name="amount" value={formData.amount} onChange={handleChange} style={inputStyle} step="0.01" required />
              </div>

              <div>
                <label style={labelStyle}>Frequency *</label>
                <select name="frequency" value={formData.frequency} onChange={handleChange} style={inputStyle} required>
                  <option value="Monthly">Monthly</option>
                  <option value="Quarterly">Quarterly</option>
                  <option value="Yearly">Yearly</option>
                </select>
              </div>

              <div>
                <label style={labelStyle}>Due Day (1-31) *</label>
                <input type="number" name="due_day" value={formData.due_day} onChange={handleChange} style={inputStyle} min="1" max="31" required />
              </div>

              <div>
                <label style={labelStyle}>Start Date *</label>
                <input type="date" name="start_date" value={formData.start_date} onChange={handleChange} style={inputStyle} required />
              </div>

              <div>
                <label style={labelStyle}>End Date (Optional)</label>
                <input type="date" name="end_date" value={formData.end_date} onChange={handleChange} style={inputStyle} />
              </div>

              <div>
                <label style={labelStyle}>Status *</label>
                <select name="status" value={formData.status} onChange={handleChange} style={inputStyle} required>
                  <option value="Active">Active</option>
                  <option value="Paused">Paused</option>
                  <option value="Stopped">Stopped</option>
                </select>
              </div>

              <div style={{ gridColumn: "span 2" }}>
                <label style={labelStyle}>Notes</label>
                <textarea name="notes" value={formData.notes} onChange={handleChange} style={{ ...inputStyle, minHeight: "80px" }} />
              </div>

              <div style={{ gridColumn: "span 2", display: "flex", justifyContent: "flex-end", gap: "10px", marginTop: "10px" }}>
                <button type="button" onClick={handleCloseModal} style={secondaryBtn}>Cancel</button>
                <button type="submit" style={primaryBtn}>Save Expense</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

const thStyle = { padding: "12px 16px", color: "#64748b", fontWeight: "600", fontSize: "12px", textTransform: "uppercase", letterSpacing: "0.05em", borderBottom: "1px solid #e2e8f0" };
const tdStyle = { padding: "16px", color: "#334155", fontSize: "14px", borderBottom: "1px solid #f1f5f9" };
const primaryBtn = { background: "#006ee6", color: "#fff", padding: "10px 20px", borderRadius: "8px", border: "none", fontWeight: "600", fontSize: "14px", cursor: "pointer", transition: "all 0.2s", boxShadow: "0 1px 2px rgba(0, 110, 230, 0.2)" };
const secondaryBtn = { background: "#fff", color: "#334155", padding: "10px 20px", borderRadius: "8px", border: "1px solid #cbd5e1", fontWeight: "600", fontSize: "14px", cursor: "pointer", transition: "all 0.2s" };
const actionBtn = { background: "#f8fafc", border: "1px solid #e2e8f0", padding: "6px 12px", borderRadius: "6px", color: "#475569", cursor: "pointer", fontWeight: "500", fontSize: "13px", transition: "all 0.2s" };
const inputStyle = { width: "100%", padding: "10px 14px", borderRadius: "8px", border: "1px solid #cbd5e1", outline: "none", boxSizing: "border-box", fontSize: "14px", transition: "border-color 0.2s" };
const labelStyle = { display: "block", marginBottom: "6px", fontSize: "13px", fontWeight: "600", color: "#475569" };

const modalOverlay = { position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(15, 23, 42, 0.4)", backdropFilter: "blur(4px)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 1000 };
const modalContent = { background: "#fff", padding: "32px", borderRadius: "16px", width: "100%", maxWidth: "640px", maxHeight: "90vh", overflowY: "auto", boxShadow: "0 20px 40px rgba(0,0,0,0.1)" };

export default RecurringExpenses;
