const pool = require("../config/db");
const bcrypt = require("bcrypt");

// ===== INITIALIZE ORGANIZATION COLUMNS =====
const ensureOrganizationColumns = async () => {
  try {
    const columns = [
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
      "logo_url TEXT",
      "owner_id INTEGER REFERENCES users(id)"
    ];
    for (const col of columns) {
      const colName = col.split(' ')[0];
      await pool.query(`ALTER TABLE organizations ADD COLUMN IF NOT EXISTS ${colName} ${col.substring(col.indexOf(' ')+1)}`);
    }
  } catch (err) {
    console.error("ensureOrganizationColumns error:", err);
  }
};
ensureOrganizationColumns();

// ===== GET ALL ORGANIZATIONS (Super Admin only) =====
const getOrganizations = async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        o.id,
        o.name,
        o.created_at,
        o.is_active,
        u.email  AS admin_email,
        u.status AS admin_status,
        (SELECT COUNT(*) FROM users WHERE organization_id = o.id) AS member_count
      FROM organizations o
      LEFT JOIN users u ON u.organization_id = o.id AND LOWER(u.role) = 'admin'
      ORDER BY o.created_at DESC
    `);
    res.json({ organizations: result.rows });
  } catch (err) {
    console.error("GET ORGANIZATIONS ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ===== ONBOARD NEW CLIENT (Super Admin only) =====
// Uses a DB transaction to atomically:
//   1. Insert the new organization
//   2. Insert an Admin user bound to that organization
const onboardOrganization = async (req, res) => {
  const { company_name, admin_email, admin_password } = req.body;

  if (!company_name?.trim() || !admin_email?.trim() || !admin_password) {
    return res.status(400).json({ message: "Company name, admin email, and password are required." });
  }
  if (admin_password.length < 6) {
    return res.status(400).json({ message: "Admin password must be at least 6 characters." });
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    // 1. Create the organization
    const orgResult = await client.query(
      `INSERT INTO organizations (name, is_active, created_at)
       VALUES ($1, true, CURRENT_TIMESTAMP)
       RETURNING *`,
      [company_name.trim()]
    );
    const newOrg = orgResult.rows[0];

    // 2. Hash the admin password
    const hashedPassword = await bcrypt.hash(admin_password, 10);

    // 3. Create the Admin user bound to the new org
    const userResult = await client.query(
      `INSERT INTO users (email, password, role, organization_id, status)
       VALUES ($1, $2, 'Admin', $3, 'active')
       RETURNING id, email, role, organization_id`,
      [admin_email.trim().toLowerCase(), hashedPassword, newOrg.id]
    );
    const newAdmin = userResult.rows[0];

    // 4. Set owner_id for the organization
    await client.query("UPDATE organizations SET owner_id = $1 WHERE id = $2", [newAdmin.id, newOrg.id]);

    await client.query("COMMIT");

    res.status(201).json({
      message: `Organization "${newOrg.name}" onboarded successfully with Admin account.`,
      organization: newOrg,
      admin: newAdmin,
    });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("ONBOARD ORGANIZATION ERROR:", err);
    if (err.code === "23505") {
      return res.status(400).json({ message: "An account with this email already exists." });
    }
    res.status(500).json({ message: "Failed to onboard organization. All changes rolled back." });
  } finally {
    client.release();
  }
};

// ===== TOGGLE ORGANIZATION ACTIVE STATUS =====
const toggleOrganizationStatus = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      `UPDATE organizations SET is_active = NOT is_active WHERE id = $1 RETURNING id, name, is_active`,
      [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Organization not found" });
    }
    const org = result.rows[0];
    res.json({
      message: `Organization "${org.name}" has been ${org.is_active ? "activated" : "deactivated"}.`,
      organization: org,
    });
  } catch (err) {
    console.error("TOGGLE ORG STATUS ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ===== GET MY ORGANIZATIONS =====
const getMyOrganizations = async (req, res) => {
  try {
    // Return organizations where the user is the owner, OR the organization they are currently in
    const result = await pool.query(
      "SELECT id, name FROM organizations WHERE owner_id = $1 OR id = $2 ORDER BY created_at ASC",
      [req.user.id, req.user.organization_id]
    );
    res.json({ organizations: result.rows });
  } catch (err) {
    console.error("GET MY ORGS ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ===== CREATE ORGANIZATION (MAX 5) =====
const createOrganization = async (req, res) => {
  const { name } = req.body;
  if (!name || name.trim() === "") {
    return res.status(400).json({ message: "Organization name is required" });
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    
    // Check limit
    const limitCheck = await client.query("SELECT COUNT(*) FROM organizations WHERE owner_id = $1", [req.user.id]);
    if (parseInt(limitCheck.rows[0].count) >= 5) {
      return res.status(400).json({ message: "You have reached the maximum limit of 5 organizations." });
    }

    // Insert new org
    const orgResult = await client.query(
      `INSERT INTO organizations (name, is_active, created_at, owner_id)
       VALUES ($1, true, CURRENT_TIMESTAMP, $2)
       RETURNING *`,
      [name.trim(), req.user.id]
    );
    const newOrg = orgResult.rows[0];

    // Automatically switch user to the new org
    await client.query("UPDATE users SET organization_id = $1 WHERE id = $2", [newOrg.id, req.user.id]);

    // Issue a new JWT token because the organization_id has changed!
    const jwt = require("jsonwebtoken");
    const token = jwt.sign(
      { 
        id: req.user.id, 
        email: req.user.email, 
        business_type: req.user.business_type, 
        role: req.user.role, 
        organization_id: newOrg.id 
      },
      process.env.JWT_SECRET,
      { expiresIn: "30d" },
    );
    res.cookie("token", token, { httpOnly: true, secure: true, sameSite: "none", maxAge: 30 * 24 * 60 * 60 * 1000 });

    await client.query("COMMIT");

    res.status(201).json({
      message: `Organization "${newOrg.name}" created and switched successfully.`,
      organization: newOrg
    });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("CREATE ORG ERROR:", err);
    res.status(500).json({ message: "Failed to create organization" });
  } finally {
    client.release();
  }
};

// ===== SWITCH ORGANIZATION =====
const switchOrganization = async (req, res) => {
  const { id } = req.params;
  try {
    // Verify the user has access to this organization (either owns it or is assigned to it)
    const checkAccess = await pool.query(
      "SELECT id FROM organizations WHERE id = $1 AND (owner_id = $2 OR id = $3)",
      [id, req.user.id, req.user.organization_id] // In a true multi-tenant we'd check user_organizations, but here we just check ownership. Wait, staff don't own it, but they shouldn't switch anyway.
    );
    
    // For staff, they can only switch to their own org (which is a no-op). So only owners can switch to other orgs they own.
    if (checkAccess.rows.length === 0) {
       return res.status(403).json({ message: "Access denied or organization not found." });
    }

    await pool.query("UPDATE users SET organization_id = $1 WHERE id = $2", [id, req.user.id]);

    // We must issue a NEW JWT token because the organization_id has changed!
    const jwt = require("jsonwebtoken");
    const token = jwt.sign(
      { 
        id: req.user.id, 
        email: req.user.email, 
        business_type: req.user.business_type, 
        role: req.user.role, 
        organization_id: id 
      },
      process.env.JWT_SECRET,
      { expiresIn: "30d" },
    );
    res.cookie("token", token, { httpOnly: true, secure: true, sameSite: "none", maxAge: 30 * 24 * 60 * 60 * 1000 });

    res.json({ message: "Switched organization successfully.", newOrganizationId: id });
  } catch (err) {
    console.error("SWITCH ORG ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

module.exports = { getOrganizations, onboardOrganization, toggleOrganizationStatus, createOrganization, getMyOrganizations, switchOrganization };
