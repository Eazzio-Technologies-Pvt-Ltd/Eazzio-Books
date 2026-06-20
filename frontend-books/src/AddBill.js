import React, { useState, useEffect, useCallback } from "react";
import { useNavigate, useParams, useSearchParams } from "react-router-dom";
import { apiRequest } from "./api";
import { FormSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";
import AddVendor from "./AddVendor";

function AddBill() {
  const { id } = useParams();
  const [searchParams] = useSearchParams();
  const preselectedVendorId = searchParams.get("vendor_id");
  const isEditMode = Boolean(id);
  const navigate = useNavigate();

  const [vendors, setVendors] = useState([]);
  const [catalogItems, setCatalogItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(false);

  // Modals
  const [showVendorModal, setShowVendorModal] = useState(false);

  const [formData, setFormData] = useState({
    vendor_id: preselectedVendorId || "",
    bill_number: "",
    bill_date: new Date().toISOString().slice(0, 10),
    due_date: "",
    status: "draft",
    notes: "",
  });

  const [items, setItems] = useState([
    { item_id: "", item_name: "", description: "", quantity: 1, unit_price: 0, tax_rate: 0, discount: 0, discount_type: "flat", hsn_code: "", unit: "" }
  ]);

  const fetchInitialData = useCallback(async () => {
    try {
      const [venRes, itRes] = await Promise.all([
        apiRequest("/vendors"),
        apiRequest("/items")
      ]);
      setVendors(venRes?.vendors || []);
      setCatalogItems(itRes?.items || []);

      if (isEditMode) {
        setFetching(true);
        const billRes = await apiRequest(`/bills/${id}`);
        if (billRes?.bill) {
          setFormData({
            vendor_id: billRes.bill.vendor_id || "",
            bill_number: billRes.bill.bill_number || "",
            bill_date: billRes.bill.bill_date ? billRes.bill.bill_date.slice(0, 10) : "",
            due_date: billRes.bill.due_date ? billRes.bill.due_date.slice(0, 10) : "",
            status: billRes.bill.status || "draft",
            notes: billRes.bill.notes || "",
          });
          if (billRes.items && billRes.items.length > 0) {
            setItems(billRes.items.map(item => ({
              item_id: item.item_id ? String(item.item_id) : "",
              item_name: item.item_name || "",
              description: item.description || "",
              quantity: item.quantity || 1,
              unit_price: item.rate || item.unit_price || 0,
              tax_rate: item.tax_rate || 0,
              discount: item.discount || 0,
              discount_type: item.discount_type || "flat",
              hsn_code: item.hsn_code || "",
              unit: item.unit || ""
            })));
          }
        }
      }
    } catch (err) {
      toast.error("Failed to load data");
    } finally {
      setFetching(false);
    }
  }, [id, isEditMode]);

  useEffect(() => {
    fetchInitialData();
  }, [fetchInitialData]);

  const handleFormChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleItemChange = (index, field, value) => {
    const newItems = [...items];
    newItems[index][field] = value;
    setItems(newItems);
  };

  const handleItemSelect = (index, catalogItemId) => {
    const selected = catalogItems.find(i => String(i.id) === String(catalogItemId));
    const newItems = [...items];
    if (selected) {
      newItems[index] = {
        ...newItems[index],
        item_id: selected.id,
        item_name: selected.name,
        description: selected.description || selected.name || "",
        unit_price: selected.cost_price > 0 ? selected.cost_price : selected.selling_price || 0,
        tax_rate: selected.tax_rate || 0,
        hsn_code: selected.hsn_code || "",
        unit: selected.unit || "",
        discount: 0,
        discount_type: "flat"
      };
    } else {
      newItems[index] = { item_id: "", item_name: "", description: "", quantity: 1, unit_price: 0, tax_rate: 0, discount: 0, discount_type: "flat", hsn_code: "", unit: "" };
    }
    setItems(newItems);
  };

  const addItemRow = () => {
    setItems([...items, { item_id: "", item_name: "", description: "", quantity: 1, unit_price: 0, tax_rate: 0, discount: 0, discount_type: "flat", hsn_code: "", unit: "" }]);
  };

  const removeItemRow = (index) => {
    if (items.length > 1) {
      setItems(items.filter((_, i) => i !== index));
    }
  };

  // Calculations
  const calcLineAmount = (item) => {
    const qty = parseFloat(item.quantity) || 0;
    const rate = parseFloat(item.unit_price) || 0;
    let amt = qty * rate;
    const disc = parseFloat(item.discount) || 0;
    if (item.discount_type === "percent") {
      amt -= amt * (disc / 100);
    } else {
      amt -= disc;
    }
    return amt;
  };

  const calcLineTax = (item) => {
    const amt = calcLineAmount(item);
    return amt * ((parseFloat(item.tax_rate) || 0) / 100);
  };

  const subtotal = items.reduce((sum, item) => sum + (parseFloat(item.quantity) || 0) * (parseFloat(item.unit_price) || 0), 0);
  const totalDiscount = items.reduce((sum, item) => {
    const qty = parseFloat(item.quantity) || 0;
    const rate = parseFloat(item.unit_price) || 0;
    const disc = parseFloat(item.discount) || 0;
    if (item.discount_type === "percent") return sum + (qty * rate * disc / 100);
    return sum + disc;
  }, 0);
  const totalTax = items.reduce((sum, item) => sum + calcLineTax(item), 0);
  const grandTotal = subtotal - totalDiscount + totalTax;

  const handleSave = async (statusOverride = null) => {
    if (!formData.vendor_id) { toast.error("Please select a vendor"); return; }
    
    setLoading(true);
    try {
      const finalStatus = statusOverride || formData.status || "draft";
      const payload = {
        ...formData,
        status: finalStatus,
        subtotal,
        discount_amount: totalDiscount,
        tax_amount: totalTax,
        total_amount: grandTotal,
        items: items.map(item => {
          const qty = parseFloat(item.quantity) || 0;
          const rate = parseFloat(item.unit_price) || 0;
          const disc = parseFloat(item.discount) || 0;
          let flatDisc = disc;
          if (item.discount_type === "percent") {
            flatDisc = (qty * rate) * (disc / 100);
          }
          const lineAmt = (qty * rate) - flatDisc;
          const tax = lineAmt * (parseFloat(item.tax_rate) || 0) / 100;
          return {
            item_id: item.item_id ? parseInt(item.item_id) : null,
            item_name: item.item_name || null,
            description: item.description || null,
            quantity: qty,
            unit_price: rate,
            tax_rate: parseFloat(item.tax_rate) || 0,
            discount: flatDisc,
            hsn_code: item.hsn_code || null,
            unit: item.unit || null,
            total: lineAmt + tax
          };
        })
      };

      if (isEditMode) {
        await apiRequest(`/bills/${id}`, { method: "PUT", body: JSON.stringify(payload) });
        toast.success("Bill updated");
        navigate(`/bills/${id}`);
      } else {
        const res = await apiRequest("/bills", { method: "POST", body: JSON.stringify(payload) });
        toast.success("Bill created");
        navigate(`/bills/${res.bill.id}`);
      }
    } catch (err) {
      toast.error(isEditMode ? "Update failed" : "Creation failed");
    } finally {
      setLoading(false);
    }
  };

  const handleSaveVendorSuccess = (newVendor) => {
    setShowVendorModal(false);
    setVendors(prev => [...prev, newVendor]);
    setFormData(prev => ({ ...prev, vendor_id: String(newVendor.id) }));
  };

  if (fetching) {
    return (
      <div style={{ maxWidth: "1120px", margin: "30px auto", padding: "30px" }}>
        <FormSkeleton fields={8} />
      </div>
    );
  }

  return (
    <div style={{ maxWidth: "1120px", margin: "30px auto", background: "#ffffff", borderRadius: "12px", border: "1px solid #eaecf0", boxShadow: "0 4px 20px rgba(16, 24, 40, 0.04)", overflow: "hidden", fontFamily: "system-ui, -apple-system, sans-serif" }}>
      
      {/* Styles Injection */}
      <style dangerouslySetInnerHTML={{__html: `
        .premium-input {
          width: 100%;
          padding: 8px 12px;
          border: 1px solid #d0d5dd;
          border-radius: 6px;
          font-size: 13px;
          color: #344054;
          background: #ffffff;
          box-sizing: border-box;
          outline: none;
          transition: all 0.15s ease;
        }
        .premium-input:hover {
          border-color: #98a2b3;
        }
        .premium-input:focus {
          border-color: #006ee6;
          box-shadow: 0 0 0 3px rgba(0, 110, 230, 0.1);
        }
        .table-input {
          border: 1px solid transparent;
          background: transparent;
          padding: 6px 8px;
          border-radius: 4px;
          font-size: 13px;
          outline: none;
          width: 100%;
          box-sizing: border-box;
          transition: all 0.1s ease;
        }
        .table-input:hover {
          border-color: #eaecf0;
          background: #f9fafb;
        }
        .table-input:focus {
          border-color: #006ee6 !important;
          background: #ffffff !important;
          box-shadow: 0 0 0 3px rgba(0, 110, 230, 0.1) !important;
        }
        .row-action-btn {
          opacity: 0.6;
          transition: opacity 0.15s ease, color 0.15s ease;
        }
        .row-action-btn:hover {
          opacity: 1;
          color: #d92d20;
        }
        .add-row-btn {
          border: 1px solid #d0d5dd;
          color: #344054;
          background: #ffffff;
          transition: all 0.15s ease;
        }
        .add-row-btn:hover {
          border-color: #006ee6;
          color: #006ee6;
          background: #f0f6ff;
        }
        .attach-box {
          border: 2px dashed #eaecf0;
          border-radius: 8px;
          padding: 24px;
          text-align: center;
          background: #fcfcfd;
          cursor: pointer;
          transition: all 0.15s ease;
        }
        .attach-box:hover {
          border-color: #006ee6;
          background: #f0f6ff;
        }
        .control-group-btn {
          padding: 10px 14px;
          background: #006ee6;
          color: #ffffff;
          border: none;
          border-radius: 0 6px 6px 0;
          cursor: pointer;
          font-weight: 500;
          display: flex;
          align-items: center;
          justify-content: center;
          transition: background 0.15s ease;
          outline: none;
        }
        .control-group-btn:hover {
          background: #0056b3;
        }
      `}} />

      {/* Form Header Banner */}
      <div style={{ borderBottom: "1px solid #eaecf0", padding: "20px 32px", display: "flex", justifyContent: "space-between", alignItems: "center", background: "#ffffff" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
          <button
            onClick={() => navigate(isEditMode ? `/bills/${id}` : "/bills")}
            style={{ border: "none", background: "none", cursor: "pointer", display: "flex", alignItems: "center", color: "#667085", padding: "4px", borderRadius: "4px" }}
            onMouseEnter={(e) => e.currentTarget.style.background = "#f2f4f7"}
            onMouseLeave={(e) => e.currentTarget.style.background = "none"}
          >
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <line x1="19" y1="12" x2="5" y2="12"></line>
              <polyline points="12 19 5 12 12 5"></polyline>
            </svg>
          </button>
          <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#006ee6" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
              <polyline points="14 2 14 8 20 8"></polyline>
              <line x1="16" y1="13" x2="8" y2="13"></line>
              <line x1="16" y1="17" x2="8" y2="17"></line>
              <polyline points="10 9 9 9 8 9"></polyline>
            </svg>
            <h2 style={{ margin: 0, fontSize: "18px", fontWeight: "600", color: "#1d2939" }}>
              {isEditMode ? "Edit Bill" : "New Bill"}
            </h2>
          </div>
        </div>
        <button
          onClick={() => navigate(isEditMode ? `/bills/${id}` : "/bills")}
          style={{ border: "none", background: "none", cursor: "pointer", fontSize: "20px", color: "#98a2b3", display: "flex", padding: "4px", borderRadius: "4px" }}
          onMouseEnter={(e) => e.currentTarget.style.background = "#f2f4f7"}
          onMouseLeave={(e) => e.currentTarget.style.background = "none"}
        >
          &times;
        </button>
      </div>

      {/* Main Form Area */}
      <div style={{ padding: "32px" }}>
        
        {/* Row 1: Vendor details & References */}
        <div style={{ display: "grid", gridTemplateColumns: "1.2fr 0.8fr 1fr", gap: "24px", marginBottom: "24px" }}>
          
          {/* Vendor Selection */}
          <div>
            <label style={labelStyle}>Vendor Name <span style={{ color: "#d92d20" }}>*</span></label>
            <div style={{ display: "flex", width: "100%" }}>
              <select 
                name="vendor_id"
                value={formData.vendor_id} 
                onChange={e => {
                  if (e.target.value === "new") setShowVendorModal(true);
                  else handleFormChange(e);
                }} 
                style={{ ...selectStyle, borderRadius: "6px 0 0 6px" }}
                className="premium-input"
                required
              >
                <option value="">Select or add a vendor</option>
                <option value="new" style={{ color: "#0ba5ec", fontWeight: "600" }}>+ New Vendor</option>
                {vendors.map(c => (
                  <option key={c.id} value={c.id}>
                    {c.display_name || [c.first_name, c.last_name].filter(Boolean).join(' ') || c.email}
                  </option>
                ))}
              </select>
              <button 
                type="button"
                onClick={() => setShowVendorModal(true)} 
                className="control-group-btn" 
                title="New Vendor"
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <line x1="12" y1="5" x2="12" y2="19"></line>
                  <line x1="5" y1="12" x2="19" y2="12"></line>
                </svg>
              </button>
            </div>
          </div>

          {/* Bill# */}
          <div>
            <label style={labelStyle}>Bill#</label>
            <input 
              type="text" 
              name="bill_number"
              value={formData.bill_number} 
              onChange={handleFormChange}
              placeholder="Leave blank to auto-generate" 
              className="premium-input"
            />
          </div>

          {/* Status Selection */}
          <div>
            <label style={labelStyle}>Status</label>
            <select 
              name="status"
              value={formData.status} 
              onChange={handleFormChange}
              style={selectStyle}
              className="premium-input"
            >
              <option value="draft">Draft</option>
              <option value="open">Open</option>
              <option value="paid">Paid</option>
            </select>
          </div>
        </div>

        {/* Row 2: Dates & payment terms */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "24px", marginBottom: "24px", borderTop: "1px solid #f2f4f7", paddingTop: "24px" }}>
          <div>
            <label style={labelStyle}>Bill Date <span style={{ color: "#d92d20" }}>*</span></label>
            <input 
              type="date" 
              name="bill_date"
              value={formData.bill_date} 
              onChange={handleFormChange}
              className="premium-input"
              required
            />
          </div>
          <div>
            <label style={labelStyle}>Due Date</label>
            <input 
              type="date" 
              name="due_date"
              value={formData.due_date} 
              onChange={handleFormChange}
              className="premium-input"
            />
          </div>
        </div>

        {/* Item Management Table */}
        <div style={{ borderTop: "1px solid #eaecf0", paddingTop: "24px", marginBottom: "24px" }}>
          <h3 style={{ margin: "0 0 16px 0", fontSize: "14px", fontWeight: "600", color: "#344054" }}>Item Details</h3>
          <div style={{ border: "1px solid #eaecf0", borderRadius: "8px", overflow: "hidden" }}>
            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "13px", textAlign: "left" }}>
              <thead>
                <tr style={{ background: "#f9fafb", borderBottom: "1px solid #eaecf0" }}>
                  <th style={{ ...thStyle, width: "30px" }}></th>
                  <th style={{ ...thStyle, width: "30%" }}>Item Details</th>
                  <th style={thStyle}>Description</th>
                  <th style={{ ...thStyle, width: "80px", textAlign: "right" }}>Qty</th>
                  <th style={{ ...thStyle, width: "110px", textAlign: "right" }}>Rate</th>
                  <th style={{ ...thStyle, width: "140px", textAlign: "right" }}>Discount</th>
                  <th style={{ ...thStyle, width: "80px", textAlign: "right" }}>Tax %</th>
                  <th style={{ ...thStyle, width: "120px", textAlign: "right" }}>Amount</th>
                  <th style={{ ...thStyle, width: "40px" }}></th>
                </tr>
              </thead>
              <tbody>
                {items.map((item, idx) => (
                  <tr key={idx} style={{ borderBottom: "1px solid #eaecf0" }}>
                    <td style={{ ...tdStyle, color: "#98a2b3" }}>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <circle cx="9" cy="5" r="1"></circle><circle cx="9" cy="12" r="1"></circle><circle cx="9" cy="19" r="1"></circle>
                        <circle cx="15" cy="5" r="1"></circle><circle cx="15" cy="12" r="1"></circle><circle cx="15" cy="19" r="1"></circle>
                      </svg>
                    </td>
                    <td style={tdStyle}>
                      <select 
                        value={item.item_id} 
                        onChange={e => handleItemSelect(idx, e.target.value)}
                        style={{ border: "1px solid #d0d5dd", padding: "6px", borderRadius: "4px", fontSize: "12px", width: "100%", color: "#344054" }}
                      >
                        <option value="">Type or select item...</option>
                        {catalogItems.map(ci => (
                          <option key={ci.id} value={ci.id}>{ci.name}</option>
                        ))}
                      </select>
                      {(item.hsn_code || item.unit) && (
                        <div style={{ fontSize: "10px", color: "#667085", marginTop: "4px", display: "flex", gap: "6px" }}>
                          {item.hsn_code && <span style={{ background: "#eff6ff", border: "1px solid #bfdbfe", borderRadius: "3px", padding: "1px 4px" }}>HSN: {item.hsn_code}</span>}
                          {item.unit && <span style={{ background: "#ecfdf5", border: "1px solid #a7f3d0", borderRadius: "3px", padding: "1px 4px" }}>Unit: {item.unit}</span>}
                        </div>
                      )}
                    </td>
                    <td style={tdStyle}>
                      <input 
                        type="text" 
                        placeholder="Description" 
                        value={item.description}
                        onChange={e => handleItemChange(idx, "description", e.target.value)} 
                        className="table-input" 
                      />
                    </td>
                    <td style={tdStyle}>
                      <input 
                        type="number" 
                        min="1" 
                        value={item.quantity}
                        onChange={e => handleItemChange(idx, "quantity", e.target.value)} 
                        className="table-input" 
                        style={{ textAlign: "right" }}
                      />
                    </td>
                    <td style={tdStyle}>
                      <input 
                        type="number" 
                        min="0" 
                        step="0.01" 
                        value={item.unit_price}
                        onChange={e => handleItemChange(idx, "unit_price", e.target.value)} 
                        className="table-input" 
                        style={{ textAlign: "right" }}
                      />
                    </td>
                    <td style={tdStyle}>
                      <div style={{ display: "flex", gap: "3px", alignItems: "center", justifyContent: "flex-end" }}>
                        <input 
                          type="number" 
                          min="0" 
                          step="0.01" 
                          value={item.discount}
                          onChange={e => handleItemChange(idx, "discount", e.target.value)} 
                          className="table-input" 
                          style={{ textAlign: "right", width: "60px" }}
                        />
                        <select 
                          value={item.discount_type} 
                          onChange={e => handleItemChange(idx, "discount_type", e.target.value)}
                          style={{ border: "1px solid #d0d5dd", padding: "4px", borderRadius: "4px", fontSize: "11px", color: "#475569" }}
                        >
                          <option value="flat">₹</option>
                          <option value="percent">%</option>
                        </select>
                      </div>
                    </td>
                    <td style={tdStyle}>
                      <input 
                        type="number" 
                        min="0" 
                        max="100" 
                        value={item.tax_rate}
                        onChange={e => handleItemChange(idx, "tax_rate", e.target.value)} 
                        className="table-input" 
                        style={{ textAlign: "right" }}
                      />
                    </td>
                    <td style={{ ...tdStyle, textAlign: "right", fontWeight: "600", color: "#1d2939" }}>
                      ₹{(calcLineAmount(item) + calcLineTax(item)).toFixed(2)}
                    </td>
                    <td style={tdStyle}>
                      {items.length > 1 && (
                        <button type="button" onClick={() => removeItemRow(idx)} className="row-action-btn" style={{ border: "none", background: "none", cursor: "pointer", color: "#667085", padding: 0 }}>
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                            <line x1="18" y1="6" x2="6" y2="18"></line>
                            <line x1="6" y1="6" x2="18" y2="18"></line>
                          </svg>
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div style={{ display: "flex", gap: "10px", marginTop: "12px" }}>
            <button type="button" onClick={addItemRow} className="add-row-btn" style={{ padding: "8px 16px", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>
              + Add New Row
            </button>
          </div>
        </div>

        {/* Lower split layout: Notes & Totals card */}
        <div style={{ display: "grid", gridTemplateColumns: "1.2fr 0.8fr", gap: "40px", borderTop: "1px solid #eaecf0", paddingTop: "32px", marginTop: "32px" }}>
          
          {/* Notes column */}
          <div>
            <div style={{ marginBottom: "20px" }}>
              <label style={labelStyle}>Notes</label>
              <textarea 
                name="notes"
                value={formData.notes} 
                onChange={handleFormChange}
                rows={4} 
                style={{ ...inputStyle, width: "100%", height: "120px", resize: "none" }} 
                placeholder="Notes for internal use or vendor details..." 
                className="premium-input"
              />
            </div>
          </div>

          {/* Totals & Upload Card */}
          <div>
            {/* Calculation summary */}
            <div style={{ background: "#fcfcfd", border: "1px solid #eaecf0", borderRadius: "8px", padding: "20px", marginBottom: "20px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "13px", color: "#667085" }}>
                <span>Sub Total</span>
                <span style={{ fontWeight: "500", color: "#344054" }}>₹{subtotal.toFixed(2)}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "13px", color: "#b91c1c" }}>
                <span>Total Discount</span>
                <span style={{ fontWeight: "500" }}>- ₹{totalDiscount.toFixed(2)}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "13px", color: "#0f766e" }}>
                <span>Total Tax</span>
                <span style={{ fontWeight: "500" }}>+ ₹{totalTax.toFixed(2)}</span>
              </div>
              
              <div style={{ display: "flex", justifyContent: "space-between", fontWeight: "700", fontSize: "15px", borderTop: "1px solid #eaecf0", paddingTop: "14px", color: "#1d2939" }}>
                <span>Total ( ₹ )</span>
                <span>₹{grandTotal.toFixed(2)}</span>
              </div>
            </div>

            {/* Attach File block */}
            <div className="attach-box" onClick={() => toast("File browser opened")}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#667085" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ marginBottom: "8px", opacity: 0.8 }}>
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="17 8 12 3 7 8"></polyline>
                <line x1="12" y1="3" x2="12" y2="15"></line>
              </svg>
              <div style={{ fontSize: "13px", fontWeight: "600", color: "#344054", marginBottom: "2px" }}>Upload Files</div>
              <div style={{ fontSize: "11px", color: "#667085" }}>Drag & Drop or click to upload. Max 5MB.</div>
            </div>
          </div>
        </div>

      </div>

      {/* Action Footer Bar */}
      <div style={{ background: "#f9fafb", borderTop: "1px solid #eaecf0", padding: "16px 32px", display: "flex", justifyContent: "flex-end", gap: "12px" }}>
        <button 
          type="button"
          onClick={() => navigate(isEditMode ? `/bills/${id}` : "/bills")} 
          style={{ background: "#ffffff", border: "1px solid #d0d5dd", color: "#344054", fontSize: "13px", fontWeight: "600", borderRadius: "6px", padding: "8px 16px", cursor: "pointer" }}
        >
          Cancel
        </button>
        <button 
          type="button"
          onClick={() => handleSave("draft")} 
          disabled={loading}
          style={{ background: "#ffffff", border: "1px solid #d0d5dd", color: "#344054", fontSize: "13px", fontWeight: "600", borderRadius: "6px", padding: "8px 16px", cursor: "pointer" }}
        >
          Save as Draft
        </button>
        <button 
          type="button"
          onClick={() => handleSave("open")} 
          disabled={loading} 
          style={{ background: "#006ee6", fontSize: "13px", fontWeight: "600", borderRadius: "6px", padding: "8px 16px", cursor: "pointer", border: "none", color: "#ffffff" }}
        >
          {loading ? "Saving..." : (isEditMode ? "Update Bill" : "Save as Open")}
        </button>
      </div>

      {/* ===== NEW VENDOR MODAL ===== */}
      {showVendorModal && (
        <div style={modalOverlay}>
          <div style={{ ...modalBox, width: "950px", maxWidth: "95vw", maxHeight: "90vh", padding: "10px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 20px 0 20px" }}>
              <h3 style={{ margin: 0, fontSize: "18px", color: "#1d2939" }}>+ New Vendor</h3>
              <button type="button" onClick={() => setShowVendorModal(false)} style={{ background: "none", border: "none", fontSize: "24px", cursor: "pointer", color: "#98a2b3" }}>&times;</button>
            </div>
            <AddVendor isModal={true} onSaveSuccess={handleSaveVendorSuccess} onCancel={() => setShowVendorModal(false)} />
          </div>
        </div>
      )}
    </div>
  );
}

// Inline constant styles
const labelStyle = {
  display: "block",
  fontSize: "12px",
  fontWeight: "600",
  color: "#344054",
  marginBottom: "6px",
};

const inputStyle = {
  boxSizing: "border-box",
};

const selectStyle = {
  width: "100%",
  boxSizing: "border-box",
};

const thStyle = {
  padding: "10px 12px",
  color: "#475569",
  fontSize: "11px",
  fontWeight: "600",
  textTransform: "uppercase",
  letterSpacing: "0.05em",
  borderBottom: "1px solid #eaecf0",
};

const tdStyle = {
  padding: "8px 12px",
  verticalAlign: "top",
};

const modalOverlay = {
  position: "fixed",
  top: 0,
  left: 0,
  right: 0,
  bottom: 0,
  background: "rgba(16, 24, 40, 0.4)",
  backdropFilter: "blur(4px)",
  display: "flex",
  justifyContent: "center",
  alignItems: "center",
  zIndex: 1000,
};

const modalBox = {
  background: "#ffffff",
  borderRadius: "12px",
  padding: "24px",
  width: "550px",
  maxWidth: "95%",
  maxHeight: "90vh",
  overflowY: "auto",
  boxShadow: "0 20px 24px -4px rgba(16, 24, 40, 0.08), 0 8px 8px -4px rgba(16, 24, 40, 0.03)",
};

export default AddBill;
