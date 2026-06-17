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

async function testOnboard() {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    console.log("Creating org...");
    const orgResult = await client.query(
      `INSERT INTO organizations (name, is_active, created_at) VALUES ($1, true, CURRENT_TIMESTAMP) RETURNING *`,
      ['Test Org Script']
    );
    const newOrg = orgResult.rows[0];
    console.log("Created org:", newOrg.id);

    console.log("Creating user...");
    const userResult = await client.query(
      `INSERT INTO users (email, password, role, organization_id, status) VALUES ($1, $2, 'Admin', $3, 'active') RETURNING id`,
      ['new_user_script@test.com', 'hashedpass', newOrg.id]
    );
    console.log("Created user:", userResult.rows[0].id);

    await client.query("ROLLBACK"); // rollback so we don't pollute DB
    console.log("SUCCESS");
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("FAILED:", err);
  } finally {
    client.release();
    process.exit(0);
  }
}

testOnboard();
