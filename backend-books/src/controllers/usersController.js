const pool = require("../config/db");
const bcrypt = require("bcrypt");

const ensureUserColumns = async () => {
  try {
    const columns = [
      "organization_name VARCHAR(255)",
      "business_type VARCHAR(100)",
      "gstin VARCHAR(50)",
      "pan VARCHAR(50)",
      "address TEXT",
      "city VARCHAR(100)",
      "state VARCHAR(100)",
      "country VARCHAR(100)",
      "phone VARCHAR(50)",
      "organization_email VARCHAR(255)",
      "financial_year_start VARCHAR(20) DEFAULT 'April'",
      "default_currency VARCHAR(10) DEFAULT 'INR'",
      "role VARCHAR(50) DEFAULT 'admin'",
      "status VARCHAR(30) DEFAULT 'active'"
    ];
    for (const col of columns) {
      const colName = col.split(' ')[0];
      await pool.query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS ${colName} ${col.substring(col.indexOf(' ')+1)}`);
    }
  } catch (err) {
    console.error("ensureUserColumns error:", err);
  }
};
ensureUserColumns();

const getUsers = async (req, res) => {
  try {
    let query;
    let params;

    if (req.user.role === "Super Admin") {
      query = "SELECT id, email, organization_name, role, status, created_at FROM users ORDER BY created_at ASC";
      params = [];
    } else {
      query = "SELECT id, email, organization_name, role, status, created_at FROM users WHERE organization_id = $1 ORDER BY created_at ASC";
      params = [req.tenantId];
    }

    const result = await pool.query(query, params);
    res.json({ users: result.rows });
  } catch (err) {
    console.error("GET USERS ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

const getOrganizationSettings = async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT organization_name, business_type, gstin, pan, address, city, state, country, phone, organization_email, financial_year_start, default_currency FROM users WHERE id = $1",
      [req.user.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ message: "User not found" });
    res.json({ settings: result.rows[0] });
  } catch (err) {
    console.error("GET ORG SETTINGS ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

const updateOrganizationSettings = async (req, res) => {
  const { organization_name, business_type, gstin, pan, address, city, state, country, phone, organization_email, financial_year_start, default_currency } = req.body;
  try {
    const result = await pool.query(
      `UPDATE users SET 
        organization_name = $1, business_type = $2, gstin = $3, pan = $4, address = $5, city = $6, 
        state = $7, country = $8, phone = $9, organization_email = $10, financial_year_start = $11, default_currency = $12
       WHERE id = $13 RETURNING organization_name, business_type, gstin, pan, address, city, state, country, phone, organization_email, financial_year_start, default_currency`,
      [organization_name, business_type, gstin, pan, address, city, state, country, phone, organization_email, financial_year_start, default_currency, req.user.id]
    );
    res.json({ message: "Settings updated", settings: result.rows[0] });
  } catch (err) {
    console.error("UPDATE ORG SETTINGS ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

const updateUserRole = async (req, res) => {
  const { id } = req.params;
  const { role } = req.body;
  
  if (req.user.id !== parseInt(id)) {
    // Basic multi-tenant lock for internship scope: user can only change their own role unless they invite others.
    // For now, if we allow them to change their own role for testing:
  }
  
  try {
    // Check if the user being updated is currently an Admin AND belongs to the tenant
    const userResult = await pool.query("SELECT role FROM users WHERE id = $1 AND organization_id = $2", [id, req.tenantId]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: "User not found or access denied" });
    }
    
    const currentRole = userResult.rows[0].role;
    const isDemotingAdmin = currentRole.toLowerCase() === 'admin' && role.toLowerCase() !== 'admin';

    if (isDemotingAdmin) {
      // Check how many admins are left IN THIS ORGANIZATION
      const adminCountResult = await pool.query(
        "SELECT COUNT(*) FROM users WHERE LOWER(role) = 'admin' AND organization_id = $1", 
        [req.tenantId]
      );
      const adminCount = parseInt(adminCountResult.rows[0].count, 10);
      
      if (adminCount <= 1) {
        return res.status(400).json({ message: "Cannot change role. You are the only Admin for this organization." });
      }
    }

    const result = await pool.query(
      "UPDATE users SET role = $1 WHERE id = $2 AND organization_id = $3 RETURNING id, email, role", 
      [role, id, req.tenantId]
    );
    res.json({ message: "Role updated", user: result.rows[0] });
  } catch (err) {
    console.error("UPDATE USER ROLE ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

const createStaffAccount = async (req, res) => {
  try {
    const orgId = req.user.organization_id;
    
    if (!orgId) {
      return res.status(403).json({ message: "Access Denied: You do not belong to an organization." });
    }

    const { email, password, role, full_name } = req.body;

    if (!email || !password || !role) {
      return res.status(400).json({ message: "Email, password, and role are required." });
    }
    
    const allowedRoles = ['Accountant', 'Staff', 'Viewer'];
    if (!allowedRoles.includes(role)) {
      return res.status(400).json({ 
        message: "Invalid role. You can only create Accountant, Staff, or Viewer accounts for your organization." 
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const result = await pool.query(
      `INSERT INTO users (email, password, role, organization_id, full_name)
       VALUES ($1, $2, $3, $4, $5) 
       RETURNING id, email, role, organization_id`,
      [email.trim(), hashedPassword, role, orgId, full_name]
    );

    res.status(201).json({ 
      message: "Team member created successfully", 
      user: result.rows[0] 
    });
  } catch (error) {
    console.error("CREATE STAFF ERROR:", error);
    if (error.code === '23505') {
      return res.status(400).json({ message: "This email is already registered." });
    }
    res.status(500).json({ message: "Server error while creating user." });
  }
};

module.exports = { getUsers, getOrganizationSettings, updateOrganizationSettings, updateUserRole, createStaffAccount };