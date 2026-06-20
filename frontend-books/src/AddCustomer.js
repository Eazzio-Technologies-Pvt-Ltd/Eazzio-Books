/**
 * AddCustomer.js – Zoho Books‑style New / Edit Customer form with tabs
 * Dependencies: apiRequest, react-router-dom, react-hot-toast
 */
import React, { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { apiRequest } from "./api";
import { FormSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";


const customCSS = `
  .add-item-container { background: #fff; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; color: #212529; min-height: calc(100vh - 60px); }
  .add-item-header { padding: 15px 30px; border-bottom: 1px solid #f0f0f0; display: flex; justify-content: space-between; align-items: center; }
  .add-item-header h2 { margin: 0; font-size: 20px; font-weight: 400; }
  .form-section { padding: 30px; display: flex; gap: 60px; }
  .top-left { flex: 1; max-width: 800px; }
  .form-row { display: flex; margin-bottom: 20px; align-items: flex-start; }
  .form-label { width: 200px; font-size: 13px; padding-top: 8px; display: flex; align-items: center; gap: 5px; color: #333; }
  .req-dashed { color: #d32f2f; }
  .form-control { flex: 1; min-width: 0; }
  .input-field { width: 100%; padding: 8px 12px; border: 1px solid #ccc; border-radius: 4px; font-size: 13px; outline: none; box-sizing: border-box; transition: border-color 0.2s; background: #fff; }
  .input-field:focus { border-color: #4a90e2; }
  .form-actions { padding: 20px 30px; border-top: 1px solid #f0f0f0; display: flex; gap: 15px; }
  .btn-save { background: #4a90e2; color: #fff; border: none; padding: 8px 20px; border-radius: 4px; font-size: 13px; cursor: pointer; transition: background 0.2s; }
  .btn-save:hover { background: #357abd; }
  .btn-cancel { background: #fff; color: #333; border: 1px solid #ccc; padding: 8px 20px; border-radius: 4px; font-size: 13px; cursor: pointer; transition: background 0.2s; }
  .btn-cancel:hover { background: #f9f9f9; }
  .tabs-container { border-bottom: 2px solid #e2e8f0; display: flex; margin-bottom: 20px; }
  .tab-btn { padding: 12px 20px; cursor: pointer; background: none; border: none; color: #64748b; border-bottom: 2px solid transparent; font-size: 14px; font-weight: 500; }
  .tab-btn.active { border-bottom-color: #4a90e2; color: #4a90e2; font-weight: 600; }
`;

const inputStyle = {}; // using classes now
const labelStyle = {}; // using classes now


function AddCustomer({ onSaveSuccess, onCancel, isModal }) {
  const navigate = useNavigate();
  const { id } = useParams();          // ✅ edit mode when id exists
  const isEdit = Boolean(id);

  // ---------- Basic fields ----------
    const [isActive, setIsActive] = useState(true);
  const [additionalOpen, setAdditionalOpen] = useState(false);
  const [customerType, setCustomerType] = useState("Business");
  const [customerSubType, setCustomerSubType] = useState("");
  const [salutation, setSalutation] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [companyName, setCompanyName] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [workPhone, setWorkPhone] = useState("");
  const [mobile, setMobile] = useState("");
  const [language, setLanguage] = useState("");

  // ---------- Financial ----------
  const [pan, setPan] = useState("");
  const [currency, setCurrency] = useState("INR");
  const [openingBalance, setOpeningBalance] = useState("0");
  const [paymentTerms, setPaymentTerms] = useState("");
  const [enablePortal, setEnablePortal] = useState(false);
  const [portalLanguage, setPortalLanguage] = useState("en");

  // ---------- Documents ----------
  const [selectedFile, setSelectedFile] = useState(null);

  // ---------- Addresses ----------
  const [billingAddress, setBillingAddress] = useState({
    attention: "", country: "", address_line1: "", address_line2: "",
    city: "", state: "", pin_code: "", phone: "", fax: ""
  });
  const [shippingAddress, setShippingAddress] = useState({
    attention: "", country: "", address_line1: "", address_line2: "",
    city: "", state: "", pin_code: "", phone: "", fax: ""
  });
  const [copyBilling, setCopyBilling] = useState(false);

  // ---------- Contact Persons ----------
  const [contactPersons, setContactPersons] = useState([
    { salutation: "", first_name: "", last_name: "", email: "", work_phone: "", mobile: "" }
  ]);

  // ---------- Other fields ----------
  const [customFields, setCustomFields] = useState("");
  const [reportingTags, setReportingTags] = useState("");
  const [remarks, setRemarks] = useState("");

  // ---------- Customer Owner ----------
  const [users, setUsers] = useState([]);
  const [customerOwnerId, setCustomerOwnerId] = useState("");

  // ---------- Tab state ----------
  const [activeTab, setActiveTab] = useState("Other Details");

  // ---------- Loading / Saving ----------
  const [loading, setLoading] = useState(false);
  const [fetching, setFetching] = useState(false);   // ✅ for edit data fetch

  // ---------- Fetch users list (same for new & edit) ----------
  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const res = await apiRequest("/users");
        if (res) setUsers(res.users);
      } catch (err) { console.error("Failed to load users", err); }
    };
    fetchUsers();
  }, []);

  // ---------- If editing, load existing customer ----------
  useEffect(() => {
    if (!isEdit) return;

    const loadCustomer = async () => {
      setFetching(true);
      try {
        const res = await apiRequest(`/customers/${id}`);
        if (!res?.customer) {
          toast.error("Customer not found");
          navigate("/customers");
          return;
        }

        const c = res.customer;
        // basic fields
        setIsActive(c.is_active ?? true);
        setCustomerType(c.customer_type || "Business");
        setCustomerSubType(c.customer_sub_type || "");
        setSalutation(c.salutation || "");
        setFirstName(c.first_name || "");
        setLastName(c.last_name || "");
        setCompanyName(c.company_name || "");
        setDisplayName(c.display_name || "");
        setEmail(c.email || "");
        setPhone(c.phone || "");
        setWorkPhone(c.work_phone || "");
        setMobile(c.mobile || "");
        setLanguage(c.language || "");

        // financial
        setPan(c.pan || "");
        setCurrency(c.currency || "INR");
        setOpeningBalance(c.opening_balance != null ? String(c.opening_balance) : "0");
        setPaymentTerms(c.payment_terms || "");
        setEnablePortal(!!c.enable_portal);
        setPortalLanguage(c.portal_language || "en");
        setCustomFields(c.custom_fields ? JSON.stringify(c.custom_fields) : "{}");
        setReportingTags(c.reporting_tags || "");
        setRemarks(c.remarks || "");
        setCustomerOwnerId(c.customer_owner_id ? String(c.customer_owner_id) : "");

        // addresses
        const addresses = res.addresses || [];
        const billing = addresses.find(a => a.type === "billing");
        const shipping = addresses.find(a => a.type === "shipping");

        if (billing) setBillingAddress(billing);
        if (shipping) {
          setShippingAddress(shipping);
          // if billing and shipping are identical, we could set copyBilling, but leave as is
        }

        // contacts
        const contacts = res.contacts || [];
        if (contacts.length > 0) {
          setContactPersons(
            contacts.map(ct => ({
              salutation: ct.salutation || "",
              first_name: ct.first_name || "",
              last_name: ct.last_name || "",
              email: ct.email || "",
              work_phone: ct.work_phone || "",
              mobile: ct.mobile || "",
            }))
          );
        }
      } catch (err) {
        toast.error("Failed to load customer data");
      } finally {
        setFetching(false);
      }
    };

    loadCustomer();
  }, [id, isEdit, navigate]);

  // copy billing logic
  const handleCopyBilling = (checked) => {
    setCopyBilling(checked);
    if (checked) setShippingAddress({ ...billingAddress });
  };

  useEffect(() => {
    if (copyBilling) setShippingAddress({ ...billingAddress });
  }, [billingAddress, copyBilling]);

  // contact persons helpers
  const addContactPerson = () => {
    setContactPersons([...contactPersons, { salutation: "", first_name: "", last_name: "", email: "", work_phone: "", mobile: "" }]);
  };
  const removeContactPerson = (index) => {
    setContactPersons(contactPersons.filter((_, i) => i !== index));
  };
  const updateContactPerson = (index, field, value) => {
    const updated = [...contactPersons];
    updated[index][field] = value;
    setContactPersons(updated);
  };

  // ---------- Save ----------
  const handleSave = async () => {
    if (!displayName && !firstName) {
      toast.error("Please enter a display name or first name");
      return;
    }
    setLoading(true);
    try {
      const addresses = [
        { type: "billing", ...billingAddress },
        { type: "shipping", ...shippingAddress },
      ];

      const payload = {
        is_active: isActive,
        customer_type: customerType,
        customer_sub_type: customerSubType || null,
        salutation,
        first_name: firstName,
        last_name: lastName,
        company_name: companyName,
        display_name: displayName || `${firstName} ${lastName}`,
        email,
        phone,
        work_phone: workPhone,
        mobile,
        language,
        pan,
        currency,
        opening_balance: parseFloat(openingBalance) || 0,
        payment_terms: paymentTerms,
        enable_portal: enablePortal,
        portal_language: portalLanguage,
        documents: [], // The backend expects an array, file upload is handled separately if needed
        addresses,
        contacts: contactPersons,
        contact_persons: [],
        custom_fields: customFields ? JSON.parse(customFields) : {},
        reporting_tags: reportingTags,
        remarks,
        customer_owner_id: customerOwnerId ? parseInt(customerOwnerId) : null,
      };

      if (isEdit) {
        const res = await apiRequest(`/customers/${id}`, { method: "PUT", body: JSON.stringify(payload) });
        toast.success("Customer updated");
        if (onSaveSuccess) {
          onSaveSuccess(res?.customer);
          return;
        }
      } else {
        const res = await apiRequest("/customers", { method: "POST", body: JSON.stringify(payload) });
        toast.success("Customer created");
        if (onSaveSuccess) {
          onSaveSuccess(res?.customer);
          return;
        }
      }
      navigate("/customers");
    } catch (err) {
      toast.error(isEdit ? "Failed to update customer" : "Failed to create customer");
    } finally {
      setLoading(false);
    }
  };

  // loading state while fetching existing data
  if (fetching) {
    return (
      <div style={{ maxWidth: "900px", margin: "auto", padding: "30px" }}>
        <FormSkeleton fields={8} />
      </div>
    );
  }

  return (
    <>
      <style>{customCSS}</style>
      <div className="add-item-container">
        {!isModal && (
          <div className="add-item-header">
            <h2>{isEdit ? "Edit Customer" : "New Customer"}</h2>
          </div>
        )}

        <div className="form-section">
          <div className="top-left">
            <div className="form-row">
              <label className="form-label">Customer Type</label>
              <div className="form-control" style={{ display: "flex", gap: "20px" }}>
                <label style={{ display: "flex", alignItems: "center", fontSize: "14px" }}>
                  <input type="radio" name="custType" checked={customerType === "Business"} onChange={() => setCustomerType("Business")} style={{ marginRight: "8px" }} /> Business
                </label>
                <label style={{ display: "flex", alignItems: "center", fontSize: "14px" }}>
                  <input type="radio" name="custType" checked={customerType === "Individual"} onChange={() => setCustomerType("Individual")} style={{ marginRight: "8px" }} /> Individual
                </label>
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Primary Contact</label>
              <div className="form-control" style={{ display: "flex", gap: "10px" }}>
                <select className="input-field" value={salutation} onChange={e => setSalutation(e.target.value)} style={{ width: "100px" }}>
                  <option value="">Salutation</option>
                  <option value="Mr.">Mr.</option>
                  <option value="Mrs.">Mrs.</option>
                  <option value="Ms.">Ms.</option>
                  <option value="Dr.">Dr.</option>
                </select>
                <input className="input-field" placeholder="First Name" value={firstName} onChange={e => setFirstName(e.target.value)} />
                <input className="input-field" placeholder="Last Name" value={lastName} onChange={e => setLastName(e.target.value)} />
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">{customerType === "Individual" ? "Father's Name" : "Company Name"}</label>
              <div className="form-control">
                <input className="input-field" value={companyName} onChange={e => setCompanyName(e.target.value)} />
              </div>
            </div>

            <div className="form-row">
              <label className="form-label"><span className="req-dashed">Display Name *</span></label>
              <div className="form-control">
                <input className="input-field" list="display-name-list" value={displayName} onChange={e => setDisplayName(e.target.value)} placeholder="Select or type to add" />
                <datalist id="display-name-list">
                  {firstName && lastName ? <option value={`${firstName} ${lastName}`} /> : null}
                  {companyName ? <option value={companyName} /> : null}
                </datalist>
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Email Address</label>
              <div className="form-control">
                <input type="email" className="input-field" value={email} onChange={e => setEmail(e.target.value)} />
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Phone</label>
              <div className="form-control" style={{ display: "flex", gap: "10px" }}>
                <input className="input-field" placeholder="Work Phone" value={phone} onChange={e => setPhone(e.target.value)} />
                <input className="input-field" placeholder="Mobile" value={mobile} onChange={e => setMobile(e.target.value)} />
              </div>
            </div>

            <div className="form-row">
              <label className="form-label">Status</label>
              <div className="form-control" style={{ display: "flex", gap: "20px" }}>
                <label style={{ display: "flex", alignItems: "center", fontSize: "14px" }}>
                  <input type="radio" checked={isActive} onChange={() => setIsActive(true)} style={{ marginRight: "8px" }} /> Active
                </label>
                <label style={{ display: "flex", alignItems: "center", fontSize: "14px" }}>
                  <input type="radio" checked={!isActive} onChange={() => setIsActive(false)} style={{ marginRight: "8px" }} /> Inactive
                </label>
              </div>
            </div>

            {/* Collapsible Additional Details */}
            <div className="form-row">
              <label className="form-label"></label>
              <div className="form-control">
                <button type="button" onClick={() => setAdditionalOpen(!additionalOpen)} style={{ background: 'none', border: 'none', color: '#4a90e2', cursor: 'pointer', fontWeight: '500', padding: 0 }}>
                  {additionalOpen ? '▼' : '▶'} Additional Details
                </button>
                {additionalOpen && (
                  <div style={{ marginTop: '15px', display: 'flex', flexDirection: 'column', gap: '15px' }}>
                    <div style={{ display: "flex", gap: "10px" }}>
                      <input className="input-field" placeholder="Language" value={language} onChange={e => setLanguage(e.target.value)} />
                      <select className="input-field" value={customerSubType} onChange={e => setCustomerSubType(e.target.value)}>
                        <option value="">Customer Sub‑Type</option>
                        <option value="Business">Business</option>
                        <option value="Individual">Individual</option>
                      </select>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* ======================== TABS ======================== */}
            <div className="tabs-container">
              {["Other Details", "Address", "Contact Persons", "Custom Fields", "Reporting Tags", "Remarks"].map((tab) => (
                <button key={tab} onClick={() => setActiveTab(tab)} className={`tab-btn ${activeTab === tab ? "active" : ""}`}>
                  {tab}
                </button>
              ))}
            </div>

            {/* ===== TAB: ADDRESS ===== */}
            {activeTab === "Address" && (
              <div>
                <h4 style={{ marginBottom: "15px", color: "#333" }}>Billing Address</h4>
                {addressFields(billingAddress, setBillingAddress)}
                <h4 style={{ marginTop: "30px", marginBottom: "15px", color: "#333" }}>Shipping Address</h4>
                <label style={{ fontSize: "13px", display: "flex", alignItems: "center", marginBottom: "15px", color: "#4a90e2", cursor: "pointer" }}>
                  <input type="checkbox" checked={copyBilling} onChange={e => handleCopyBilling(e.target.checked)} style={{ marginRight: "8px" }} />
                  ↓ Copy billing address
                </label>
                <div>
                  {addressFields(shippingAddress, copyBilling ? () => {} : setShippingAddress, copyBilling)}
                </div>
              </div>
            )}

            {/* ===== TAB: CONTACT PERSONS ===== */}
            {activeTab === "Contact Persons" && (
              <div>
                {contactPersons.map((person, idx) => (
                  <div key={idx} style={{ borderBottom: `1px solid #e2e8f0`, paddingBottom: "20px", marginBottom: "20px" }}>
                    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "15px" }}>
                      <h4 style={{ margin: 0, color: "#333" }}>Contact Person {idx + 1}</h4>
                      {contactPersons.length > 1 && (
                        <button type="button" onClick={() => removeContactPerson(idx)} style={{ background: "none", color: "#ef4444", border: "none", cursor: "pointer", fontSize: "13px" }}>Remove</button>
                      )}
                    </div>
                    <div className="form-row">
                      <label className="form-label">Name</label>
                      <div className="form-control" style={{ display: "flex", gap: "10px" }}>
                        <select className="input-field" value={person.salutation} onChange={e => updateContactPerson(idx, 'salutation', e.target.value)} style={{ width: "100px" }}>
                          <option value="">Salutation</option>
                          <option value="Mr.">Mr.</option>
                          <option value="Mrs.">Mrs.</option>
                          <option value="Ms.">Ms.</option>
                        </select>
                        <input className="input-field" placeholder="First Name" value={person.first_name} onChange={e => updateContactPerson(idx, 'first_name', e.target.value)} />
                        <input className="input-field" placeholder="Last Name" value={person.last_name} onChange={e => updateContactPerson(idx, 'last_name', e.target.value)} />
                      </div>
                    </div>
                    <div className="form-row">
                      <label className="form-label">Email</label>
                      <div className="form-control">
                        <input className="input-field" value={person.email} onChange={e => updateContactPerson(idx, 'email', e.target.value)} />
                      </div>
                    </div>
                    <div className="form-row">
                      <label className="form-label">Phone</label>
                      <div className="form-control" style={{ display: "flex", gap: "10px" }}>
                        <input className="input-field" placeholder="Work Phone" value={person.work_phone} onChange={e => updateContactPerson(idx, 'work_phone', e.target.value)} />
                        <input className="input-field" placeholder="Mobile" value={person.mobile} onChange={e => updateContactPerson(idx, 'mobile', e.target.value)} />
                      </div>
                    </div>
                  </div>
                ))}
                <button type="button" onClick={addContactPerson} style={{ background: "none", color: "#4a90e2", border: "none", cursor: "pointer", fontSize: "13px", fontWeight: "500", padding: 0 }}>
                  + Add Another Contact
                </button>
              </div>
            )}

            {/* ===== TAB: OTHER DETAILS ===== */}
            {activeTab === "Other Details" && (
              <div>
                <div className="form-row">
                  <label className="form-label">PAN</label>
                  <div className="form-control">
                    <input className="input-field" value={pan} onChange={e => setPan(e.target.value)} />
                  </div>
                </div>
                <div className="form-row">
                  <label className="form-label">Currency</label>
                  <div className="form-control">
                    <input className="input-field" value={currency} onChange={e => setCurrency(e.target.value)} />
                  </div>
                </div>
                <div className="form-row">
                  <label className="form-label">Opening Balance</label>
                  <div className="form-control">
                    <input type="number" className="input-field" value={openingBalance} onChange={e => setOpeningBalance(e.target.value)} />
                  </div>
                </div>
                <div className="form-row">
                  <label className="form-label">Payment Terms</label>
                  <div className="form-control">
                    <select className="input-field" value={paymentTerms} onChange={e => setPaymentTerms(e.target.value)}>
                      <option value="">Select Payment Terms</option>
                      <option value="Due end of next month">Due end of next month</option>
                      <option value="Due end of the month">Due end of the month</option>
                      <option value="Due on Receipt">Due on Receipt</option>
                      <option value="Net 15">Net 15</option>
                      <option value="Net 30">Net 30</option>
                      <option value="Net 45">Net 45</option>
                      <option value="Net 60">Net 60</option>
                    </select>
                  </div>
                </div>
                <div className="form-row">
                  <label className="form-label"></label>
                  <div className="form-control">
                    <label style={{ fontSize: "13px", display: "flex", alignItems: "center" }}>
                      <input type="checkbox" checked={enablePortal} onChange={e => setEnablePortal(e.target.checked)} style={{ marginRight: "8px" }} />
                      Allow portal access for this customer
                    </label>
                  </div>
                </div>
                {enablePortal && (
                  <div className="form-row">
                    <label className="form-label">Portal Language</label>
                    <div className="form-control">
                      <input className="input-field" value={portalLanguage} onChange={e => setPortalLanguage(e.target.value)} />
                    </div>
                  </div>
                )}
                
                <div className="form-row">
                  <label className="form-label">Documents</label>
                  <div className="form-control">
                    <div 
                      style={{ border: "1px dashed #ccc", borderRadius: "6px", padding: "25px", textAlign: "center", background: "#fafafa", cursor: "pointer", transition: "background 0.2s" }}
                      onClick={() => document.getElementById('customer-file-upload').click()}
                      onMouseEnter={(e) => e.currentTarget.style.background = "#f0f8ff"}
                      onMouseLeave={(e) => e.currentTarget.style.background = "#fafafa"}
                    >
                      <span style={{ fontSize: "24px", color: "#888", display: "block", marginBottom: "8px" }}>📁</span>
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
                          <span style={{ fontSize: "12px", color: "#888" }}>Maximum file size 5MB</span>
                        </>
                      )}
                      <input 
                        type="file" 
                        style={{ display: "none" }} 
                        id="customer-file-upload" 
                        onChange={(e) => setSelectedFile(e.target.files[0])}
                      />
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* ===== TAB: CUSTOM FIELDS ===== */}
            {activeTab === "Custom Fields" && (
              <div>
                <div className="form-row">
                  <label className="form-label">Custom Fields (JSON)</label>
                  <div className="form-control">
                    <textarea className="input-field" value={customFields} onChange={e => setCustomFields(e.target.value)} rows="3" />
                  </div>
                </div>
              </div>
            )}

            {/* ===== TAB: REPORTING TAGS ===== */}
            {activeTab === "Reporting Tags" && (
              <div>
                <div className="form-row">
                  <label className="form-label">Reporting Tags</label>
                  <div className="form-control">
                    <input className="input-field" value={reportingTags} onChange={e => setReportingTags(e.target.value)} />
                  </div>
                </div>
              </div>
            )}

            {/* ===== TAB: REMARKS ===== */}
            {activeTab === "Remarks" && (
              <div>
                <div className="form-row" style={{ display: "block" }}>
                  <label className="form-label" style={{ width: "100%", marginBottom: "10px" }}>Remarks <span style={{ color: "#888", fontWeight: "normal" }}>(For Internal Use)</span></label>
                  <div className="form-control">
                    <textarea className="input-field" value={remarks} onChange={e => setRemarks(e.target.value)} rows="5" />
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Action Buttons */}
        <div className="form-actions">
          <button type="button" className="btn-save" onClick={handleSave} disabled={loading}>
            {loading ? "Saving..." : isEdit ? "Update" : "Save"}
          </button>
          <button type="button" className="btn-cancel" onClick={() => onCancel ? onCancel() : navigate("/customers")}>
            Cancel
          </button>
        </div>

      </div>
    </>
  );
}

const addressFields = (address, setAddress, disabled = false) => (
  <>
    <div className="form-row">
      <label className="form-label">Attention</label>
      <div className="form-control">
        <input className="input-field" value={address.attention} onChange={e => setAddress({ ...address, attention: e.target.value })} disabled={disabled} />
      </div>
    </div>
    <div className="form-row">
      <label className="form-label">Country/Region</label>
      <div className="form-control">
        <input className="input-field" value={address.country} onChange={e => setAddress({ ...address, country: e.target.value })} disabled={disabled} />
      </div>
    </div>
    <div className="form-row">
      <label className="form-label">Address</label>
      <div className="form-control">
        <input className="input-field" value={address.address_line1} onChange={e => setAddress({ ...address, address_line1: e.target.value })} disabled={disabled} placeholder="Street 1" style={{ marginBottom: "10px" }} />
        <input className="input-field" value={address.address_line2} onChange={e => setAddress({ ...address, address_line2: e.target.value })} disabled={disabled} placeholder="Street 2" />
      </div>
    </div>
    <div className="form-row">
      <label className="form-label">City / State</label>
      <div className="form-control" style={{ display: "flex", gap: "10px" }}>
        <input className="input-field" value={address.city} onChange={e => setAddress({ ...address, city: e.target.value })} disabled={disabled} placeholder="City" />
        <input className="input-field" value={address.state} onChange={e => setAddress({ ...address, state: e.target.value })} disabled={disabled} placeholder="State" />
        <input className="input-field" value={address.pin_code} onChange={e => setAddress({ ...address, pin_code: e.target.value })} disabled={disabled} placeholder="Pin Code" />
      </div>
    </div>
    <div className="form-row">
      <label className="form-label">Phone / Fax</label>
      <div className="form-control" style={{ display: "flex", gap: "10px" }}>
        <input className="input-field" value={address.phone} onChange={e => setAddress({ ...address, phone: e.target.value })} disabled={disabled} placeholder="Phone" />
        <input className="input-field" value={address.fax} onChange={e => setAddress({ ...address, fax: e.target.value })} disabled={disabled} placeholder="Fax" />
      </div>
    </div>
  </>
);

export default AddCustomer;
