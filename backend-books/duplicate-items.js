require('dotenv').config();
const pool = require('./src/config/db');

async function duplicateItems() {
  const client = await pool.connect();
  try {
    const res = await client.query('SELECT * FROM items WHERE organization_id = 26');
    const items = res.rows;
    console.log(`Found ${items.length} items in org 26. Copying to org 14 and 1...`);
    
    let count = 0;
    for (const item of items) {
      for (const targetOrg of [1, 14]) {
        await client.query(
          `INSERT INTO items (
            user_id, name, sku, hsn_code, tax_rate, buying_price, selling_price, stock_quantity, low_stock_alert, 
            item_type, unit, cost_price, description, sales_account, purchase_account, image_url, 
            preferred_vendor_id, purchase_description, is_deleted, is_active, reorder_level, is_inventory_tracked, 
            inventory_account, opening_stock, opening_stock_rate, organization_id, is_low_stock_alert_sent, current_valuation_rate
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28)`,
          [
            item.user_id, item.name, item.sku, item.hsn_code, item.tax_rate, item.buying_price, item.selling_price, item.stock_quantity, item.low_stock_alert,
            item.item_type, item.unit, item.cost_price, item.description, item.sales_account, item.purchase_account, item.image_url,
            item.preferred_vendor_id, item.purchase_description, item.is_deleted, item.is_active, item.reorder_level, item.is_inventory_tracked,
            item.inventory_account, item.opening_stock, item.opening_stock_rate, targetOrg, item.is_low_stock_alert_sent, item.current_valuation_rate
          ]
        );
        count++;
      }
    }
    console.log(`Successfully duplicated ${count} items.`);
  } catch (err) {
    console.error(err);
  } finally {
    client.release();
    pool.end();
  }
}

duplicateItems();
