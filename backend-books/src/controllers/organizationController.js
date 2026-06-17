const pool = require("../config/db");
const bcrypt = require("bcrypt");

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

module.exports = { getOrganizations, onboardOrganization, toggleOrganizationStatus };
