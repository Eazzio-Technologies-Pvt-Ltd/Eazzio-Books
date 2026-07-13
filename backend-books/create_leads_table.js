require('dotenv').config();
const pool = require('./src/config/db');

async function createLeadsTable() {
  const query = `
    CREATE TABLE IF NOT EXISTS leads (
      id SERIAL PRIMARY KEY,
      business_size VARCHAR(50),
      current_tool VARCHAR(100),
      key_need VARCHAR(100),
      recommended_plan VARCHAR(50),
      email VARCHAR(255),
      source VARCHAR(50) DEFAULT 'chatbot',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `;
  try {
    await pool.query(query);
    console.log("leads table created successfully.");
  } catch (err) {
    console.error("Error creating leads table:", err);
  } finally {
    pool.end();
  }
}

createLeadsTable();
