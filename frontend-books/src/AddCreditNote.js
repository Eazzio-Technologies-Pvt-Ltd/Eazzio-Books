/**
 * AddCreditNote.js – Modernized Zoho-style Credit Note creation & edit form
 */
import React, { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { apiRequest } from "./api";
import { FormSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

function AddCreditNote() {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditMode = Boolean(id);

  // --- Basic fields ---
  const [customerId, setCustomerId] = useState("");
  const [invoiceId, setInvoiceId] = useState("");
  const [creditNoteDate, setCreditNoteDate] = useState(new Date().toISOString().slice(0, 10));
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
  const [adjustment, setAdjustment] = useState("");

  // --- Dropdown data ---
  const [customers, setCustomers] = useState([]);
  const [invoices, setInvoices] = useState([]);
  const [catalogItems, setCatalogItems] = useState([]);
  const [taxes, setTaxes] = useState([]);
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(false);

  // --- Modals ---
  const [showCustomerModal, setShowCustomerModal] = useState(false);

  // --- New Customer form ---
  const [newCustomer, setNewCustomer] = useState({ display_name: "", company_name: "", email: "", phone: "", billing_address: "", pan: "" });

  useEffect(() => {
    const fetchAll = async () => {
      try {
        const [custRes, itemRes, invRes, taxRes] = await Promise.all([
          apiRequest("/customers"),
          apiRequest("/items"),
          apiRequest("/invoices"),
          apiRequest("/taxes"),
        ]);
        setCustomers(custRes?.customers || []);
        setCatalogItems(itemRes?.items || []);
        setInvoices(invRes?.invoices || []);
        setTaxes(taxRes?.taxes || []);

        if (isEditMode) {
          setFetching(true);
          const res = await apiRequest(`/credit-notes/${id}`);
          if (res?.credit_note) {
            const cn = res.credit_note;
            if (parseFloat(cn.applied_amount) > 0) {
              toast.error("Cannot edit a credit note that has already been applied to an invoice.");
              navigate("/credit-notes");
              return;
            }
            setCustomerId(cn.customer_id ? String(cn.customer_id) : "");
            setInvoiceId(cn.invoice_id ? String(cn.invoice_id) : "");
            setCreditNoteDate(cn.credit_note_date ? cn.credit_note_date.slice(0, 10) : "");
            setReferenceNumber(cn.reference_number || "");
            setReason(cn.reason || "");
            setNotes(cn.notes || "");
            setTerms(cn.terms_conditions || "");
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
    
    const adj = parseFloat(adjustment) || 0;

    setSubTotal(sTotal);
    setTotalDiscount(dTotal);
    setTotalTax(tTotal);
    setGrandTotal(sTotal - dTotal + tTotal + adj);
  }, [items, adjustment]);

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
        updated[index].rate        = catalogItem.selling_price || 0;
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

  // Pre-fill invoice items optionally
  const handleInvoiceSelect = async (invId) => {
    setInvoiceId(invId);
    if (!invId) return;
    
    if (window.confirm("Do you want to copy items from this invoice? This will replace your current items.")) {
        try {
            const res = await apiRequest(`/invoices/${invId}`);
            if(res?.items) {
                setItems(res.items.map(i => ({
                    item_id: i.item_id ? String(i.item_id) : "",
                    item_name: i.item_name || "",
                    description: i.description || "",
                    quantity: i.quantity || 1,
                    rate: i.unit_price || 0,
                    discount: i.discount || 0,
                    discount_type: "percent", // original invoice assumed percent for discount column
                    tax_rate: i.tax_rate || 0,
                })));
            }
        } catch(err) {
            toast.error("Failed to load invoice items");
        }
    }
  };

  const handleSave = async (statusOverride = null) => {
    if (!customerId) { toast.error("Please select a customer"); return; }
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
        customer_id: parseInt(customerId),
        invoice_id: invoiceId ? parseInt(invoiceId) : null,
        credit_note_date: creditNoteDate,
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
        if(statusOverride) payload.status = statusOverride;
        await apiRequest(`/credit-notes/${id}`, {
          method: "PUT",
          body: JSON.stringify(payload),
        });
        toast.success("Credit Note updated");
        navigate(`/credit-notes/${id}/document`);
      } else {
        payload.status = statusOverride || "Draft";
        await apiRequest("/credit-notes", {
          method: "POST",
          body: JSON.stringify(payload),
        });
        toast.success("Credit Note created");
        navigate("/credit-notes");
      }
    } catch (err) {
      toast.error(err.message || (isEditMode ? "Failed to update Credit Note" : "Failed to create Credit Note"));
    } finally {
      setLoading(false);
    }
  };

  const handleSaveCustomer = async () => {
    if (!newCustomer.display_name && !newCustomer.company_name) { toast.error("Customer name required"); return; }
    try {
      const res = await apiRequest("/customers", {
        method: "POST",
        body: JSON.stringify(newCustomer),
      });
      if (res?.customer) {
        setCustomers(prev => [...prev, res.customer]);
        setCustomerId(String(res.customer.id));
        toast.success("Customer created");
      }
      setShowCustomerModal(false);
      setNewCustomer({ display_name: "", company_name: "", email: "", phone: "", billing_address: "", pan: "" });
    } catch (err) { toast.error("Failed to create customer"); }
  };

  if (fetching) {
    return (
      <div style={{ maxWidth: "1120px", margin: "30px auto", padding: "30px" }}>
        <FormSkeleton fields={8} />
      </div>
    );
  }

  const labelStyle = { display: "block", marginBottom: "6px", fontSize: "13px", fontWeight: "500", color: "#344054" };
  const thStyle = { padding: "12px 16px", color: "#475569", fontWeight: "600", fontSize: "12px", borderBottom: "1px solid #eaecf0", letterSpacing: "0.02em" };
  const tdStyle = { padding: "12px 16px", verticalAlign: "top" };
  const selectStyle = { width: "100%", padding: "8px 12px", borderRadius: "6px", border: "1px solid #d0d5dd", boxSizing: "border-box", fontSize: "13px", color: "#344054", background: "#ffffff", outline: "none", transition: "all 0.15s ease" };
  const inputStyle = { width: "100%", padding: "8px 12px", borderRadius: "6px", border: "1px solid #d0d5dd", boxSizing: "border-box", fontSize: "13px", color: "#344054", background: "#ffffff", outline: "none", transition: "all 0.15s ease" };

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
        .premium-input:hover { border-color: #98a2b3; }
        .premium-input:focus { border-color: #006ee6; box-shadow: 0 0 0 3px rgba(0, 110, 230, 0.1); }
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
        .table-input:hover { border-color: #eaecf0; background: #f9fafb; }
        .table-input:focus { border-color: #006ee6 !important; background: #ffffff !important; box-shadow: 0 0 0 3px rgba(0, 110, 230, 0.1) !important; }
        .row-action-btn { opacity: 0.6; transition: opacity 0.15s ease, color 0.15s ease; }
        .row-action-btn:hover { opacity: 1; color: #d92d20; }
        .add-row-btn { border: 1px solid #d0d5dd; color: #344054; background: #ffffff; transition: all 0.15s ease; }
        .add-row-btn:hover { border-color: #006ee6; color: #006ee6; background: #f0f6ff; }
        .attach-box { border: 2px dashed #eaecf0; border-radius: 8px; padding: 24px; text-align: center; background: #fcfcfd; cursor: pointer; transition: all 0.15s ease; }
        .attach-box:hover { border-color: #006ee6; background: #f0f6ff; }
        .control-group-btn {
          padding: 10px 14px; background: #006ee6; color: #ffffff; border: none; borderRadius: 0 6px 6px 0; cursor: pointer; font-weight: 500; display: flex; align-items: center; justify-content: center; transition: background 0.15s ease; outline: none;
        }
        .control-group-btn:hover { background: #0056b3; }
      `}} />

      {/* Form Header Banner */}
      <div style={{ borderBottom: "1px solid #eaecf0", padding: "20px 32px", display: "flex", justifyContent: "space-between", alignItems: "center", background: "#ffffff" }}>
        <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
          <button onClick={() => navigate(isEditMode ? `/credit-notes/${id}/document` : "/credit-notes")} style={{ border: "none", background: "none", cursor: "pointer", display: "flex", alignItems: "center", color: "#667085", padding: "4px", borderRadius: "4px" }} onMouseEnter={(e) => e.currentTarget.style.background = "#f2f4f7"} onMouseLeave={(e) => e.currentTarget.style.background = "none"}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>
          </button>
          <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#006ee6" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path><polyline points="14 2 14 8 20 8"></polyline><line x1="16" y1="13" x2="8" y2="13"></line><line x1="16" y1="17" x2="8" y2="17"></line><polyline points="10 9 9 9 8 9"></polyline></svg>
            <h2 style={{ margin: 0, fontSize: "18px", fontWeight: "600", color: "#1d2939" }}>
              {isEditMode ? "Edit Credit Note" : "New Credit Note"}
            </h2>
          </div>
        </div>
        <button onClick={() => navigate(isEditMode ? `/credit-notes/${id}/document` : "/credit-notes")} style={{ border: "none", background: "none", cursor: "pointer", fontSize: "20px", color: "#98a2b3", display: "flex", padding: "4px", borderRadius: "4px" }} onMouseEnter={(e) => e.currentTarget.style.background = "#f2f4f7"} onMouseLeave={(e) => e.currentTarget.style.background = "none"}>&times;</button>
      </div>

      {/* Main Form Area */}
      <div style={{ padding: "32px" }}>
        
        {/* Row 1: Customer details & References */}
        <div style={{ display: "grid", gridTemplateColumns: "1.2fr 0.8fr 1fr", gap: "24px", marginBottom: "24px" }}>
          
          {/* Customer Selection */}
          <div>
            <label style={labelStyle}>Customer Name <span style={{ color: "#d92d20" }}>*</span></label>
            <div style={{ display: "flex", width: "100%" }}>
              <select value={customerId} onChange={e => {
                  if (e.target.value === "new") setShowCustomerModal(true);
                  else setCustomerId(e.target.value);
                }} style={{ ...selectStyle, borderRadius: "6px 0 0 6px" }} className="premium-input">
                <option value="">Select or add a customer</option>
                <option value="new" style={{ color: "#0ba5ec", fontWeight: "600" }}>+ New Customer</option>
                {customers.map(c => (
                  <option key={c.id} value={c.id}>{c.display_name || [c.first_name, c.last_name].filter(Boolean).join(' ') || c.email}</option>
                ))}
              </select>
              <button onClick={() => setShowCustomerModal(true)} className="control-group-btn" title="New Customer">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
              </button>
            </div>
          </div>

          {/* Invoice Select */}
          <div>
            <label style={labelStyle}>Invoice (Optional)</label>
            <select value={invoiceId} onChange={e => handleInvoiceSelect(e.target.value)} className="premium-input">
              <option value="">Select Invoice</option>
              {invoices.filter(inv => !customerId || String(inv.customer_id) === String(customerId)).map(inv => (
                <option key={inv.id} value={inv.id}>
                  {inv.invoice_number} (Bal: ₹{parseFloat(inv.balance_due).toFixed(2)})
                </option>
              ))}
            </select>
          </div>

          {/* Reference# */}
          <div>
            <label style={labelStyle}>Reference#</label>
            <input type="text" value={referenceNumber} onChange={e => setReferenceNumber(e.target.value)} placeholder="e.g. Return-001" className="premium-input" />
          </div>
        </div>

        {/* Row 2: Dates & reason */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 2fr", gap: "24px", marginBottom: "24px", borderTop: "1px solid #f2f4f7", paddingTop: "24px" }}>
          <div>
            <label style={labelStyle}>Credit Note Date <span style={{ color: "#d92d20" }}>*</span></label>
            <input type="date" value={creditNoteDate} onChange={e => setCreditNoteDate(e.target.value)} className="premium-input" />
          </div>
          <div>
            <label style={labelStyle}>Reason / Subject</label>
            <input type="text" value={reason} onChange={e => setReason(e.target.value)} placeholder="e.g. Items returned, Price adjustment" className="premium-input" />
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
                  <th style={{ ...thStyle, width: "25%" }}>Item Details</th>
                  <th style={thStyle}>Description</th>
                  <th style={{ ...thStyle, width: "80px", textAlign: "right" }}>Qty</th>
                  <th style={{ ...thStyle, width: "100px", textAlign: "right" }}>Rate</th>
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
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="9" cy="5" r="1"></circle><circle cx="9" cy="12" r="1"></circle><circle cx="9" cy="19" r="1"></circle><circle cx="15" cy="5" r="1"></circle><circle cx="15" cy="12" r="1"></circle><circle cx="15" cy="19" r="1"></circle></svg>
                    </td>
                    <td style={tdStyle}>
                      <select value={item.item_id} onChange={e => handleItemSelect(idx, e.target.value)} style={{ border: "1px solid #d0d5dd", padding: "6px", borderRadius: "4px", fontSize: "12px", width: "100%", color: "#344054" }}>
                        <option value="">Type or select item...</option>
                        {catalogItems.map(ci => (<option key={ci.id} value={ci.id}>{ci.name}</option>))}
                      </select>
                    </td>
                    <td style={tdStyle}>
                      <input type="text" placeholder="Description" value={item.description} onChange={e => updateItem(idx, "description", e.target.value)} className="table-input" />
                    </td>
                    <td style={tdStyle}>
                      <input type="number" min="0" value={item.quantity} onChange={e => updateItem(idx, "quantity", e.target.value)} className="table-input" style={{ textAlign: "right" }} />
                    </td>
                    <td style={tdStyle}>
                      <input type="number" min="0" step="0.01" value={item.rate} onChange={e => updateItem(idx, "rate", e.target.value)} className="table-input" style={{ textAlign: "right" }} />
                    </td>
                    <td style={tdStyle}>
                      <div style={{ display: "flex", border: "1px solid #transparent", borderRadius: "4px", overflow: "hidden", background: "transparent" }}>
                        <input type="number" min="0" step="0.01" value={item.discount} onChange={e => updateItem(idx, "discount", e.target.value)} className="table-input" style={{ width: "60px", textAlign: "right", borderRadius: "4px 0 0 4px" }} />
                        <select value={item.discount_type} onChange={e => updateItem(idx, "discount_type", e.target.value)} style={{ border: "none", background: "transparent", outline: "none", fontSize: "12px", padding: "0 4px", cursor: "pointer", color: "#667085" }}>
                          <option value="percent">%</option><option value="flat">₹</option>
                        </select>
                      </div>
                    </td>
                    <td style={tdStyle}>
                      <select value={item.tax_rate} onChange={e => updateItem(idx, "tax_rate", e.target.value)} style={{ border: "1px solid transparent", background: "transparent", padding: "6px", fontSize: "12px", width: "100%", outline: "none", color: "#344054" }} className="table-input">
                        <option value="0">Non-Taxable</option>
                        {taxes.map(t => (<option key={t.id} value={t.rate}>{t.tax_name} ({t.rate}%)</option>))}
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
                        <button onClick={() => removeItem(idx)} className="row-action-btn" style={{ border: "none", background: "none", cursor: "pointer", color: "#667085", padding: 0 }}>
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div style={{ display: "flex", gap: "10px", marginTop: "12px" }}>
            <button onClick={addItem} className="add-row-btn" style={{ padding: "8px 16px", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>+ Add New Row</button>
            <button onClick={() => toast("Bulk Add Feature")} className="add-row-btn" style={{ padding: "8px 16px", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>Add Items in Bulk</button>
          </div>
        </div>

        {/* Lower split layout: Notes & Totals card */}
        <div style={{ display: "grid", gridTemplateColumns: "1.2fr 0.8fr", gap: "40px", borderTop: "1px solid #eaecf0", paddingTop: "32px", marginTop: "32px" }}>
          
          {/* Notes column */}
          <div>
            <div style={{ marginBottom: "20px" }}>
              <label style={labelStyle}>Customer Notes / Terms</label>
              <textarea value={notes} onChange={e => setNotes(e.target.value)} rows={3} style={{ ...inputStyle, width: "100%", height: "80px", resize: "none" }} placeholder="Add any specific notes for this credit note here." className="premium-input" />
            </div>
            <div>
              <label style={labelStyle}>Terms & Conditions</label>
              <textarea value={terms} onChange={e => setTerms(e.target.value)} rows={3} style={{ ...inputStyle, width: "100%", height: "80px", resize: "none" }} placeholder="Terms and conditions..." className="premium-input" />
            </div>
          </div>

          {/* Totals & Upload Card */}
          <div>
            <div style={{ background: "#fcfcfd", border: "1px solid #eaecf0", borderRadius: "8px", padding: "20px", marginBottom: "20px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "14px", color: "#1d2939", fontWeight: "600" }}>
                <span>Sub Total</span><span>{subTotal.toFixed(2)}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "13px", color: "#ef4444" }}>
                <span>Discount</span><span>- {totalDiscount.toFixed(2)}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "13px", color: "#667085" }}>
                <span>Total Tax</span><span>{totalTax.toFixed(2)}</span>
              </div>
              
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "12px", fontSize: "13px", color: "#667085" }}>
                <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                  <span style={{ border: "1px dashed #d0d5dd", padding: "4px 8px", borderRadius: "4px", color: "#344054" }}>Adjustment</span>
                  <input type="number" step="0.01" value={adjustment} onChange={(e) => setAdjustment(e.target.value)} style={{ width: "80px", padding: "4px 8px", border: "1px solid #d0d5dd", borderRadius: "4px", outline: "none", fontSize: "13px" }} />
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#98a2b3" strokeWidth="2"><circle cx="12" cy="12" r="10"></circle><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"></path><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
                </div>
                <span style={{ color: "#1d2939" }}>{parseFloat(adjustment || 0).toFixed(2)}</span>
              </div>

              <div style={{ display: "flex", justifyContent: "space-between", fontWeight: "700", fontSize: "16px", color: "#1d2939", borderTop: "1px solid #eaecf0", paddingTop: "14px", marginTop: "14px" }}>
                <span>Total ( ₹ )</span><span>{grandTotal.toFixed(2)}</span>
              </div>
            </div>

            <div className="attach-box" onClick={() => toast("File browser opened")}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#667085" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ marginBottom: "8px", opacity: 0.8 }}><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="17 8 12 3 7 8"></polyline><line x1="12" y1="3" x2="12" y2="15"></line></svg>
              <div style={{ fontSize: "13px", fontWeight: "600", color: "#344054", marginBottom: "2px" }}>Upload Files</div>
              <div style={{ fontSize: "11px", color: "#667085" }}>Drag & Drop or click to upload. Max 5MB.</div>
            </div>
          </div>
        </div>

      </div>

      {/* Action Footer Bar */}
      <div style={{ background: "#f9fafb", borderTop: "1px solid #eaecf0", padding: "16px 32px", display: "flex", justifyContent: "flex-end", gap: "12px" }}>
        <button onClick={() => navigate(isEditMode ? `/credit-notes/${id}/document` : "/credit-notes")} style={{ background: "#ffffff", border: "1px solid #d0d5dd", color: "#344054", fontSize: "13px", fontWeight: "600", borderRadius: "6px", padding: "8px 16px", cursor: "pointer" }}>Cancel</button>
        <button onClick={() => handleSave("Draft")} disabled={loading} style={{ background: "#ffffff", border: "1px solid #d0d5dd", color: "#344054", fontSize: "13px", fontWeight: "600", borderRadius: "6px", padding: "8px 16px", cursor: "pointer" }}>Save as Draft</button>
        <button onClick={() => handleSave("Open")} disabled={loading} style={{ background: "#006ee6", fontSize: "13px", fontWeight: "600", borderRadius: "6px", padding: "8px 16px", cursor: "pointer", border: "none", color: "#ffffff" }}>
          {loading ? "Saving..." : (isEditMode ? "Update Credit Note" : "Save and Send")}
        </button>
      </div>

      {/* ===== NEW CUSTOMER MODAL ===== */}
      {showCustomerModal && (
        <div style={{ position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(0,0,0,0.5)", display: "flex", justifyContent: "center", alignItems: "center", zIndex: 1000 }}>
          <div style={{ background: "#fff", borderRadius: "8px", padding: "25px", width: "550px", maxWidth: "95%", maxHeight: "85vh", overflow: "auto", boxShadow: "0 4px 20px rgba(0,0,0,0.2)" }}>
            <h3 style={{ marginTop: 0 }}>+ New Customer</h3>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "10px" }}>
              <div><label style={labelStyle}>Display Name *</label><input value={newCustomer.display_name} onChange={e => setNewCustomer({ ...newCustomer, display_name: e.target.value })} className="premium-input" /></div>
              <div><label style={labelStyle}>Company Name</label><input value={newCustomer.company_name} onChange={e => setNewCustomer({ ...newCustomer, company_name: e.target.value })} className="premium-input" /></div>
              <div><label style={labelStyle}>Email</label><input type="email" value={newCustomer.email} onChange={e => setNewCustomer({ ...newCustomer, email: e.target.value })} className="premium-input" /></div>
              <div><label style={labelStyle}>Phone</label><input value={newCustomer.phone} onChange={e => setNewCustomer({ ...newCustomer, phone: e.target.value })} className="premium-input" /></div>
              <div><label style={labelStyle}>GSTIN / Tax Number</label><input value={newCustomer.pan} onChange={e => setNewCustomer({ ...newCustomer, pan: e.target.value })} className="premium-input" /></div>
              <div style={{ gridColumn: "1/-1" }}><label style={labelStyle}>Billing Address</label><input value={newCustomer.billing_address} onChange={e => setNewCustomer({ ...newCustomer, billing_address: e.target.value })} className="premium-input" /></div>
            </div>
            <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end", marginTop: "15px" }}>
              <button onClick={() => setShowCustomerModal(false)} style={{ padding: "10px 20px", background: "#ccc", color: "#333", border: "none", borderRadius: "5px", cursor: "pointer" }}>Cancel</button>
              <button onClick={handleSaveCustomer} style={{ padding: "10px 20px", background: "#006ee6", color: "#fff", border: "none", borderRadius: "5px", cursor: "pointer", fontWeight: "500" }}>Save Customer</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default AddCreditNote;
