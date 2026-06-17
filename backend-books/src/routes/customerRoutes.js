const express = require("express");
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const tenantMiddleware = require('../middleware/tenantMiddleware');
const { requirePermission } = require('../middleware/roleMiddleware');
const { MODULES, ACTIONS } = require('../config/permissions');
const {
  getCustomers,
  getCustomerById,
  createCustomer,
  updateCustomer,
  deleteCustomer,
  getActivityLog,
  getCustomerStatement
} = require("../controllers/customerController");

router.get("/customers", authMiddleware, tenantMiddleware, requirePermission(MODULES.CUSTOMERS, ACTIONS.VIEW), getCustomers);
router.get("/customers/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.CUSTOMERS, ACTIONS.VIEW), getCustomerById);
router.post("/customers", authMiddleware, tenantMiddleware, requirePermission(MODULES.CUSTOMERS, ACTIONS.CREATE), createCustomer);
router.put("/customers/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.CUSTOMERS, ACTIONS.EDIT), updateCustomer);
router.delete("/customers/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.CUSTOMERS, ACTIONS.DELETE), deleteCustomer);
router.get("/customers/:id/activity", authMiddleware, tenantMiddleware, requirePermission(MODULES.CUSTOMERS, ACTIONS.VIEW), getActivityLog);
router.get("/customers/:id/statement", authMiddleware, tenantMiddleware, requirePermission(MODULES.CUSTOMERS, ACTIONS.VIEW), getCustomerStatement);

// ── Statement PDF & Email routes ─────────────────────────────────────────────
const nodemailer = require('nodemailer');
const pool = require('../config/db');
const generateStatementPDF = require('../utils/generateStatementPDF');

// Helper: fetch invoices by customer + date range
async function getCustomerInvoicesInRange(customerId, tenantId, fromDate, toDate) {
  let query = `SELECT * FROM invoices WHERE customer_id = $1`;
  const values = [customerId];
  let paramIndex = 2;

  if (tenantId) {
    query += ` AND organization_id = $${paramIndex++}`;
    values.push(tenantId);
  }

  if (fromDate && toDate) {
    query += ` AND invoice_date BETWEEN $${paramIndex++} AND $${paramIndex++}`;
    values.push(fromDate, toDate);
  }
  query += ` ORDER BY invoice_date ASC`;
  const result = await pool.query(query, values);
  return result.rows;
}

// GET /customers/:id/statement/pdf — Download statement as real PDF
router.get('/customers/:id/statement/pdf', authMiddleware, tenantMiddleware, requirePermission(MODULES.CUSTOMERS, ACTIONS.EXPORT), async (req, res) => {
  const { id } = req.params;
  const { from, to } = req.query;

  try {
    let query = 'SELECT * FROM customers WHERE id = $1';
    let values = [id];
    if (req.tenantId) {
      query += ' AND organization_id = $2';
      values.push(req.tenantId);
    }

    const custRes = await pool.query(query, values);
    if (custRes.rows.length === 0) {
      return res.status(404).json({ message: 'Customer not found' });
    }
    const customer = custRes.rows[0];

    const invoices = await getCustomerInvoicesInRange(id, req.tenantId, from, to);
    const pdfBuffer = await generateStatementPDF(customer, invoices, from || 'All time', to || 'All time');

    const customerName = customer.display_name || customer.first_name || 'Customer';
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="Statement_${customerName}_${from || 'all'}_${to || 'all'}.pdf"`
    );
    res.send(pdfBuffer);
  } catch (err) {
    console.error('STATEMENT PDF ERROR:', err);
    res.status(500).json({ message: 'Failed to generate statement PDF' });
  }
});

// POST /customers/:id/statement/send — Generate PDF + email it as attachment
router.post('/customers/:id/statement/send', authMiddleware, tenantMiddleware, requirePermission(MODULES.CUSTOMERS, ACTIONS.EXPORT), async (req, res) => {
  const { id } = req.params;
  const { to: emailTo, subject, body: emailBody, from: fromDate, to_date: toDate } = req.body;

  try {
    let query = 'SELECT * FROM customers WHERE id = $1';
    let values = [id];
    if (req.tenantId) {
      query += ' AND organization_id = $2';
      values.push(req.tenantId);
    }

    const custRes = await pool.query(query, values);
    if (custRes.rows.length === 0) {
      return res.status(404).json({ message: 'Customer not found' });
    }
    const customer = custRes.rows[0];

    const recipientEmail = emailTo || customer.email;
    if (!recipientEmail) {
      return res.status(400).json({ message: 'No recipient email address available' });
    }

    const invoices = await getCustomerInvoicesInRange(id, req.tenantId, fromDate, toDate);
    const pdfBuffer = await generateStatementPDF(
      customer, invoices,
      fromDate || 'All time', toDate || 'All time'
    );

    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST || 'smtp-relay.sendinblue.com',
      port: parseInt(process.env.SMTP_PORT || '587'),
      secure: false,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });

    const customerName = customer.display_name || customer.first_name || 'Customer';

    await transporter.sendMail({
      from: process.env.FROM_EMAIL || 'noreply@tinplate.com',
      to: recipientEmail,
      subject: subject || `Statement of Accounts – ${customerName}`,
      text: emailBody || `Dear ${customerName},\n\nPlease find your statement of accounts attached.\n\nRegards,\nTinplate Computer Training Center`,
      attachments: [
        {
          filename: `Statement_${customerName}.pdf`,
          content: pdfBuffer,
          contentType: 'application/pdf',
        },
      ],
    });

    res.json({ message: 'Statement sent successfully' });
  } catch (err) {
    console.error('STATEMENT SEND EMAIL ERROR:', err);
    res.status(500).json({ message: 'Failed to send statement email' });
  }
});

module.exports = router;