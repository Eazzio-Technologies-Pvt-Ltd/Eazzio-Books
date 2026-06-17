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

async function fixOrganizations() {
  try {
    await pool.query(`ALTER TABLE organizations ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true`);
    await pool.query(`ALTER TABLE organizations ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP`);
    console.log("Added missing columns to organizations table.");
    process.exit(0);
  } catch(e) {
    console.error(e);
    process.exit(1);
  }
}

fixOrganizations();
