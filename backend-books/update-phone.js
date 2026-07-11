require('dotenv').config();

const dns = require('dns');
const originalLookup = dns.lookup;
dns.lookup = function (domain, options, callback) {
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

async function updatePhone() {
  try {
    const res = await pool.query(
      "UPDATE customers SET mobile = $1, phone = $1 WHERE display_name = $2 RETURNING *",
      ['9631628912', 'Sagar Kumar']
    );
    console.log("Updated customers:", res.rows.length);
  } catch (err) {
    console.error(err);
  } finally {
    pool.end();
  }
}

updatePhone();
