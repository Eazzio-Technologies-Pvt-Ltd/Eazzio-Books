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

async function checkUserOrgs() {
  try {
    const result = await pool.query('SELECT id, email, organization_id, role FROM users');
    console.table(result.rows);
    process.exit(0);
  } catch(e) {
    console.error(e);
    process.exit(1);
  }
}

checkUserOrgs();
