import React, { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { apiRequest } from "./api";
import { FormSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";

function AddVendor() {
  const { id } = useParams();
  const isEditMode = Boolean(id);
  const navigate = useNavigate();

  const [activeTab, setActiveTab] = useState("Other Details");
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(false);

  const [formData, setFormData] = useState({
    salutation: "",
    first_name: "",
    last_name: "",
    display_name: "",
    company_name: "",
    email: "",
    phone: "",
    mobile: "",
    gstin: "",
    pan: "",
    msme_registered: false,
    currency: "INR- Indian Rupee",
    opening_balance: "",
    payment_terms: "Due on Receipt",
    tds: "",
    billing_attention: "",
    billing_country: "",
    billing_street1: "",
    billing_street2: "",
    billing_city: "",
    billing_state: "",
    billing_pin: "",
    billing_phone: "",
    billing_fax: "",
    shipping_attention: "",
    shipping_country: "",
    shipping_street1: "",
    shipping_street2: "",
    shipping_city: "",
    shipping_state: "",
    shipping_pin: "",
    shipping_phone: "",
    shipping_fax: "",
    contact_persons: [{ salutation: "", first_name: "", last_name: "", email: "", work_phone: "", mobile: "" }],
    status: "active",
    notes: "",
  });

  useEffect(() => {
    if (isEditMode) {
      setFetching(true);
      fetchVendor();
    }
  }, [id]);

  const fetchVendor = async () => {
    try {
      const res = await apiRequest(`/vendors/${id}`);
      if (res?.vendor) {
        setFormData((prev) => ({
          ...prev,
          display_name: res.vendor.display_name || "",
          company_name: res.vendor.company_name || "",
          email: res.vendor.email || "",
          phone: res.vendor.phone || "",
          gstin: res.vendor.gstin || "",
          pan: res.vendor.pan || "",
          billing_attention: res.vendor.billing_attention || "",
          billing_country: res.vendor.billing_country || "",
          billing_street1: res.vendor.billing_street1 || "",
          billing_street2: res.vendor.billing_street2 || "",
          billing_city: res.vendor.billing_city || "",
          billing_state: res.vendor.billing_state || "",
          billing_pin: res.vendor.billing_pin || "",
          billing_phone: res.vendor.billing_phone || "",
          billing_fax: res.vendor.billing_fax || "",
          shipping_attention: res.vendor.shipping_attention || "",
          shipping_country: res.vendor.shipping_country || "",
          shipping_street1: res.vendor.shipping_street1 || "",
          shipping_street2: res.vendor.shipping_street2 || "",
          shipping_city: res.vendor.shipping_city || "",
          shipping_state: res.vendor.shipping_state || "",
          shipping_pin: res.vendor.shipping_pin || "",
          shipping_phone: res.vendor.shipping_phone || "",
          shipping_fax: res.vendor.shipping_fax || "",
          contact_persons: res.vendor.contact_persons || [{ salutation: "", first_name: "", last_name: "", email: "", work_phone: "", mobile: "" }],
          opening_balance: res.vendor.opening_balance || "",
          payment_terms: res.vendor.payment_terms || "Due on Receipt",
          status: res.vendor.status || "active",
          notes: res.vendor.notes || "",
        }));
      }
    } catch (err) {
      toast.error("Failed to load vendor");
    } finally {
      setFetching(false);
    }
  };

  const handleContactChange = (index, field, value) => {
    const updatedContacts = [...(formData.contact_persons || [])];
    if (!updatedContacts[index]) {
      updatedContacts[index] = { salutation: "", first_name: "", last_name: "", email: "", work_phone: "", mobile: "" };
    }
    updatedContacts[index][field] = value;
    setFormData((prev) => ({ ...prev, contact_persons: updatedContacts }));
  };

  const addContactPerson = () => {
    const updatedContacts = [...(formData.contact_persons || []), { salutation: "", first_name: "", last_name: "", email: "", work_phone: "", mobile: "" }];
    setFormData((prev) => ({ ...prev, contact_persons: updatedContacts }));
  };

  const removeContactPerson = (index) => {
    const updatedContacts = [...(formData.contact_persons || [])];
    updatedContacts.splice(index, 1);
    setFormData((prev) => ({ ...prev, contact_persons: updatedContacts }));
  };

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData((prev) => ({ ...prev, [name]: type === "checkbox" ? checked : value }));
  };

  const handleSave = async (e) => {
    e.preventDefault();
    if (!formData.display_name) {
      toast.error("Display Name is required");
      return;
    }

    setLoading(true);
    // Prepare payload keeping only the fields that backend currently expects to avoid issues, 
    // but sending them anyway since extra fields are usually ignored safely.
    const payload = {
      ...formData,
      opening_balance: parseFloat(formData.opening_balance) || 0,
    };

    try {
      if (isEditMode) {
        await apiRequest(`/vendors/${id}`, {
          method: "PUT",
          body: JSON.stringify(payload),
        });
        toast.success("Vendor updated successfully");
        navigate(`/vendors/${id}`);
      } else {
        const res = await apiRequest("/vendors", {
          method: "POST",
          body: JSON.stringify(payload),
        });
        toast.success("Vendor created successfully");
        navigate(`/vendors/${res.vendor.id}`);
      }
    } catch (err) {
      toast.error(isEditMode ? "Failed to update vendor" : "Failed to create vendor");
    } finally {
      setLoading(false);
    }
  };

  if (fetching) {
    return (
      <div style={{ maxWidth: "1000px", margin: "auto", padding: "30px" }}>
        <h2 style={{ marginBottom: "25px", fontSize: "24px", fontWeight: "400" }}>{isEditMode ? "Edit Vendor" : "New Vendor"}</h2>
        <FormSkeleton fields={6} />
      </div>
    );
  }

  const InfoIcon = () => (
    <svg style={{marginLeft: '6px', color: '#9ca3af', cursor: 'help'}} width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>
  );

  return (
    <div style={{ background: "#ffffff", minHeight: "100vh", fontFamily: "system-ui, -apple-system, sans-serif", color: "#1d2939", paddingBottom: "100px" }}>
      <div style={{ padding: "20px 30px", borderBottom: "1px solid #f1f5f9" }}>
        <h2 style={{ margin: 0, fontSize: "24px", fontWeight: "400" }}>{isEditMode ? "Edit Vendor" : "New Vendor"}</h2>
      </div>


      <form onSubmit={handleSave} style={{ maxWidth: "900px", padding: "30px", boxSizing: "border-box" }}>
        
        {/* Top Fields Grid */}
        <div style={{ display: "grid", gridTemplateColumns: "180px 1fr", gap: "20px 30px", alignItems: "center", marginBottom: "40px" }}>
          
          {/* Primary Contact */}
          <div style={{ textAlign: "left", fontSize: "14px", color: "#334155" }}>
            Primary Contact <InfoIcon />
          </div>
          <div style={{ display: "flex", gap: "10px" }}>
            <select name="salutation" value={formData.salutation} onChange={handleChange} style={{ ...inputStyle, width: "120px", color: formData.salutation ? "#111" : "#888" }}>
              <option value="">Salutation</option>
              <option value="Mr.">Mr.</option>
              <option value="Mrs.">Mrs.</option>
              <option value="Ms.">Ms.</option>
              <option value="Dr.">Dr.</option>
            </select>
            <input type="text" name="first_name" value={formData.first_name} onChange={handleChange} placeholder="First Name" style={{ ...inputStyle, flex: 1 }} />
            <input type="text" name="last_name" value={formData.last_name} onChange={handleChange} placeholder="Last Name" style={{ ...inputStyle, flex: 1 }} />
          </div>

          {/* Company Name */}
          <div style={{ textAlign: "left", fontSize: "14px", color: "#334155" }}>
            Company Name
          </div>
          <div>
            <input type="text" name="company_name" value={formData.company_name} onChange={handleChange} style={{ ...inputStyle, maxWidth: "400px" }} />
          </div>

          {/* Display Name */}
          <div style={{ textAlign: "left", fontSize: "14px", color: "#dc2626" }}>
            Display Name* <InfoIcon />
          </div>
          <div>
            <input 
              type="text"
              list="displayNameOptions"
              name="display_name" 
              value={formData.display_name} 
              onChange={handleChange} 
              placeholder="Select or type to add"
              style={{ ...inputStyle, maxWidth: "400px", color: formData.display_name ? "#111" : "#888" }} 
              required 
            />
            <datalist id="displayNameOptions">
              {formData.company_name && <option value={formData.company_name} />}
              {formData.first_name && <option value={`${formData.first_name} ${formData.last_name}`.trim()} />}
            </datalist>
          </div>

          {/* Email Address */}
          <div style={{ textAlign: "left", fontSize: "14px", color: "#334155" }}>
            Email Address <InfoIcon />
          </div>
          <div style={{ position: "relative", maxWidth: "400px" }}>
            <span style={{ position: "absolute", left: "10px", top: "50%", transform: "translateY(-50%)", color: "#9ca3af" }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path><polyline points="22,6 12,13 2,6"></polyline></svg>
            </span>
            <input type="email" name="email" value={formData.email} onChange={handleChange} style={{ ...inputStyle, width: "100%", paddingLeft: "35px" }} />
          </div>

          {/* Phone */}
          <div style={{ textAlign: "left", fontSize: "14px", color: "#334155" }}>
            Phone <InfoIcon />
          </div>
          <div style={{ display: "flex", gap: "20px" }}>
            <div style={{ display: "flex", width: "100%", maxWidth: "250px" }}>
              <select style={{ ...inputStyle, width: "70px", borderRight: "none", borderTopRightRadius: 0, borderBottomRightRadius: 0, background: "#f8fafc" }}>
                <option>+91</option>
              </select>
              <input type="text" name="phone" value={formData.phone} onChange={handleChange} placeholder="Work Phone" style={{ ...inputStyle, flex: 1, borderTopLeftRadius: 0, borderBottomLeftRadius: 0 }} />
            </div>
            <div style={{ display: "flex", width: "100%", maxWidth: "250px" }}>
              <select style={{ ...inputStyle, width: "70px", borderRight: "none", borderTopRightRadius: 0, borderBottomRightRadius: 0, background: "#f8fafc" }}>
                <option>+91</option>
              </select>
              <input type="text" name="mobile" value={formData.mobile} onChange={handleChange} placeholder="Mobile" style={{ ...inputStyle, flex: 1, borderTopLeftRadius: 0, borderBottomLeftRadius: 0 }} />
            </div>
          </div>
        </div>

        {/* Tabs System */}
        <div style={{ borderBottom: "1px solid #e2e8f0", marginBottom: "30px", display: "flex", gap: "30px" }}>
          {["Other Details", "Address", "Contact Persons", "Bank Details", "Custom Fields", "Reporting Tags", "Remarks"].map(tab => (
            <div 
              key={tab} 
              onClick={() => setActiveTab(tab)}
              style={{ 
                padding: "10px 0", 
                cursor: "pointer", 
                fontSize: "14px", 
                fontWeight: activeTab === tab ? "600" : "500", 
                color: activeTab === tab ? "#1e293b" : "#64748b",
                borderBottom: activeTab === tab ? "2px solid #3b82f6" : "2px solid transparent",
                marginBottom: "-1px"
              }}
            >
              {tab}
            </div>
          ))}
        </div>

        {/* Tab Content */}
        <div style={{ minHeight: "300px" }}>
          {activeTab === "Other Details" && (
            <div style={{ display: "grid", gridTemplateColumns: "180px 1fr", gap: "20px 30px", alignItems: "center" }}>
              <div style={{ textAlign: "left", fontSize: "14px", color: "#334155" }}>PAN <InfoIcon /></div>
              <div><input type="text" name="pan" value={formData.pan} onChange={handleChange} style={{ ...inputStyle, maxWidth: "400px" }} /></div>



              <div style={{ textAlign: "left", fontSize: "14px", color: "#334155" }}>Currency</div>
              <div>
                <select name="currency" value={formData.currency} onChange={handleChange} style={{ ...inputStyle, maxWidth: "400px" }}>
                  <option value="INR- Indian Rupee">INR- Indian Rupee</option>
                  <option value="USD- US Dollar">USD- US Dollar</option>
                </select>
              </div>

              <div style={{ textAlign: "left", fontSize: "14px", color: "#334155" }}>Opening Balance</div>
              <div style={{ display: "flex", maxWidth: "400px" }}>
                <div style={{ padding: "8px 12px", background: "#f8fafc", border: "1px solid #d0d5dd", borderRight: "none", borderTopLeftRadius: "6px", borderBottomLeftRadius: "6px", color: "#64748b", fontSize: "14px" }}>INR</div>
                <input type="number" step="0.01" name="opening_balance" value={formData.opening_balance} onChange={handleChange} style={{ ...inputStyle, borderTopLeftRadius: 0, borderBottomLeftRadius: 0, flex: 1 }} />
              </div>

              <div style={{ textAlign: "left", fontSize: "14px", color: "#334155" }}>Payment Terms</div>
              <div>
                <select name="payment_terms" value={formData.payment_terms} onChange={handleChange} style={{ ...inputStyle, maxWidth: "400px" }}>
                  <option value="Due on Receipt">Due on Receipt</option>
                  <option value="Net 15">Net 15</option>
                  <option value="Net 30">Net 30</option>
                  <option value="Net 45">Net 45</option>
                  <option value="Net 60">Net 60</option>
                </select>
              </div>

              <div style={{ textAlign: "left", fontSize: "14px", color: "#334155" }}>TDS</div>
              <div>
                <select name="tds" value={formData.tds} onChange={handleChange} style={{ ...inputStyle, maxWidth: "400px", color: formData.tds ? "#111" : "#888" }}>
                  <option value="">Select a Tax</option>
                  <option value="Commission or Brokerage - [2 %]">Commission or Brokerage - [2 %]</option>
                  <option value="Dividend - [10 %]">Dividend - [10 %]</option>
                  <option value="Other Interest than securities - [10 %]">Other Interest than securities - [10 %]</option>
                  <option value="Payment of contractors for Others - [2 %]">Payment of contractors for Others - [2 %]</option>
                  <option value="Payment of contractors HUF/Indiv - [1 %]">Payment of contractors HUF/Indiv - [1 %]</option>
                  <option value="Technical Fees (2%) - [2 %]">Technical Fees (2%) - [2 %]</option>
                </select>
              </div>


            </div>
          )}

          {activeTab === "Address" && (
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "40px" }}>
              {/* Billing Column */}
              <div>
                <h3 style={{ fontSize: "16px", fontWeight: "600", marginBottom: "20px", color: "#1e293b" }}>Billing Address</h3>
                <div style={{ display: "grid", gridTemplateColumns: "120px 1fr", gap: "15px", alignItems: "center" }}>
                  <div style={{ fontSize: "13px", color: "#475569" }}>Attention</div>
                  <div><input type="text" name="billing_attention" value={formData.billing_attention || ""} onChange={handleChange} style={inputStyle} /></div>

                  <div style={{ fontSize: "13px", color: "#475569" }}>Country/Region</div>
                  <div>
                    <select name="billing_country" value={formData.billing_country || ""} onChange={handleChange} style={inputStyle}>
                      <option value="">Select</option>
                      <option value="India">India</option>
                    </select>
                  </div>

                  <div style={{ fontSize: "13px", color: "#475569", alignSelf: "flex-start", marginTop: "8px" }}>Address</div>
                  <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
                    <textarea name="billing_street1" value={formData.billing_street1 || ""} onChange={handleChange} placeholder="Street 1" rows={3} style={{...inputStyle, resize: 'vertical'}}></textarea>
                    <textarea name="billing_street2" value={formData.billing_street2 || ""} onChange={handleChange} placeholder="Street 2" rows={3} style={{...inputStyle, resize: 'vertical'}}></textarea>
                  </div>

                  <div style={{ fontSize: "13px", color: "#475569" }}>City</div>
                  <div><input type="text" name="billing_city" value={formData.billing_city || ""} onChange={handleChange} style={inputStyle} /></div>

                  <div style={{ fontSize: "13px", color: "#475569" }}>State</div>
                  <div>
                    <input type="text" name="billing_state" value={formData.billing_state || ""} onChange={handleChange} placeholder="Select or type to add" style={inputStyle} list="billingStates" />
                    <datalist id="billingStates">
                      <option value="Maharashtra" />
                      <option value="Delhi" />
                      <option value="Karnataka" />
                    </datalist>
                  </div>

                  <div style={{ fontSize: "13px", color: "#475569" }}>Pin Code</div>
                  <div><input type="text" name="billing_pin" value={formData.billing_pin || ""} onChange={handleChange} style={inputStyle} /></div>

                  <div style={{ fontSize: "13px", color: "#475569" }}>Phone</div>
                  <div style={{ display: "flex", gap: "0" }}>
                    <select style={{ ...inputStyle, width: "60px", borderRight: "none", borderTopRightRadius: 0, borderBottomRightRadius: 0, background: "#f8fafc" }}><option>+91</option></select>
                    <input type="text" name="billing_phone" value={formData.billing_phone || ""} onChange={handleChange} style={{ ...inputStyle, flex: 1, borderTopLeftRadius: 0, borderBottomLeftRadius: 0 }} />
                  </div>

                  <div style={{ fontSize: "13px", color: "#475569" }}>Fax Number</div>
                  <div><input type="text" name="billing_fax" value={formData.billing_fax || ""} onChange={handleChange} style={inputStyle} /></div>
                </div>
              </div>

              {/* Shipping Column */}
              <div>
                <h3 style={{ fontSize: "16px", fontWeight: "600", marginBottom: "20px", color: "#1e293b", display: "flex", alignItems: "center", gap: "8px" }}>
                  Shipping Address
                  <span 
                    onClick={() => {
                      setFormData(prev => ({
                        ...prev,
                        shipping_attention: prev.billing_attention,
                        shipping_country: prev.billing_country,
                        shipping_street1: prev.billing_street1,
                        shipping_street2: prev.billing_street2,
                        shipping_city: prev.billing_city,
                        shipping_state: prev.billing_state,
                        shipping_pin: prev.billing_pin,
                        shipping_phone: prev.billing_phone,
                        shipping_fax: prev.billing_fax,
                      }));
                    }} 
                    style={{ fontSize: "13px", color: "#3b82f6", fontWeight: "normal", cursor: "pointer", display: "flex", alignItems: "center", gap: "4px" }}
                  >
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 5v14M19 12l-7 7-7-7"/></svg>
                    Copy billing address
                  </span>
                </h3>
                <div style={{ display: "grid", gridTemplateColumns: "120px 1fr", gap: "15px", alignItems: "center" }}>
                  <div style={{ fontSize: "13px", color: "#475569" }}>Attention</div>
                  <div><input type="text" name="shipping_attention" value={formData.shipping_attention || ""} onChange={handleChange} style={inputStyle} /></div>

                  <div style={{ fontSize: "13px", color: "#475569" }}>Country/Region</div>
                  <div>
                    <select name="shipping_country" value={formData.shipping_country || ""} onChange={handleChange} style={inputStyle}>
                      <option value="">Select</option>
                      <option value="India">India</option>
                    </select>
                  </div>

                  <div style={{ fontSize: "13px", color: "#475569", alignSelf: "flex-start", marginTop: "8px" }}>Address</div>
                  <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
                    <textarea name="shipping_street1" value={formData.shipping_street1 || ""} onChange={handleChange} placeholder="Street 1" rows={3} style={{...inputStyle, resize: 'vertical'}}></textarea>
                    <textarea name="shipping_street2" value={formData.shipping_street2 || ""} onChange={handleChange} placeholder="Street 2" rows={3} style={{...inputStyle, resize: 'vertical'}}></textarea>
                  </div>

                  <div style={{ fontSize: "13px", color: "#475569" }}>City</div>
                  <div><input type="text" name="shipping_city" value={formData.shipping_city || ""} onChange={handleChange} style={inputStyle} /></div>

                  <div style={{ fontSize: "13px", color: "#475569" }}>State</div>
                  <div>
                    <input type="text" name="shipping_state" value={formData.shipping_state || ""} onChange={handleChange} placeholder="Select or type to add" style={inputStyle} list="shippingStates" />
                    <datalist id="shippingStates">
                      <option value="Maharashtra" />
                      <option value="Delhi" />
                      <option value="Karnataka" />
                    </datalist>
                  </div>

                  <div style={{ fontSize: "13px", color: "#475569" }}>Pin Code</div>
                  <div><input type="text" name="shipping_pin" value={formData.shipping_pin || ""} onChange={handleChange} style={inputStyle} /></div>

                  <div style={{ fontSize: "13px", color: "#475569" }}>Phone</div>
                  <div style={{ display: "flex", gap: "0" }}>
                    <select style={{ ...inputStyle, width: "60px", borderRight: "none", borderTopRightRadius: 0, borderBottomRightRadius: 0, background: "#f8fafc" }}><option>+91</option></select>
                    <input type="text" name="shipping_phone" value={formData.shipping_phone || ""} onChange={handleChange} style={{ ...inputStyle, flex: 1, borderTopLeftRadius: 0, borderBottomLeftRadius: 0 }} />
                  </div>

                  <div style={{ fontSize: "13px", color: "#475569" }}>Fax Number</div>
                  <div><input type="text" name="shipping_fax" value={formData.shipping_fax || ""} onChange={handleChange} style={inputStyle} /></div>
                </div>
              </div>
            </div>
          )}

          {activeTab === "Remarks" && (
            <div style={{ display: "grid", gridTemplateColumns: "180px 1fr", gap: "20px 30px" }}>
              <div style={{ textAlign: "left", fontSize: "14px", color: "#334155", alignSelf: "flex-start", marginTop: "10px" }}>Remarks</div>
              <div><textarea name="notes" value={formData.notes} onChange={handleChange} rows={4} placeholder="Any additional notes for the vendor" style={{ ...inputStyle, maxWidth: "400px" }}></textarea></div>
            </div>
          )}

          {/* Contact Persons Tab */}
          {activeTab === "Contact Persons" && (
            <div style={{ marginTop: "20px", width: "100%" }}>
              <table style={{ width: "100%", borderCollapse: "collapse", tableLayout: "fixed" }}>
                <thead>
                  <tr style={{ borderBottom: "1px solid #d0d5dd" }}>
                    <th style={{ padding: "16px 12px", textAlign: "left", fontSize: "11px", fontWeight: "600", color: "#64748b", textTransform: "uppercase", width: "10%" }}>Salutation</th>
                    <th style={{ padding: "16px 12px", textAlign: "left", fontSize: "11px", fontWeight: "600", color: "#64748b", textTransform: "uppercase", width: "20%" }}>First Name</th>
                    <th style={{ padding: "16px 12px", textAlign: "left", fontSize: "11px", fontWeight: "600", color: "#64748b", textTransform: "uppercase", width: "20%" }}>Last Name</th>
                    <th style={{ padding: "16px 12px", textAlign: "left", fontSize: "11px", fontWeight: "600", color: "#64748b", textTransform: "uppercase", width: "20%" }}>Email Address</th>
                    <th style={{ padding: "16px 12px", textAlign: "left", fontSize: "11px", fontWeight: "600", color: "#64748b", textTransform: "uppercase", width: "20%" }}>Work Phone</th>
                    <th style={{ padding: "16px 12px", textAlign: "left", fontSize: "11px", fontWeight: "600", color: "#64748b", textTransform: "uppercase", width: "20%" }}>Mobile</th>
                    <th style={{ padding: "16px 12px", width: "5%" }}></th>
                  </tr>
                </thead>
                <tbody>
                  {(formData.contact_persons || []).map((contact, idx) => (
                    <tr key={idx} style={{ borderBottom: "1px solid #d0d5dd" }}>
                      <td style={{ padding: 0, borderRight: "1px solid #d0d5dd" }}>
                        <select value={contact.salutation} onChange={(e) => handleContactChange(idx, "salutation", e.target.value)} style={{ width: "100%", padding: "14px 12px", border: "none", background: "transparent", outline: "none", fontSize: "14px", color: "#334155", boxSizing: "border-box", cursor: "pointer" }}>
                          <option value=""></option>
                          <option value="Mr.">Mr.</option>
                          <option value="Mrs.">Mrs.</option>
                          <option value="Ms.">Ms.</option>
                          <option value="Miss.">Miss.</option>
                          <option value="Dr.">Dr.</option>
                        </select>
                      </td>
                      <td style={{ padding: 0, borderRight: "1px solid #d0d5dd" }}>
                        <input type="text" value={contact.first_name} onChange={(e) => handleContactChange(idx, "first_name", e.target.value)} style={{ width: "100%", padding: "14px 12px", border: "none", background: "transparent", outline: "none", fontSize: "14px", color: "#334155", boxSizing: "border-box" }} />
                      </td>
                      <td style={{ padding: 0, borderRight: "1px solid #d0d5dd" }}>
                        <input type="text" value={contact.last_name} onChange={(e) => handleContactChange(idx, "last_name", e.target.value)} style={{ width: "100%", padding: "14px 12px", border: "none", background: "transparent", outline: "none", fontSize: "14px", color: "#334155", boxSizing: "border-box" }} />
                      </td>
                      <td style={{ padding: 0, borderRight: "1px solid #d0d5dd" }}>
                        <input type="email" value={contact.email} onChange={(e) => handleContactChange(idx, "email", e.target.value)} style={{ width: "100%", padding: "14px 12px", border: "none", background: "transparent", outline: "none", fontSize: "14px", color: "#334155", boxSizing: "border-box" }} />
                      </td>
                      <td style={{ padding: "8px 12px", borderRight: "1px solid #d0d5dd" }}>
                        <div style={{ display: "flex", alignItems: "center", border: "1px solid #d0d5dd", borderRadius: "4px", overflow: "hidden", boxSizing: "border-box", width: "100%" }}>
                          <select style={{ padding: "10px 6px", border: "none", borderRight: "1px solid #d0d5dd", background: "#f8fafc", outline: "none", fontSize: "13px", color: "#475569", cursor: "pointer" }}><option>+91</option></select>
                          <input type="text" value={contact.work_phone} onChange={(e) => handleContactChange(idx, "work_phone", e.target.value)} style={{ flex: 1, padding: "10px 8px", border: "none", outline: "none", fontSize: "14px", minWidth: "50px", boxSizing: "border-box" }} />
                        </div>
                      </td>
                      <td style={{ padding: "8px 12px" }}>
                        <div style={{ display: "flex", alignItems: "center", border: "1px solid #d0d5dd", borderRadius: "4px", overflow: "hidden", boxSizing: "border-box", width: "100%" }}>
                          <select style={{ padding: "10px 6px", border: "none", borderRight: "1px solid #d0d5dd", background: "#f8fafc", outline: "none", fontSize: "13px", color: "#475569", cursor: "pointer" }}><option>+91</option></select>
                          <input type="text" value={contact.mobile} onChange={(e) => handleContactChange(idx, "mobile", e.target.value)} style={{ flex: 1, padding: "10px 8px", border: "none", outline: "none", fontSize: "14px", minWidth: "50px", boxSizing: "border-box" }} />
                        </div>
                      </td>
                      <td style={{ padding: "10px 12px", textAlign: "center", verticalAlign: "middle" }}>
                        <div style={{ display: "flex", gap: "8px", justifyContent: "center", alignItems: "center", height: "100%" }}>
                          <span onClick={() => removeContactPerson(idx)} style={{ cursor: "pointer", color: "#ef4444", fontSize: "14px", display: "flex", alignItems: "center", justifyContent: "center", width: "18px", height: "18px", borderRadius: "50%", border: "1px solid #fca5a5", background: "#fef2f2" }}>&times;</span>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <div style={{ marginTop: "24px" }}>
                <button type="button" onClick={addContactPerson} style={{ display: "inline-flex", alignItems: "center", gap: "6px", background: "#f1f5f9", color: "#334155", border: "none", padding: "8px 12px", borderRadius: "4px", cursor: "pointer", fontSize: "13px", fontWeight: "500" }}>
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="#3b82f6"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm5 11h-4v4h-2v-4H7v-2h4V7h2v4h4v2z"/></svg>
                  Add Contact Person
                </button>
              </div>
            </div>
          )}

          {/* Placeholders for other tabs */}
          {["Bank Details", "Custom Fields", "Reporting Tags"].includes(activeTab) && (
            <div style={{ padding: "40px", textAlign: "center", color: "#94a3b8", background: "#f8fafc", borderRadius: "8px", maxWidth: "600px", marginTop: "20px" }}>
              This section ({activeTab}) will be implemented in future updates.
            </div>
          )}
        </div>



        {/* Action Buttons */}
        <div style={{ position: "fixed", bottom: 0, left: "240px", right: 0, padding: "15px 30px", background: "#fff", borderTop: "1px solid #e2e8f0", display: "flex", gap: "12px", zIndex: 100, boxShadow: "0 -4px 6px -1px rgba(0, 0, 0, 0.05)" }}>
          <button type="submit" disabled={loading} style={{ padding: "8px 24px", background: "#4a90e2", color: "#fff", border: "none", borderRadius: "4px", cursor: "pointer", fontWeight: "500", fontSize: "14px" }}>
            {loading ? "Saving..." : "Save"}
          </button>
          <button type="button" onClick={() => navigate("/vendors")} style={{ padding: "8px 24px", background: "#f8fafc", color: "#334155", border: "1px solid #d0d5dd", borderRadius: "4px", cursor: "pointer", fontSize: "14px", fontWeight: "500" }}>
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}

const inputStyle = { 
  width: "100%", 
  padding: "8px 12px", 
  borderRadius: "6px", 
  border: "1px solid #d0d5dd", 
  boxSizing: "border-box",
  fontSize: "14px",
  outline: "none",
  transition: "border-color 0.2s"
};

export default AddVendor;
