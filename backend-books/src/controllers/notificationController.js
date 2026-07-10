const pool = require("../config/db");

exports.getNotifications = async (req, res) => {
  try {
    const orgId = req.user.organization_id;

    // Fetch overdue and due today schedules
    const schedulesQuery = `
      SELECT 
        s.id, s.invoice_id, s.due_date, s.balance_amount,
        i.invoice_number,
        c.display_name as customer_name, c.email as customer_email, c.phone as customer_phone, c.mobile as customer_mobile, c.work_phone as customer_work_phone
      FROM invoice_payment_schedules s
      JOIN invoices i ON s.invoice_id = i.id
      JOIN customers c ON s.customer_id = c.id
      WHERE s.organization_id = $1 
        AND s.status != 'paid' 
        AND s.due_date <= CURRENT_DATE
      ORDER BY s.due_date ASC
    `;
    const schedulesRes = await pool.query(schedulesQuery, [orgId]);

    // Format the notifications
    const notifications = schedulesRes.rows.map(row => {
      // Prioritize mobile > phone > work_phone for WhatsApp
      const bestPhone = row.customer_mobile || row.customer_phone || row.customer_work_phone || "";
      return {
        id: row.id,
        type: "installment_due",
        invoice_id: row.invoice_id,
        invoice_number: row.invoice_number,
        customer_name: row.customer_name,
        customer_email: row.customer_email,
        customer_phone: bestPhone,
        due_date: row.due_date,
        balance_amount: row.balance_amount
      };
    });

    res.json({ notifications });
  } catch (error) {
    console.error("Error fetching notifications:", error);
    res.status(500).json({ error: "Server error" });
  }
};
