require("dotenv").config();
const dns = require('dns');
const originalLookup = dns.lookup;
dns.lookup = function(domain, options, callback) {
  if (typeof options === 'function') {
    callback = options;
    options = { family: 4 };
  } else if (typeof options === 'object') {
    options.family = 4;
  } else {
    options = { family: 4, hints: options };
  }
  return originalLookup(domain, options, callback);
};

const pool = require('./src/config/db');

async function testDuplicate() {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const orgResult = await client.query(
      `INSERT INTO organizations (name, is_active, created_at) VALUES ($1, true, CURRENT_TIMESTAMP) RETURNING *`,
      ['Test Duplicate']
    );
    const newOrg = orgResult.rows[0];

    console.log("Attempting to insert demo@tinplate.com...");
    const userResult = await client.query(
      `INSERT INTO users (email, password, role, organization_id, status) VALUES ($1, $2, 'Admin', $3, 'active') RETURNING id`,
      ['demo@tinplate.com', 'hashedpass', newOrg.id]
    );

    await client.query("ROLLBACK");
    console.log("SUCCESS");
  } catch (err) {
    await client.query("ROLLBACK");
    console.log("FAILED WITH ERROR CODE:", err.code);
    console.log("ERROR MESSAGE:", err.message);
  } finally {
    client.release();
    process.exit(0);
  }
}

testDuplicate();
