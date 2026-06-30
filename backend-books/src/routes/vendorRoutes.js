const express = require("express");
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const tenantMiddleware = require('../middleware/tenantMiddleware');
const { requirePermission } = require('../middleware/roleMiddleware');
const { MODULES, ACTIONS } = require('../config/permissions');
const {
  getVendors,
  getVendorById,
  createVendor,
  updateVendor,
  deleteVendor,
} = require("../controllers/vendorController");

router.get("/vendors",     authMiddleware, tenantMiddleware, requirePermission(MODULES.VENDORS, ACTIONS.VIEW), getVendors);
router.get("/vendors/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.VENDORS, ACTIONS.VIEW), getVendorById);
router.post("/vendors",    authMiddleware, tenantMiddleware, requirePermission(MODULES.VENDORS, ACTIONS.CREATE), createVendor);
router.put("/vendors/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.VENDORS, ACTIONS.EDIT), updateVendor);
router.delete("/vendors/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.VENDORS, ACTIONS.DELETE), deleteVendor);

// ── Vendor Invoices & Statement PDF/Email routes ─────────────────────────────
const nodemailer = require('nodemailer');
const pool = require('../config/db');
const generateStatementPDF = require('../utils/generateStatementPDF');

// Helper: fetch bills by vendor + date range
async function getVendorBillsInRange(vendorId, tenantId, fromDate, toDate) {
  let query = `SELECT * FROM bills WHERE vendor_id = $1 AND is_deleted = false`;
  const values = [vendorId];
  let paramIndex = 2;

  if (tenantId) {
    query += ` AND organization_id = $${paramIndex++}`;
    values.push(tenantId);
  }

  if (fromDate && toDate) {
    query += ` AND bill_date BETWEEN $${paramIndex++} AND $${paramIndex++}`;
    values.push(fromDate, toDate);
  }
  query += ` ORDER BY bill_date ASC`;
  const result = await pool.query(query, values);
  return result.rows.map(bill => ({
    id: bill.id,
    invoice_date: bill.bill_date,
    invoice_number: bill.bill_number,
    total_amount: bill.total_amount,
    balance_due: bill.balance_due,
    status: bill.status,
    description: bill.notes || ''
  }));
}

// GET /vendors/:id/invoices — Get bills mapped as invoices for the UI
router.get('/vendors/:id/invoices', authMiddleware, tenantMiddleware, requirePermission(MODULES.VENDORS, ACTIONS.VIEW), async (req, res) => {
  const { id } = req.params;
  try {
    const invoices = await getVendorBillsInRange(id, req.tenantId);
    res.json({ invoices });
  } catch (err) {
    console.error('VENDOR INVOICES ERROR:', err);
    res.status(500).json({ message: 'Failed to fetch invoices' });
  }
});

// GET /vendors/:id/statement/pdf — Download statement as real PDF
router.get('/vendors/:id/statement/pdf', authMiddleware, tenantMiddleware, requirePermission(MODULES.VENDORS, ACTIONS.EXPORT), async (req, res) => {
  const { id } = req.params;
  const { from, to } = req.query;

  try {
    let query = 'SELECT * FROM vendors WHERE id = $1 AND is_deleted = false';
    let values = [id];
    if (req.tenantId) {
      query += ' AND organization_id = $2';
      values.push(req.tenantId);
    }

    const vendRes = await pool.query(query, values);
    if (vendRes.rows.length === 0) {
      return res.status(404).json({ message: 'Vendor not found' });
    }
    const vendor = vendRes.rows[0];

    const invoices = await getVendorBillsInRange(id, req.tenantId, from, to);
    const pdfBuffer = await generateStatementPDF(vendor, invoices, from || 'All time', to || 'All time');

    const vendorName = vendor.display_name || vendor.company_name || 'Vendor';
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="Statement_${vendorName}_${from || 'all'}_${to || 'all'}.pdf"`
    );
    res.send(pdfBuffer);
  } catch (err) {
    console.error('VENDOR STATEMENT PDF ERROR:', err);
    res.status(500).json({ message: 'Failed to generate statement PDF' });
  }
});

// POST /vendors/:id/statement/send — Generate PDF + email it as attachment
router.post('/vendors/:id/statement/send', authMiddleware, tenantMiddleware, requirePermission(MODULES.VENDORS, ACTIONS.EXPORT), async (req, res) => {
  const { id } = req.params;
  const { to: emailTo, subject, body: emailBody, from: fromDate, to_date: toDate } = req.body;

  try {
    let query = 'SELECT * FROM vendors WHERE id = $1 AND is_deleted = false';
    let values = [id];
    if (req.tenantId) {
      query += ' AND organization_id = $2';
      values.push(req.tenantId);
    }

    const vendRes = await pool.query(query, values);
    if (vendRes.rows.length === 0) {
      return res.status(404).json({ message: 'Vendor not found' });
    }
    const vendor = vendRes.rows[0];

    const recipientEmail = emailTo || vendor.email;
    if (!recipientEmail) {
      return res.status(400).json({ message: 'No recipient email address available' });
    }

    const invoices = await getVendorBillsInRange(id, req.tenantId, fromDate, toDate);
    const pdfBuffer = await generateStatementPDF(
      vendor, invoices,
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

    const vendorName = vendor.display_name || vendor.company_name || 'Vendor';

    await transporter.sendMail({
      from: process.env.FROM_EMAIL || 'noreply@tinplate.com',
      to: recipientEmail,
      subject: subject || `Statement of Accounts – ${vendorName}`,
      text: emailBody || `Dear ${vendorName},\n\nPlease find your statement of accounts attached.\n\nRegards,\nTinplate Computer Training Center`,
      attachments: [
        {
          filename: `Statement_${vendorName}.pdf`,
          content: pdfBuffer,
          contentType: 'application/pdf',
        },
      ],
    });

    res.json({ message: 'Statement sent successfully' });
  } catch (err) {
    console.error('VENDOR STATEMENT SEND EMAIL ERROR:', err);
    res.status(500).json({ message: 'Failed to send statement email' });
  }
});

module.exports = router;
