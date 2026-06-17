import React, { useState, useEffect, useCallback } from "react";
import { apiRequest } from "./api";
import toast from "react-hot-toast";
import { useAuth } from "./AuthContext";
import { Navigate } from "react-router-dom";

// ─── Helpers ─────────────────────────────────────────────────────────────────
const DEFAULT_FORM = { company_name: "", admin_email: "", admin_password: "" };

const fmtDate = (d) =>
  new Date(d).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" });

// ─── Main Component ───────────────────────────────────────────────────────────
export default function SuperAdminDashboard() {
  const { user } = useAuth();

  // Hard-guard: only Super Admin can reach this page at all
  if (user && user.role !== "Super Admin") {
    return <Navigate to="/access-denied" replace />;
  }

  return <OrganizationsPanel />;
}

function OrganizationsPanel() {
  const [orgs, setOrgs]           = useState([]);
  const [loading, setLoading]     = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [form, setForm]           = useState(DEFAULT_FORM);
  const [submitting, setSubmitting] = useState(false);
  const [toggling, setToggling]   = useState(null); // id of org being toggled
  const [search, setSearch]       = useState("");

  // ─── Fetch all organizations ───────────────────────────────────────────────
  const fetchOrgs = useCallback(async () => {
    setLoading(true);
    try {
      const res = await apiRequest("/organizations");
      setOrgs(res?.organizations || []);
    } catch (err) {
      toast.error("Failed to load organizations");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchOrgs(); }, [fetchOrgs]);

  // ─── Onboard new client ────────────────────────────────────────────────────
  const handleOnboard = async (e) => {
    e.preventDefault();
    if (!form.company_name.trim() || !form.admin_email.trim() || !form.admin_password) {
      toast.error("All fields are required");
      return;
    }
    if (form.admin_password.length < 6) {
      toast.error("Password must be at least 6 characters");
      return;
    }
    setSubmitting(true);
    try {
      const res = await apiRequest("/organizations", {
        method: "POST",
        body: JSON.stringify({
          company_name: form.company_name.trim(),
          admin_email: form.admin_email.trim(),
          admin_password: form.admin_password,
        }),
      });
      toast.success(res.message || "Client onboarded!");
      setForm(DEFAULT_FORM);
      setShowModal(false);
      fetchOrgs();
    } catch (err) {
      toast.error(err.message || "Failed to onboard client");
    } finally {
      setSubmitting(false);
    }
  };

  // ─── Toggle active/inactive ────────────────────────────────────────────────
  const handleToggle = async (org) => {
    setToggling(org.id);
    try {
      const res = await apiRequest(`/organizations/${org.id}/toggle-status`, { method: "PATCH" });
      toast.success(res.message);
      fetchOrgs();
    } catch (err) {
      toast.error(err.message || "Failed to update status");
    } finally {
      setToggling(null);
    }
  };

  // ─── Filtered list ─────────────────────────────────────────────────────────
  const filtered = orgs.filter(
    (o) =>
      o.name?.toLowerCase().includes(search.toLowerCase()) ||
      o.admin_email?.toLowerCase().includes(search.toLowerCase())
  );

  const activeCount   = orgs.filter((o) => o.is_active).length;
  const inactiveCount = orgs.filter((o) => !o.is_active).length;
  const totalMembers  = orgs.reduce((s, o) => s + parseInt(o.member_count || 0), 0);

  return (
    <div style={{ padding: "30px", maxWidth: "1300px", margin: "auto", fontFamily: "inherit" }}>

      {/* ── Header ── */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "28px" }}>
        <div>
          <div style={{ display: "flex", alignItems: "center", gap: "10px", marginBottom: "6px" }}>
            <span style={{
              padding: "3px 10px", background: "#fdf2ff", color: "#7e22ce",
              border: "1px solid #e9d5ff", borderRadius: "20px", fontSize: "12px", fontWeight: "700",
            }}>
              ⚡ SUPER ADMIN
            </span>
          </div>
          <h2 style={{ margin: 0, fontSize: "24px", fontWeight: "800", color: "#0f172a" }}>
            Organizations Control Center
          </h2>
          <p style={{ margin: "6px 0 0", color: "#64748b", fontSize: "14px" }}>
            Onboard and manage all client organizations from one place.
          </p>
        </div>
        <button
          id="onboard-client-btn"
          style={styles.primaryBtn}
          onClick={() => setShowModal(true)}
        >
          + Onboard New Client
        </button>
      </div>

      {/* ── Stats cards ── */}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))", gap: "16px", marginBottom: "24px" }}>
        {[
          { label: "Total Organizations", value: orgs.length, icon: "🏢", color: "#eff6ff", border: "#bfdbfe", text: "#1d4ed8" },
          { label: "Active",              value: activeCount,  icon: "✅", color: "#f0fdf4", border: "#bbf7d0", text: "#15803d" },
          { label: "Inactive",            value: inactiveCount, icon: "⏸️", color: "#fff7ed", border: "#fed7aa", text: "#c2410c" },
          { label: "Total Users",         value: totalMembers, icon: "👥", color: "#fdf4ff", border: "#e9d5ff", text: "#7e22ce" },
        ].map(({ label, value, icon, color, border, text }) => (
          <div key={label} style={{ ...styles.statCard, background: color, border: `1px solid ${border}` }}>
            <div style={{ fontSize: "22px", marginBottom: "6px" }}>{icon}</div>
            <div style={{ fontSize: "28px", fontWeight: "800", color: text }}>{value}</div>
            <div style={{ fontSize: "12px", color: "#64748b", fontWeight: "500", marginTop: "2px" }}>{label}</div>
          </div>
        ))}
      </div>

      {/* ── Search bar ── */}
      <div style={{ marginBottom: "16px" }}>
        <input
          id="org-search"
          type="text"
          placeholder="🔍  Search by company name or admin email..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          style={styles.searchInput}
        />
      </div>

      {/* ── Table ── */}
      <div style={styles.card}>
        {loading ? (
          <div style={{ padding: "60px", textAlign: "center", color: "#94a3b8" }}>
            <div style={{ fontSize: "32px", marginBottom: "12px" }}>⏳</div>
            Loading organizations...
          </div>
        ) : filtered.length === 0 ? (
          <div style={{ padding: "60px", textAlign: "center" }}>
            <div style={{ fontSize: "40px", marginBottom: "12px" }}>🏢</div>
            <p style={{ color: "#64748b", fontSize: "15px", margin: 0 }}>
              {search ? "No organizations match your search." : "No organizations yet. Onboard your first client!"}
            </p>
          </div>
        ) : (
          <table style={styles.table}>
            <thead>
              <tr style={styles.thead}>
                <th style={styles.th}>#</th>
                <th style={styles.th}>Organization</th>
                <th style={styles.th}>Admin Email</th>
                <th style={styles.th}>Members</th>
                <th style={styles.th}>Status</th>
                <th style={styles.th}>Onboarded</th>
                <th style={{ ...styles.th, textAlign: "right" }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map((org, idx) => (
                <tr key={org.id} style={{
                  ...styles.tr,
                  background: idx % 2 === 0 ? "#ffffff" : "#f8fafc",
                  opacity: org.is_active ? 1 : 0.65,
                }}>
                  <td style={{ ...styles.td, color: "#94a3b8", fontWeight: "600", fontSize: "13px", width: "40px" }}>
                    {idx + 1}
                  </td>
                  <td style={styles.td}>
                    <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                      <div style={{
                        width: "36px", height: "36px", borderRadius: "8px", flexShrink: 0,
                        background: "linear-gradient(135deg, #7c3aed, #2563eb)",
                        display: "flex", alignItems: "center", justifyContent: "center",
                        color: "#fff", fontWeight: "800", fontSize: "14px",
                      }}>
                        {(org.name || "?")[0].toUpperCase()}
                      </div>
                      <div>
                        <div style={{ fontWeight: "700", color: "#0f172a", fontSize: "14px" }}>{org.name}</div>
                        <div style={{ fontSize: "11px", color: "#94a3b8" }}>ID: {org.id}</div>
                      </div>
                    </div>
                  </td>
                  <td style={{ ...styles.td, color: "#475569" }}>{org.admin_email || "—"}</td>
                  <td style={styles.td}>
                    <span style={{
                      padding: "3px 10px", background: "#f1f5f9", color: "#334155",
                      borderRadius: "20px", fontSize: "12px", fontWeight: "600",
                    }}>
                      👤 {org.member_count}
                    </span>
                  </td>
                  <td style={styles.td}>
                    <span style={{
                      padding: "3px 10px",
                      background: org.is_active ? "#dcfce7" : "#fee2e2",
                      color: org.is_active ? "#166534" : "#991b1b",
                      border: `1px solid ${org.is_active ? "#bbf7d0" : "#fecaca"}`,
                      borderRadius: "20px", fontSize: "12px", fontWeight: "600",
                    }}>
                      {org.is_active ? "● Active" : "● Inactive"}
                    </span>
                  </td>
                  <td style={{ ...styles.td, color: "#64748b", fontSize: "13px" }}>{fmtDate(org.created_at)}</td>
                  <td style={{ ...styles.td, textAlign: "right" }}>
                    <button
                      id={`toggle-org-${org.id}`}
                      onClick={() => handleToggle(org)}
                      disabled={toggling === org.id}
                      style={{
                        ...styles.outlineBtn,
                        ...(org.is_active ? styles.deactivateBtn : styles.activateBtn),
                        opacity: toggling === org.id ? 0.6 : 1,
                      }}
                    >
                      {toggling === org.id ? "..." : org.is_active ? "Deactivate" : "Activate"}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* ─────────────────── ONBOARD MODAL ─────────────────── */}
      {showModal && (
        <div style={styles.overlay} onClick={() => { setShowModal(false); setForm(DEFAULT_FORM); }}>
          <div style={styles.modal} onClick={(e) => e.stopPropagation()}>

            {/* Modal header */}
            <div style={styles.modalHeader}>
              <div>
                <h3 style={{ margin: 0, fontSize: "20px", fontWeight: "800", color: "#0f172a" }}>
                  🏢 Onboard New Client
                </h3>
                <p style={{ margin: "6px 0 0", fontSize: "13px", color: "#64748b" }}>
                  Creates the organization and its Admin account in one atomic transaction.
                </p>
              </div>
              <button
                id="close-onboard-modal-btn"
                onClick={() => { setShowModal(false); setForm(DEFAULT_FORM); }}
                style={styles.closeBtn}
              >
                ✕
              </button>
            </div>

            {/* Atomic transaction notice */}
            <div style={styles.atomicNote}>
              <span style={{ fontSize: "14px" }}>⚡</span>
              <span style={{ fontSize: "13px", color: "#1d4ed8" }}>
                <strong>Atomic:</strong> Both the organization and Admin account are created in a single database transaction. If anything fails, both are rolled back automatically.
              </span>
            </div>

            {/* Form */}
            <form onSubmit={handleOnboard} style={{ display: "flex", flexDirection: "column", gap: "16px" }}>

              <div>
                <label style={styles.label} htmlFor="org-company-name">
                  Company Name <span style={{ color: "#ef4444" }}>*</span>
                </label>
                <input
                  id="org-company-name"
                  type="text"
                  placeholder="e.g. Acme Corp Pvt. Ltd."
                  value={form.company_name}
                  onChange={(e) => setForm({ ...form, company_name: e.target.value })}
                  style={styles.input}
                  required
                  autoFocus
                />
              </div>

              <div style={{ borderTop: "1px dashed #e2e8f0", paddingTop: "16px" }}>
                <p style={{ margin: "0 0 12px", fontSize: "13px", fontWeight: "600", color: "#475569" }}>
                  Admin Account Credentials
                </p>

                <div style={{ display: "flex", flexDirection: "column", gap: "14px" }}>
                  <div>
                    <label style={styles.label} htmlFor="org-admin-email">
                      Admin Email <span style={{ color: "#ef4444" }}>*</span>
                    </label>
                    <input
                      id="org-admin-email"
                      type="email"
                      placeholder="admin@clientcompany.com"
                      value={form.admin_email}
                      onChange={(e) => setForm({ ...form, admin_email: e.target.value })}
                      style={styles.input}
                      required
                    />
                  </div>

                  <div>
                    <label style={styles.label} htmlFor="org-admin-password">
                      Admin Password <span style={{ color: "#ef4444" }}>*</span>
                    </label>
                    <input
                      id="org-admin-password"
                      type="password"
                      placeholder="Minimum 6 characters"
                      value={form.admin_password}
                      onChange={(e) => setForm({ ...form, admin_password: e.target.value })}
                      style={styles.input}
                      required
                      minLength={6}
                    />
                    <p style={{ margin: "5px 0 0", fontSize: "12px", color: "#94a3b8" }}>
                      Share these credentials securely with your client. Advise them to change the password on first login.
                    </p>
                  </div>
                </div>
              </div>

              <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end", marginTop: "4px" }}>
                <button
                  type="button"
                  id="cancel-onboard-btn"
                  onClick={() => { setShowModal(false); setForm(DEFAULT_FORM); }}
                  style={styles.secondaryBtn}
                  disabled={submitting}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  id="submit-onboard-btn"
                  style={{ ...styles.primaryBtn, opacity: submitting ? 0.7 : 1 }}
                  disabled={submitting}
                >
                  {submitting ? "Creating..." : "🚀 Onboard Client"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Styles ──────────────────────────────────────────────────────────────────
const styles = {
  primaryBtn: {
    padding: "10px 20px",
    background: "linear-gradient(135deg, #7c3aed, #2563eb)",
    color: "#fff",
    border: "none",
    borderRadius: "7px",
    cursor: "pointer",
    fontWeight: "700",
    fontSize: "14px",
    boxShadow: "0 2px 8px rgba(124,58,237,0.3)",
    whiteSpace: "nowrap",
  },
  secondaryBtn: {
    padding: "10px 20px",
    background: "#f1f5f9",
    color: "#475569",
    border: "1px solid #e2e8f0",
    borderRadius: "7px",
    cursor: "pointer",
    fontWeight: "600",
    fontSize: "14px",
  },
  outlineBtn: {
    padding: "6px 14px",
    borderRadius: "6px",
    cursor: "pointer",
    fontSize: "13px",
    fontWeight: "600",
    border: "1px solid",
  },
  deactivateBtn: {
    background: "#fff1f2",
    color: "#dc2626",
    borderColor: "#fecaca",
  },
  activateBtn: {
    background: "#f0fdf4",
    color: "#16a34a",
    borderColor: "#bbf7d0",
  },
  statCard: {
    padding: "18px 20px",
    borderRadius: "10px",
    boxShadow: "0 1px 4px rgba(0,0,0,0.05)",
  },
  searchInput: {
    width: "100%",
    padding: "10px 14px",
    borderRadius: "8px",
    border: "1px solid #e2e8f0",
    fontSize: "14px",
    background: "#f8fafc",
    boxSizing: "border-box",
    outline: "none",
    color: "#1e293b",
  },
  card: {
    background: "#fff",
    borderRadius: "10px",
    border: "1px solid #e2e8f0",
    boxShadow: "0 1px 4px rgba(0,0,0,0.06)",
    overflow: "hidden",
  },
  table: {
    width: "100%",
    borderCollapse: "collapse",
    fontSize: "14px",
  },
  thead: {
    background: "#f8fafc",
    borderBottom: "2px solid #e2e8f0",
    textAlign: "left",
  },
  th: {
    padding: "12px 16px",
    color: "#475569",
    fontWeight: "600",
    fontSize: "12px",
    textTransform: "uppercase",
    letterSpacing: "0.5px",
  },
  tr: {
    borderBottom: "1px solid #f1f5f9",
  },
  td: {
    padding: "14px 16px",
    color: "#334155",
    verticalAlign: "middle",
  },
  overlay: {
    position: "fixed",
    inset: 0,
    background: "rgba(15,23,42,0.55)",
    backdropFilter: "blur(4px)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    zIndex: 1000,
  },
  modal: {
    background: "#fff",
    borderRadius: "14px",
    padding: "30px",
    width: "100%",
    maxWidth: "500px",
    boxShadow: "0 24px 64px rgba(0,0,0,0.22)",
  },
  modalHeader: {
    display: "flex",
    justifyContent: "space-between",
    alignItems: "flex-start",
    marginBottom: "16px",
  },
  closeBtn: {
    background: "none",
    border: "none",
    fontSize: "18px",
    cursor: "pointer",
    color: "#94a3b8",
    padding: "4px 8px",
    borderRadius: "4px",
  },
  atomicNote: {
    display: "flex",
    alignItems: "flex-start",
    gap: "8px",
    padding: "10px 14px",
    background: "#eff6ff",
    border: "1px solid #bfdbfe",
    borderRadius: "8px",
    marginBottom: "20px",
  },
  label: {
    display: "block",
    marginBottom: "6px",
    fontSize: "13px",
    fontWeight: "600",
    color: "#374151",
  },
  input: {
    width: "100%",
    padding: "10px 12px",
    borderRadius: "7px",
    border: "1px solid #d1d5db",
    fontSize: "14px",
    color: "#1e293b",
    background: "#fff",
    boxSizing: "border-box",
    outline: "none",
  },
};
