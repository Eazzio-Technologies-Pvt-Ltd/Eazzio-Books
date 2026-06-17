require('dotenv').config();
const pool = require('./src/config/db');
pool.query(`
  SELECT conname, pg_get_constraintdef(c.oid)
  FROM pg_constraint c
  JOIN pg_namespace n ON n.oid = c.connamespace
  WHERE conrelid = 'invoices'::regclass;
`).then(res => console.log(res.rows)).catch(console.error).finally(() => pool.end());
