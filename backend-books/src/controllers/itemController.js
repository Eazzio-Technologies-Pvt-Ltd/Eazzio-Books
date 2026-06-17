/**
 * itemsController.js – CRUD for inventory items (Multi-Tenant)
 * Dependencies: pool, validationResult
 */
const pool = require("../config/db");
const { validationResult } = require("express-validator");

// ================= GET ALL ITEMS =================
const getItems = async (req, res) => {
  try {
    let query = `SELECT * FROM items WHERE 1=1`;
    const values = [];
    let paramIndex = 1;

    // SaaS ISOLATION: Filter by organization for Org Admins and below
    if (req.tenantId) {
      query += ` AND organization_id = $${paramIndex++}`;
      values.push(req.tenantId);
    }

    query += ` ORDER BY created_at DESC`;
    const result = await pool.query(query, values);
    res.json({ items: result.rows });
  } catch (err) {
    console.error("GET ITEMS ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ================= GET SINGLE ITEM =================
const getItemById = async (req, res) => {
  const { id } = req.params;
  try {
    let query = `SELECT * FROM items WHERE id = $1`;
    const values = [id];
    let paramIndex = 2;

    if (req.tenantId) {
      query += ` AND organization_id = $${paramIndex++}`;
      values.push(req.tenantId);
    }

    const result = await pool.query(query, values);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Item not found" });
    }
    res.json({ item: result.rows[0] });
  } catch (err) {
    console.error("GET ITEM ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ================= CREATE ITEM =================
const createItem = async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ message: errors.array()[0].msg });
  }

  const {
    name, sku, hsn_code, tax_rate, item_type, unit,
    selling_price, sales_account, cost_price, purchase_account,
    description, purchase_description, image_url, preferred_vendor_id,
    is_inventory_tracked, inventory_account, opening_stock,
    opening_stock_rate, reorder_level
  } = req.body;

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const trackInv = Boolean(is_inventory_tracked);
    const initialStock = trackInv ? (parseFloat(opening_stock) || 0) : 0;

    const result = await client.query(
      `INSERT INTO items
        (user_id, name, sku, hsn_code, tax_rate, item_type, unit,
         selling_price, sales_account, cost_price, purchase_account,
         description, purchase_description, image_url, preferred_vendor_id,
         is_inventory_tracked, inventory_account, opening_stock, opening_stock_rate,
         reorder_level, stock_quantity, organization_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22)
       RETURNING *`,
      [
        req.user.id,
        name,
        sku || null,
        hsn_code || null,
        tax_rate || 0,
        item_type || "Goods",
        unit || null,
        selling_price || 0,
        sales_account || null,
        cost_price || 0,
        purchase_account || null,
        description || null,
        purchase_description || null,
        image_url || null,
        preferred_vendor_id || null,
        trackInv,
        trackInv ? (inventory_account || null) : null,
        trackInv ? initialStock : 0,
        trackInv ? (parseFloat(opening_stock_rate) || 0) : 0,
        trackInv ? (parseFloat(reorder_level) || 0) : 0,
        initialStock,
        req.tenantId || null   // BOUND TO THE ORG ADMIN'S ORGANIZATION
      ]
    );

    const newItem = result.rows[0];

    if (trackInv && initialStock > 0) {
      await client.query(
        `INSERT INTO inventory_movements 
         (user_id, item_id, transaction_type, quantity_change, entry_date, description)
         VALUES ($1, $2, $3, $4, CURRENT_DATE, $5)`,
        [req.user.id, newItem.id, "initial_stock", initialStock, "Initial stock added during item creation"]
      );
    }

    await client.query(
      `INSERT INTO item_history (item_id, user_id, action, description)
       VALUES ($1, $2, $3, $4)`,
      [newItem.id, req.user.id, 'CREATED', 'Item created successfully']
    );

    await client.query("COMMIT");
    res.json({ message: "Item created", item: newItem });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("CREATE ITEM ERROR:", err);
    res.status(500).json({ message: "Server error" });
  } finally {
    client.release();
  }
};

// ================= UPDATE ITEM =================
const updateItem = async (req, res) => {
  const { id } = req.params;
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ message: errors.array()[0].msg });
  }

  const {
    name, sku, hsn_code, tax_rate, item_type, unit,
    selling_price, sales_account, cost_price, purchase_account,
    description, purchase_description, image_url, preferred_vendor_id,
    is_inventory_tracked, inventory_account, opening_stock,
    opening_stock_rate, reorder_level
  } = req.body;

  try {
    const trackInv = Boolean(is_inventory_tracked);

    let query = `
      UPDATE items
      SET name = $1, sku = $2, hsn_code = $3, tax_rate = $4,
          item_type = $5, unit = $6, selling_price = $7,
          sales_account = $8, cost_price = $9, purchase_account = $10,
          description = $11, purchase_description = $12,
          image_url = $13, preferred_vendor_id = $14,
          is_inventory_tracked = $15, inventory_account = $16, opening_stock = $17, 
          opening_stock_rate = $18, reorder_level = $19
      WHERE id = $20`;
    
    const values = [
      name,
      sku || null,
      hsn_code || null,
      tax_rate || 0,
      item_type || "Goods",
      unit || null,
      selling_price || 0,
      sales_account || null,
      cost_price || 0,
      purchase_account || null,
      description || null,
      purchase_description || null,
      image_url || null,
      preferred_vendor_id || null,
      trackInv,
      trackInv ? (inventory_account || null) : null,
      trackInv ? (parseFloat(opening_stock) || 0) : 0,
      trackInv ? (parseFloat(opening_stock_rate) || 0) : 0,
      trackInv ? (parseFloat(reorder_level) || 0) : 0,
      id
    ];

    let paramIndex = 21;
    if (req.tenantId) {
      query += ` AND organization_id = $${paramIndex++}`;
      values.push(req.tenantId);
    }
    query += ` RETURNING *`;

    const result = await pool.query(query, values);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Item not found" });
    }

    await pool.query(
      `INSERT INTO item_history (item_id, user_id, action, description)
       VALUES ($1, $2, $3, $4)`,
      [id, req.user.id, 'UPDATED', 'Item details updated']
    );

    res.json({ message: "Item updated", item: result.rows[0] });
  } catch (err) {
    console.error("UPDATE ITEM ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ================= DELETE ITEM =================
const deleteItem = async (req, res) => {
  const { id } = req.params;
  try {
    let query = `DELETE FROM items WHERE id = $1`;
    const values = [id];
    let paramIndex = 2;

    if (req.tenantId) {
      query += ` AND organization_id = $${paramIndex++}`;
      values.push(req.tenantId);
    }
    query += ` RETURNING *`;

    const result = await pool.query(query, values);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Item not found" });
    }
    res.json({ message: "Item deleted" });
  } catch (err) {
    console.error("DELETE ITEM ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// ================= GET ITEM HISTORY =================
const getItemHistory = async (req, res) => {
  const { id } = req.params;
  try {
    // First verify the item belongs to this tenant
    let checkQuery = `SELECT id FROM items WHERE id = $1`;
    const checkValues = [id];
    let paramIndex = 2;
    if (req.tenantId) {
      checkQuery += ` AND organization_id = $${paramIndex++}`;
      checkValues.push(req.tenantId);
    }
    const itemCheck = await pool.query(checkQuery, checkValues);
    if (itemCheck.rows.length === 0) {
      return res.status(404).json({ message: "Item not found" });
    }

    const result = await pool.query(
      `SELECT h.*, u.organization_name as username
       FROM item_history h
       LEFT JOIN users u ON h.user_id = u.id
       WHERE h.item_id = $1
       ORDER BY h.created_at DESC`,
      [id]
    );
    res.json({ history: result.rows });
  } catch (err) {
    console.error("GET ITEM HISTORY ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

module.exports = {
  getItems,
  getItemById,
  createItem,
  updateItem,
  deleteItem,
  getItemHistory,
};