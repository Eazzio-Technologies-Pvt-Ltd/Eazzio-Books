const pool = require("../config/db");
const sendEmail = require("../utils/sendEmail");
const { checkTransactionLock } = require("../utils/lockHelper");

// ---- ensure extra columns exist (safe to re-run) ----
const ensureColumns = async () => {
  const alterStatements = [
    `ALTER TABLE invoices     ADD COLUMN IF NOT EXISTS salesperson_id INTEGER`,
    `ALTER TABLE invoices     ADD COLUMN IF NOT EXISTS project_id INTEGER`,
    `ALTER TABLE invoices     ADD COLUMN IF NOT EXISTS balance_due NUMERIC(12,2) DEFAULT 0`,
    `ALTER TABLE invoices     ADD COLUMN IF NOT EXISTS quote_id INTEGER`,
    `ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS discount NUMERIC(10,2) DEFAULT 0`,
    `ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS discount_type VARCHAR(10) DEFAULT 'flat'`,
    `ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS item_name VARCHAR(255)`,
    `ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS hsn_code  VARCHAR(50)`,
    `ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS unit      VARCHAR(50)`,
    `ALTER TABLE invoices ADD COLUMN IF NOT EXISTS supplier_state VARCHAR(100)`,
    `ALTER TABLE invoices ADD COLUMN IF NOT EXISTS place_of_supply VARCHAR(100)`,
    `ALTER TABLE invoices ADD COLUMN IF NOT EXISTS customer_gstin VARCHAR(20)`,
    `ALTER TABLE invoices ADD COLUMN IF NOT EXISTS gst_type VARCHAR(30)`,
    `ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS taxable_value NUMERIC(12,2) DEFAULT 0`,
    `ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS cgst_rate NUMERIC(5,2) DEFAULT 0`,
    `ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS cgst_amount NUMERIC(12,2) DEFAULT 0`,
    `ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS sgst_rate NUMERIC(5,2) DEFAULT 0`,
    `ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS sgst_amount NUMERIC(12,2) DEFAULT 0`,
    `ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS igst_rate NUMERIC(5,2) DEFAULT 0`,
    `ALTER TABLE invoice_items ADD COLUMN IF NOT EXISTS igst_amount NUMERIC(12,2) DEFAULT 0`,
  ];
  for (const sql of alterStatements) {
    try { await pool.query(sql); } catch (_) { /* column may already exist */ }
  }
};
ensureColumns();

// GET all invoices
const getInvoices = async (req, res) => {
  try {
    let query = "SELECT * FROM invoices WHERE 1=1";
    let values = [];
    let paramIndex = 1;
    
    if (req.tenantId) {
      query += ` AND organization_id = $${paramIndex++}`;
      values.push(req.tenantId);
    }
    query += " ORDER BY created_at DESC";

    const result = await pool.query(query, values);
    res.json({ invoices: result.rows });
  } catch (err) {
    console.error("GET INVOICES ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// GET single invoice with items
const getInvoiceById = async (req, res) => {
  const { id } = req.params;
  try {
    let query = "SELECT * FROM invoices WHERE id = $1";
    let values = [id];
    let paramIndex = 2;
    if (req.tenantId) {
      query += ` AND organization_id = $${paramIndex++}`;
      values.push(req.tenantId);
    }

    const invoice = await pool.query(query, values);
    if (invoice.rows.length === 0) {
      return res.status(404).json({ message: "Invoice not found" });
    }
    const items = await pool.query(
      `SELECT ii.*,
              COALESCE(ii.item_name, i.name) AS item_name,
              COALESCE(ii.hsn_code,  i.hsn_code)  AS hsn_code,
              COALESCE(ii.unit,      i.unit)       AS unit
       FROM invoice_items ii
       LEFT JOIN items i ON ii.item_id = i.id
       WHERE ii.invoice_id = $1`,
      [id]
    );
    res.json({ invoice: invoice.rows[0], items: items.rows });
  } catch (err) {
    console.error("GET INVOICE ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// CREATE invoice
const createInvoice = async (req, res) => {
  const { customer_id, invoice_date, due_date, status, notes, terms, items, salesperson_id, project_id, supplier_state, place_of_supply, customer_gstin, gst_type } = req.body;

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const invNumber = "INV-" + Date.now();
    const invResult = await client.query(
      `INSERT INTO invoices (customer_id, user_id, invoice_number, invoice_date, due_date, status, notes, terms, total_amount, balance_due, salesperson_id, project_id, supplier_state, place_of_supply, customer_gstin, gst_type, organization_id)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,0,0,$9,$10,$11,$12,$13,$14,$15) RETURNING *`,
      [customer_id, req.user.id, invNumber, invoice_date || new Date(), due_date, status || "draft", notes, terms, salesperson_id || null, project_id || null, supplier_state || null, place_of_supply || null, customer_gstin || null, gst_type || null, req.tenantId || null]
    );
    const invoiceId = invResult.rows[0].id;

    let total = 0;
    if (Array.isArray(items)) {
      for (const item of items) {
        const qty = parseFloat(item.quantity) || 0;
        const rate = parseFloat(item.unit_price) || 0;
        const disc = parseFloat(item.discount) || 0;
        const discType = item.discount_type || "flat";
        const taxRate = parseFloat(item.tax_rate) || 0;

        let taxableValue = qty * rate;
        if (discType === "percent") {
          taxableValue -= taxableValue * (disc / 100);
        } else {
          taxableValue -= disc;
        }

        const cgstRate = parseFloat(item.cgst_rate) || 0;
        const cgstAmount = parseFloat(item.cgst_amount) || 0;
        const sgstRate = parseFloat(item.sgst_rate) || 0;
        const sgstAmount = parseFloat(item.sgst_amount) || 0;
        const igstRate = parseFloat(item.igst_rate) || 0;
        const igstAmount = parseFloat(item.igst_amount) || 0;

        let lineTotal = taxableValue + cgstAmount + sgstAmount + igstAmount;
        
        if (cgstRate === 0 && igstRate === 0 && taxRate > 0) {
           const taxAmt = taxableValue * (taxRate / 100);
           lineTotal = taxableValue + taxAmt;
        }

        await client.query(
          `INSERT INTO invoice_items (invoice_id, item_id, item_name, hsn_code, unit, description, quantity, unit_price, tax_rate, discount, discount_type, total, taxable_value, cgst_rate, cgst_amount, sgst_rate, sgst_amount, igst_rate, igst_amount)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19)`,
          [invoiceId, item.item_id || null, item.item_name || null, item.hsn_code || null, item.unit || null,
           item.description, item.quantity, item.unit_price, item.tax_rate, disc, discType, lineTotal,
           taxableValue, cgstRate, cgstAmount, sgstRate, sgstAmount, igstRate, igstAmount]
        );
        total += lineTotal;

        // Inventory processing
        if (item.item_id) {
          const itemCheck = await client.query(`SELECT is_inventory_tracked, stock_quantity, reorder_level, name, is_low_stock_alert_sent, organization_id FROM items WHERE id = $1`, [item.item_id]);
          if (itemCheck.rows.length > 0) {
            const itemData = itemCheck.rows[0];
            if (itemData.is_inventory_tracked) {
              if (itemData.stock_quantity < qty) {
                throw new Error(`Insufficient stock for item: ${itemData.name}. Available: ${itemData.stock_quantity}, Requested: ${qty}`);
              }
              const newStock = itemData.stock_quantity - qty;
              await client.query(`UPDATE items SET stock_quantity = $1 WHERE id = $2`, [newStock, item.item_id]);
              await client.query(
                `INSERT INTO inventory_movements 
                 (user_id, item_id, transaction_type, quantity_change, reference_type, reference_id, reference_number, entry_date, description, organization_id)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_DATE, $8, $9)`,
                [req.user.id, item.item_id, 'sale', -qty, 'invoice', invoiceId, invNumber, `Sale via Invoice ${invNumber}`, req.tenantId || null]
              );
              
              // Phase 2: Low-Stock Alert Check
              const reorderLevel = parseFloat(itemData.reorder_level) || 0;
              if (newStock <= reorderLevel && !itemData.is_low_stock_alert_sent) {
                // Set flag to true to debounce
                await client.query(`UPDATE items SET is_low_stock_alert_sent = TRUE WHERE id = $1`, [item.item_id]);
                
                // Fetch org users
                const orgId = itemData.organization_id || req.tenantId;
                if (orgId) {
                  const usersRes = await client.query(`SELECT email FROM users WHERE organization_id = $1`, [orgId]);
                  const emails = usersRes.rows.map(u => u.email).filter(Boolean);
                  if (emails.length > 0) {
                    const subject = `Low Stock Alert: ${itemData.name}`;
                    const text = `The stock quantity for ${itemData.name} has dropped to ${newStock} (Reorder Level: ${reorderLevel}). Please reorder soon.`;
                    for (const email of emails) {
                      // Fire and forget (don't await to avoid blocking invoice creation if SMTP fails)
                      sendEmail(email, subject, text).catch(e => console.error("Low stock email failed", e));
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    await client.query("UPDATE invoices SET total_amount = $1, balance_due = $2 WHERE id = $3", [total, total, invoiceId]);

    await client.query("COMMIT");
    res.json({ message: "Invoice created", invoice: { ...invResult.rows[0], total_amount: total, balance_due: total } });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("CREATE INVOICE ERROR:", err);
    res.status(500).json({ message: err.message || "Server error" });
  } finally {
    client.release();
  }
};

// UPDATE invoice (partial)
const updateInvoice = async (req, res) => {
  const { id } = req.params;
  const updates = req.body;
  delete updates.id; delete updates.user_id; delete updates.created_at; delete updates.updated_at;
  const { items, ...fields } = updates;

  const client = await pool.connect();
  try {
    let checkQuery = `SELECT invoice_date FROM invoices WHERE id = $1`;
    let checkVals = [id];
    let pIdx = 2;
    if (req.tenantId) {
      checkQuery += ` AND organization_id = $${pIdx++}`;
      checkVals.push(req.tenantId);
    }
    const existing = await client.query(checkQuery, checkVals);
    if (existing.rows.length === 0) return res.status(404).json({ message: "Invoice not found" });
    
    await checkTransactionLock(req.user.id, "Invoices", existing.rows[0].invoice_date);
    if (updates.invoice_date) await checkTransactionLock(req.user.id, "Invoices", updates.invoice_date);

    await client.query("BEGIN");

    const setColumns = [];
    const values = [];
    let idx = 1;
    for (const [key, value] of Object.entries(fields)) {
      if (value !== undefined) {
        setColumns.push(`${key} = $${idx}`);
        values.push(value);
        idx++;
      }
    }
    if (setColumns.length > 0) {
      setColumns.push("updated_at = CURRENT_TIMESTAMP");
      let query = `UPDATE invoices SET ${setColumns.join(", ")} WHERE id = $${idx}`;
      values.push(id);
      idx++;
      if (req.tenantId) {
        query += ` AND organization_id = $${idx++}`;
        values.push(req.tenantId);
      }
      query += ` RETURNING *`;
      const result = await client.query(query, values);
      if (result.rows.length === 0) {
        await client.query("ROLLBACK");
        return res.status(404).json({ message: "Invoice not found" });
      }
    }

    if (items !== undefined) {
      await client.query("DELETE FROM invoice_items WHERE invoice_id = $1", [id]);
      let total = 0;
      if (Array.isArray(items)) {
        for (const item of items) {
          const qty = parseFloat(item.quantity) || 0;
          const rate = parseFloat(item.unit_price) || 0;
          const disc = parseFloat(item.discount) || 0;
          const discType = item.discount_type || "flat";
          const taxRate = parseFloat(item.tax_rate) || 0;

          let taxableValue = qty * rate;
          if (discType === "percent") {
            taxableValue -= taxableValue * (disc / 100);
          } else {
            taxableValue -= disc;
          }

          const cgstRate = parseFloat(item.cgst_rate) || 0;
          const cgstAmount = parseFloat(item.cgst_amount) || 0;
          const sgstRate = parseFloat(item.sgst_rate) || 0;
          const sgstAmount = parseFloat(item.sgst_amount) || 0;
          const igstRate = parseFloat(item.igst_rate) || 0;
          const igstAmount = parseFloat(item.igst_amount) || 0;

          let lineTotal = taxableValue + cgstAmount + sgstAmount + igstAmount;
          
          if (cgstRate === 0 && igstRate === 0 && taxRate > 0) {
             const taxAmt = taxableValue * (taxRate / 100);
             lineTotal = taxableValue + taxAmt;
          }

          await client.query(
            `INSERT INTO invoice_items (invoice_id, item_id, item_name, hsn_code, unit, description, quantity, unit_price, tax_rate, discount, discount_type, total, taxable_value, cgst_rate, cgst_amount, sgst_rate, sgst_amount, igst_rate, igst_amount)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19)`,
            [id, item.item_id || null, item.item_name || null, item.hsn_code || null, item.unit || null,
             item.description, item.quantity, item.unit_price, item.tax_rate, disc, discType, lineTotal,
             taxableValue, cgstRate, cgstAmount, sgstRate, sgstAmount, igstRate, igstAmount]
          );
          total += lineTotal;
        }
      }
      await client.query("UPDATE invoices SET total_amount = $1, balance_due = $2 WHERE id = $3", [total, total, id]);
    }

    await client.query("COMMIT");
    res.json({ message: "Invoice updated" });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("UPDATE INVOICE ERROR:", err);
    res.status(err.message.includes("locked") ? 403 : 500).json({ message: err.message || "Server error" });
  } finally {
    client.release();
  }
};

// DELETE invoice
const deleteInvoice = async (req, res) => {
  const { id } = req.params;
  try {
    let checkQuery = `SELECT invoice_date FROM invoices WHERE id = $1`;
    let checkVals = [id];
    let pIdx = 2;
    if (req.tenantId) {
      checkQuery += ` AND organization_id = $${pIdx++}`;
      checkVals.push(req.tenantId);
    }
    const existing = await pool.query(checkQuery, checkVals);
    if (existing.rows.length === 0) return res.status(404).json({ message: "Invoice not found" });
    await checkTransactionLock(req.user.id, "Invoices", existing.rows[0].invoice_date);

    let query = "DELETE FROM invoices WHERE id = $1";
    let values = [id];
    let paramIndex = 2;
    if (req.tenantId) {
      query += ` AND organization_id = $${paramIndex++}`;
      values.push(req.tenantId);
    }
    query += " RETURNING *";

    const result = await pool.query(query, values);
    if (result.rows.length === 0) return res.status(404).json({ message: "Invoice not found" });
    res.json({ message: "Invoice deleted" });
  } catch (err) {
    console.error("DELETE INVOICE ERROR:", err);
    res.status(err.message.includes("locked") ? 403 : 500).json({ message: err.message || "Server error" });
  }
};

module.exports = { getInvoices, getInvoiceById, createInvoice, updateInvoice, deleteInvoice };