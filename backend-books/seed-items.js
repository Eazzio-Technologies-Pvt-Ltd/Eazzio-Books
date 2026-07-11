require('dotenv').config();
const pool = require('./src/config/db');

async function seedItems() {
  const email = 'demo@tinplate.com';
  
  try {
    const userRes = await pool.query('SELECT id, organization_id FROM users WHERE email = $1', [email]);
    if (userRes.rows.length === 0) {
      console.log('User not found');
      process.exit(1);
    }
    
    const { id: userId, organization_id: orgId } = userRes.rows[0];
    console.log(`Found User: ${userId}, Org: ${orgId}`);
    
    // Seed items
    // Item 1: Low Stock Item
    // Item 2: High Stock Item
    // Item 3: Service Item (no inventory)
    
    const items = [
      {
        name: 'Logitech G Pro Wireless Mouse',
        sku: 'LOGI-GPW-001',
        item_type: 'Goods',
        selling_price: 12000,
        cost_price: 8500,
        is_inventory_tracked: true,
        opening_stock: 2,
        opening_stock_rate: 8500,
        reorder_level: 5,
        stock_quantity: 2
      },
      {
        name: 'Keychron K2 Mechanical Keyboard',
        sku: 'KEYC-K2-002',
        item_type: 'Goods',
        selling_price: 8500,
        cost_price: 6000,
        is_inventory_tracked: true,
        opening_stock: 15,
        opening_stock_rate: 6000,
        reorder_level: 5,
        stock_quantity: 15
      },
      {
        name: 'Dell UltraSharp 27 Monitor',
        sku: 'DELL-U2720Q',
        item_type: 'Goods',
        selling_price: 45000,
        cost_price: 38000,
        is_inventory_tracked: true,
        opening_stock: 1,
        opening_stock_rate: 38000,
        reorder_level: 3,
        stock_quantity: 1
      },
      {
        name: 'Computer Setup Service',
        sku: 'SRV-SETUP-01',
        item_type: 'Service',
        selling_price: 1500,
        cost_price: 0,
        is_inventory_tracked: false,
        opening_stock: 0,
        opening_stock_rate: 0,
        reorder_level: 0,
        stock_quantity: 0
      }
    ];

    for (const item of items) {
      const res = await pool.query(
        `INSERT INTO items
          (user_id, name, sku, item_type, selling_price, cost_price, 
           is_inventory_tracked, opening_stock, opening_stock_rate,
           reorder_level, stock_quantity, organization_id, current_valuation_rate)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
         RETURNING *`,
        [
          userId, item.name, item.sku, item.item_type, item.selling_price, item.cost_price,
          item.is_inventory_tracked, item.opening_stock, item.opening_stock_rate,
          item.reorder_level, item.stock_quantity, orgId, item.is_inventory_tracked ? item.opening_stock_rate : 0
        ]
      );
      
      const newItem = res.rows[0];
      console.log(`Inserted item: ${newItem.name}`);

      if (item.is_inventory_tracked && item.opening_stock > 0) {
        await pool.query(
          `INSERT INTO inventory_movements 
           (user_id, item_id, transaction_type, quantity_change, entry_date, description)
           VALUES ($1, $2, $3, $4, CURRENT_DATE, $5)`,
          [userId, newItem.id, "initial_stock", item.opening_stock, "Initial stock added during item creation"]
        );
      }
    }
    
    console.log('Seeding complete.');
  } catch (e) {
    console.error('Error seeding items:', e);
  } finally {
    pool.end();
  }
}

seedItems();
