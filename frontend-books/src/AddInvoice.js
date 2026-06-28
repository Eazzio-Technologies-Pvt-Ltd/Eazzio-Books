import React, { useState, useEffect } from "react";
import { useNavigate, useSearchParams, useParams } from "react-router-dom";
import { apiRequest } from "./api";
import { FormSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";
import AddCustomer from "./AddCustomer";

const customCSS = `
  .add-item-container { background: #fff; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; color: #212529; min-height: calc(100vh - 60px); }
  .add-item-header { padding: 15px 30px; border-bottom: 1px solid #f0f0f0; display: flex; justify-content: space-between; align-items: center; }
  .add-item-header h2 { margin: 0; font-size: 20px; font-weight: 400; }
  .form-section { padding: 30px; }
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
  
  .item-table-container { margin-top: 30px; border: 1px solid #e2e8f0; border-radius: 8px; background: #fff; overflow: visible; }
  .item-table-header { padding: 15px 20px; background: #f8fafc; border-bottom: 1px solid #e2e8f0; border-radius: 8px 8px 0 0; }
  .item-table-header h3 { font-size: 15px; color: #334155; font-weight: 600; margin: 0; }
  .item-table { width: 100%; border-collapse: collapse; }
  .item-table th { background: #f8fafc; border-bottom: 1px solid #e2e8f0; padding: 12px 20px; text-align: left; font-size: 12px; color: #64748b; font-weight: 600; text-transform: uppercase; }
  .item-table td { padding: 10px 20px; border-bottom: 1px solid #f1f5f9; vertical-align: top; }
  .table-input { width: 100%; padding: 8px 10px; border: 1px solid transparent; border-radius: 4px; font-size: 13px; outline: none; box-sizing: border-box; transition: all 0.2s; background: transparent; }
  .table-input:hover { border-color: #cbd5e1; background: #f8fafc; }
  .table-input:focus { border-color: #4a90e2; background: #fff; }
  
  .totals-section { background: #f8fafc; border-radius: 8px; padding: 25px; width: 400px; border: 1px solid #e2e8f0; }
  .totals-row { display: flex; justify-content: space-between; margin-bottom: 15px; font-size: 14px; color: #334155; align-items: center; }
  
  .modal-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(15, 23, 42, 0.4); backdrop-filter: blur(4px); display: flex; justify-content: center; align-items: center; z-index: 1000; }
  .modal-box { background: #fff; border-radius: 12px; padding: 30px; width: 450px; max-width: 90vw; max-height: 90vh; overflow-y: auto; box-shadow: 0 20px 40px rgba(0,0,0,0.12); }
  
  .btn-new-link { background: none; border: 1px solid #cbd5e1; padding: 0 15px; border-radius: 4px; cursor: pointer; color: #4a90e2; white-space: nowrap; font-size: 13px; transition: all 0.2s; }
  .btn-new-link:hover { background: #f0f6ff; border-color: #4a90e2; }
`;

function AddInvoice() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { id } = useParams();
  const isEditMode = Boolean(id);

  // --- Basic fields ---
  const [customerId, setCustomerId] = useState(searchParams.get("customer_id") || "");
  const [invoiceNumber, setInvoiceNumber] = useState("");
  const [orderNumber, setOrderNumber] = useState("");
  const [invoiceDate, setInvoiceDate] = useState(new Date().toISOString().slice(0, 10));
  const [dueDate, setDueDate] = useState("");
  const [subject, setSubject] = useState("");
  const [notes, setNotes] = useState("Thanks for your business.");
  const [terms, setTerms] = useState("");
  const [salespersonId, setSalespersonId] = useState("");
  const [projectId, setProjectId] = useState("");
  const [selectedFile, setSelectedFile] = useState(null);
  const [adjustment, setAdjustment] = useState(0);

  // --- GST Fields ---
  const [supplierState, setSupplierState] = useState("Jharkhand");
  const [placeOfSupply, setPlaceOfSupply] = useState("Jharkhand");
  const [customerGstin, setCustomerGstin] = useState("");
  const [gstType, setGstType] = useState("intra_state");
  const [tdsTcsType, setTdsTcsType] = useState("TDS");
  const [taxSelection, setTaxSelection] = useState("");

  // --- Items ---
  const [items, setItems] = useState([
    { item_id: "", item_name: "", description: "", quantity: 1, unit_price: 0, tax_rate: 0, discount: 0, discount_type: "flat", hsn_code: "", unit: "" }
  ]);

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
  const [newProj, setNewProj] = useState({ project_name: "", customer_id: "", start_date: "", end_date: "", description: "", status: "active" });

  useEffect(() => {
    const fetchAll = async () => {
      try {
        const [custRes, itemRes, spRes, projRes, orgRes] = await Promise.all([
          apiRequest("/customers"),
          apiRequest("/items"),
          apiRequest("/salespersons"),
          apiRequest("/projects"),
          apiRequest("/organization-settings")
        ]);
        setCustomers(Array.isArray(custRes?.customers) ? custRes.customers : []);
        setCatalogItems(Array.isArray(itemRes?.items) ? itemRes.items : []);
        setSalespersons(Array.isArray(spRes?.salespersons) ? spRes.salespersons : []);
        setProjects(Array.isArray(projRes?.projects) ? projRes.projects : []);

        if (orgRes?.settings?.state) {
          setSupplierState(orgRes.settings.state);
        }

        if (isEditMode) {
          setFetching(true);
          const res = await apiRequest(`/invoices/${id}`);
          if (res?.invoice) {
            const inv = res.invoice;
            setCustomerId(inv.customer_id ? String(inv.customer_id) : "");
            setInvoiceNumber(inv.invoice_number || "");
            setOrderNumber(inv.reference_number || ""); 
            setInvoiceDate(inv.invoice_date ? inv.invoice_date.slice(0, 10) : "");
            setDueDate(inv.due_date ? inv.due_date.slice(0, 10) : "");
            setSubject(inv.subject || "");
            setNotes(inv.notes || "Thanks for your business.");
            setTerms(inv.terms || "");
            setSalespersonId(inv.salesperson_id ? String(inv.salesperson_id) : "");
            setProjectId(inv.project_id ? String(inv.project_id) : "");
            if (inv.supplier_state) setSupplierState(inv.supplier_state);
            if (inv.place_of_supply) setPlaceOfSupply(inv.place_of_supply);
            if (inv.customer_gstin) setCustomerGstin(inv.customer_gstin);
            if (inv.gst_type) setGstType(inv.gst_type);
            if (res.items && res.items.length > 0) {
              setItems(res.items.map(item => ({
                item_id:       item.item_id       ? String(item.item_id) : "",
                item_name:     item.item_name     || "",
                description:   item.description   || "",
                quantity:      item.quantity       || 1,
                unit_price:    item.unit_price     || item.rate || 0,
                tax_rate:      item.tax_rate       || 0,
                discount:      item.discount       || 0,
                discount_type: item.discount_type  || "flat",
                hsn_code:      item.hsn_code       || "",
                unit:          item.unit           || "",
              })));
            }
          }
        }
      } catch (err) { console.error("Failed to load data", err); }
      finally { setFetching(false); }
    };
    fetchAll();
  }, [id, isEditMode]);

  useEffect(() => {
    if (customerId) {
      const cust = customers.find(c => String(c.id) === String(customerId));
      if (cust && !isEditMode) {
        if (cust.pan && cust.pan.length >= 15) setCustomerGstin(cust.pan);
      }
    }
  }, [customerId, customers, isEditMode]);

  useEffect(() => {
    if (supplierState.toLowerCase().trim() === placeOfSupply.toLowerCase().trim()) {
      setGstType("intra_state");
    } else {
      setGstType("inter_state");
    }
  }, [supplierState, placeOfSupply]);

  const addItem = () => {
    setItems([...items, { item_id: "", item_name: "", description: "", quantity: 1, unit_price: 0, tax_rate: 0, discount: 0, discount_type: "flat", hsn_code: "", unit: "" }]);
  };
  const removeItem = (index) => setItems(items.filter((_, i) => i !== index));
  const updateItem = (index, field, value) => {
    const updated = [...items]; updated[index][field] = value; setItems(updated);
  };

  const handleItemSelect = (index, itemId) => {
    const updated = [...items];
    updated[index].item_id = itemId;
    if (itemId) {
      const ci = catalogItems.find(c => String(c.id) === String(itemId));
      if (ci) {
        updated[index].item_name   = ci.name || "";
        updated[index].description = ci.description || ci.name || "";
        updated[index].unit_price  = ci.selling_price || 0;
        updated[index].tax_rate    = ci.tax_rate || 0;
        updated[index].hsn_code    = ci.hsn_code || "";
        updated[index].unit        = ci.unit || "";
      }
    } else {
      updated[index].item_name = "";
      updated[index].hsn_code  = "";
      updated[index].unit      = "";
    }
    setItems(updated);
  };

  const calcLineAmount = (item) => {
    let amt = (parseFloat(item.quantity) || 0) * (parseFloat(item.unit_price) || 0);
    const disc = parseFloat(item.discount) || 0;
    if (item.discount_type === "percent") { amt -= amt * (disc / 100); } else { amt -= disc; }
    return amt;
  };

  const getLineGst = (item) => {
    const taxableAmt = calcLineAmount(item);
    const rate = parseFloat(item.tax_rate) || 0;
    let cgstRate = 0, sgstRate = 0, igstRate = 0;
    
    if (gstType === "intra_state") {
      cgstRate = rate / 2;
      sgstRate = rate / 2;
    } else {
      igstRate = rate;
    }

    return {
      cgst_rate: cgstRate,
      sgst_rate: sgstRate,
      igst_rate: igstRate,
      cgst_amount: taxableAmt * (cgstRate / 100),
      sgst_amount: taxableAmt * (sgstRate / 100),
      igst_amount: taxableAmt * (igstRate / 100),
      tax_amount: taxableAmt * (rate / 100)
    };
  };

  const calcLineTax = (item) => getLineGst(item).tax_amount;

  const subtotal = items.reduce((s, i) => s + (parseFloat(i.quantity) || 0) * (parseFloat(i.unit_price) || 0), 0);
  const totalDiscount = items.reduce((s, i) => {
    const d = parseFloat(i.discount) || 0;
    if (i.discount_type === "percent") return s + ((parseFloat(i.quantity) || 0) * (parseFloat(i.unit_price) || 0) * d / 100);
    return s + d;
  }, 0);
  
  let totalCGST = 0, totalSGST = 0, totalIGST = 0;
  items.forEach(i => {
    const gst = getLineGst(i);
    totalCGST += gst.cgst_amount;
    totalSGST += gst.sgst_amount;
    totalIGST += gst.igst_amount;
  });
  
  const totalTax = totalCGST + totalSGST + totalIGST;
  const grandTotal = subtotal - totalDiscount + totalTax + parseFloat(adjustment || 0);

  const handleSave = async (status = "draft") => {
    if (!customerId) { toast.error("Please select a customer"); return; }
    if (items.length === 0 || items.every(item => !item.description && !item.item_id)) {
      toast.error("Add at least one item"); return;
    }
    setLoading(true);
    try {
      const payload = {
        customer_id: parseInt(customerId),
        invoice_date: invoiceDate,
        due_date: dueDate || null,
        status: status,
        notes, 
        terms,
        reference_number: orderNumber,
        subject: subject,
        salesperson_id: salespersonId ? parseInt(salespersonId) : null,
        project_id: projectId ? parseInt(projectId) : null,
        supplier_state: supplierState,
        place_of_supply: placeOfSupply,
        customer_gstin: customerGstin,
        gst_type: gstType,
        items: items.map(item => {
          const gst = getLineGst(item);
          return {
            ...item,
            item_id:    item.item_id    ? parseInt(item.item_id) : null,
            item_name:  item.item_name  || null,
            hsn_code:   item.hsn_code   || null,
            unit:       item.unit       || null,
            quantity:   parseFloat(item.quantity)   || 0,
            unit_price: parseFloat(item.unit_price) || 0,
            tax_rate:   parseFloat(item.tax_rate)   || 0,
            discount:   parseFloat(item.discount)   || 0,
            cgst_rate: gst.cgst_rate,
            cgst_amount: gst.cgst_amount,
            sgst_rate: gst.sgst_rate,
            sgst_amount: gst.sgst_amount,
            igst_rate: gst.igst_rate,
            igst_amount: gst.igst_amount
          };
        }),
      };

      if (isEditMode) {
        await apiRequest(`/invoices/${id}`, {
          method: "PUT",
          body: JSON.stringify(payload),
        });
        toast.success("Invoice updated");
        navigate(`/invoices/${id}`);
      } else {
        await apiRequest("/invoices", {
          method: "POST",
          body: JSON.stringify(payload),
        });
        toast.success("Invoice created");
        navigate("/invoices");
      }
    } catch (err) { toast.error((isEditMode ? "Failed to update invoice: " : "Failed to create invoice: ") + (err.message || "")); }
    finally { setLoading(false); }
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
      if (res?.salesperson) { setSalespersons(prev => [...prev, res.salesperson]); setSalespersonId(String(res.salesperson.id)); toast.success("Salesperson created"); }
      setShowSalespersonModal(false); setNewSp({ name: "", email: "", phone: "", employee_id: "" });
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
          <h2>{isEditMode ? "Edit Invoice" : "New Invoice"}</h2>
          <button className="btn-cancel" onClick={() => navigate("/invoices")} style={{ border: 'none', background: 'none', fontSize: '24px', padding: '0', color: '#888' }}>&times;</button>
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
                <button type="button" onClick={() => setShowCustomerModal(true)} className="btn-new-link">+ New</button>
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Invoice# <span className="req-dashed">*</span></label>
              <div className="form-control">
                <input className="input-field" type="text" value={isEditMode ? invoiceNumber : "INV-[Auto-Generated]"} disabled={!isEditMode} style={{ background: isEditMode ? "#fff" : "#f8fafc", color: "#64748b" }} />
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Order Number</label>
              <div className="form-control">
                <input className="input-field" type="text" value={orderNumber} onChange={e => setOrderNumber(e.target.value)} />
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Invoice Date <span className="req-dashed">*</span></label>
              <div className="form-control" style={{ display: "flex", gap: "20px" }}>
                <input className="input-field" type="date" value={invoiceDate} onChange={e => setInvoiceDate(e.target.value)} />
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
              <label className="form-label">Due Date</label>
              <div className="form-control">
                <input className="input-field" type="date" value={dueDate} onChange={e => setDueDate(e.target.value)} style={{ borderStyle: "dashed" }} />
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Salesperson</label>
              <div className="form-control" style={{ display: "flex", gap: "10px" }}>
                <select className="input-field" value={salespersonId} onChange={e => setSalespersonId(e.target.value)}>
                  <option value="">Select Salesperson</option>
                  {salespersons.map(sp => <option key={sp.id} value={sp.id}>{sp.name}</option>)}
                </select>
                <button type="button" onClick={() => setShowSalespersonModal(true)} className="btn-new-link">+ New</button>
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Project Name</label>
              <div className="form-control" style={{ display: "flex", gap: "10px" }}>
                <select className="input-field" value={projectId} onChange={e => setProjectId(e.target.value)}>
                  <option value="">Select project</option>
                  {projects.map(p => <option key={p.id} value={p.id}>{p.project_name}</option>)}
                </select>
                <button type="button" onClick={() => setShowProjectModal(true)} className="btn-new-link">+ New</button>
              </div>
            </div>
            
            <div className="form-row">
              <label className="form-label">Subject</label>
              <div className="form-control">
                <input className="input-field" type="text" value={subject} onChange={e => setSubject(e.target.value)} placeholder="Let your customer know what this Invoice is for..." />
              </div>
            </div>
            
            {/* Hidden fields for GST logic */}
            <div style={{ display: "none" }}>
              <input type="text" value={supplierState} readOnly />
              <input type="text" value={placeOfSupply} readOnly />
              <input type="text" value={customerGstin} readOnly />
            </div>
          </div>

          <div className="item-table-container">
            <div className="item-table-header">
              <h3>Item Table</h3>
            </div>
            <table className="item-table">
              <thead>
                <tr>
                  <th style={{ width: "40%" }}>ITEM DETAILS</th>
                  <th style={{ width: "15%", textAlign: "right" }}>QUANTITY</th>
                  <th style={{ width: "15%", textAlign: "right" }}>RATE</th>
                  <th style={{ width: "15%", textAlign: "right" }}>DISCOUNT</th>
                  <th style={{ width: "15%", textAlign: "right", paddingRight: "20px" }}>AMOUNT</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item, idx) => (
                  <tr key={idx}>
                    <td>
                      <div style={{ display: "flex", alignItems: "flex-start", gap: "10px" }}>
                        <span style={{ color: "#cbd5e1", cursor: "grab", marginTop: "10px" }}>⋮⋮</span>
                        <div style={{ flex: 1 }}>
                          <select 
                            value={item.item_id} 
                            onChange={e => handleItemSelect(idx, e.target.value)} 
                            className="table-input"
                            style={{ appearance: "none", cursor: "pointer", fontWeight: "500", color: "#64748b" }}
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
                              style={{ resize: "none", color: "#475569", marginTop: "4px" }}
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
                      <div style={{ display: "flex", alignItems: "center", background: "#f8fafc", borderRadius: "4px", border: "1px solid transparent" }} onFocus={e => e.currentTarget.style.borderColor="#4a90e2"} onBlur={e => e.currentTarget.style.borderColor="transparent"}>
                        <input type="number" min="0" step="0.01" value={item.discount} onChange={e => updateItem(idx, "discount", e.target.value)} className="table-input" style={{ textAlign: "right", border: "none" }} />
                        <select value={item.discount_type} onChange={e => updateItem(idx, "discount_type", e.target.value)} className="table-input" style={{ width: "45px", padding: "6px 2px", borderLeft: "1px solid #e2e8f0", border: "none", borderRadius: "0 4px 4px 0" }}>
                          <option value="percent">%</option>
                          <option value="flat">₹</option>
                        </select>
                      </div>
                    </td>
                    <td style={{ textAlign: "right", fontWeight: "600", color: "#334155", paddingTop: "18px", paddingRight: "20px" }}>
                      {(calcLineAmount(item)).toFixed(2)}
                      {items.length > 1 && (
                        <button onClick={() => removeItem(idx)} style={{ background: "none", border: "none", color: "#ef4444", cursor: "pointer", marginLeft: "10px", fontSize: "14px" }}>✕</button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          
          <div style={{ display: "flex", justifyContent: "space-between", marginTop: "30px", gap: "60px", alignItems: "flex-start" }}>
            <div style={{ flex: 1 }}>
              <div style={{ display: "flex", gap: "15px", marginBottom: "30px" }}>
                <button type="button" onClick={addItem} style={{ background: "#f0f6ff", color: "#4a90e2", border: "none", padding: "10px 16px", borderRadius: "6px", cursor: "pointer", fontSize: "13px", fontWeight: "500", display: "flex", alignItems: "center", gap: "8px", transition: "background 0.2s" }} onMouseEnter={e => e.currentTarget.style.background="#e0edff"} onMouseLeave={e => e.currentTarget.style.background="#f0f6ff"}>
                  <span style={{ background: "#4a90e2", color: "#fff", borderRadius: "50%", width: "16px", height: "16px", display: "inline-flex", alignItems: "center", justifyContent: "center", fontSize: "12px", paddingBottom: "2px" }}>+</span> Add New Row <span style={{ marginLeft: "4px", color: "#94a3b8" }}>⌄</span>
                </button>
                <button type="button" onClick={() => toast("Bulk add feature coming soon")} style={{ background: "#f0f6ff", color: "#4a90e2", border: "none", padding: "10px 16px", borderRadius: "6px", cursor: "pointer", fontSize: "13px", fontWeight: "500", display: "flex", alignItems: "center", gap: "8px", transition: "background 0.2s" }} onMouseEnter={e => e.currentTarget.style.background="#e0edff"} onMouseLeave={e => e.currentTarget.style.background="#f0f6ff"}>
                  <span style={{ background: "#4a90e2", color: "#fff", borderRadius: "50%", width: "16px", height: "16px", display: "inline-flex", alignItems: "center", justifyContent: "center", fontSize: "12px", paddingBottom: "2px" }}>+</span> Add Items in Bulk
                </button>
              </div>

              <div className="form-row" style={{ display: "block", marginBottom: "20px" }}>
                <label className="form-label" style={{ width: "100%", marginBottom: "10px", color: "#334155", fontWeight: "500" }}>Customer Notes</label>
                <div className="form-control">
                  <textarea className="input-field" value={notes} onChange={e => setNotes(e.target.value)} rows="3" placeholder="Thanks for your business." />
                  <div style={{ fontSize: "12px", color: "#64748b", marginTop: "5px" }}>Will be displayed on the invoice</div>
                </div>
              </div>

              <div className="form-row" style={{ display: "block", marginBottom: "20px" }}>
                <label className="form-label" style={{ width: "100%", marginBottom: "10px", color: "#334155", fontWeight: "500" }}>Terms & Conditions</label>
                <div className="form-control">
                  <textarea className="input-field" value={terms} onChange={e => setTerms(e.target.value)} rows="3" placeholder="Enter the terms and conditions of your business to be displayed in your transaction" />
                </div>
              </div>

              <div className="form-row" style={{ display: "block" }}>
                <label className="form-label" style={{ width: "100%", marginBottom: "10px", color: "#334155", fontWeight: "500" }}>Attach File(s) to Invoice</label>
                <div className="form-control">
                  <div 
                    style={{ border: "1px dashed #cbd5e1", borderRadius: "8px", padding: "20px", textAlign: "center", background: "#f8fafc", cursor: "pointer", transition: "background 0.2s" }}
                    onClick={() => document.getElementById('invoice-file-upload').click()}
                    onMouseEnter={(e) => e.currentTarget.style.background = "#f0f6ff"}
                    onMouseLeave={(e) => e.currentTarget.style.background = "#f8fafc"}
                  >
                    <span style={{ fontSize: "20px", color: "#94a3b8", display: "block", marginBottom: "8px" }}>📎</span>
                    {selectedFile ? (
                      <div style={{ color: "#334155", fontWeight: "500" }}>
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
                        <span style={{ fontSize: "12px", color: "#64748b", marginTop: "5px", display: "inline-block" }}>Maximum file size 5MB</span>
                      </>
                    )}
                    <input 
                      type="file" 
                      id="invoice-file-upload" 
                      style={{ display: "none" }} 
                      onChange={(e) => setSelectedFile(e.target.files[0])}
                    />
                  </div>
                </div>
              </div>
            </div>

            <div className="totals-section">
              <div className="totals-row" style={{ fontWeight: "600", marginBottom: "20px" }}>
                <span>Sub Total</span>
                <span>{subtotal.toFixed(2)}</span>
              </div>
              
              {totalDiscount > 0 && (
                <div className="totals-row" style={{ marginBottom: "20px", color: "#ef4444" }}>
                  <span>Discount</span>
                  <span>- {totalDiscount.toFixed(2)}</span>
                </div>
              )}

              <div className="totals-row" style={{ marginBottom: "20px" }}>
                <div style={{ display: "flex", alignItems: "center", gap: "15px" }}>
                  <label style={{ display: "flex", alignItems: "center", gap: "5px", fontSize: "13px", cursor: "pointer", color: "#4a90e2" }}>
                    <input type="radio" name="tdsTcs" checked={tdsTcsType === "TDS"} onChange={() => setTdsTcsType("TDS")} style={{ accentColor: "#4a90e2" }} /> TDS
                  </label>
                  <label style={{ display: "flex", alignItems: "center", gap: "5px", fontSize: "13px", cursor: "pointer", color: "#64748b" }}>
                    <input type="radio" name="tdsTcs" checked={tdsTcsType === "TCS"} onChange={() => setTdsTcsType("TCS")} /> TCS
                  </label>
                </div>
                <div style={{ flex: 1, marginLeft: "15px" }}>
                  <select className="input-field" value={taxSelection} onChange={(e) => setTaxSelection(e.target.value)} style={{ padding: "6px 10px", color: "#475569" }}>
                    <option value="">Select a Tax</option>
                    <option value="5">5%</option>
                    <option value="10">10%</option>
                  </select>
                </div>
                <span style={{ color: "#94a3b8", width: "60px", textAlign: "right" }}>- 0.00</span>
              </div>

              {totalTax > 0 && (
                <div className="totals-row" style={{ marginBottom: "20px" }}>
                  <span>Total Tax (GST)</span>
                  <span>+ {totalTax.toFixed(2)}</span>
                </div>
              )}

              <div className="totals-row" style={{ marginBottom: "20px" }}>
                <div style={{ display: "flex", alignItems: "center", gap: "15px" }}>
                  <input type="text" value="Adjustment" readOnly className="input-field" style={{ width: "90px", borderStyle: "dashed", background: "transparent", padding: "6px", color: "#64748b" }} />
                  <input type="number" value={adjustment} onChange={(e) => setAdjustment(parseFloat(e.target.value) || 0)} className="input-field" style={{ width: "80px", padding: "6px" }} />
                  <span style={{ color: "#94a3b8", fontSize: "12px", cursor: "help" }} title="Adjustment">(?)</span>
                </div>
                <span style={{ width: "60px", textAlign: "right" }}>{parseFloat(adjustment || 0).toFixed(2)}</span>
              </div>
              
              <div className="totals-row" style={{ marginTop: "20px", paddingTop: "20px", borderTop: "1px solid #cbd5e1", fontSize: "18px", fontWeight: "700", color: "#0f172a" }}>
                <span>Total ( ₹ )</span>
                <span>{grandTotal.toFixed(2)}</span>
              </div>
            </div>
          </div>

        </div>

        {/* Action Buttons */}
        <div className="form-actions">
          <button type="button" className="btn-cancel" onClick={() => handleSave("draft")} disabled={loading}>
            Save as Draft
          </button>
          <button type="button" className="btn-save" onClick={() => handleSave("sent")} disabled={loading}>
            {loading ? "Saving..." : (isEditMode ? "Update and Send" : "Save and Send")}
          </button>
          <button type="button" className="btn-cancel" onClick={() => navigate("/invoices")}>
            Cancel
          </button>
        </div>

      </div>

      {/* ===== NEW CUSTOMER MODAL ===== */}
      {showCustomerModal && (
        <div className="modal-overlay">
          <div className="modal-box" style={{ width: "950px", maxWidth: "95vw", padding: 0 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "20px 30px", borderBottom: "1px solid #f1f5f9" }}>
              <h3 style={{ margin: 0, fontSize: "18px", color: "#334155", fontWeight: "500" }}>New Customer</h3>
              <button onClick={() => setShowCustomerModal(false)} style={{ background: "none", border: "none", fontSize: "24px", cursor: "pointer", color: "#94a3b8" }}>&times;</button>
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
            <h3 style={{ margin: "0 0 20px 0", fontSize: "18px", color: "#334155", fontWeight: "500" }}>New Salesperson</h3>
            <div style={{ display: "flex", flexDirection: "column", gap: "15px" }}>
              <div><label style={{ display: "block", marginBottom: "5px", fontSize: "13px", color: "#475569" }}>Name *</label><input value={newSp.name} onChange={e => setNewSp({ ...newSp, name: e.target.value })} className="input-field" /></div>
              <div><label style={{ display: "block", marginBottom: "5px", fontSize: "13px", color: "#475569" }}>Email</label><input type="email" value={newSp.email} onChange={e => setNewSp({ ...newSp, email: e.target.value })} className="input-field" /></div>
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
              <h3 style={{ margin: 0, fontSize: "18px", fontWeight: "500", color: "#334155" }}>New Project</h3>
              <button onClick={() => setShowProjectModal(false)} style={{ background: "none", border: "none", fontSize: "24px", cursor: "pointer", color: "#94a3b8" }}>&times;</button>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: "15px" }}>
              <div>
                <label style={{ display: "block", marginBottom: "5px", fontSize: "13px", color: "#475569" }}>Project Name *</label>
                <input value={newProj.project_name} onChange={e => setNewProj({ ...newProj, project_name: e.target.value })} className="input-field" />
              </div>
              <div>
                <label style={{ display: "block", marginBottom: "5px", fontSize: "13px", color: "#475569" }}>Customer</label>
                <select value={newProj.customer_id} onChange={e => setNewProj({ ...newProj, customer_id: e.target.value })} className="input-field">
                  <option value="">Select customer</option>
                  {customers.map(c => <option key={c.id} value={c.id}>{c.display_name || c.email}</option>)}
                </select>
              </div>
              <div style={{ display: "flex", gap: "15px" }}>
                <div style={{ flex: 1 }}>
                  <label style={{ display: "block", marginBottom: "5px", fontSize: "13px", color: "#475569" }}>Start Date</label>
                  <input type="date" value={newProj.start_date} onChange={e => setNewProj({ ...newProj, start_date: e.target.value })} className="input-field" />
                </div>
                <div style={{ flex: 1 }}>
                  <label style={{ display: "block", marginBottom: "5px", fontSize: "13px", color: "#475569" }}>End Date</label>
                  <input type="date" value={newProj.end_date} onChange={e => setNewProj({ ...newProj, end_date: e.target.value })} className="input-field" />
                </div>
              </div>
              <div>
                <label style={{ display: "block", marginBottom: "5px", fontSize: "13px", color: "#475569" }}>Description</label>
                <textarea value={newProj.description} onChange={e => setNewProj({ ...newProj, description: e.target.value })} rows={2} className="input-field" />
              </div>
              <div>
                <label style={{ display: "block", marginBottom: "5px", fontSize: "13px", color: "#475569" }}>Status</label>
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

export default AddInvoice;