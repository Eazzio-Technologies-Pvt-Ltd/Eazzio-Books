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

pool.query(`
  SELECT
    o.id,
    o.name,
    o.created_at,
    o.is_active,
    u.email  AS admin_email,
    u.status AS admin_status,
    (SELECT COUNT(*) FROM users WHERE organization_id = o.id) AS member_count
  FROM organizations o
  LEFT JOIN users u ON u.organization_id = o.id AND LOWER(u.role) = 'admin'
  ORDER BY o.created_at DESC
`).then(res => {
  console.log('SUCCESS:');
  console.log(res.rows);
  process.exit(0);
}).catch(err => {
  console.error('FAILED:');
  console.error(err);
  process.exit(1);
});
