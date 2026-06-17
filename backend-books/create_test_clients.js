require("dotenv").config();
const dns = require('dns');
const bcrypt = require('bcrypt');
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

async function createTestClients() {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const hashedPassword = await bcrypt.hash('password123', 10);

    // Client 1
    const org1 = await client.query(
      `INSERT INTO organizations (name, is_active, created_at) VALUES ($1, true, CURRENT_TIMESTAMP) RETURNING id`,
      ['Stark Industries']
    );
    await client.query(
      `INSERT INTO users (email, password, role, organization_id, status) VALUES ($1, $2, 'Admin', $3, 'active')`,
      ['tony@stark.com', hashedPassword, org1.rows[0].id]
    );

    // Client 2
    const org2 = await client.query(
      `INSERT INTO organizations (name, is_active, created_at) VALUES ($1, true, CURRENT_TIMESTAMP) RETURNING id`,
      ['Wayne Enterprises']
    );
    await client.query(
      `INSERT INTO users (email, password, role, organization_id, status) VALUES ($1, $2, 'Admin', $3, 'active')`,
      ['bruce@wayne.com', hashedPassword, org2.rows[0].id]
    );

    await client.query("COMMIT");
    console.log("Successfully created Stark Industries and Wayne Enterprises!");
  } catch (err) {
    await client.query("ROLLBACK");
    console.error(err);
  } finally {
    client.release();
    process.exit(0);
  }
}

createTestClients();
