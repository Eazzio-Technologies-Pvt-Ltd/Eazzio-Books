require('dotenv').config();
const pool = require('./src/config/db');

async function addFeatureInterestColumn() {
  const query = `ALTER TABLE leads ADD COLUMN IF NOT EXISTS feature_interest VARCHAR(100);`;
  try {
    await pool.query(query);
    console.log("feature_interest column added successfully.");
  } catch (err) {
    console.error("Error altering leads table:", err);
  } finally {
    pool.end();
  }
}

addFeatureInterestColumn();
