require('dotenv').config();
const pool = require('./src/config/db');

async function testInsert() {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    
    // mimic frontend
    const invNumber = "INV-TEST-" + Date.now();
    const custRes = await client.query("SELECT id, user_id FROM customers LIMIT 1");
    if(custRes.rows.length === 0) return;
    const cid = custRes.rows[0].id;
    const uid = custRes.rows[0].user_id;

    const invResult = await client.query(
      `INSERT INTO invoices (customer_id, user_id, invoice_number, invoice_date, due_date, status, notes, terms, total_amount, balance_due, salesperson_id, project_id, supplier_state, place_of_supply, customer_gstin, gst_type)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,0,0,$9,$10,$11,$12,$13,$14) RETURNING *`,
      [cid, uid, invNumber, new Date(), null, "draft", "notes", "terms", null, null, null, null, null, null]
    );
    const invoiceId = invResult.rows[0].id;

    await client.query(
      `INSERT INTO invoice_items (invoice_id, item_id, item_name, hsn_code, unit, description, quantity, unit_price, tax_rate, discount, discount_type, total, taxable_value, cgst_rate, cgst_amount, sgst_rate, sgst_amount, igst_rate, igst_amount)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19)`,
      [invoiceId, null, null, null, null,
       "", 1, 0, 0, 0, "flat", 0,
       0, 0, 0, 0, 0, 0, 0]
    );
    console.log("Item inserted!");

    await client.query("ROLLBACK");
  } catch (err) {
    console.error("ERROR:", err.message);
    await client.query("ROLLBACK");
  } finally {
    client.release();
    pool.end();
  }
}
testInsert();
