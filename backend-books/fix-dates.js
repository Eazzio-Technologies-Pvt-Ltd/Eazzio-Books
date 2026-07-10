require('dotenv').config();
const pool = require('./src/config/db');

async function fix() {
  try {
    await pool.query("UPDATE invoice_payment_schedules SET due_date = '2026-09-09T18:30:00.000Z' WHERE id = 14");
    await pool.query("UPDATE invoice_payment_schedules SET due_date = '2026-10-09T18:30:00.000Z' WHERE id = 15");
    await pool.query("UPDATE invoice_payment_schedules SET due_date = '2026-11-09T18:30:00.000Z' WHERE id = 16");
    await pool.query("UPDATE invoice_payment_schedules SET due_date = '2026-12-09T18:30:00.000Z' WHERE id = 17");
    console.log('Fixed dates for invoice 283');
  } catch (err) {
    console.error(err);
  } finally {
    pool.end();
  }
}
fix();
