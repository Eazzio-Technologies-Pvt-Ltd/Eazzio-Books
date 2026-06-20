import React, { useState } from "react";
import { apiRequest } from "../api";
import toast from "react-hot-toast";
import "./CreateOrganizationForm.css";

function CreateOrganizationForm({ onClose }) {
  const [saving, setSaving] = useState(false);
  const [formData, setFormData] = useState({
    name: ""
  });

  const handleSave = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      const res = await apiRequest("/my-organizations", {
        method: "POST",
        body: JSON.stringify(formData)
      });
      if (res && res.message) {
        toast.success(res.message);
        setTimeout(() => window.location.reload(), 1000);
      } else {
        throw new Error("Failed");
      }
    } catch (err) {
      toast.error(err.message || "Failed to create organization");
      setSaving(false);
    }
  };

  return (
    <div className="org-modal-overlay">
      <div className="org-modal-container">
        <div className="org-modal-header">
          <h2>Create New Organization</h2>
          <button className="org-modal-close" onClick={onClose}>×</button>
        </div>
        
        <form onSubmit={handleSave} className="org-modal-body">
          <div className="org-form-group" style={{ marginBottom: '20px' }}>
            <label>Organization Name *</label>
            <input 
              required
              value={formData.name} 
              onChange={e => setFormData({...formData, name: e.target.value})} 
              placeholder="E.g., Acme Corp"
              style={{ width: '100%', padding: '10px', marginTop: '5px', borderRadius: '4px', border: '1px solid #ccc' }}
            />
          </div>

          <div className="org-modal-footer">
            <button type="button" className="btn-cancel" onClick={onClose} disabled={saving}>Cancel</button>
            <button type="submit" className="btn-save" disabled={saving}>{saving ? "Saving..." : "Save and Continue"}</button>
          </div>
        </form>
      </div>
    </div>
  );
}

export default CreateOrganizationForm;
