import React, { useState, useEffect, useCallback } from "react";
import { apiRequest } from "./api";
import { TableSkeleton } from "./components/skeletons";
import toast from "react-hot-toast";
import { useAuth } from "./AuthContext";
import { canAccess, MODULES, ACTIONS } from "./utils/permissions";

// ─── Role badge colors ───────────────────────────────────────────────────────
const ROLE_COLORS = {
  "Super Admin": { bg: "#fdf2ff", color: "#7e22ce", border: "#e9d5ff" },
  "Admin":       { bg: "#eff6ff", color: "#1d4ed8", border: "#bfdbfe" },
  "Accountant":  { bg: "#f0fdf4", color: "#15803d", border: "#bbf7d0" },
  "Staff":       { bg: "#fff7ed", color: "#c2410c", border: "#fed7aa" },
  "Viewer":      { bg: "#f8fafc", color: "#475569", border: "#e2e8f0" },
};

const getRoleBadge = (role) => {
  const style = ROLE_COLORS[role] || ROLE_COLORS["Viewer"];
  return (
    <span style={{
      padding: "3px 10px",
      background: style.bg,
      color: style.color,
      border: `1px solid ${style.border}`,
      borderRadius: "20px",
      fontSize: "12px",
      fontWeight: "600",
      letterSpacing: "0.3px",
    }}>
      {role || "—"}
    </span>
  );
};

// ─── Default form state ──────────────────────────────────────────────────────
const DEFAULT_FORM = { email: "", password: "", role: "Staff" };

// ─── Main Component ──────────────────────────────────────────────────────────
function UsersRoles() {
  const { user } = useAuth();
  const [users, setUsers]         = useState([]);
  const [loading, setLoading]     = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [form, setForm]           = useState(DEFAULT_FORM);
  const [submitting, setSubmitting] = useState(false);
  const [deleteId, setDeleteId]   = useState(null);
  const [confirmDelete, setConfirmDelete] = useState(false);

  const isAdmin = user?.role === "Admin" || user?.role === "Super Admin";

  // ─── Fetch team members ────────────────────────────────────────────────────
  const fetchUsers = useCallback(async () => {
    try {
      const res = await apiRequest("/users");
      setUsers(res?.users || []);
    } catch (err) {
      toast.error("Failed to load team members");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchUsers(); }, [fetchUsers]);

  // ─── Create staff account ──────────────────────────────────────────────────
  const handleCreate = async (e) => {
    e.preventDefault();
    if (!form.email.trim() || !form.password.trim()) {
      toast.error("Email and password are required");
      return;
    }
    if (form.password.length < 6) {
      toast.error("Password must be at least 6 characters");
      return;
    }
    setSubmitting(true);
    try {
      // NOTE: organization_id is intentionally NOT sent — the backend binds it
      // automatically from the logged-in Org Admin's JWT token.
      await apiRequest("/users", {
        method: "POST",
        body: JSON.stringify({
          email: form.email.trim(),
          password: form.password,
          role: form.role,
        }),
      });
      toast.success(`${form.role} account created successfully!`);
      setForm(DEFAULT_FORM);
      setShowModal(false);
      fetchUsers();
    } catch (err) {
      toast.error(err.message || "Failed to create account");
    } finally {
      setSubmitting(false);
    }
  };

  // ─── Update role ───────────────────────────────────────────────────────────
  const handleRoleChange = async (userId, newRole) => {
    try {
      await apiRequest(`/users/${userId}/role`, {
        method: "PUT",
        body: JSON.stringify({ role: newRole }),
      });
      toast.success("Role updated successfully!");
      fetchUsers();
    } catch (err) {
      toast.error("Failed to update role");
    }
  };

  // ─── Delete (deactivate) user ──────────────────────────────────────────────
  const handleDelete = async () => {
    if (!deleteId) return;
    try {
      await apiRequest(`/users/${deleteId}`, { method: "DELETE" });
      toast.success("User removed from your team");
      setDeleteId(null);
      setConfirmDelete(false);
      fetchUsers();
    } catch (err) {
      toast.error(err.message || "Failed to remove user");
    }
  };

  const canManage = canAccess(user?.role, MODULES.USERS, ACTIONS.MANAGE);

  // ─── Render ────────────────────────────────────────────────────────────────
  return (
    <div style={{ padding: "30px", maxWidth: "1200px", margin: "auto", fontFamily: "inherit" }}>

      {/* ── Page header ── */}
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "28px" }}>
        <div>
          <h2 style={{ margin: 0, fontSize: "22px", fontWeight: "700", color: "#0f172a" }}>
            Manage Team
          </h2>
          <p style={{ margin: "6px 0 0", color: "#64748b", fontSize: "14px" }}>
            Manage your organization's staff accounts and access roles.
          </p>
        </div>
        {isAdmin && (
          <button
            id="add-user-btn"
            style={styles.primaryBtn}
            onClick={() => setShowModal(true)}
          >
            + Add New User
          </button>
        )}
      </div>

      {/* ── Permissions overview card ── */}
      <div style={styles.infoCard}>
        <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "12px" }}>
          <span style={{ fontSize: "16px" }}>🔐</span>
          <h4 style={{ margin: 0, color: "#1e293b", fontSize: "14px", fontWeight: "600" }}>
            Permissions Overview
          </h4>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))", gap: "10px" }}>
          {[
            { role: "Admin", desc: "Full access to all modules and settings.", icon: "🛡️" },
            { role: "Accountant", desc: "Accounting, Reports, Taxes, and Banking.", icon: "📊" },
            { role: "Staff", desc: "Sales and Purchases: Invoices, Bills, Customers, Vendors.", icon: "👤" },
            { role: "Viewer", desc: "Read-only access across the application.", icon: "👁️" },
          ].map(({ role, desc, icon }) => (
            <div key={role} style={styles.permCard}>
              <div style={{ display: "flex", alignItems: "center", gap: "6px", marginBottom: "4px" }}>
                <span>{icon}</span>
                {getRoleBadge(role)}
              </div>
              <p style={{ margin: 0, fontSize: "12px", color: "#64748b", lineHeight: "1.5" }}>{desc}</p>
            </div>
          ))}
        </div>
      </div>

      {/* ── Users table ── */}
      <div style={styles.card}>
        {loading ? (
          <TableSkeleton columns={5} rows={3} />
        ) : users.length === 0 ? (
          <div style={{ textAlign: "center", padding: "60px 20px" }}>
            <div style={{ fontSize: "40px", marginBottom: "12px" }}>👥</div>
            <p style={{ color: "#64748b", fontSize: "15px", margin: 0 }}>
              No team members yet. Add your first staff account above.
            </p>
          </div>
        ) : (
          <table style={styles.table}>
            <thead>
              <tr style={styles.thead}>
                <th style={styles.th}>User</th>
                <th style={styles.th}>Role</th>
                <th style={styles.th}>Status</th>
                <th style={styles.th}>Joined</th>
                {canManage && <th style={{ ...styles.th, textAlign: "right" }}>Actions</th>}
              </tr>
            </thead>
            <tbody>
              {users.map((u, idx) => (
                <tr
                  key={u.id}
                  style={{
                    ...styles.tr,
                    background: idx % 2 === 0 ? "#ffffff" : "#f8fafc",
                    ...(u.id === user?.id ? { background: "#eff6ff" } : {}),
                  }}
                >
                  {/* Email column */}
                  <td style={styles.td}>
                    <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
                      <div style={{
                        width: "34px", height: "34px", borderRadius: "50%",
                        background: "linear-gradient(135deg, #2563eb, #7c3aed)",
                        display: "flex", alignItems: "center", justifyContent: "center",
                        color: "#fff", fontWeight: "700", fontSize: "13px", flexShrink: 0,
                      }}>
                        {(u.email || "?")[0].toUpperCase()}
                      </div>
                      <div>
                        <div style={{ fontWeight: "600", color: "#1e293b", fontSize: "14px" }}>
                          {u.email}
                          {u.id === user?.id && (
                            <span style={{ marginLeft: "6px", fontSize: "11px", color: "#2563eb", fontWeight: "500" }}>(you)</span>
                          )}
                        </div>
                        {u.organization_name && (
                          <div style={{ fontSize: "12px", color: "#94a3b8" }}>{u.organization_name}</div>
                        )}
                      </div>
                    </div>
                  </td>

                  {/* Role column — dropdown if can manage, badge otherwise */}
                  <td style={styles.td}>
                    {canManage && u.id !== user?.id ? (
                      <select
                        id={`role-select-${u.id}`}
                        value={u.role || "Staff"}
                        onChange={(e) => handleRoleChange(u.id, e.target.value)}
                        style={styles.select}
                      >
                        <option value="Admin">Admin</option>
                        <option value="Accountant">Accountant</option>
                        <option value="Staff">Staff</option>
                        <option value="Viewer">Viewer</option>
                      </select>
                    ) : (
                      getRoleBadge(u.role)
                    )}
                  </td>

                  {/* Status column */}
                  <td style={styles.td}>
                    <span style={{
                      padding: "3px 10px",
                      background: u.status === "active" ? "#dcfce7" : "#fee2e2",
                      color: u.status === "active" ? "#166534" : "#991b1b",
                      borderRadius: "20px",
                      fontSize: "12px",
                      fontWeight: "600",
                    }}>
                      {u.status === "active" ? "● Active" : "● Inactive"}
                    </span>
                  </td>

                  {/* Joined column */}
                  <td style={{ ...styles.td, color: "#64748b", fontSize: "13px" }}>
                    {new Date(u.created_at).toLocaleDateString("en-IN", {
                      day: "2-digit", month: "short", year: "numeric",
                    })}
                  </td>

                  {/* Actions column */}
                  {canManage && (
                    <td style={{ ...styles.td, textAlign: "right" }}>
                      {u.id !== user?.id && (
                        <button
                          id={`remove-user-${u.id}`}
                          onClick={() => { setDeleteId(u.id); setConfirmDelete(true); }}
                          style={styles.dangerBtn}
                          title="Remove user"
                        >
                          Remove
                        </button>
                      )}
                    </td>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* ─────────────────── ADD USER MODAL ─────────────────── */}
      {showModal && (
        <div style={styles.overlay} onClick={() => { setShowModal(false); setForm(DEFAULT_FORM); }}>
          <div style={styles.modal} onClick={(e) => e.stopPropagation()}>

            {/* Modal header */}
            <div style={styles.modalHeader}>
              <div>
                <h3 style={{ margin: 0, fontSize: "18px", fontWeight: "700", color: "#0f172a" }}>
                  Add New Team Member
                </h3>
                <p style={{ margin: "4px 0 0", fontSize: "13px", color: "#64748b" }}>
                  They will be automatically bound to your organization.
                </p>
              </div>
              <button
                id="close-modal-btn"
                onClick={() => { setShowModal(false); setForm(DEFAULT_FORM); }}
                style={styles.closeBtn}
              >
                ✕
              </button>
            </div>

            {/* Security notice */}
            <div style={styles.securityNote}>
              <span style={{ fontSize: "14px" }}>🔒</span>
              <span style={{ fontSize: "13px", color: "#166534" }}>
                <strong>Secure:</strong> New accounts are automatically restricted to your organization. They cannot access other companies' data.
              </span>
            </div>

            {/* Form */}
            <form onSubmit={handleCreate} style={{ display: "flex", flexDirection: "column", gap: "16px" }}>

              <div>
                <label style={styles.label} htmlFor="new-user-email">Email Address <span style={{ color: "#ef4444" }}>*</span></label>
                <input
                  id="new-user-email"
                  type="email"
                  placeholder="staff@yourcompany.com"
                  value={form.email}
                  onChange={(e) => setForm({ ...form, email: e.target.value })}
                  style={styles.input}
                  required
                  autoFocus
                />
              </div>

              <div>
                <label style={styles.label} htmlFor="new-user-password">Password <span style={{ color: "#ef4444" }}>*</span></label>
                <input
                  id="new-user-password"
                  type="password"
                  placeholder="Minimum 6 characters"
                  value={form.password}
                  onChange={(e) => setForm({ ...form, password: e.target.value })}
                  style={styles.input}
                  required
                  minLength={6}
                />
              </div>

              <div>
                <label style={styles.label} htmlFor="new-user-role">Role <span style={{ color: "#ef4444" }}>*</span></label>
                <select
                  id="new-user-role"
                  value={form.role}
                  onChange={(e) => setForm({ ...form, role: e.target.value })}
                  style={styles.input}
                >
                  {/* Strictly limited — Org Admins cannot create other Admins */}
                  <option value="Accountant">Accountant — Accounting, Reports, Taxes</option>
                  <option value="Staff">Staff — Sales &amp; Purchase entries</option>
                </select>
                <p style={{ margin: "6px 0 0", fontSize: "12px", color: "#94a3b8" }}>
                  Only Accountant and Staff roles can be created here.
                </p>
              </div>

              <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end", marginTop: "4px" }}>
                <button
                  type="button"
                  id="cancel-add-user-btn"
                  onClick={() => { setShowModal(false); setForm(DEFAULT_FORM); }}
                  style={styles.secondaryBtn}
                  disabled={submitting}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  id="submit-add-user-btn"
                  style={{ ...styles.primaryBtn, opacity: submitting ? 0.7 : 1 }}
                  disabled={submitting}
                >
                  {submitting ? "Creating..." : "Create Account"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ─────────────────── DELETE CONFIRMATION MODAL ─────────────────── */}
      {confirmDelete && (
        <div style={styles.overlay} onClick={() => { setConfirmDelete(false); setDeleteId(null); }}>
          <div style={{ ...styles.modal, maxWidth: "420px" }} onClick={(e) => e.stopPropagation()}>
            <div style={{ textAlign: "center", padding: "10px 0 20px" }}>
              <div style={{ fontSize: "36px", marginBottom: "12px" }}>⚠️</div>
              <h3 style={{ margin: "0 0 8px", color: "#0f172a", fontSize: "18px" }}>Remove User?</h3>
              <p style={{ margin: 0, color: "#64748b", fontSize: "14px", lineHeight: "1.6" }}>
                This user will be removed from your team and will lose access to the application.
              </p>
            </div>
            <div style={{ display: "flex", gap: "10px", justifyContent: "center" }}>
              <button
                id="cancel-delete-btn"
                style={styles.secondaryBtn}
                onClick={() => { setConfirmDelete(false); setDeleteId(null); }}
              >
                Cancel
              </button>
              <button
                id="confirm-delete-btn"
                style={{ ...styles.primaryBtn, background: "#dc2626" }}
                onClick={handleDelete}
              >
                Yes, Remove
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── Styles ──────────────────────────────────────────────────────────────────
const styles = {
  primaryBtn: {
    padding: "9px 18px",
    background: "linear-gradient(135deg, #2563eb, #1d4ed8)",
    color: "#fff",
    border: "none",
    borderRadius: "6px",
    cursor: "pointer",
    fontWeight: "600",
    fontSize: "14px",
    boxShadow: "0 1px 4px rgba(37,99,235,0.3)",
    transition: "opacity 0.15s",
  },
  secondaryBtn: {
    padding: "9px 18px",
    background: "#f1f5f9",
    color: "#475569",
    border: "1px solid #e2e8f0",
    borderRadius: "6px",
    cursor: "pointer",
    fontWeight: "600",
    fontSize: "14px",
  },
  dangerBtn: {
    padding: "5px 12px",
    background: "#fff1f2",
    color: "#dc2626",
    border: "1px solid #fecaca",
    borderRadius: "5px",
    cursor: "pointer",
    fontSize: "13px",
    fontWeight: "500",
  },
  infoCard: {
    background: "#f8fafc",
    padding: "16px",
    borderRadius: "10px",
    border: "1px solid #e2e8f0",
    marginBottom: "20px",
  },
  permCard: {
    background: "#fff",
    padding: "12px",
    borderRadius: "8px",
    border: "1px solid #e2e8f0",
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
    transition: "background 0.1s",
  },
  td: {
    padding: "14px 16px",
    color: "#334155",
    verticalAlign: "middle",
  },
  select: {
    padding: "6px 10px",
    borderRadius: "5px",
    border: "1px solid #cbd5e1",
    fontSize: "13px",
    color: "#1e293b",
    background: "#fff",
    cursor: "pointer",
  },
  overlay: {
    position: "fixed",
    inset: 0,
    background: "rgba(15,23,42,0.5)",
    backdropFilter: "blur(3px)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    zIndex: 1000,
  },
  modal: {
    background: "#fff",
    borderRadius: "12px",
    padding: "28px",
    width: "100%",
    maxWidth: "480px",
    boxShadow: "0 20px 60px rgba(0,0,0,0.2)",
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
  securityNote: {
    display: "flex",
    alignItems: "flex-start",
    gap: "8px",
    padding: "10px 14px",
    background: "#f0fdf4",
    border: "1px solid #bbf7d0",
    borderRadius: "8px",
    marginBottom: "18px",
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
    padding: "9px 12px",
    borderRadius: "6px",
    border: "1px solid #d1d5db",
    fontSize: "14px",
    color: "#1e293b",
    background: "#fff",
    boxSizing: "border-box",
    outline: "none",
  },
};

export default UsersRoles;
