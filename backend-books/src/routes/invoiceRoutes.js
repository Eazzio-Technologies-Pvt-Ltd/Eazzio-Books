/*Import functions*/

const express = require("express");
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const tenantMiddleware = require('../middleware/tenantMiddleware');
const { requirePermission } = require('../middleware/roleMiddleware');
const { MODULES, ACTIONS } = require('../config/permissions');
const nodemailer = require("nodemailer");
const pool = require("../config/db");
const generateInvoicePDF = require("../utils/generateInvoicePDF");
const {
  getInvoices,
  getInvoiceById,
  createInvoice,
  updateInvoice,
  deleteInvoice,
} = require("../controllers/invoiceController");

router.get("/invoices", authMiddleware, tenantMiddleware, requirePermission(MODULES.INVOICES, ACTIONS.VIEW), getInvoices);
router.get("/invoices/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.INVOICES, ACTIONS.VIEW), getInvoiceById);
router.post("/invoices", authMiddleware, tenantMiddleware, requirePermission(MODULES.INVOICES, ACTIONS.CREATE), createInvoice);
router.put("/invoices/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.INVOICES, ACTIONS.EDIT), updateInvoice);
router.delete("/invoices/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.INVOICES, ACTIONS.DELETE), deleteInvoice);

const ORG_NAME = "Tinplate Computer Training Center";
const ORG_ADDRESS = "2nd Floor, Thakur Pyara Singh Road, Jamshedpur – 831001";
const ORG_EMAIL = process.env.FROM_EMAIL;
const ORG_COUNTRY = "India";

// Helper: Fetch invoice with dynamic tenant isolation
async function fetchInvoiceWithTenant(id, tenantId) {
  let query = "SELECT * FROM invoices WHERE id = $1";
  let values = [id];
  if (tenantId) {
    query += " AND organization_id = $2";
    values.push(tenantId);
  }
  const res = await pool.query(query, values);
  return res.rows.length ? res.rows[0] : null;
}

// Helper: Fetch customer with dynamic tenant isolation
async function fetchCustomerWithTenant(customerId, tenantId) {
  let query = "SELECT * FROM customers WHERE id = $1";
  let values = [customerId];
  if (tenantId) {
    query += " AND organization_id = $2";
    values.push(tenantId);
  }
  const res = await pool.query(query, values);
  return res.rows.length ? res.rows[0] : null;
}

router.post("/invoices/:id/send", authMiddleware, tenantMiddleware, requirePermission(MODULES.INVOICES, ACTIONS.SEND), async (req, res) => {
  const { id } = req.params;
  const { to, subject, body, cc, bcc } = req.body;

  try {
    // ---- 1. Fetch invoice ----
    const invoice = await fetchInvoiceWithTenant(id, req.tenantId);
    if (!invoice) return res.status(404).json({ message: "Invoice not found" });

    // ---- 2. Fetch customer ----
    const customer = await fetchCustomerWithTenant(invoice.customer_id, req.tenantId);
    if (!customer) return res.status(404).json({ message: "Customer not found" });

    const emailTo = to || customer?.email;
    if (!emailTo) return res.status(400).json({ message: "Recipient email required" });

    // ---- 3. Fetch items ----
    const itemsRes = await pool.query("SELECT * FROM invoice_items WHERE invoice_id = $1", [id]);
    const items = itemsRes.rows;

    // ---- 4. Generate PDF (Puppeteer) ----
    const pdfBuffer = await generateInvoicePDF(invoice, items, customer, req.user.id);

    // ---- 5. Send email ----
    const transporter = nodemailer.createTransport({
      host: process.env.SMTP_HOST || "smtp-relay.sendinblue.com",
      port: parseInt(process.env.SMTP_PORT || "587"),
      secure: false,
      auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
      },
    });

    await transporter.sendMail({
      from: process.env.FROM_EMAIL || "noreply@tinplate.com",
      to: emailTo,
      cc: cc || undefined,
      bcc: bcc || undefined,
      subject: subject,
      text: body,
      attachments: [
        {
          filename: `Tax_Invoice_${invoice.invoice_number}.pdf`,
          content: pdfBuffer,
          contentType: "application/pdf",
        },
      ],
    });

    // Mark as sent
    let updQuery = "UPDATE invoices SET status = 'sent', updated_at = CURRENT_TIMESTAMP WHERE id = $1";
    let updVals = [id];
    if (req.tenantId) {
      updQuery += " AND organization_id = $2";
      updVals.push(req.tenantId);
    }
    await pool.query(updQuery, updVals);

    res.json({ message: "Email sent with Tax Invoice PDF" });
  } catch (err) {
    console.error("SEND INVOICE EMAIL ERROR:", err);
    res.status(500).json({ message: "Failed to send email" });
  }
});

router.get("/invoices/:id/pdf", authMiddleware, tenantMiddleware, requirePermission(MODULES.INVOICES, ACTIONS.EXPORT), async (req, res) => {
  const { id } = req.params;

  try {
    const invoice = await fetchInvoiceWithTenant(id, req.tenantId);
    if (!invoice) return res.status(404).json({ message: "Invoice not found" });

    const customer = await fetchCustomerWithTenant(invoice.customer_id, req.tenantId);
    if (!customer) return res.status(404).json({ message: "Customer not found" });

    const itemsRes = await pool.query("SELECT * FROM invoice_items WHERE invoice_id = $1", [id]);

    const pdfBuffer = await generateInvoicePDF(invoice, itemsRes.rows, customer);

    res.setHeader("Content-Type", "application/pdf");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="Invoice_${invoice.invoice_number || id}.pdf"`
    );
    res.send(pdfBuffer);
  } catch (err) {
    console.error("DOWNLOAD INVOICE PDF ERROR:", err);
    res.status(500).json({ message: "Failed to generate PDF" });
  }
});

// ================= GET INVOICES BY CUSTOMER ID =================
router.get("/customers/:id/invoices", authMiddleware, tenantMiddleware, requirePermission(MODULES.INVOICES, ACTIONS.EXPORT), async (req, res) => {
  const { id } = req.params;
  try {
    let query = "SELECT * FROM invoices WHERE customer_id = $1";
    let values = [id];
    let pIdx = 2;
    if (req.tenantId) {
      query += ` AND organization_id = $${pIdx++}`;
      values.push(req.tenantId);
    }
    query += " ORDER BY created_at DESC";

    const result = await pool.query(query, values);
    res.json({ invoices: result.rows });
  } catch (err) {
    console.error("GET CUSTOMER INVOICES ERROR:", err);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;
