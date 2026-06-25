/**
 * Taxes.js – Modernized Taxes & GST management
 */
import React, { useEffect, useState } from "react";
import { apiRequest } from "./api";
import { TableSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

function Taxes() {
  const [taxes, setTaxes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [filterType, setFilterType] = useState("all");
  const [filterStatus, setFilterStatus] = useState("all");

  const [showModal, setShowModal] = useState(false);
  const [isEditMode, setIsEditMode] = useState(false);
  const [currentId, setCurrentId] = useState(null);
  
  const [formData, setFormData] = useState({
    tax_name: "",
    tax_type: "GST",
    rate: 0,
    description: "",
    status: "active"
  });

  useEffect(() => {
    fetchTaxes();
  }, []);

  const fetchTaxes = async () => {
    try {
      setLoading(true);
      const res = await apiRequest("/taxes");
      setTaxes(res?.taxes || []);
    } catch (err) {
      toast.error("Failed to load taxes");
    } finally {
      setLoading(false);
    }
  };

  const handleOpenAdd = () => {
    setIsEditMode(false);
    setCurrentId(null);
    setFormData({
      tax_name: "",
      tax_type: "GST",
      rate: 0,
      description: "",
      status: "active"
    });
    setShowModal(true);
  };

  const handleOpenEdit = (tax) => {
    setIsEditMode(true);
    setCurrentId(tax.id);
    setFormData({
      tax_name: tax.tax_name || "",
      tax_type: tax.tax_type || "GST",
      rate: tax.rate || 0,
      description: tax.description || "",
      status: tax.status || "active"
    });
    setShowModal(true);
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSave = async (e) => {
    e.preventDefault();
    if (!formData.tax_name) return toast.error("Tax Name is required");
    
    try {
      if (isEditMode) {
        await apiRequest(`/taxes/${currentId}`, { method: "PUT", body: JSON.stringify(formData) });
        toast.success("Tax updated successfully");
      } else {
        await apiRequest("/taxes", { method: "POST", body: JSON.stringify(formData) });
        toast.success("Tax added successfully");
      }
      setShowModal(false);
      fetchTaxes();
    } catch (err) {
      toast.error("Failed to save tax");
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm("Are you sure you want to delete this tax?")) return;
    try {
      await apiRequest(`/taxes/${id}`, { method: "DELETE" });
      toast.success("Tax deleted");
      fetchTaxes();
    } catch (err) {
      toast.error("Failed to delete tax");
    }
  };

  const filteredTaxes = taxes.filter(t => {
    const matchSearch = t.tax_name.toLowerCase().includes(search.toLowerCase());
    const matchType = filterType === "all" || t.tax_type === filterType;
    const matchStatus = filterStatus === "all" || t.status === filterStatus;
    return matchSearch && matchType && matchStatus;
  });

  const labelStyle = { display: "block", marginBottom: "6px", fontSize: "13px", fontWeight: "500", color: "#344054" };
  const thStyle = { padding: "12px 18px", color: "#475569", fontWeight: "600", fontSize: "12px", borderBottom: "1px solid #eaecf0", letterSpacing: "0.02em" };
  const tdStyle = { padding: "14px 18px", verticalAlign: "middle", borderBottom: "1px solid #eaecf0" };

  return (
    <div style={{ padding: "30px", maxWidth: "1000px", margin: "auto", fontFamily: "system-ui, -apple-system, sans-serif" }}>
      
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
          <h2 style={{ margin: 0, fontSize: "24px", fontWeight: "700", color: "#1d2939" }}>Taxes & GST Management</h2>
          <p style={{ margin: "4px 0 0 0", fontSize: "14px", color: "#667085" }}>Manage your goods and services tax rates, types, and active statuses.</p>
        </div>
        <button onClick={handleOpenAdd} className="primary-btn">+ New Tax</button>
      </div>

      {/* Filters Bar */}
      <div style={{ display: "flex", gap: "16px", marginBottom: "24px", background: "#ffffff", padding: "18px 24px", borderRadius: "10px", border: "1px solid #eaecf0", boxShadow: "0 1px 3px rgba(16, 24, 40, 0.05)", alignItems: "center" }}>
        <div style={{ position: "relative", flex: 1, maxWidth: "320px" }}>
          <input
            type="text"
            placeholder="Search tax name..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="premium-input"
          />
        </div>
        <select value={filterType} onChange={e => setFilterType(e.target.value)} className="premium-input" style={{ maxWidth: "160px", cursor: "pointer" }}>
          <option value="all">All Types</option>
          <option value="GST">GST</option>
          <option value="IGST">IGST</option>
          <option value="CGST">CGST</option>
          <option value="SGST">SGST</option>
          <option value="CESS">CESS</option>
          <option value="Other">Other</option>
        </select>
        <select value={filterStatus} onChange={e => setFilterStatus(e.target.value)} className="premium-input" style={{ maxWidth: "160px", cursor: "pointer" }}>
          <option value="all">All Statuses</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>
      </div>

      {/* Table Container */}
      {loading ? (
        <TableSkeleton columns={5} rows={5} />
      ) : filteredTaxes.length === 0 ? (
        <div style={{ textAlign: "center", padding: "50px", color: "#667085", background: "#f9fafb", borderRadius: "8px", border: "1px solid #eaecf0" }}>
          <p style={{ margin: "0 0 16px 0", fontSize: "14px" }}>No taxes found.</p>
          <button onClick={handleOpenAdd} className="secondary-btn">Add New Tax</button>
        </div>
      ) : (
        <div style={{ border: "1px solid #eaecf0", borderRadius: "10px", overflow: "hidden", boxShadow: "0 1px 3px rgba(16, 24, 40, 0.05)", background: "#ffffff" }}>
          <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "13px", textAlign: "left" }}>
            <thead>
              <tr style={{ background: "#f9fafb" }}>
                <th style={thStyle}>Tax Name</th>
                <th style={thStyle}>Type</th>
                <th style={thStyle}>Rate (%)</th>
                <th style={thStyle}>Status</th>
                <th style={thStyle}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredTaxes.map(tax => (
                <tr key={tax.id} style={{ transition: "background 0.2s" }} onMouseOver={e => e.currentTarget.style.background = "#f9fafb"} onMouseOut={e => e.currentTarget.style.background = "transparent"}>
                  <td style={tdStyle}>
                    <div style={{ fontWeight: "600", color: "#1d2939" }}>{tax.tax_name}</div>
                    {tax.description && <div style={{ fontSize: "12px", color: "#667085", marginTop: "2px" }}>{tax.description}</div>}
                  </td>
                  <td style={{ ...tdStyle, color: "#475569" }}>{tax.tax_type || "—"}</td>
                  <td style={tdStyle}><span style={{ fontWeight: "700", color: "#1d2939" }}>{parseFloat(tax.rate).toFixed(2)}%</span></td>
                  <td style={tdStyle}>
                    <span className={tax.status === 'active' ? "status-pill-active" : "status-pill-inactive"}>
                      {tax.status === 'active' ? "Active" : "Inactive"}
                    </span>
                  </td>
                  <td style={tdStyle}>
                    <button onClick={() => handleOpenEdit(tax)} className="action-link">Edit</button>
                    <button onClick={() => handleDelete(tax.id)} className="delete-link">Delete</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Add/Edit Modal */}
      {showModal && (
        <div style={{ position: "fixed", top: 0, left: 0, width: "100%", height: "100%", background: "rgba(16, 24, 40, 0.4)", backdropFilter: "blur(4px)", display: "flex", justifyContent: "center", alignItems: "center", zIndex: 1000 }}>
          <div style={{ background: "#ffffff", padding: "32px", borderRadius: "12px", width: "100%", maxWidth: "480px", boxShadow: "0 20px 24px -4px rgba(16, 24, 40, 0.08), 0 8px 8px -4px rgba(16, 24, 40, 0.03)", border: "1px solid #eaecf0", overflow: "hidden" }}>
            <h3 style={{ margin: "0 0 4px 0", fontSize: "18px", fontWeight: "700", color: "#1d2939" }}>
              {isEditMode ? "Edit Tax" : "New Tax"}
            </h3>
            <p style={{ margin: "0 0 24px 0", fontSize: "14px", color: "#667085" }}>
              {isEditMode ? "Update tax rate details" : "Add a new tax rate to your account."}
            </p>
            <form onSubmit={handleSave}>
              <div style={{ marginBottom: "16px" }}>
                <label style={labelStyle}>Tax Name *</label>
                <input type="text" name="tax_name" value={formData.tax_name} onChange={handleChange} className="premium-input" placeholder="e.g. GST 18%" required />
              </div>
              
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "16px", marginBottom: "16px" }}>
                <div>
                  <label style={labelStyle}>Rate (%) *</label>
                  <input type="number" step="0.01" name="rate" value={formData.rate} onChange={handleChange} className="premium-input" placeholder="e.g. 18.00" required />
                </div>
                <div>
                  <label style={labelStyle}>Tax Type</label>
                  <select name="tax_type" value={formData.tax_type} onChange={handleChange} className="premium-input" style={{ cursor: "pointer" }}>
                    <option value="GST">GST</option>
                    <option value="IGST">IGST</option>
                    <option value="CGST">CGST</option>
                    <option value="SGST">SGST</option>
                    <option value="CESS">CESS</option>
                    <option value="Other">Other</option>
                  </select>
                </div>
              </div>
              
              <div style={{ marginBottom: "16px" }}>
                <label style={labelStyle}>Status</label>
                <select name="status" value={formData.status} onChange={handleChange} className="premium-input" style={{ cursor: "pointer" }}>
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                </select>
              </div>
              
              <div style={{ marginBottom: "24px" }}>
                <label style={labelStyle}>Description (Optional)</label>
                <textarea name="description" value={formData.description} onChange={handleChange} rows={3} className="premium-input" placeholder="Enter tax details..." style={{ resize: "none" }}></textarea>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", gap: "12px", borderTop: "1px solid #eaecf0", padding: "16px 32px", margin: "24px -32px -32px -32px", background: "#f9fafb", borderBottomLeftRadius: "12px", borderBottomRightRadius: "12px" }}>
                <button type="button" onClick={() => setShowModal(false)} className="secondary-btn">Cancel</button>
                <button type="submit" className="primary-btn">Save Tax</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default Taxes;
