/**
 * AddRecurringInvoice.js – Modernized Zoho-style Recurring Invoice creation & edit form
 */
import React, { useState, useEffect, useMemo, useCallback } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { apiRequest } from "./api";
import { FormSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

function AddRecurringInvoice() {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditMode = Boolean(id);

  // --- Basic fields ---
  const [profileName, setProfileName] = useState("");
  const [customerId, setCustomerId] = useState("");
  const [frequency, setFrequency] = useState("Monthly");
  const [startDate, setStartDate] = useState(new Date().toISOString().slice(0, 10));
  const [endDate, setEndDate] = useState("");
  const [nextInvoiceDate, setNextInvoiceDate] = useState(new Date().toISOString().slice(0, 10));
  
  const [notes, setNotes] = useState("");
  const [terms, setTerms] = useState("");
  const [autoSendEmail, setAutoSendEmail] = useState(false);

  // --- Items ---
  const [items, setItems] = useState([
    { id: Date.now(), item_id: "", item_name: "", description: "", quantity: 1, rate: 0, discount: 0, tax_rate: 0 }
  ]);

  // --- Dropdown data ---
  const [customers, setCustomers] = useState([]);
  const [inventoryItems, setInventoryItems] = useState([]);
  const [taxes, setTaxes] = useState([]);
  
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(false);

  // --- Customer Modal ---
  const [showCustomerModal, setShowCustomerModal] = useState(false);
  const [newCustomer, setNewCustomer] = useState({ display_name: "", company_name: "", email: "", phone: "", billing_address: "", pan: "" });

  useEffect(() => {
    const fetchAll = async () => {
      try {
        setFetching(true);
        const [custRes, itemRes, taxRes] = await Promise.all([
          apiRequest("/customers"),
          apiRequest("/items"),
          apiRequest("/taxes")
        ]);
        setCustomers(custRes?.customers || []);
        setInventoryItems(itemRes?.items || []);
        setTaxes(taxRes?.taxes || []);

        if (isEditMode) {
          const res = await apiRequest(`/recurring-invoices/${id}`);
          if (res?.recurring_invoice) {
            const r = res.recurring_invoice;
            setProfileName(r.profile_name || "");
            setCustomerId(r.customer_id ? String(r.customer_id) : "");
            setFrequency(r.frequency || "Monthly");
            setStartDate(r.start_date ? r.start_date.slice(0, 10) : "");
            setEndDate(r.end_date ? r.end_date.slice(0, 10) : "");
            setNextInvoiceDate(r.next_invoice_date ? r.next_invoice_date.slice(0, 10) : "");
            setNotes(r.notes || "");
            setTerms(r.terms_conditions || "");
            setAutoSendEmail(r.auto_send_email || false);
            
            if (r.items && r.items.length > 0) {
              setItems(r.items.map(i => ({
                id: i.id || Math.random(),
                item_id: i.item_id ? String(i.item_id) : "",
                item_name: i.item_name || "",
                description: i.description || "",
                quantity: parseFloat(i.quantity) || 1,
                rate: parseFloat(i.rate) || 0,
                discount: parseFloat(i.discount) || 0,
                tax_rate: parseFloat(i.tax_rate) || 0
              })));
            }
          }
        }
      } catch (err) {
        toast.error("Failed to load data");
      } finally {
        setFetching(false);
      }
    };
    fetchAll();
  }, [id, isEditMode]);

  // Sync Start Date and Next Invoice Date on new records
  useEffect(() => {
    if (!isEditMode) setNextInvoiceDate(startDate);
  }, [startDate, isEditMode]);

  // --- Calculations ---
  const calcLineTotal = useCallback((item) => {
    const q = parseFloat(item.quantity) || 0;
    const r = parseFloat(item.rate) || 0;
    const d = parseFloat(item.discount) || 0;
    const sub = (q * r) - d;
    return sub > 0 ? sub : 0;
  }, []);

  const calcLineTax = useCallback((item) => {
    const sub = calcLineTotal(item);
    const t = parseFloat(item.tax_rate) || 0;
    return (sub * t) / 100;
  }, [calcLineTotal]);

  const totals = useMemo(() => {
    let subtotal = 0;
    let tax_total = 0;
    let discount_total = 0;
    
    items.forEach(i => {
      discount_total += parseFloat(i.discount) || 0;
      subtotal += calcLineTotal(i);
      tax_total += calcLineTax(i);
    });

    return {
      subtotal,
      discount_total,
      tax_total,
      total: subtotal + tax_total
    };
  }, [items, calcLineTotal, calcLineTax]);

  const handleItemChange = (index, field, value) => {
    const newItems = [...items];
    newItems[index][field] = value;
    
    if (field === "item_id") {
      const selected = inventoryItems.find(i => String(i.id) === String(value));
      if (selected) {
        newItems[index].item_name = selected.name;
        newItems[index].description = selected.description || selected.name || "";
        newItems[index].rate = selected.selling_price || 0;
        if (selected.tax_id) {
          const tax = taxes.find(t => String(t.id) === String(selected.tax_id));
          if (tax) newItems[index].tax_rate = tax.rate;
        } else {
          newItems[index].tax_rate = selected.tax_rate || 0;
        }
      } else {
        newItems[index].item_name = "";
        newItems[index].rate = 0;
        newItems[index].tax_rate = 0;
      }
    }
    setItems(newItems);
  };

  const addItem = () => {
    setItems([...items, { id: Date.now(), item_id: "", item_name: "", description: "", quantity: 1, rate: 0, discount: 0, tax_rate: 0 }]);
  };

  const removeItem = (index) => {
    setItems(items.filter((_, i) => i !== index));
  };

  const handleSave = async (e) => {
    if (e && e.preventDefault) e.preventDefault();
    if (!profileName || !customerId || !frequency || !startDate) {
      toast.error("Please fill required fields"); return;
    }
    
    const validItems = items.filter(i => i.item_name && i.quantity > 0);
    if (validItems.length === 0) {
      toast.error("Add at least one valid item"); return;
    }

    for (const item of validItems) {
      if (parseFloat(item.quantity) <= 0) {
        toast.error("Quantity must be greater than zero"); return;
      }
      if (parseFloat(item.rate) < 0) {
        toast.error("Rate cannot be negative"); return;
      }
    }

    const payloadItems = validItems.map(i => ({
      item_id: i.item_id ? parseInt(i.item_id) : null,
      item_name: i.item_name,
      description: i.description || "",
      quantity: parseFloat(i.quantity) || 0,
      rate: parseFloat(i.rate) || 0,
      discount: parseFloat(i.discount) || 0,
      tax_rate: parseFloat(i.tax_rate) || 0,
      tax_amount: calcLineTax(i),
      line_total: calcLineTotal(i)
    }));

    const payload = {
      profile_name: profileName,
      customer_id: parseInt(customerId),
      frequency,
      start_date: startDate,
      end_date: endDate || null,
      next_invoice_date: nextInvoiceDate,
      notes,
      terms_conditions: terms,
      auto_send_email: autoSendEmail,
      subtotal: totals.subtotal,
      discount_total: totals.discount_total,
      tax_total: totals.tax_total,
      total: totals.total,
      items: payloadItems
    };

    setLoading(true);
    try {
      if (isEditMode) {
        await apiRequest(`/recurring-invoices/${id}`, { method: "PUT", body: JSON.stringify(payload) });
        toast.success("Recurring Invoice updated");
        navigate(`/recurring-invoices/${id}`);
      } else {
        await apiRequest("/recurring-invoices", { method: "POST", body: JSON.stringify(payload) });
        toast.success("Recurring Invoice created");
        navigate("/recurring-invoices");
      }
    } catch (err) {
      toast.error(err.message || "Failed to save");
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
          <button type="button" onClick={() => navigate(isEditMode ? `/recurring-invoices/${id}` : "/recurring-invoices")} style={{ border: "none", background: "none", cursor: "pointer", display: "flex", alignItems: "center", color: "#667085", padding: "4px", borderRadius: "4px" }} onMouseEnter={(e) => e.currentTarget.style.background = "#f2f4f7"} onMouseLeave={(e) => e.currentTarget.style.background = "none"}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>
          </button>
          <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#006ee6" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="16" rx="2" ry="2"></rect><line x1="16" y1="2" x2="16" y2="6"></line><line x1="8" y1="2" x2="8" y2="6"></line><line x1="3" y1="10" x2="21" y2="10"></line></svg>
            <h2 style={{ margin: 0, fontSize: "18px", fontWeight: "600", color: "#1d2939" }}>
              {isEditMode ? "Edit Recurring Invoice" : "New Recurring Invoice"}
            </h2>
          </div>
        </div>
        <button type="button" onClick={() => navigate(isEditMode ? `/recurring-invoices/${id}` : "/recurring-invoices")} style={{ border: "none", background: "none", cursor: "pointer", fontSize: "20px", color: "#98a2b3", display: "flex", padding: "4px", borderRadius: "4px" }} onMouseEnter={(e) => e.currentTarget.style.background = "#f2f4f7"} onMouseLeave={(e) => e.currentTarget.style.background = "none"}>&times;</button>
      </div>

      {/* Main Form Area */}
      <form onSubmit={handleSave} style={{ padding: "32px", margin: 0 }}>
        
        {/* Row 1: Profile setup */}
        <div style={{ display: "grid", gridTemplateColumns: "1.2fr 1.2fr", gap: "24px", marginBottom: "24px" }}>
          <div>
            <label style={labelStyle}>Profile Name <span style={{ color: "#d92d20" }}>*</span></label>
            <input type="text" value={profileName} onChange={e => setProfileName(e.target.value)} required placeholder="e.g. Monthly Retainer" className="premium-input" />
          </div>
          <div>
            <label style={labelStyle}>Customer Name <span style={{ color: "#d92d20" }}>*</span></label>
            <div style={{ display: "flex", width: "100%" }}>
              <select value={customerId} onChange={e => {
                  if (e.target.value === "new") setShowCustomerModal(true);
                  else setCustomerId(e.target.value);
                }} required style={{ ...selectStyle, borderRadius: "6px 0 0 6px" }} className="premium-input">
                <option value="">Select or add a customer</option>
                <option value="new" style={{ color: "#0ba5ec", fontWeight: "600" }}>+ New Customer</option>
                {customers.map(c => (
                  <option key={c.id} value={c.id}>{c.display_name || c.company_name}</option>
                ))}
              </select>
              <button type="button" onClick={() => setShowCustomerModal(true)} className="control-group-btn" title="New Customer">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
              </button>
            </div>
          </div>
        </div>

        {/* Row 2: Frequency & Dates */}
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr 1fr", gap: "24px", marginBottom: "24px", borderTop: "1px solid #f2f4f7", paddingTop: "24px" }}>
          <div>
            <label style={labelStyle}>Frequency <span style={{ color: "#d92d20" }}>*</span></label>
            <select value={frequency} onChange={e => setFrequency(e.target.value)} required className="premium-input" style={selectStyle}>
              <option value="Weekly">Weekly</option>
              <option value="Monthly">Monthly</option>
              <option value="Quarterly">Quarterly</option>
              <option value="Yearly">Yearly</option>
            </select>
          </div>
          <div>
            <label style={labelStyle}>Start Date <span style={{ color: "#d92d20" }}>*</span></label>
            <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} required className="premium-input" />
          </div>
          <div>
            <label style={labelStyle}>End Date (Optional)</label>
            <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} className="premium-input" />
          </div>
          <div>
            <label style={labelStyle}>Next Invoice Date</label>
            <input type="date" value={nextInvoiceDate} onChange={e => setNextInvoiceDate(e.target.value)} required className="premium-input" style={{ ...inputStyle, background: "#f8fafc" }} />
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
                  <th style={{ ...thStyle, width: "120px", textAlign: "right" }}>Rate</th>
                  <th style={{ ...thStyle, width: "100px", textAlign: "right" }}>Discount</th>
                  <th style={{ ...thStyle, width: "140px", textAlign: "right" }}>Tax</th>
                  <th style={{ ...thStyle, width: "120px", textAlign: "right" }}>Amount</th>
                  <th style={{ ...thStyle, width: "40px" }}></th>
                </tr>
              </thead>
              <tbody>
                {items.map((item, idx) => (
                  <tr key={item.id} style={{ borderBottom: "1px solid #eaecf0" }}>
                    <td style={{ ...tdStyle, color: "#98a2b3" }}>
                      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="9" cy="5" r="1"></circle><circle cx="9" cy="12" r="1"></circle><circle cx="9" cy="19" r="1"></circle><circle cx="15" cy="5" r="1"></circle><circle cx="15" cy="12" r="1"></circle><circle cx="15" cy="19" r="1"></circle></svg>
                    </td>
                    <td style={tdStyle}>
                      <div style={{ display: "flex", flexDirection: "column", gap: "6px" }}>
                        <select value={item.item_id} onChange={e => handleItemChange(idx, 'item_id', e.target.value)} style={{ border: "1px solid #d0d5dd", padding: "6px", borderRadius: "4px", fontSize: "12px", width: "100%", color: "#344054", outline: "none" }}>
                          <option value="">Select Catalog Item...</option>
                          {inventoryItems.map(i => <option key={i.id} value={i.id}>{i.name}</option>)}
                        </select>
                        <input type="text" placeholder="Or enter item name" value={item.item_name} onChange={e => handleItemChange(idx, 'item_name', e.target.value)} className="table-input" style={{ border: "1px solid #d0d5dd", padding: "4px 8px", borderRadius: "4px", fontSize: "12px" }} required />
                      </div>
                    </td>
                    <td style={tdStyle}>
                      <textarea placeholder="Description" value={item.description} onChange={e => handleItemChange(idx, "description", e.target.value)} className="table-input" rows={2} style={{ resize: "vertical" }} />
                    </td>
                    <td style={tdStyle}>
                      <input type="number" min="0" value={item.quantity} onChange={e => handleItemChange(idx, "quantity", e.target.value)} className="table-input" style={{ textAlign: "right" }} />
                    </td>
                    <td style={tdStyle}>
                      <input type="number" min="0" step="0.01" value={item.rate} onChange={e => handleItemChange(idx, "rate", e.target.value)} className="table-input" style={{ textAlign: "right" }} />
                    </td>
                    <td style={tdStyle}>
                      <div style={{ display: "flex", alignItems: "center", border: "1px solid transparent", borderRadius: "4px", overflow: "hidden", background: "transparent" }}>
                        <span style={{ fontSize: "12px", color: "#667085", paddingRight: "4px" }}>₹</span>
                        <input type="number" min="0" step="0.01" value={item.discount} onChange={e => handleItemChange(idx, "discount", e.target.value)} className="table-input" style={{ textAlign: "right" }} />
                      </div>
                    </td>
                    <td style={tdStyle}>
                      <select value={item.tax_rate} onChange={e => handleItemChange(idx, "tax_rate", e.target.value)} style={{ border: "1px solid transparent", background: "transparent", padding: "6px", fontSize: "12px", width: "100%", outline: "none", color: "#344054" }} className="table-input">
                        <option value="0">Non-Taxable (0%)</option>
                        {taxes.map(t => (<option key={t.id} value={t.rate}>{t.tax_name} ({t.rate}%)</option>))}
                        {item.tax_rate && parseFloat(item.tax_rate) !== 0 && !taxes.some(t => parseFloat(t.rate) === parseFloat(item.tax_rate)) && (
                          <option value={item.tax_rate}>Custom ({item.tax_rate}%)</option>
                        )}
                      </select>
                    </td>
                    <td style={{ ...tdStyle, textAlign: "right", fontWeight: "600", color: "#1d2939" }}>
                      ₹{calcLineTotal(item).toFixed(2)}
                    </td>
                    <td style={tdStyle}>
                      {items.length > 1 && (
                        <button type="button" onClick={() => removeItem(idx)} className="row-action-btn" style={{ border: "none", background: "none", cursor: "pointer", color: "#667085", padding: 0 }}>
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
            <button type="button" onClick={addItem} className="add-row-btn" style={{ padding: "8px 16px", borderRadius: "6px", fontSize: "13px", fontWeight: "600", cursor: "pointer" }}>+ Add New Row</button>
          </div>
        </div>

        {/* Lower split layout: Notes & Totals card */}
        <div style={{ display: "grid", gridTemplateColumns: "1.2fr 0.8fr", gap: "40px", borderTop: "1px solid #eaecf0", paddingTop: "32px", marginTop: "32px" }}>
          
          {/* Notes column */}
          <div>
            <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "20px", background: "#f9fafb", padding: "12px 16px", borderRadius: "8px", border: "1px solid #eaecf0" }}>
              <input type="checkbox" id="autoEmail" checked={autoSendEmail} onChange={e => setAutoSendEmail(e.target.checked)} style={{ width: "16px", height: "16px", cursor: "pointer", accentColor: "#006ee6" }} />
              <label htmlFor="autoEmail" style={{ cursor: "pointer", fontSize: "13px", color: "#344054", fontWeight: "500" }}>Automatically send generated invoices via email to customer</label>
            </div>
            <div style={{ marginBottom: "20px" }}>
              <label style={labelStyle}>Customer Notes</label>
              <textarea value={notes} onChange={e => setNotes(e.target.value)} rows={3} style={{ ...inputStyle, width: "100%", height: "80px", resize: "none" }} placeholder="Notes displayed to the customer..." className="premium-input" />
            </div>
            <div>
              <label style={labelStyle}>Terms & Conditions</label>
              <textarea value={terms} onChange={e => setTerms(e.target.value)} rows={3} style={{ ...inputStyle, width: "100%", height: "80px", resize: "none" }} placeholder="Terms and conditions..." className="premium-input" />
            </div>
          </div>

          {/* Totals card */}
          <div>
            <div style={{ background: "#fcfcfd", border: "1px solid #eaecf0", borderRadius: "8px", padding: "20px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "14px", color: "#1d2939", fontWeight: "600" }}>
                <span>Sub Total</span><span>₹{totals.subtotal.toFixed(2)}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "13px", color: "#ef4444" }}>
                <span>Discount</span><span>- ₹{totals.discount_total.toFixed(2)}</span>
              </div>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "12px", fontSize: "13px", color: "#667085" }}>
                <span>Total Tax</span><span>₹{totals.tax_total.toFixed(2)}</span>
              </div>
              
              <div style={{ display: "flex", justifyContent: "space-between", fontWeight: "700", fontSize: "16px", color: "#1d2939", borderTop: "1px solid #eaecf0", paddingTop: "14px", marginTop: "14px" }}>
                <span>Total ( ₹ )</span><span>₹{totals.total.toFixed(2)}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Action Footer Bar */}
        <div style={{ background: "#f9fafb", borderTop: "1px solid #eaecf0", margin: "32px -32px -32px -32px", padding: "16px 32px", display: "flex", justifyContent: "flex-end", gap: "12px" }}>
          <button type="button" onClick={() => navigate(isEditMode ? `/recurring-invoices/${id}` : "/recurring-invoices")} style={{ background: "#ffffff", border: "1px solid #d0d5dd", color: "#344054", fontSize: "13px", fontWeight: "600", borderRadius: "6px", padding: "8px 16px", cursor: "pointer" }} disabled={loading}>Cancel</button>
          <button type="submit" style={{ background: "#006ee6", fontSize: "13px", fontWeight: "600", borderRadius: "6px", padding: "8px 16px", cursor: "pointer", border: "none", color: "#ffffff" }} disabled={loading}>
            {loading ? "Saving..." : (isEditMode ? "Update Profile" : "Save Profile")}
          </button>
        </div>

      </form>

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
              <button type="button" onClick={() => setShowCustomerModal(false)} style={{ padding: "10px 20px", background: "#ccc", color: "#333", border: "none", borderRadius: "5px", cursor: "pointer" }}>Cancel</button>
              <button type="button" onClick={handleSaveCustomer} style={{ padding: "10px 20px", background: "#006ee6", color: "#fff", border: "none", borderRadius: "5px", cursor: "pointer", fontWeight: "500" }}>Save Customer</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default AddRecurringInvoice;
