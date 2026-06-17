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

async function fixUserOrgs() {
  try {
    // 1. Make sure Default Test Corp exists (ID 1)
    const orgCheck = await pool.query('SELECT id FROM organizations WHERE id = 1');
    if (orgCheck.rows.length === 0) {
      await pool.query('INSERT INTO organizations (id, name, is_active) VALUES (1, $1, true)', ['Default Test Corp']);
      console.log('Created Default Test Corp (ID 1)');
    }

    // 2. Assign existing users to ID 1 where organization_id is NULL
    const result = await pool.query('UPDATE users SET organization_id = 1 WHERE organization_id IS NULL RETURNING email');
    console.log(`Assigned ${result.rowCount} users to organization_id 1:`, result.rows.map(r => r.email));

    process.exit(0);
  } catch(e) {
    console.error(e);
    process.exit(1);
  }
}

fixUserOrgs();
