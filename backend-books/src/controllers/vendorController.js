const pool = require("../config/db");

// ---- Ensure vendors table exists (safe to re-run) ----
const ensureVendorsTable = async () => {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS vendors (
      id               SERIAL PRIMARY KEY,
      user_id          INTEGER NOT NULL,
      display_name     VARCHAR(255) NOT NULL,
      company_name     VARCHAR(255),
      email            VARCHAR(255),
      phone            VARCHAR(50),
      gstin            VARCHAR(20),
      pan              VARCHAR(20),
      billing_address  TEXT,
      shipping_address TEXT,
      opening_balance  NUMERIC(12,2) DEFAULT 0,
      payment_terms    VARCHAR(100),
      status           VARCHAR(20) DEFAULT 'active',
      notes            TEXT,
      is_deleted       BOOLEAN DEFAULT false,
      created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // Add missing columns if table existed prior to these additions
  try {
    await pool.query(`ALTER TABLE vendors ADD COLUMN IF NOT EXISTS gstin VARCHAR(20)`);
    await pool.query(`ALTER TABLE vendors ADD COLUMN IF NOT EXISTS pan VARCHAR(20)`);
  } catch(e) {
    console.error("Error adding columns to vendors:", e);
  }
};
ensureVendorsTable().catch(err => console.error("ensureVendorsTable error:", err));

// ===== GET ALL VENDORS =====
const getVendors = async (req, res) => {
  try {
    let query = `SELECT * FROM vendors WHERE is_deleted = false`;
    const values = [];
    let paramIndex = 1;

    if (req.tenantId) {
      query += ` AND organization_id = $${paramIndex++}`;
      values.push(req.tenantId);
    }
    query += ` ORDER BY display_name ASC`;

    const result = await pool.query(query, values);
    res.json({ vendors: result.rows });
  } catch (err) {
    console.error("GET VENDORS ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ===== GET VENDOR BY ID =====
const getVendorById = async (req, res) => {
  const { id } = req.params;
  try {
    let query = `SELECT * FROM vendors WHERE id = $1 AND is_deleted = false`;
    const values = [id];
    let paramIndex = 2;

    if (req.tenantId) {
      query += ` AND organization_id = $${paramIndex++}`;
      values.push(req.tenantId);
    }

    const result = await pool.query(query, values);
    if (result.rows.length === 0)
      return res.status(404).json({ message: "Vendor not found" });
    res.json({ vendor: result.rows[0] });
  } catch (err) {
    console.error("GET VENDOR BY ID ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ===== CREATE VENDOR =====
const createVendor = async (req, res) => {
  const {
    display_name, company_name, email, phone, gstin, pan,
    billing_address, shipping_address, opening_balance,
    payment_terms, status, notes,
  } = req.body;

  if (!display_name || display_name.trim() === "") {
    return res.status(400).json({ message: "Display name is required" });
  }

  try {
    const result = await pool.query(
      `INSERT INTO vendors
         (user_id, display_name, company_name, email, phone, gstin, pan,
          billing_address, shipping_address, opening_balance, payment_terms, status, notes, organization_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
       RETURNING *`,
      [
        req.user.id,
        display_name.trim(),
        company_name  || null,
        email         || null,
        phone         || null,
        gstin         || null,
        pan           || null,
        billing_address  || null,
        shipping_address || null,
        parseFloat(opening_balance) || 0,
        payment_terms || null,
        status        || "active",
        notes         || null,
        req.tenantId  || null,
      ]
    );
    res.status(201).json({ vendor: result.rows[0], message: "Vendor created" });
  } catch (err) {
    console.error("CREATE VENDOR ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ===== UPDATE VENDOR =====
const updateVendor = async (req, res) => {
  const { id } = req.params;
  const {
    display_name, company_name, email, phone, gstin, pan,
    billing_address, shipping_address, opening_balance,
    payment_terms, status, notes,
  } = req.body;

  try {
    let query = `UPDATE vendors SET
       display_name     = COALESCE($1, display_name),
       company_name     = COALESCE($2, company_name),
       email            = COALESCE($3, email),
       phone            = COALESCE($4, phone),
       gstin            = COALESCE($5, gstin),
       pan              = COALESCE($6, pan),
       billing_address  = COALESCE($7, billing_address),
       shipping_address = COALESCE($8, shipping_address),
       opening_balance  = COALESCE($9, opening_balance),
       payment_terms    = COALESCE($10, payment_terms),
       status           = COALESCE($11, status),
       notes            = COALESCE($12, notes),
       updated_at       = CURRENT_TIMESTAMP
     WHERE id = $13 AND is_deleted = false`;

    const values = [
      display_name     || null,
      company_name     || null,
      email            || null,
      phone            || null,
      gstin            || null,
      pan              || null,
      billing_address  || null,
      shipping_address || null,
      opening_balance !== undefined ? parseFloat(opening_balance) : null,
      payment_terms    || null,
      status           || null,
      notes            !== undefined ? notes : null,
      id,
    ];

    let paramIndex = 14;
    if (req.tenantId) {
      query += ` AND organization_id = $${paramIndex++}`;
      values.push(req.tenantId);
    }
    query += ` RETURNING *`;

    const result = await pool.query(query, values);
    if (result.rows.length === 0)
      return res.status(404).json({ message: "Vendor not found" });
    res.json({ vendor: result.rows[0], message: "Vendor updated" });
  } catch (err) {
    console.error("UPDATE VENDOR ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ===== DELETE VENDOR (soft delete) =====
const deleteVendor = async (req, res) => {
  const { id } = req.params;
  try {
    let query = `UPDATE vendors SET is_deleted = true, updated_at = CURRENT_TIMESTAMP
       WHERE id = $1 AND is_deleted = false`;
    const values = [id];
    let paramIndex = 2;

    if (req.tenantId) {
      query += ` AND organization_id = $${paramIndex++}`;
      values.push(req.tenantId);
    }
    query += ` RETURNING id`;

    const result = await pool.query(query, values);
    if (result.rows.length === 0)
      return res.status(404).json({ message: "Vendor not found" });
    res.json({ message: "Vendor deleted" });
  } catch (err) {
    console.error("DELETE VENDOR ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

module.exports = { getVendors, getVendorById, createVendor, updateVendor, deleteVendor };
