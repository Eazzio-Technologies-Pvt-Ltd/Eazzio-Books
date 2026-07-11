require('dotenv').config();
const pool = require('./src/config/db');

pool.query('UPDATE items SET organization_id = 26, is_active = true')
  .then(res => {
    console.log(`Updated ${res.rowCount} items`);
    pool.end();
  })
  .catch(err => {
    console.error(err);
    pool.end();
  });
