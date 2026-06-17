const { Pool } = require('pg');

// Use SSL only when DATABASE_URL indicates it (e.g. Neon cloud uses sslmode=require)
const sslConfig = process.env.DATABASE_URL && process.env.DATABASE_URL.includes('sslmode=require')
  ? { rejectUnauthorized: false }
  : false;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: sslConfig,
  max: 3, // Limit concurrent connections so Neon Free Tier doesn't get overwhelmed
  connectionTimeoutMillis: 15000, // Give Neon up to 15 seconds to wake up
});

module.exports = pool;