const pool = require("../config/db");

// ---- Ensure payments table exists (safe to re-run) ----
const ensurePaymentsTable = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS payments (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL,
        invoice_id INTEGER NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
        customer_id INTEGER,
        amount NUMERIC(12,2) NOT NULL DEFAULT 0,
        payment_date DATE DEFAULT CURRENT_DATE,
        payment_mode VARCHAR(50),
        reference VARCHAR(100),
        notes TEXT,
        status VARCHAR(50) DEFAULT 'received',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // In case the table already exists, try to add customer_id if missing
    try {
      await pool.query(`ALTER TABLE payments ADD COLUMN IF NOT EXISTS customer_id INTEGER`);
      await pool.query(`ALTER TABLE payments ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'received'`);
      await pool.query(`ALTER TABLE payments ADD COLUMN IF NOT EXISTS deposit_to VARCHAR(100)`);
    } catch (_) {}
  } catch (err) {
    console.error("ensurePaymentsTable error:", err);
  }
};
ensurePaymentsTable();

// Record a payment against an invoice
const recordPayment = async (req, res) => {
  const { id: invoiceId } = req.params;
  const { amount, payment_date, payment_mode, reference, notes, customer_id, transfer_shortfall, installment_months, deposit_to, splits } = req.body;
  
  const paymentSplits = splits && Array.isArray(splits) && splits.length > 0 ? splits : [{
    amount: amount,
    payment_mode: payment_mode || "cash",
    deposit_to: deposit_to || null,
    reference: reference || null
  }];
  
  const totalAmountToPay = paymentSplits.reduce((sum, s) => sum + parseFloat(s.amount || 0), 0);

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    // We can infer customer_id from invoice if not provided, but frontend will provide it.
    let finalCustomerId = customer_id;
    const invCheck = await client.query("SELECT customer_id, balance_due FROM invoices WHERE id = $1 AND user_id = $2", [invoiceId, req.user.id]);
    
    if (invCheck.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({ message: "Invoice not found" });
    }

    if (!finalCustomerId) {
      finalCustomerId = invCheck.rows[0].customer_id;
    }

    const currentBalance = parseFloat(invCheck.rows[0].balance_due);
    if (totalAmountToPay > currentBalance) {
      await client.query("ROLLBACK");
      return res.status(400).json({ message: `Payment amount (₹${totalAmountToPay}) exceeds remaining balance (₹${currentBalance})` });
    }

    // Insert payment records for each split
    const paymentRecords = [];
    for (const split of paymentSplits) {
      if (parseFloat(split.amount) > 0) {
        const pRes = await client.query(
          `INSERT INTO payments (invoice_id, user_id, customer_id, amount, payment_date, payment_mode, deposit_to, reference, notes, organization_id)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING *`,
          [invoiceId, req.user.id, finalCustomerId, split.amount, payment_date || new Date(), split.payment_mode || "cash", split.deposit_to || null, split.reference || reference, notes, req.tenantId]
        );
        paymentRecords.push(pRes.rows[0]);
      }
    }

    // Update invoice balance_due
    const invResult = await client.query(
      `UPDATE invoices
       SET balance_due = balance_due - $1, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2 AND user_id = $3
       RETURNING balance_due, total_amount`,
      [totalAmountToPay, invoiceId, req.user.id]
    );

    if (invResult.rows.length === 0) {
      await client.query("ROLLBACK");
      return res.status(404).json({ message: "Invoice not found" });
    }

    const newBalanceDue = parseFloat(invResult.rows[0].balance_due);
    const totalAmount = parseFloat(invResult.rows[0].total_amount);

    // Auto-update status
    let newStatus = 'partially_paid';
    if (newBalanceDue <= 0) {
      newStatus = 'paid';
    }
    
    // In case overpayment (should be prevented by frontend, but safeguard here)
    const finalBalance = newBalanceDue <= 0 ? 0 : newBalanceDue;

    await client.query(
      `UPDATE invoices SET status = $1, balance_due = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3`,
      [newStatus, finalBalance, invoiceId]
    );

    // Update payment schedules
    let remainingPayment = totalAmountToPay;
    if (remainingPayment > 0) {
      const schedulesRes = await client.query(
        `SELECT id, balance_amount, paid_amount, due_amount, due_date, organization_id, customer_id FROM invoice_payment_schedules 
         WHERE invoice_id = $1 AND status != 'paid' 
         ORDER BY due_date ASC`,
        [invoiceId]
      );
      
      let idx = 0;
      
      if (schedulesRes.rows.length === 0 && remainingPayment > 0 && newBalanceDue > 0) {
        const invoiceData = await client.query(`SELECT customer_id, organization_id FROM invoices WHERE id = $1`, [invoiceId]);
        const invInfo = invoiceData.rows[0];
        const currDate = new Date(payment_date || new Date());
        
        if (installment_months && installment_months > 0) {
          await client.query(`INSERT INTO invoice_payment_schedules (organization_id, invoice_id, customer_id, due_date, due_amount, paid_amount, balance_amount, status) VALUES ($1, $2, $3, $4, $5, $5, 0, 'paid')`, [invInfo.organization_id, invoiceId, invInfo.customer_id, currDate, remainingPayment]);
          
          const monthlyAmount = newBalanceDue / installment_months;
          for (let i = 1; i <= installment_months; i++) {
            const nextDate = new Date(currDate);
            nextDate.setMonth(nextDate.getMonth() + i);
            let iterAmount = monthlyAmount;
            if (i === installment_months) {
              iterAmount = newBalanceDue - (Number(monthlyAmount.toFixed(2)) * (installment_months - 1));
            }
            await client.query(`INSERT INTO invoice_payment_schedules (organization_id, invoice_id, customer_id, due_date, due_amount, paid_amount, balance_amount, status) VALUES ($1, $2, $3, $4, $5, 0, $5, 'pending')`, [invInfo.organization_id, invoiceId, invInfo.customer_id, nextDate, iterAmount]);
          }
          remainingPayment = 0;
        } else if (transfer_shortfall) {
          await client.query(`INSERT INTO invoice_payment_schedules (organization_id, invoice_id, customer_id, due_date, due_amount, paid_amount, balance_amount, status) VALUES ($1, $2, $3, $4, $5, $5, 0, 'paid')`, [invInfo.organization_id, invoiceId, invInfo.customer_id, currDate, remainingPayment]);
          
          const nextDate = new Date(currDate);
          nextDate.setMonth(nextDate.getMonth() + 1);
          await client.query(`INSERT INTO invoice_payment_schedules (organization_id, invoice_id, customer_id, due_date, due_amount, paid_amount, balance_amount, status) VALUES ($1, $2, $3, $4, $5, 0, $5, 'pending')`, [invInfo.organization_id, invoiceId, invInfo.customer_id, nextDate, newBalanceDue]);
          
          remainingPayment = 0;
        }
      }

      for (const sch of schedulesRes.rows) {
        if (remainingPayment <= 0) break;
        
        let schBalance = parseFloat(sch.balance_amount);
        let schPaid = parseFloat(sch.paid_amount);
        let schDue = parseFloat(sch.due_amount);
        
        const appliedAmt = Math.min(remainingPayment, schBalance);
        schBalance -= appliedAmt;
        schPaid += appliedAmt;
        remainingPayment -= appliedAmt;
        
        let schStatus = 'partially_paid';
        if (schBalance <= 0) schStatus = 'paid';
        
        if (idx === 0 && transfer_shortfall && schBalance > 0 && remainingPayment <= 0) {
           const shortfall = schBalance;
           schDue -= shortfall;
           schBalance = 0;
           schStatus = 'paid';
           
           const nextSch = schedulesRes.rows[1];
           if (nextSch) {
             await client.query(`UPDATE invoice_payment_schedules SET due_amount = due_amount + $1, balance_amount = balance_amount + $1 WHERE id = $2`, [shortfall, nextSch.id]);
             nextSch.due_amount = parseFloat(nextSch.due_amount) + shortfall;
             nextSch.balance_amount = parseFloat(nextSch.balance_amount) + shortfall;
           } else {
             const currDate = new Date(sch.due_date);
             currDate.setMonth(currDate.getMonth() + 1);
             await client.query(`INSERT INTO invoice_payment_schedules (organization_id, invoice_id, customer_id, due_date, due_amount, paid_amount, balance_amount, status) VALUES ($1, $2, $3, $4, $5, 0, $5, 'pending')`, [sch.organization_id, invoiceId, sch.customer_id, currDate, shortfall]);
           }
        }
        
        await client.query(
          `UPDATE invoice_payment_schedules 
           SET due_amount = $1, paid_amount = $2, balance_amount = $3, status = $4, updated_at = CURRENT_TIMESTAMP 
           WHERE id = $5`,
          [schDue, schPaid, schBalance, schStatus, sch.id]
        );
        idx++;
      }
    }

    // Return the updated schedules for frontend state update
    const updatedSchRes = await client.query(`SELECT * FROM invoice_payment_schedules WHERE invoice_id = $1 ORDER BY due_date ASC`, [invoiceId]);

    await client.query("COMMIT");
    res.json({ payment: paymentRecords[0], payments: paymentRecords, newBalanceDue: finalBalance, updated_schedules: updatedSchRes.rows });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("RECORD PAYMENT ERROR:", err);
    res.status(500).json({ message: "Failed to record payment" });
  } finally {
    client.release();
  }
};

// GET payments for an invoice
const getPayments = async (req, res) => {
  const { id: invoiceId } = req.params;
  try {
    const result = await pool.query(
      "SELECT * FROM payments WHERE invoice_id = $1 AND user_id = $2" + (req.tenantId ? " AND organization_id = $3" : "") + " ORDER BY payment_date DESC",
      req.tenantId ? [invoiceId, req.user.id, req.tenantId] : [invoiceId, req.user.id]
    );
    res.json({ payments: result.rows });
  } catch (err) {
    console.error("GET PAYMENTS ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// GET all payments
const getAllPayments = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT p.*, c.display_name AS customer_name, i.invoice_number 
       FROM payments p
       LEFT JOIN customers c ON p.customer_id = c.id
       LEFT JOIN invoices i ON p.invoice_id = i.id
       WHERE p.user_id = $1` + (req.tenantId ? " AND p.organization_id = $2" : "") + `
       ORDER BY p.payment_date DESC`,
      req.tenantId ? [req.user.id, req.tenantId] : [req.user.id]
    );
    res.json({ payments: result.rows });
  } catch (err) {
    console.error("GET ALL PAYMENTS ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// GET payment by ID
const getPaymentById = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      `SELECT p.*, c.display_name AS customer_name, c.email AS customer_email,
       (SELECT CONCAT_WS(', ', ca.address_line1, ca.address_line2, ca.city, ca.state, ca.country, ca.pin_code) 
        FROM customer_addresses ca 
        WHERE ca.customer_id = c.id AND ca.type = 'billing' LIMIT 1) AS billing_address,
       i.invoice_number 
       FROM payments p
       LEFT JOIN customers c ON p.customer_id = c.id
       LEFT JOIN invoices i ON p.invoice_id = i.id
       WHERE p.id = $1 AND p.user_id = $2` + (req.tenantId ? " AND p.organization_id = $3" : ""),
      req.tenantId ? [id, req.user.id, req.tenantId] : [id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: "Payment not found" });
    }
    res.json({ payment: result.rows[0] });
  } catch (err) {
    console.error("GET PAYMENT ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

// GET deposit balances for Dashboard
const getDepositBalances = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT deposit_to, SUM(amount) as total_balance 
       FROM payments 
       WHERE user_id = $1 AND deposit_to IN ('Petty Cash', 'Undeposited Funds')` + (req.tenantId ? " AND organization_id = $2" : "") + ` 
       GROUP BY deposit_to`,
      req.tenantId ? [req.user.id, req.tenantId] : [req.user.id]
    );
    
    let balances = { petty_cash: 0, undeposited_funds: 0 };
    result.rows.forEach(row => {
      if (row.deposit_to === 'Petty Cash') balances.petty_cash = parseFloat(row.total_balance);
      if (row.deposit_to === 'Undeposited Funds') balances.undeposited_funds = parseFloat(row.total_balance);
    });
    
    res.json({ balances });
  } catch (err) {
    console.error("GET DEPOSIT BALANCES ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
};

module.exports = { recordPayment, getPayments, getAllPayments, getPaymentById, getDepositBalances };