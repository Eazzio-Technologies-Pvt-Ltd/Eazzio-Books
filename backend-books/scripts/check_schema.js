const { Pool } = require('pg');
require('dotenv').config();
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
async function run() {
  const orgs = await pool.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'organizations'");
  console.log('organizations:', orgs.rows);
  const users = await pool.query("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'users'");
  console.log('users:', users.rows);
  process.exit(0);
}
run();
