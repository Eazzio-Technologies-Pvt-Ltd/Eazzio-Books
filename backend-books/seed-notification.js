require('dotenv').config();
const pool = require('./src/config/db');

async function seedNotification() {
  const client = await pool.connect();
  try {
    const invNumber = 'INV-1782802797341';
    
    // Check if customer exists
    let res = await client.query('SELECT id FROM customers WHERE display_name = $1 AND organization_id = 26', ['Test Customer']);
    let customerId;
    if (res.rows.length === 0) {
      res = await client.query(
        "INSERT INTO customers (user_id, display_name, email, organization_id) VALUES (1, $1, $2, 26) RETURNING id", 
        ['Test Customer', 'test@test.com']
      );
    }
    
    // Ensure customer is in orgs 1, 14, 26
    for (const orgId of [1, 14]) {
      let chk = await client.query('SELECT id FROM customers WHERE display_name = $1 AND organization_id = $2', ['Test Customer', orgId]);
      if (chk.rows.length === 0) {
        await client.query("INSERT INTO customers (user_id, display_name, email, organization_id) VALUES (1, $1, $2, $3)", ['Test Customer', 'test@test.com', orgId]);
      }
    }
    
    for (const orgId of [1, 14, 26]) {
      const cRes = await client.query('SELECT id FROM customers WHERE display_name = $1 AND organization_id = $2', ['Test Customer', orgId]);
      const cId = cRes.rows[0].id;

      // Check if invoice exists
      let invRes = await client.query('SELECT id FROM invoices WHERE invoice_number = $1 AND organization_id = $2', [invNumber, orgId]);
      let invoiceId;
      if (invRes.rows.length === 0) {
        invRes = await client.query(
          "INSERT INTO invoices (invoice_number, user_id, customer_id, invoice_date, due_date, total_amount, balance_due, status, organization_id) VALUES ($1, 1, $2, '2026-06-01', '2026-06-30', 50000, 50000, 'Sent', $3) RETURNING id",
          [invNumber, cId, orgId]
        );
      }
      invoiceId = invRes.rows[0].id;
      
      // Check if payment schedule exists
      let schRes = await client.query('SELECT id FROM invoice_payment_schedules WHERE invoice_id = $1', [invoiceId]);
      if (schRes.rows.length === 0) {
        await client.query(
          "INSERT INTO invoice_payment_schedules (invoice_id, customer_id, due_date, due_amount, paid_amount, balance_amount, status, organization_id) VALUES ($1, $2, '2026-06-30', 50000, 0, 50000, 'pending', $3)",
          [invoiceId, cId, orgId]
        );
        console.log(`Seeded pending installment in org ${orgId}!`);
      } else {
        console.log(`Installment already exists in org ${orgId}!`);
      }
    }
    
  } catch (err) {
    console.error(err);
  } finally {
    client.release();
    pool.end();
  }
}

seedNotification();
