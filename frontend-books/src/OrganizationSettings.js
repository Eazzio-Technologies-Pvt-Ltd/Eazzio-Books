import React, { useState, useEffect } from "react";
import { apiRequest } from "./api";
import { FormSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";
import { useAuth } from "./AuthContext";

const DEFAULT_SETTINGS = {
  organization_name: "",
  business_type: "",
  gstin: "",
  pan: "",
  address: "",
  city: "",
  state: "",
  country: "India",
  phone: "",
  organization_email: "",
  financial_year_start: "April",
  default_currency: "INR",
  logo_url: ""
};

function OrganizationSettings() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleteConfirmText, setDeleteConfirmText] = useState("");
  
  const [organizations, setOrganizations] = useState([]);
  const [selectedOrgId, setSelectedOrgId] = useState(null);
  const [settings, setSettings] = useState(DEFAULT_SETTINGS);

  useEffect(() => {
    fetchSettings();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const fetchSettings = async () => {
    try {
      const res = await apiRequest("/admin/organizations");
      if (res.organizations && res.organizations.length > 0) {
        setOrganizations(res.organizations);
        const defaultOrg = res.organizations[0];
        setSelectedOrgId(defaultOrg.id);
        setSettings({ ...DEFAULT_SETTINGS, ...defaultOrg });
      }
    } catch (err) {
      toast.error("Failed to load organizations");
    } finally {
      setLoading(false);
    }
  };

  const handleOrgSwitch = (org) => {
    setSelectedOrgId(org.id);
    setSettings({ ...DEFAULT_SETTINGS, ...org });
  };

  const handleLogoUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      if (file.size > 1048576) { // 1MB limit
        toast.error("Logo file size must be less than 1MB");
        return;
      }
      const reader = new FileReader();
      reader.onloadend = () => {
        setSettings({ ...settings, logo_url: reader.result });
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSave = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const res = await apiRequest(`/admin/organizations/${selectedOrgId}`, {
        method: "PUT",
        body: JSON.stringify(settings)
      });
      toast.success("Organization Settings updated successfully!");
      setOrganizations(organizations.map(o => o.id === selectedOrgId ? { ...o, ...res.settings } : o));
    } catch (err) {
      toast.error(err.message || "Failed to update organization settings");
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (deleteConfirmText !== settings.organization_name) {
      toast.error("Organization name does not match.");
      return;
    }
    setDeleting(true);
    try {
      await apiRequest(`/admin/organizations/${selectedOrgId}`, {
        method: "DELETE"
      });
      toast.success("Organization permanently deleted.");
      setTimeout(() => {
        window.location.href = "/";
      }, 1500);
    } catch (err) {
      toast.error(err.message || "Failed to delete organization");
      setDeleting(false);
    }
  };

  if (user?.role !== 'Admin') {
    return (
      <div style={{ padding: "50px", textAlign: "center", color: "#64748b" }}>
        <h2>Access Denied</h2>
        <p>Only the Organization Admin can view and manage organization settings.</p>
      </div>
    );
  }

  return (
    <div style={{ padding: "30px", maxWidth: "900px", margin: "auto" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" }}>
        <h2>Organization Settings</h2>
      </div>

      {loading ? (
        <FormSkeleton fields={6} />
      ) : (
        <>
          {organizations.length > 1 && (
            <div style={{ display: "flex", gap: "10px", overflowX: "auto", paddingBottom: "10px", marginBottom: "20px" }}>
              {organizations.map(org => (
                <div
                  key={org.id}
                  onClick={() => handleOrgSwitch(org)}
                  style={{
                    padding: "12px 20px",
                    background: selectedOrgId === org.id ? "#eff6ff" : "#fff",
                    border: `1px solid ${selectedOrgId === org.id ? "#3b82f6" : "#e2e8f0"}`,
                    borderRadius: "8px",
                    cursor: "pointer",
                    minWidth: "150px",
                    textAlign: "center",
                    fontWeight: selectedOrgId === org.id ? "600" : "400",
                    color: selectedOrgId === org.id ? "#1d4ed8" : "#475569",
                    boxShadow: selectedOrgId === org.id ? "0 2px 4px rgba(59, 130, 246, 0.1)" : "none",
                    transition: "all 0.2s"
                  }}
                >
                  {org.organization_name}
                </div>
              ))}
            </div>
          )}

          <div style={{ background: "#fff", padding: "30px", borderRadius: "8px", boxShadow: "0 1px 3px rgba(0,0,0,0.1)" }}>
            <form onSubmit={handleSave} style={{ display: "flex", flexDirection: "column", gap: "20px" }}>
              
              <h4 style={{ margin: "0 0 10px 0", color: "#475569", borderBottom: "1px solid #e2e8f0", paddingBottom: "10px" }}>General Information</h4>
              
              <div style={{ marginBottom: "20px" }}>
                <label style={labelStyle}>Organization Logo</label>
                <div style={{ display: "flex", alignItems: "center", gap: "15px", marginTop: "10px" }}>
                  {settings.logo_url ? (
                    <img src={settings.logo_url} alt="Logo Preview" style={{ width: "100px", height: "100px", objectFit: "contain", border: "1px solid #e2e8f0", borderRadius: "8px", background: "#f8fafc" }} />
                  ) : (
                    <div style={{ width: "100px", height: "100px", background: "#f1f5f9", border: "1px dashed #cbd5e1", borderRadius: "8px", display: "flex", alignItems: "center", justifyContent: "center", color: "#94a3b8", fontSize: "12px" }}>
                      No Logo
                    </div>
                  )}
                  <div>
                    <input type="file" accept="image/*" onChange={handleLogoUpload} style={{ display: "none" }} id="logo-upload" />
                    <label htmlFor="logo-upload" style={{ cursor: "pointer", background: "#f1f5f9", padding: "8px 16px", borderRadius: "6px", fontSize: "14px", border: "1px solid #cbd5e1", display: "inline-block" }}>
                      Upload Image
                    </label>
                    <div style={{ fontSize: "12px", color: "#64748b", marginTop: "8px" }}>Preferred Size: 240px x 240px @ 72 DPI. Maximum size of 1MB.</div>
                  </div>
                </div>
              </div>
              
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "20px" }}>
                <div>
                  <label style={labelStyle}>Organization Name</label>
                  <input 
                    value={settings.organization_name || ""} 
                    onChange={e => setSettings({...settings, organization_name: e.target.value})} 
                    style={inputStyle} 
                    required 
                  />
                </div>
                <div>
                  <label style={labelStyle}>Business Type</label>
                  <input 
                    value={settings.business_type || ""} 
                    onChange={e => setSettings({...settings, business_type: e.target.value})} 
                    style={inputStyle} 
                  />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "20px" }}>
                <div>
                  <label style={labelStyle}>GSTIN (For automated Tax calculation)</label>
                  <input 
                    value={settings.gstin || ""} 
                    onChange={e => setSettings({...settings, gstin: e.target.value})} 
                    style={inputStyle} 
                  />
                </div>
                <div>
                  <label style={labelStyle}>PAN</label>
                  <input 
                    value={settings.pan || ""} 
                    onChange={e => setSettings({...settings, pan: e.target.value})} 
                    style={inputStyle} 
                  />
                </div>
              </div>

              <h4 style={{ margin: "20px 0 10px 0", color: "#475569", borderBottom: "1px solid #e2e8f0", paddingBottom: "10px" }}>Contact Details</h4>
              
              <div>
                <label style={labelStyle}>Street Address</label>
                <textarea 
                  rows="2"
                  value={settings.address || ""} 
                  onChange={e => setSettings({...settings, address: e.target.value})} 
                  style={inputStyle} 
                />
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "20px" }}>
                <div>
                  <label style={labelStyle}>City</label>
                  <input 
                    value={settings.city || ""} 
                    onChange={e => setSettings({...settings, city: e.target.value})} 
                    style={inputStyle} 
                  />
                </div>
                <div>
                  <label style={labelStyle}>State / Province (Determines CGST/SGST vs IGST)</label>
                  <input 
                    value={settings.state || ""} 
                    onChange={e => setSettings({...settings, state: e.target.value})} 
                    style={inputStyle} 
                    placeholder="e.g. Maharashtra"
                  />
                </div>
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "20px" }}>
                <div>
                  <label style={labelStyle}>Email</label>
                  <input 
                    type="email"
                    value={settings.organization_email || ""} 
                    onChange={e => setSettings({...settings, organization_email: e.target.value})} 
                    style={inputStyle} 
                  />
                </div>
                <div>
                  <label style={labelStyle}>Phone</label>
                  <input 
                    value={settings.phone || ""} 
                    onChange={e => setSettings({...settings, phone: e.target.value})} 
                    style={inputStyle} 
                  />
                </div>
              </div>

              <h4 style={{ margin: "20px 0 10px 0", color: "#475569", borderBottom: "1px solid #e2e8f0", paddingBottom: "10px" }}>Regional Settings</h4>

              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "20px" }}>
                <div>
                  <label style={labelStyle}>Financial Year Start</label>
                  <select value={settings.financial_year_start || "April"} onChange={e => setSettings({...settings, financial_year_start: e.target.value})} style={inputStyle}>
                    <option value="January">January</option>
                    <option value="April">April</option>
                    <option value="July">July</option>
                    <option value="October">October</option>
                  </select>
                </div>
                <div>
                  <label style={labelStyle}>Default Currency</label>
                  <select value={settings.default_currency || "INR"} onChange={e => setSettings({...settings, default_currency: e.target.value})} style={inputStyle}>
                    <option value="INR">INR - Indian Rupee</option>
                    <option value="USD">USD - US Dollar</option>
                    <option value="EUR">EUR - Euro</option>
                    <option value="GBP">GBP - British Pound</option>
                  </select>
                </div>
              </div>

              <div style={{ display: "flex", justifyContent: "flex-end", marginTop: "20px" }}>
                <button type="submit" disabled={saving} style={primaryBtn}>{saving ? "Saving..." : "Save Settings"}</button>
              </div>
            </form>
          </div>

          <div style={{ background: "#fef2f2", border: "1px solid #f87171", padding: "30px", borderRadius: "8px", marginTop: "30px" }}>
            <h4 style={{ margin: "0 0 10px 0", color: "#dc2626" }}>Danger Zone</h4>
            <p style={{ color: "#7f1d1d", fontSize: "14px", marginBottom: "20px" }}>
              Permanently delete this organization and all its data (invoices, customers, payments, etc). This action cannot be undone.
            </p>
            <button 
              onClick={() => setShowDeleteModal(true)} 
              style={{ ...primaryBtn, background: "#dc2626" }}
            >
              Delete Organization
            </button>
          </div>

          {showDeleteModal && (
            <div style={{ position: "fixed", top: 0, left: 0, right: 0, bottom: 0, background: "rgba(0,0,0,0.5)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 9999 }}>
              <div style={{ background: "#fff", padding: "30px", borderRadius: "8px", width: "400px", maxWidth: "90%", boxShadow: "0 20px 25px -5px rgba(0,0,0,0.1)" }}>
                <h3 style={{ marginTop: 0, color: "#1e293b" }}>Delete Organization?</h3>
                <p style={{ fontSize: "14px", color: "#475569", marginBottom: "20px" }}>
                  This will permanently delete <strong>{settings.organization_name}</strong>. All financial data will be lost forever.
                </p>
                <div style={{ marginBottom: "20px" }}>
                  <label style={{ ...labelStyle, fontSize: "13px" }}>Type <strong>{settings.organization_name}</strong> to confirm:</label>
                  <input 
                    type="text" 
                    value={deleteConfirmText}
                    onChange={e => setDeleteConfirmText(e.target.value)}
                    style={inputStyle}
                    placeholder={settings.organization_name}
                  />
                </div>
                <div style={{ display: "flex", justifyContent: "flex-end", gap: "10px" }}>
                  <button onClick={() => { setShowDeleteModal(false); setDeleteConfirmText(""); }} style={{ padding: "8px 16px", border: "1px solid #cbd5e1", background: "#fff", borderRadius: "5px", cursor: "pointer" }}>Cancel</button>
                  <button 
                    onClick={handleDelete} 
                    disabled={deleting || deleteConfirmText !== settings.organization_name} 
                    style={{ ...primaryBtn, background: "#dc2626", opacity: (deleting || deleteConfirmText !== settings.organization_name) ? 0.5 : 1 }}
                  >
                    {deleting ? "Deleting..." : "Permanently Delete"}
                  </button>
                </div>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
}

const labelStyle = { display: "block", marginBottom: "5px", fontWeight: "500", color: "#334155", fontSize: "14px" };
const inputStyle = { width: "100%", padding: "10px", borderRadius: "5px", border: "1px solid #cbd5e1", boxSizing: "border-box" };
const primaryBtn = { padding: "10px 20px", background: "#2563eb", color: "#fff", border: "none", borderRadius: "5px", cursor: "pointer", fontWeight: "500" };

export default OrganizationSettings;
