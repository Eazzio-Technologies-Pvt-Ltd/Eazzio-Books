/**
 * AddVendorCredit.js – Modernized Zoho-style Vendor Credit creation & edit form
 */
import React, { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { apiRequest } from "./api";
import { FormSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";
import AddVendor from "./AddVendor";

function AddVendorCredit() {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditMode = Boolean(id);

  // --- Basic fields ---
  const [vendorId, setVendorId] = useState("");
  const [billId, setBillId] = useState("");
  const [vendorCreditDate, setVendorCreditDate] = useState(new Date().toISOString().slice(0, 10));
  const [referenceNumber, setReferenceNumber] = useState("");
  const [reason, setReason] = useState("");
  const [notes, setNotes] = useState("");
  const [terms, setTerms] = useState("");

  // --- Items ---
  const [items, setItems] = useState([
    { item_id: "", item_name: "", description: "", quantity: 1, rate: 0, discount: 0, discount_type: "flat", tax_rate: 0 }
  ]);

  // --- Calculations ---
  const [subTotal, setSubTotal] = useState(0);
  const [totalDiscount, setTotalDiscount] = useState(0);
  const [totalTax, setTotalTax] = useState(0);
  const [grandTotal, setGrandTotal] = useState(0);

  // --- Dropdown data ---
  const [vendors, setVendors] = useState([]);
  const [creditNotes, setCreditNotes] = useState([]);
  const [catalogItems, setCatalogItems] = useState([]);
  const [taxes, setTaxes] = useState([]);
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(false);

  // --- Modals ---
  const [showVendorModal, setShowVendorModal] = useState(false);

  useEffect(() => {
    const fetchAll = async () => {
      try {
        const [vendorRes, itemRes, cnRes, taxRes] = await Promise.all([
          apiRequest("/vendors"),
          apiRequest("/items"),
          apiRequest("/credit-notes"),
          apiRequest("/taxes"),
        ]);
        setVendors(vendorRes?.vendors || []);
        setCatalogItems(itemRes?.items || []);
        setCreditNotes(cnRes?.credit_notes || []);
        setTaxes(taxRes?.taxes || []);

        if (isEditMode) {
          setFetching(true);
          const res = await apiRequest(`/vendor-credits/${id}`);
          if (res?.vendor_credit) {
            const vc = res.vendor_credit;
            if (parseFloat(vc.applied_amount) > 0) {
              toast.error("Cannot edit a vendor credit that has already been applied to a bill.");
              navigate("/vendor-credits");
              return;
            }
            setVendorId(vc.vendor_id ? String(vc.vendor_id) : "");
            setBillId(vc.bill_id ? String(vc.bill_id) : "");
            setVendorCreditDate(vc.vendor_credit_date ? vc.vendor_credit_date.slice(0, 10) : "");
            setReferenceNumber(vc.reference_number || "");
            setReason(vc.reason || "");
            setNotes(vc.notes || "");
            setTerms(vc.terms_conditions || "");
            if (res.items && res.items.length > 0) {
              setItems(res.items.map(item => ({
                item_id:       item.item_id       ? String(item.item_id)  : "",
                item_name:     item.item_name     || "",
                description:   item.description   || "",
                quantity:      item.quantity      || 1,
                rate:          item.rate          || 0,
                discount:      item.discount      || 0,
                discount_type: item.discount_type || "flat",
                tax_rate:      item.tax_rate      || 0,
              })));
            }
          }
        }
      } catch (err) {
        console.error("Failed to load data", err);
      } finally {
        setFetching(false);
      }
    };
    fetchAll();
  }, [id, isEditMode, navigate]);

  // Recalculate totals whenever items change
  useEffect(() => {
    let sTotal = 0, dTotal = 0, tTotal = 0;
    items.forEach(item => {
      const q = parseFloat(item.quantity) || 0;
      const r = parseFloat(item.rate) || 0;
      const rowSub = q * r;
      sTotal += rowSub;

      let d = parseFloat(item.discount) || 0;
      let rowDisc = 0;
      if (item.discount_type === "percent") {
        rowDisc = rowSub * (d / 100);
      } else {
        rowDisc = d;
      }
      dTotal += rowDisc;

      const taxable = rowSub - rowDisc;
      const taxRate = parseFloat(item.tax_rate) || 0;
      tTotal += taxable * (taxRate / 100);
    });
    setSubTotal(sTotal);
    setTotalDiscount(dTotal);
    setTotalTax(tTotal);
    setGrandTotal(sTotal - dTotal + tTotal);
  }, [items]);

  const addItem = () => {
    setItems([...items, { item_id: "", item_name: "", description: "", quantity: 1, rate: 0, discount: 0, discount_type: "flat", tax_rate: 0 }]);
  };

  const removeItem = (index) => {
    setItems(items.filter((_, i) => i !== index));
  };

  const updateItem = (index, field, value) => {
    const updated = [...items];
    updated[index][field] = value;
    setItems(updated);
  };

  const handleItemSelect = (index, itemId) => {
    const updated = [...items];
    updated[index].item_id = itemId;
    if (itemId) {
      const catalogItem = catalogItems.find(ci => String(ci.id) === String(itemId));
      if (catalogItem) {
        updated[index].item_name   = catalogItem.name || "";
        updated[index].description = catalogItem.description || catalogItem.name || "";
        updated[index].rate        = catalogItem.purchase_price || catalogItem.selling_price || 0;
        if (catalogItem.tax_id) {
          const tax = taxes.find(t => String(t.id) === String(catalogItem.tax_id));
          if (tax) updated[index].tax_rate = tax.rate;
        }
      }
    } else {
      updated[index].item_name = "";
      updated[index].rate = 0;
      updated[index].tax_rate = 0;
    }
    setItems(updated);
  };

  // Pre-fill bill items optionally
  const handleBillSelect = async (bId) => {
    setBillId(bId);
    if (!bId) return;
    
    if (window.confirm("Do you want to copy items from this credit note? This will replace your current items.")) {
      try {
        const res = await apiRequest(`/credit-notes/${bId}`);
        if(res?.items) {
          setItems(res.items.map(i => ({
            item_id: i.item_id ? String(i.item_id) : "",
            item_name: i.item_name || "",
            description: i.description || "",
            quantity: i.quantity || 1,
            rate: i.rate || i.unit_price || 0,
            discount: i.discount || 0,
            discount_type: i.discount_type || "percent",
            tax_rate: i.tax_rate || 0,
          })));
        }
      } catch(err) {
        toast.error("Failed to load credit note items");
      }
    }
  };

  const handleSave = async () => {
    if (!vendorId) { toast.error("Please select a vendor"); return; }
    if (items.length === 0 || items.every(item => !item.description && !item.item_id && !item.rate)) {
      toast.error("Add at least one item or amount"); return;
    }
    
    for(const item of items) {
      if(parseFloat(item.quantity) <= 0) {
        toast.error("Quantity must be greater than zero"); return;
      }
      if(parseFloat(item.rate) < 0) {
        toast.error("Rate cannot be negative"); return;
      }
    }

    setLoading(true);
    try {
      const payload = {
        vendor_id: parseInt(vendorId),
        bill_id: billId ? parseInt(billId) : null,
        vendor_credit_date: vendorCreditDate,
        reference_number: referenceNumber,
        reason: reason,
        notes: notes,
        terms_conditions: terms,
        items: items.map(item => ({
          ...item,
          item_id:   item.item_id   ? parseInt(item.item_id) : null,
          item_name: item.item_name || null,
          quantity:  parseFloat(item.quantity) || 0,
          rate:      parseFloat(item.rate) || 0,
          discount:  parseFloat(item.discount) || 0,
          tax_rate:  parseFloat(item.tax_rate) || 0,
        })),
      };

      if (isEditMode) {
        await apiRequest(`/vendor-credits/${id}`, {
          method: "PUT",
          body: JSON.stringify(payload),
        });
        toast.success("Vendor Credit updated");
        navigate(`/vendor-credits/${id}/document`);
      } else {
        payload.status = "Draft";
        await apiRequest("/vendor-credits", {
          method: "POST",
          body: JSON.stringify(payload),
        });
        toast.success("Vendor Credit created");
        navigate("/vendor-credits");
      }
    } catch (err) {
      toast.error(err.message || (isEditMode ? "Failed to update Vendor Credit" : "Failed to create Vendor Credit"));
    } finally {
      setLoading(false);
    }
  };

  const handleSaveVendorSuccess = (newVendor) => {
    setShowVendorModal(false);
    setVendors(prev => [...prev, newVendor]);
    setVendorId(String(newVendor.id));
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
            onClick={() => navigate(isEditMode ? `/vendor-credits/${id}/document` : "/vendor-credits")}
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
              <circle cx="9" cy="21" r="1"></circle>
              <circle cx="20" cy="21" r="1"></circle>
              <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
            </svg>
            <h2 style={{ margin: 0, fontSize: "18px", fontWeight: "600", color: "#1d2939" }}>
              {isEditMode ? "Edit Vendor Credit" : "New Vendor Credit"}
            </h2>
          </div>
        </div>
        <button
          onClick={() => navigate(isEditMode ? `/vendor-credits/${id}/document` : "/vendor-credits")}
          style={{ border: "none", background: "none", cursor: "pointer", fontSize: "20px", color: "#98a2b3", display: "flex", padding: "4px", borderRadius: "4px" }}
          onMouseEnter={(e) => e.currentTarget.style.background = "#f2f4f7"}
          onMouseLeave={(e) => e.currentTarget.style.background = "none"}
        >
          &times;
        </button>
      </div>

      {/* Main Form Area */}
      <div style={{ padding: "32px" }}>
        
        {/* Row 1: Vendor Name, Bill selection, Reference# */}
        <div style={{ display: "grid", gridTemplateColumns: "1.2fr 0.8fr 1fr", gap: "24px", marginBottom: "24px" }}>
          
          {/* Vendor Selection */}
          <div>
            <label style={labelStyle}>Vendor Name <span style={{ color: "#d92d20" }}>*</span></label>
            <div style={{ display: "flex", width: "100%" }}>
              <select 
                value={vendorId} 
                onChange={e => {
                  if (e.target.value === "new") setShowVendorModal(true);
                  else setVendorId(e.target.value);
                }} 
                style={{ ...selectStyle, borderRadius: "6px 0 0 6px" }}
                className="premium-input"
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

          {/* Credit Note */}
          <div>
            <label style={labelStyle}>Credit Note</label>
            <select 
              value={billId} 
              onChange={e => handleBillSelect(e.target.value)} 
              style={selectStyle}
              className="premium-input"
            >
              <option value="">Select Credit Note</option>
              {creditNotes.filter(cn => !vendorId || String(cn.customer_id) === vendorId || String(cn.vendor_id) === vendorId).map(cn => (
                <option key={cn.id} value={cn.id}>
                  {cn.credit_note_number} (Total: ₹{parseFloat(cn.total).toFixed(2)})
                </option>
              ))} 
            </select>
          </div>

          {/* Order Number */}
          <div>
            <label style={labelStyle}>Order Number</label>
            <input 
              type="text" 
              value={referenceNumber} 
              onChange={e => setReferenceNumber(e.target.value)} 
              placeholder="e.g. Ord-12345" 
              className="premium-input"
            />
          </div>
        </div>

        {/* Row 2: Dates, Reason */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1.5fr", gap: "24px", marginBottom: "32px", borderTop: "1px solid #f2f4f7", paddingTop: "24px" }}>
          <div>
            <label style={labelStyle}>Vendor Credit Date <span style={{ color: "#d92d20" }}>*</span></label>
            <input 
              type="date" 
              value={vendorCreditDate} 
              onChange={e => setVendorCreditDate(e.target.value)} 
              className="premium-input"
            />
          </div>
          <div>
            <label style={labelStyle}>Subject</label>
            <input 
              type="text" 
              value={reason} 
              onChange={e => setReason(e.target.value)} 
              placeholder="e.g. Items returned, Price adjustment" 
              className="premium-input"
            />
          </div>
        </div>

        {/* Item Details Table */}
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
                  <th style={{ ...thStyle, width: "120px", textAlign: "right" }}>Tax</th>
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
                    </td>
                    <td style={tdStyle}>
                      <input 
                        type="text" 
                        placeholder="Description" 
                        value={item.description}
                        onChange={e => updateItem(idx, "description", e.target.value)} 
                        className="table-input" 
                      />
                    </td>
                    <td style={tdStyle}>
                      <input 
                        type="number" 
                        min="0" 
                        value={item.quantity}
                        onChange={e => updateItem(idx, "quantity", e.target.value)} 
                        className="table-input" 
                        style={{ textAlign: "right" }}
                      />
                    </td>
                    <td style={tdStyle}>
                      <input 
                        type="number" 
                        min="0" 
                        step="0.01" 
                        value={item.rate}
                        onChange={e => updateItem(idx, "rate", e.target.value)} 
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
                          onChange={e => updateItem(idx, "discount", e.target.value)} 
                          className="table-input" 
                          style={{ textAlign: "right", width: "60px" }}
                        />
                        <select 
                          value={item.discount_type} 
                          onChange={e => updateItem(idx, "discount_type", e.target.value)}
                          style={{ border: "1px solid #d0d5dd", padding: "4px", borderRadius: "4px", fontSize: "11px", color: "#475569" }}
                        >
                          <option value="flat">₹</option>
                          <option value="percent">%</option>
                        </select>
                      </div>
                    </td>
                    <td style={tdStyle}>
                      <select 
                        value={item.tax_rate} 
                        onChange={e => updateItem(idx, "tax_rate", e.target.value)}
                        style={{ border: "1px solid #d0d5dd", padding: "6px", borderRadius: "4px", fontSize: "12px", width: "100%", color: "#344054" }}
                      >
                        <option value="0">Non-Taxable</option>
                        {taxes.map(t => (
                          <option key={t.id} value={t.rate}>{t.tax_name} ({t.rate}%)</option>
                        ))}
                      </select>
                    </td>
                    <td style={{ ...tdStyle, textAlign: "right", fontWeight: "600", color: "#1d2939" }}>
                      {(() => {
                        const q = parseFloat(item.quantity) || 0;
                        const r = parseFloat(item.rate) || 0;
                        const d = parseFloat(item.discount) || 0;
                        const t = parseFloat(item.tax_rate) || 0;
                        const sub = q * r;
                        const disc = item.discount_type === "percent" ? sub * (d / 100) : d;
                        const tax = (sub - disc) * (t / 100);
                        return `₹${(sub - disc + tax).toFixed(2)}`;
                      })()}
                    </td>
                    <td style={tdStyle}>
                      {items.length > 1 && (
                        <button 
                          type="button"
                          onClick={() => removeItem(idx)} 
                          className="row-action-btn" 
                          style={{ border: "none", background: "none", cursor: "pointer", color: "#667085", padding: 0 }}
                        >
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

          <div style={{ marginTop: "16px" }}>
            <button 
              type="button" 
              onClick={addItem} 
              className="add-row-btn"
              style={{ padding: "8px 16px", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}
            >
              + Add Row
            </button>
          </div>
        </div>

        {/* Calculations Block */}
        <div style={{ display: "grid", gridTemplateColumns: "1.5fr 1fr", gap: "32px", marginTop: "32px" }}>
          <div></div>
          <div style={{ background: "#f9fafb", border: "1px solid #eaecf0", borderRadius: "8px", padding: "24px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "14px", color: "#475569" }}>
              <span>Sub Total</span>
              <span style={{ fontWeight: "500", color: "#1d2939" }}>₹{subTotal.toFixed(2)}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "14px", color: "#475569" }}>
              <span>Discount</span>
              <span style={{ fontWeight: "500", color: "#d92d20" }}>-₹{totalDiscount.toFixed(2)}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "14px", color: "#475569" }}>
              <span>Tax</span>
              <span style={{ fontWeight: "500", color: "#1d2939" }}>₹{totalTax.toFixed(2)}</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", borderTop: "1px solid #eaecf0", paddingTop: "16px", marginTop: "16px", fontSize: "16px", fontWeight: "700", color: "#1d2939" }}>
              <span>Total Amount (₹)</span>
              <span style={{ color: "#006ee6" }}>₹{grandTotal.toFixed(2)}</span>
            </div>
          </div>
        </div>

        {/* Notes & Terms */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "24px", marginTop: "32px", borderTop: "1px solid #f2f4f7", paddingTop: "32px" }}>
          <div>
            <label style={labelStyle}>Notes</label>
            <textarea 
              value={notes} 
              onChange={e => setNotes(e.target.value)}
              rows={4} 
              className="premium-input" 
              placeholder="Any specific notes for this vendor credit." 
              style={{ resize: "vertical" }}
            />
          </div>
          <div>
            <label style={labelStyle}>Terms & Conditions</label>
            <textarea 
              value={terms} 
              onChange={e => setTerms(e.target.value)}
              rows={4} 
              className="premium-input" 
              placeholder="Terms and conditions..." 
              style={{ resize: "vertical" }}
            />
          </div>
        </div>

        {/* Form Actions */}
        <div style={{ display: "flex", gap: "12px", justifyContent: "flex-end", marginTop: "32px", borderTop: "1px solid #eaecf0", paddingTop: "24px" }}>
          <button 
            type="button" 
            onClick={() => navigate(isEditMode ? `/vendor-credits/${id}/document` : "/vendor-credits")} 
            className="premium-input"
            style={{ width: "auto", padding: "10px 18px", background: "#ffffff", border: "1px solid #d0d5dd", borderRadius: "6px", cursor: "pointer", fontWeight: "600", color: "#344054" }}
          >
            Cancel
          </button>
          <button 
            type="button" 
            onClick={handleSave} 
            disabled={loading}
            style={{ background: "#006ee6", fontSize: "13px", fontWeight: "600", borderRadius: "6px", padding: "10px 20px", cursor: "pointer", border: "none", color: "#ffffff" }}
          >
            {loading ? "Saving..." : (isEditMode ? "Update Vendor Credit" : "Save Vendor Credit")}
          </button>
        </div>

      </div>

      {/* ===== NEW VENDOR MODAL ===== */}
      {showVendorModal && (
        <div style={modalOverlay}>
          <div style={{ ...modalBox, width: "950px", maxWidth: "95vw", maxHeight: "90vh", padding: "10px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "10px 20px 0 20px" }}>
              <h3 style={{ margin: 0, fontSize: "18px", color: "#1d2939" }}>+ New Vendor</h3>
              <button onClick={() => setShowVendorModal(false)} style={{ background: "none", border: "none", fontSize: "24px", cursor: "pointer", color: "#98a2b3" }}>&times;</button>
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

export default AddVendorCredit;
