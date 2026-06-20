import React, { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { apiRequest } from "./api";
import { FormSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";
import AddCustomer from "./AddCustomer";

const customCSS = `
  .add-item-container { background: #fff; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; color: #212529; min-height: calc(100vh - 60px); }
  .add-item-header { padding: 15px 30px; border-bottom: 1px solid #f0f0f0; display: flex; justify-content: space-between; align-items: center; }
  .add-item-header h2 { margin: 0; font-size: 20px; font-weight: 400; }
  .form-section { padding: 30px; display: flex; flex-direction: column; }
  .top-left { max-width: 800px; }
  .form-row { display: flex; margin-bottom: 20px; align-items: flex-start; }
  .form-label { width: 200px; font-size: 13px; padding-top: 8px; display: flex; align-items: center; gap: 5px; color: #333; }
  .req-dashed { color: #d32f2f; }
  .form-control { flex: 1; min-width: 0; }
  .input-field { width: 100%; padding: 8px 12px; border: 1px solid #ccc; border-radius: 4px; font-size: 13px; outline: none; box-sizing: border-box; transition: border-color 0.2s; background: #fff; }
  .input-field:focus { border-color: #4a90e2; }
  .form-actions { padding: 20px 30px; border-top: 1px solid #f0f0f0; display: flex; gap: 15px; position: sticky; bottom: 0; background: #fff; z-index: 100; box-shadow: 0 -2px 10px rgba(0,0,0,0.05); }
  .btn-save { background: #4a90e2; color: #fff; border: none; padding: 8px 20px; border-radius: 4px; font-size: 13px; cursor: pointer; transition: background 0.2s; }
  .btn-save:hover { background: #357abd; }
  .btn-cancel { background: #fff; color: #333; border: 1px solid #ccc; padding: 8px 20px; border-radius: 4px; font-size: 13px; cursor: pointer; transition: background 0.2s; }
  .btn-cancel:hover { background: #f9f9f9; }
  
  .item-table { width: 100%; border-collapse: collapse; margin-top: 20px; }
  .item-table th { background: #f9f9f9; border-bottom: 1px solid #eee; padding: 10px; text-align: left; font-size: 12px; color: #666; font-weight: 600; text-transform: uppercase; }
  .item-table td { padding: 10px; border-bottom: 1px solid #eee; vertical-align: top; }
  .table-input { width: 100%; padding: 6px 8px; border: 1px solid transparent; border-radius: 4px; font-size: 13px; outline: none; box-sizing: border-box; transition: border-color 0.2s; background: transparent; }
  .table-input:hover { border-color: #e0e0e0; background: #f9f9f9; }
  .table-input:focus { border-color: #4a90e2; background: #fff; }
  
  .totals-section { background: #f9f9f9; border-radius: 8px; padding: 20px; width: 350px; }
  .totals-row { display: flex; justify-content: space-between; margin-bottom: 12px; font-size: 14px; color: #333; }
  
  .modal-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); display: flex; justify-content: center; alignItems: center; z-index: 1000; }
  .modal-box { background: #fff; border-radius: 8px; padding: 25px; width: 450px; max-width: 90vw; max-height: 90vh; overflow-y: auto; }
`;

function AddQuote() {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditMode = Boolean(id);

  // --- Basic fields ---
  const [customerId, setCustomerId] = useState("");
  const [quoteNumber, setQuoteNumber] = useState("");
  const [quoteDate, setQuoteDate] = useState(new Date().toISOString().slice(0, 10));
  const [expiryDate, setExpiryDate] = useState("");
  const [customerNotes, setCustomerNotes] = useState("");
  const [terms, setTerms] = useState("");
  const [termsConditions, setTermsConditions] = useState("");
  const [selectedFile, setSelectedFile] = useState(null);
  const [salespersonId, setSalespersonId] = useState("");
  const [projectId, setProjectId] = useState("");

  // --- Items ---
  const [items, setItems] = useState([
    { item_id: "", item_name: "", description: "", quantity: 1, unit_price: 0, tax_rate: 0, discount: 0, discount_type: "flat", hsn_code: "", unit: "" }
  ]);

  const [tdsTcsType, setTdsTcsType] = useState("TDS");
  const [taxSelection, setTaxSelection] = useState("");
  const [adjustment, setAdjustment] = useState(0);

  // --- Dropdown data ---
  const [customers, setCustomers] = useState([]);
  const [catalogItems, setCatalogItems] = useState([]);
  const [salespersons, setSalespersons] = useState([]);
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(false);

  // --- Modals ---
  const [showCustomerModal, setShowCustomerModal] = useState(false);
  const [showSalespersonModal, setShowSalespersonModal] = useState(false);
  const [showProjectModal, setShowProjectModal] = useState(false);

  // --- New Salesperson form ---
  const [newSp, setNewSp] = useState({ name: "", email: "", phone: "", employee_id: "" });

  // --- New Project form ---
  const [newProj, setNewProj] = useState({ project_name: "", customer_id: "", start_date: "", end_date: "", description: "", status: "active" });

  useEffect(() => {
    const fetchAll = async () => {
      try {
        const [custRes, itemRes, spRes, projRes] = await Promise.all([
          apiRequest("/customers"),
          apiRequest("/items"),
          apiRequest("/salespersons"),
          apiRequest("/projects"),
        ]);
        setCustomers(custRes?.customers || []);
        setCatalogItems(itemRes?.items || []);
        setSalespersons(spRes?.salespersons || []);
        setProjects(projRes?.projects || []);

        if (isEditMode) {
          setFetching(true);
          const res = await apiRequest(`/quotes/${id}`);
          if (res?.quote) {
            const q = res.quote;
            setCustomerId(q.customer_id ? String(q.customer_id) : "");
            setQuoteDate(q.quote_date ? q.quote_date.slice(0, 10) : "");
            setExpiryDate(q.expiry_date ? q.expiry_date.slice(0, 10) : "");
            setCustomerNotes(q.notes || "");
            setTerms(q.terms || "");
            setSalespersonId(q.salesperson_id ? String(q.salesperson_id) : "");
            setProjectId(q.project_id ? String(q.project_id) : "");
            setQuoteNumber(q.quote_number || "");
            if (res.items && res.items.length > 0) {
              setItems(res.items.map(item => ({
                item_id:       item.item_id       ? String(item.item_id)  : "",
                item_name:     item.item_name     || "",
                description:   item.description   || "",
                quantity:      item.quantity       || 1,
                unit_price:    item.unit_price     || 0,
                tax_rate:      item.tax_rate       || 0,
                discount:      item.discount       || 0,
                discount_type: item.discount_type  || "flat",
                hsn_code:      item.hsn_code       || "",
                unit:          item.unit           || "",
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
  }, [id, isEditMode]);

  const addItem = () => {
    setItems([...items, { item_id: "", item_name: "", description: "", quantity: 1, unit_price: 0, tax_rate: 0, discount: 0, discount_type: "flat", hsn_code: "", unit: "" }]);
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
        updated[index].unit_price  = catalogItem.selling_price || 0;
        updated[index].tax_rate    = catalogItem.tax_rate || 0;
        updated[index].hsn_code    = catalogItem.hsn_code || "";
        updated[index].unit        = catalogItem.unit || "";
      }
    } else {
      updated[index].item_name = "";
      updated[index].hsn_code  = "";
      updated[index].unit      = "";
    }
    setItems(updated);
  };

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
  const grandTotal = subtotal - totalDiscount + totalTax + parseFloat(adjustment || 0);

  const handleSave = async (statusArg) => {
    if (!customerId) { toast.error("Please select a customer"); return; }
    if (items.length === 0 || items.every(item => !item.description && !item.item_id)) {
      toast.error("Add at least one item"); return;
    }
    setLoading(true);
    try {
      const payload = {
        customer_id: parseInt(customerId),
        quote_date: quoteDate,
        expiry_date: expiryDate || null,
        notes: customerNotes,
        terms,
        salesperson_id: salespersonId ? parseInt(salespersonId) : null,
        project_id: projectId ? parseInt(projectId) : null,
        items: items.map(item => ({
          ...item,
          item_id:   item.item_id   ? parseInt(item.item_id) : null,
          item_name: item.item_name || null,
          hsn_code:  item.hsn_code  || null,
          unit:      item.unit      || null,
          quantity:  parseFloat(item.quantity) || 0,
          unit_price: parseFloat(item.unit_price) || 0,
          tax_rate:  parseFloat(item.tax_rate) || 0,
          discount:  parseFloat(item.discount) || 0,
        })),
      };

      if (isEditMode) {
        const finalPayload = statusArg ? { ...payload, status: statusArg } : payload;
        await apiRequest(`/quotes/${id}`, {
          method: "PUT",
          body: JSON.stringify(finalPayload),
        });
        toast.success("Quote updated");
        navigate(`/quotes/${id}`);
      } else {
        const finalStatus = statusArg || "draft";
        await apiRequest("/quotes", {
          method: "POST",
          body: JSON.stringify({ ...payload, status: finalStatus }),
        });
        toast.success("Quote created");
        navigate("/quotes");
      }
    } catch (err) {
      toast.error(isEditMode ? "Failed to update quote" : "Failed to create quote");
    } finally {
      setLoading(false);
    }
  };

  const handleSaveCustomerSuccess = (newCustomer) => {
    if (newCustomer) {
      setCustomers(prev => {
        if (prev.some(c => c.id === newCustomer.id)) return prev;
        return [...prev, newCustomer];
      });
      setCustomerId(String(newCustomer.id));
    }
    setShowCustomerModal(false);
  };

  const handleSaveSalesperson = async () => {
    if (!newSp.name) { toast.error("Name required"); return; }
    try {
      const res = await apiRequest("/salespersons", { method: "POST", body: JSON.stringify(newSp) });
      if (res?.salesperson) {
        setSalespersons(prev => [...prev, res.salesperson]);
        setSalespersonId(String(res.salesperson.id));
        toast.success("Salesperson created");
      }
      setShowSalespersonModal(false);
      setNewSp({ name: "", email: "", phone: "", employee_id: "" });
    } catch (err) { toast.error("Failed to create salesperson"); }
  };

  const handleSaveProject = async () => {
    if (!newProj.project_name) { toast.error("Project name required"); return; }
    try {
      const payload = {
        project_name: newProj.project_name,
        customer_id: newProj.customer_id ? parseInt(newProj.customer_id) : null,
        start_date: newProj.start_date || null,
        end_date: newProj.end_date || null,
        description: newProj.description,
        status: newProj.status,
      };
      const res = await apiRequest("/projects", { method: "POST", body: JSON.stringify(payload) });
      if (res?.project) {
        setProjects(prev => [...prev, res.project]);
        setProjectId(String(res.project.id));
        toast.success("Project created");
      }
      setShowProjectModal(false);
      setNewProj({ project_name: "", customer_id: "", start_date: "", end_date: "", description: "", status: "active" });
    } catch (err) { toast.error("Failed to create project"); }
  };

  if (fetching) {
    return (
      <div style={{ maxWidth: "1100px", margin: "auto", padding: "30px" }}>
        <FormSkeleton fields={8} />
      </div>
    );
  }

  return (
    <>
      <style>{customCSS}</style>
      <div className="add-item-container">
        
        {/* Header */}
        <div className="add-item-header">
          <h2>{isEditMode ? "Edit Quote" : "New Quote"}</h2>
          <button className="btn-cancel" onClick={() => navigate("/quotes")} style={{ border: 'none', background: 'none', fontSize: '24px', padding: '0', color: '#888' }}>&times;</button>
        </div>

        <div className="form-section">
          
          <div className="top-left">
            <div className="form-row">
              <label className="form-label">Customer Name <span className="req-dashed">*</span></label>
              <div className="form-control" style={{ display: "flex", gap: "10px" }}>
                <select className="input-field" value={customerId} onChange={e => setCustomerId(e.target.value)}>
                  <option value="">Select a customer</option>
                  {customers.map(c => <option key={c.id} value={c.id}>{c.display_name || c.email}</option>)}
                </select>
                <button type="button" onClick={() => setShowCustomerModal(true)} style={{ background: "none", border: "1px solid #ccc", padding: "0 15px", borderRadius: "4px", cursor: "pointer", color: "#4a90e2", whiteSpace: "nowrap" }}>+ New</button>
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Quote# <span className="req-dashed">*</span></label>
              <div className="form-control">
                <input className="input-field" type="text" value={isEditMode ? quoteNumber : "QT-[Auto-Generated]"} disabled={!isEditMode} style={{ background: isEditMode ? "#fff" : "#f9f9f9", color: "#666" }} />
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Quote Date <span className="req-dashed">*</span></label>
              <div className="form-control" style={{ display: "flex", gap: "20px" }}>
                <input className="input-field" type="date" value={quoteDate} onChange={e => setQuoteDate(e.target.value)} />
                <div style={{ display: "flex", alignItems: "center", gap: "10px", width: "100%" }}>
                  <label className="form-label" style={{ width: "auto", paddingTop: "0" }}>Terms</label>
                  <select className="input-field" value={terms} onChange={e => setTerms(e.target.value)}>
                    <option value="">Due on Receipt</option>
                    <option value="Net 15">Net 15</option>
                    <option value="Net 30">Net 30</option>
                    <option value="Net 45">Net 45</option>
                    <option value="Net 60">Net 60</option>
                  </select>
                </div>
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Expiry Date</label>
              <div className="form-control">
                <input className="input-field" type="date" value={expiryDate} onChange={e => setExpiryDate(e.target.value)} style={{ borderStyle: "dashed" }} />
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Salesperson</label>
              <div className="form-control" style={{ display: "flex", gap: "10px" }}>
                <select className="input-field" value={salespersonId} onChange={e => setSalespersonId(e.target.value)}>
                  <option value="">Select Salesperson</option>
                  {salespersons.map(sp => <option key={sp.id} value={sp.id}>{sp.name}</option>)}
                </select>
                <button type="button" onClick={() => setShowSalespersonModal(true)} style={{ background: "none", border: "1px solid #ccc", padding: "0 15px", borderRadius: "4px", cursor: "pointer", color: "#4a90e2", whiteSpace: "nowrap" }}>+ New</button>
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Project Name</label>
              <div className="form-control" style={{ display: "flex", gap: "10px" }}>
                <select className="input-field" value={projectId} onChange={e => setProjectId(e.target.value)}>
                  <option value="">Select project</option>
                  {projects.map(p => <option key={p.id} value={p.id}>{p.project_name}</option>)}
                </select>
                <button type="button" onClick={() => setShowProjectModal(true)} style={{ background: "none", border: "1px solid #ccc", padding: "0 15px", borderRadius: "4px", cursor: "pointer", color: "#4a90e2", whiteSpace: "nowrap" }}>+ New</button>
              </div>
            </div>
          </div>

          <div style={{ marginTop: "40px", border: "1px solid #eee", borderRadius: "8px", background: "#fff", overflow: "hidden" }}>
            <div style={{ padding: "15px 20px", background: "#f9f9f9", borderBottom: "1px solid #eee" }}>
              <h3 style={{ fontSize: "16px", color: "#333", fontWeight: "600", margin: 0 }}>Item Table</h3>
            </div>
            <table className="item-table" style={{ marginTop: 0 }}>
              <thead>
                <tr>
                  <th style={{ width: "40%", padding: "12px 20px" }}>ITEM DETAILS</th>
                  <th style={{ width: "15%", textAlign: "right" }}>QUANTITY</th>
                  <th style={{ width: "15%", textAlign: "right" }}>RATE <span style={{ fontSize: '10px' }}>🏷️</span></th>
                  <th style={{ width: "15%", textAlign: "right" }}>DISCOUNT</th>
                  <th style={{ width: "15%", textAlign: "right", paddingRight: "20px" }}>AMOUNT</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item, idx) => (
                  <tr key={idx}>
                    <td style={{ padding: "10px 20px" }}>
                      <div style={{ display: "flex", alignItems: "flex-start", gap: "10px" }}>
                        <span style={{ color: "#ccc", cursor: "grab", marginTop: "5px" }}>⋮⋮</span>
                        <div style={{ flex: 1 }}>
                          <select 
                            value={item.item_id} 
                            onChange={e => handleItemSelect(idx, e.target.value)} 
                            className="table-input"
                            style={{ appearance: "none", cursor: "pointer", fontWeight: "500", color: "#888", padding: "4px 8px" }}
                          >
                            <option value="">Type or click to select an item.</option>
                            {catalogItems.map(ci => <option key={ci.id} value={ci.id}>{ci.name}</option>)}
                          </select>
                          {item.item_id && (
                            <textarea 
                              value={item.description}
                              onChange={e => updateItem(idx, "description", e.target.value)}
                              placeholder="Description"
                              rows={1}
                              className="table-input"
                              style={{ resize: "none", color: "#666", marginTop: "4px", padding: "4px 8px" }}
                            />
                          )}
                        </div>
                      </div>
                    </td>
                    <td>
                      <input type="number" min="0" value={item.quantity} onChange={e => updateItem(idx, "quantity", e.target.value)} className="table-input" style={{ textAlign: "right" }} />
                    </td>
                    <td>
                      <input type="number" min="0" step="0.01" value={item.unit_price} onChange={e => updateItem(idx, "unit_price", e.target.value)} className="table-input" style={{ textAlign: "right" }} />
                    </td>
                    <td>
                      <div style={{ display: "flex", alignItems: "center", gap: "0", background: "#f9f9f9", borderRadius: "4px" }}>
                        <input type="number" min="0" step="0.01" value={item.discount} onChange={e => updateItem(idx, "discount", e.target.value)} className="table-input" style={{ textAlign: "right", background: "transparent" }} />
                        <select value={item.discount_type} onChange={e => updateItem(idx, "discount_type", e.target.value)} className="table-input" style={{ width: "45px", padding: "6px 2px", borderLeft: "1px solid #eee", background: "transparent", borderRadius: "0 4px 4px 0" }}>
                          <option value="percent">%</option>
                          <option value="flat">₹</option>
                        </select>
                      </div>
                    </td>
                    <td style={{ textAlign: "right", fontWeight: "600", color: "#333", paddingTop: "16px", paddingRight: "20px" }}>
                      {(calcLineAmount(item)).toFixed(2)}
                      {items.length > 1 && (
                        <button onClick={() => removeItem(idx)} className="remove-row-btn" style={{ marginLeft: "10px" }}>✕</button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          
          <div style={{ display: "flex", justifyContent: "space-between", marginTop: "20px", gap: "60px", alignItems: "flex-start" }}>
            <div style={{ flex: 1 }}>
              <div style={{ display: "flex", gap: "10px", marginBottom: "30px" }}>
                <button type="button" onClick={addItem} style={{ background: "#f0f4ff", color: "#4a90e2", border: "none", padding: "8px 16px", borderRadius: "6px", cursor: "pointer", fontSize: "13px", fontWeight: "500", display: "flex", alignItems: "center", gap: "6px" }}>
                  <span style={{ background: "#4a90e2", color: "#fff", borderRadius: "50%", width: "14px", height: "14px", display: "inline-flex", alignItems: "center", justifyContent: "center", fontSize: "12px", paddingBottom: "2px" }}>+</span> Add New Row <span style={{ marginLeft: "4px", color: "#888" }}>⌄</span>
                </button>
                <button type="button" onClick={() => toast("Bulk add feature coming soon")} style={{ background: "#f0f4ff", color: "#4a90e2", border: "none", padding: "8px 16px", borderRadius: "6px", cursor: "pointer", fontSize: "13px", fontWeight: "500", display: "flex", alignItems: "center", gap: "6px" }}>
                  <span style={{ background: "#4a90e2", color: "#fff", borderRadius: "50%", width: "14px", height: "14px", display: "inline-flex", alignItems: "center", justifyContent: "center", fontSize: "12px", paddingBottom: "2px" }}>+</span> Add Items in Bulk
                </button>
              </div>

              <div className="form-row" style={{ display: "block", marginBottom: "20px" }}>
                <label className="form-label" style={{ width: "100%", marginBottom: "10px", color: "#333", fontWeight: "500" }}>Customer Notes</label>
                <div className="form-control">
                  <textarea className="input-field" value={customerNotes} onChange={e => setCustomerNotes(e.target.value)} rows="3" placeholder="Looking forward for your business." style={{ borderRadius: "8px" }} />
                  <div style={{ fontSize: "12px", color: "#888", marginTop: "5px" }}>Will be displayed on the quote</div>
                </div>
              </div>

              <div className="form-row" style={{ display: "block", marginBottom: "20px" }}>
                <label className="form-label" style={{ width: "100%", marginBottom: "10px", color: "#333", fontWeight: "500" }}>Terms & Conditions</label>
                <div className="form-control">
                  <textarea className="input-field" value={termsConditions} onChange={e => setTermsConditions(e.target.value)} rows="3" placeholder="Enter the terms and conditions of your business to be displayed in your transaction" style={{ borderRadius: "8px" }} />
                </div>
              </div>

              <div className="form-row" style={{ display: "block" }}>
                <label className="form-label" style={{ width: "100%", marginBottom: "10px", color: "#333", fontWeight: "500" }}>Attach File(s) to Quote</label>
                <div className="form-control">
                  <div 
                    style={{ border: "1px dashed #ccc", borderRadius: "8px", padding: "20px", textAlign: "center", background: "#f8f9fb", cursor: "pointer", transition: "background 0.2s" }}
                    onClick={() => document.getElementById('quote-file-upload').click()}
                    onMouseEnter={(e) => e.currentTarget.style.background = "#f0f8ff"}
                    onMouseLeave={(e) => e.currentTarget.style.background = "#f8f9fb"}
                  >
                    <span style={{ fontSize: "20px", color: "#888", display: "block", marginBottom: "8px" }}>📎</span>
                    {selectedFile ? (
                      <div style={{ color: "#333", fontWeight: "500" }}>
                        {selectedFile.name}
                        <span 
                          style={{ color: "#ef4444", marginLeft: "10px", fontSize: "12px", cursor: "pointer" }}
                          onClick={(e) => { e.stopPropagation(); setSelectedFile(null); }}
                        >
                          Remove
                        </span>
                      </div>
                    ) : (
                      <>
                        <span style={{ color: "#4a90e2", fontWeight: "500" }}>Click to upload</span> or drag and drop<br/>
                        <span style={{ fontSize: "12px", color: "#888", marginTop: "5px", display: "inline-block" }}>Maximum file size 5MB</span>
                      </>
                    )}
                    <input 
                      type="file" 
                      id="quote-file-upload" 
                      style={{ display: "none" }} 
                      onChange={(e) => setSelectedFile(e.target.files[0])}
                    />
                  </div>
                </div>
              </div>
            </div>

            <div className="totals-section" style={{ background: "#f8f9fb", borderRadius: "10px", padding: "25px", width: "400px" }}>
              <div className="totals-row" style={{ fontWeight: "600", marginBottom: "20px" }}>
                <span>Sub Total</span>
                <span>{subtotal.toFixed(2)}</span>
              </div>
              
              <div className="totals-row" style={{ alignItems: "center", marginBottom: "20px" }}>
                <div style={{ display: "flex", alignItems: "center", gap: "15px" }}>
                  <label style={{ display: "flex", alignItems: "center", gap: "5px", fontSize: "13px", cursor: "pointer", color: "#4a90e2" }}>
                    <input type="radio" name="tdsTcs" checked={tdsTcsType === "TDS"} onChange={() => setTdsTcsType("TDS")} style={{ accentColor: "#4a90e2" }} /> TDS
                  </label>
                  <label style={{ display: "flex", alignItems: "center", gap: "5px", fontSize: "13px", cursor: "pointer", color: "#666" }}>
                    <input type="radio" name="tdsTcs" checked={tdsTcsType === "TCS"} onChange={() => setTdsTcsType("TCS")} /> TCS
                  </label>
                </div>
                <div style={{ flex: 1, marginLeft: "15px" }}>
                  <select className="input-field" value={taxSelection} onChange={(e) => setTaxSelection(e.target.value)} style={{ padding: "6px 10px", color: "#666" }}>
                    <option value="">Select a Tax</option>
                    <option value="5">5%</option>
                    <option value="10">10%</option>
                  </select>
                </div>
                <span style={{ color: "#888", width: "60px", textAlign: "right" }}>- 0.00</span>
              </div>

              <div className="totals-row" style={{ alignItems: "center", marginBottom: "20px" }}>
                <div style={{ display: "flex", alignItems: "center", gap: "15px" }}>
                  <input type="text" value="Adjustment" readOnly className="input-field" style={{ width: "90px", borderStyle: "dashed", background: "transparent", padding: "6px", color: "#666" }} />
                  <input type="number" value={adjustment} onChange={(e) => setAdjustment(parseFloat(e.target.value) || 0)} className="input-field" style={{ width: "80px", padding: "6px" }} />
                  <span style={{ color: "#888", fontSize: "12px", cursor: "help" }} title="Adjustment">(?)</span>
                </div>
                <span style={{ color: "#333", width: "60px", textAlign: "right" }}>{parseFloat(adjustment || 0).toFixed(2)}</span>
              </div>
              
              <div className="totals-row" style={{ marginTop: "20px", paddingTop: "20px", borderTop: "1px solid #e0e0e0", fontSize: "18px", fontWeight: "700", color: "#111" }}>
                <span>Total ( ₹ )</span>
                <span>{grandTotal.toFixed(2)}</span>
              </div>
            </div>
          </div>

        </div>

        {/* Action Buttons */}
        <div className="form-actions">
          <button type="button" className="btn-save" onClick={() => handleSave("draft")} disabled={loading} style={{ background: "#f5f5f5", color: "#333", border: "1px solid #ccc" }}>
            Save as Draft
          </button>
          <button type="button" className="btn-save" onClick={() => handleSave("sent")} disabled={loading}>
            {loading ? "Saving..." : (isEditMode ? "Update and Send" : "Save and Send")}
          </button>
          <button type="button" className="btn-cancel" onClick={() => navigate("/quotes")}>
            Cancel
          </button>
        </div>

      </div>

      {/* ===== NEW CUSTOMER MODAL ===== */}
      {showCustomerModal && (
        <div className="modal-overlay">
          <div className="modal-box" style={{ width: "950px", maxWidth: "95vw", padding: 0 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "15px 30px", borderBottom: "1px solid #eee" }}>
              <h3 style={{ margin: 0, fontSize: "18px", color: "#333", fontWeight: "500" }}>New Customer</h3>
              <button onClick={() => setShowCustomerModal(false)} style={{ background: "none", border: "none", fontSize: "24px", cursor: "pointer", color: "#888" }}>&times;</button>
            </div>
            <div style={{ maxHeight: "70vh", overflowY: "auto" }}>
              <AddCustomer isModal={true} onSaveSuccess={handleSaveCustomerSuccess} onCancel={() => setShowCustomerModal(false)} />
            </div>
          </div>
        </div>
      )}

      {/* ===== NEW SALESPERSON MODAL ===== */}
      {showSalespersonModal && (
        <div className="modal-overlay">
          <div className="modal-box">
            <h3 style={{ marginTop: 0, fontSize: "18px", color: "#333", fontWeight: "500", marginBottom: "20px" }}>New Salesperson</h3>
            <div style={{ display: "flex", flexDirection: "column", gap: "15px" }}>
              <div><label style={{ display: "block", marginBottom: "5px", fontSize: "13px" }}>Name *</label><input value={newSp.name} onChange={e => setNewSp({ ...newSp, name: e.target.value })} className="input-field" /></div>
              <div><label style={{ display: "block", marginBottom: "5px", fontSize: "13px" }}>Email</label><input type="email" value={newSp.email} onChange={e => setNewSp({ ...newSp, email: e.target.value })} className="input-field" /></div>
            </div>
            <div style={{ display: "flex", gap: "15px", justifyContent: "flex-end", marginTop: "25px" }}>
              <button onClick={() => setShowSalespersonModal(false)} className="btn-cancel">Cancel</button>
              <button onClick={handleSaveSalesperson} className="btn-save">Save</button>
            </div>
          </div>
        </div>
      )}

      {/* ===== NEW PROJECT MODAL ===== */}
      {showProjectModal && (
        <div className="modal-overlay">
          <div className="modal-box">
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" }}>
              <h3 style={{ margin: 0, fontSize: "18px", fontWeight: "500", color: "#333" }}>New Project</h3>
              <button onClick={() => setShowProjectModal(false)} style={{ background: "none", border: "none", fontSize: "24px", cursor: "pointer", color: "#888" }}>&times;</button>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: "15px" }}>
              <div>
                <label style={{ display: "block", marginBottom: "5px", fontSize: "13px" }}>Project Name *</label>
                <input value={newProj.project_name} onChange={e => setNewProj({ ...newProj, project_name: e.target.value })} className="input-field" />
              </div>
              <div>
                <label style={{ display: "block", marginBottom: "5px", fontSize: "13px" }}>Customer</label>
                <select value={newProj.customer_id} onChange={e => setNewProj({ ...newProj, customer_id: e.target.value })} className="input-field">
                  <option value="">Select customer</option>
                  {customers.map(c => <option key={c.id} value={c.id}>{c.display_name || c.email}</option>)}
                </select>
              </div>
              <div style={{ display: "flex", gap: "15px" }}>
                <div style={{ flex: 1 }}>
                  <label style={{ display: "block", marginBottom: "5px", fontSize: "13px" }}>Start Date</label>
                  <input type="date" value={newProj.start_date} onChange={e => setNewProj({ ...newProj, start_date: e.target.value })} className="input-field" />
                </div>
                <div style={{ flex: 1 }}>
                  <label style={{ display: "block", marginBottom: "5px", fontSize: "13px" }}>End Date</label>
                  <input type="date" value={newProj.end_date} onChange={e => setNewProj({ ...newProj, end_date: e.target.value })} className="input-field" />
                </div>
              </div>
              <div>
                <label style={{ display: "block", marginBottom: "5px", fontSize: "13px" }}>Description</label>
                <textarea value={newProj.description} onChange={e => setNewProj({ ...newProj, description: e.target.value })} rows={2} className="input-field" />
              </div>
              <div>
                <label style={{ display: "block", marginBottom: "5px", fontSize: "13px" }}>Status</label>
                <select value={newProj.status} onChange={e => setNewProj({ ...newProj, status: e.target.value })} className="input-field">
                  <option value="active">Active</option>
                  <option value="on_hold">On Hold</option>
                  <option value="completed">Completed</option>
                </select>
              </div>
            </div>
            <div style={{ display: "flex", gap: "15px", justifyContent: "flex-end", marginTop: "25px" }}>
              <button onClick={() => setShowProjectModal(false)} className="btn-cancel">Cancel</button>
              <button onClick={handleSaveProject} className="btn-save">Save</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}

export default AddQuote;