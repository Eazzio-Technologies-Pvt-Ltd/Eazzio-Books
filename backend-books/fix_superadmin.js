require('dotenv').config();
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

async function fixSuperAdmin() {
  try {
    await pool.query("UPDATE users SET organization_id = NULL WHERE email = 'superadmin@test.com'");
    console.log("Fixed Super Admin organization_id");
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

fixSuperAdmin();
