const express = require("express");
const router = express.Router();
const authMiddleware = require('../middleware/authMiddleware');
const tenantMiddleware = require('../middleware/tenantMiddleware');
const { requirePermission } = require('../middleware/roleMiddleware');
const { MODULES, ACTIONS } = require('../config/permissions');
const {
  getExpenses,
  getExpenseById,
  createExpense,
  updateExpense,
  deleteExpense,
} = require("../controllers/expenseController");

router.get("/expenses",     authMiddleware, tenantMiddleware, requirePermission(MODULES.EXPENSES, ACTIONS.VIEW), getExpenses);
router.get("/expenses/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.EXPENSES, ACTIONS.VIEW), getExpenseById);
router.post("/expenses",    authMiddleware, tenantMiddleware, requirePermission(MODULES.EXPENSES, ACTIONS.CREATE), createExpense);
router.put("/expenses/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.EXPENSES, ACTIONS.EDIT), updateExpense);
router.delete("/expenses/:id", authMiddleware, tenantMiddleware, requirePermission(MODULES.EXPENSES, ACTIONS.DELETE), deleteExpense);

// ── Expense Invoices & Statement PDF/Email routes ─────────────────────────────
const nodemailer = require('nodemailer');
const pool = require('../config/db');
const generateStatementPDF = require('../utils/generateStatementPDF');

async function getExpenseAndInvoices(expenseId, req, fromDate, toDate) {
  let query = `SELECT e.*, v.display_name AS vendor_name, v.email AS vendor_email, v.company_name AS vendor_company, v.opening_balance AS vendor_opening_balance
               FROM expenses e
               LEFT JOIN vendors v ON e.vendor_id = v.id
               WHERE e.id = $1`;
  const values = [expenseId];
  let paramIndex = 2;

  if (req.tenantId) {
    query += ` AND e.organization_id = $${paramIndex++}`;
    values.push(req.tenantId);
  } else {
    query += ` AND e.user_id = $${paramIndex++}`;
    values.push(req.user.id);
  }

  const expRes = await pool.query(query, values);
  if (expRes.rows.length === 0) {
    return null;
  }
  const expense = expRes.rows[0];

  let invoices = [];
  let recipient = null;

  if (expense.vendor_id) {
    recipient = {
      display_name: expense.vendor_name || expense.vendor_company || 'Vendor',
      email: expense.vendor_email || '',
      opening_balance: parseFloat(expense.vendor_opening_balance) || 0
    };

    let billQuery = `SELECT * FROM bills WHERE vendor_id = $1 AND is_deleted = false`;
    const billVals = [expense.vendor_id];
    let billParamIdx = 2;

    if (req.tenantId) {
      billQuery += ` AND organization_id = $${billParamIdx++}`;
      billVals.push(req.tenantId);
    }

    if (fromDate && toDate) {
      billQuery += ` AND bill_date BETWEEN $${billParamIdx++} AND $${billParamIdx++}`;
      billVals.push(fromDate, toDate);
    }
    billQuery += ` ORDER BY bill_date ASC`;
    const billsRes = await pool.query(billQuery, billVals);

    invoices = billsRes.rows.map(bill => ({
      id: bill.id,
      invoice_date: bill.bill_date,
      invoice_number: bill.bill_number,
      total_amount: bill.total_amount,
      balance_due: bill.balance_due,
      status: bill.status,
      description: bill.notes || ''
    }));
  } else {
    recipient = {
      display_name: 'Expense Recipient',
      email: '',
      opening_balance: 0
    };

    let withinRange = true;
    if (fromDate && toDate && expense.expense_date) {
      const expD = new Date(expense.expense_date).toISOString().slice(0, 10);
      withinRange = (expD >= fromDate && expD <= toDate);
    }

    if (withinRange) {
      invoices = [{
        id: expense.id,
        invoice_date: expense.expense_date,
        invoice_number: expense.reference || `EXP-${expense.id}`,
        total_amount: expense.amount,
        balance_due: expense.status?.toLowerCase() === 'unpaid' ? expense.amount : 0,
        status: expense.status,
        description: expense.description || ''
      }];
    }
  }

  return { expense, invoices, recipient };
}

// GET /expenses/:id/invoices — Get bills mapped as invoices for the UI
router.get('/expenses/:id/invoices', authMiddleware, tenantMiddleware, requirePermission(MODULES.EXPENSES, ACTIONS.VIEW), async (req, res) => {
  const { id } = req.params;
  try {
    const data = await getExpenseAndInvoices(id, req);
    if (!data) {
      return res.status(404).json({ message: 'Expense not found' });
    }
    res.json({ invoices: data.invoices });
  } catch (err) {
    console.error('EXPENSE INVOICES ERROR:', err);
    res.status(500).json({ message: 'Failed to fetch invoices' });
  }
});

// GET /expenses/:id/statement/pdf — Download statement as real PDF
router.get('/expenses/:id/statement/pdf', authMiddleware, tenantMiddleware, requirePermission(MODULES.EXPENSES, ACTIONS.EXPORT), async (req, res) => {
  const { id } = req.params;
  const { from, to } = req.query;

  try {
    const data = await getExpenseAndInvoices(id, req, from, to);
    if (!data) {
      return res.status(404).json({ message: 'Expense not found' });
    }

    const pdfBuffer = await generateStatementPDF(data.recipient, data.invoices, from || 'All time', to || 'All time');

    const recipientName = data.recipient.display_name || 'Expense';
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="Statement_${recipientName}_${from || 'all'}_${to || 'all'}.pdf"`
    );
    res.send(pdfBuffer);
  } catch (err) {
    console.error('EXPENSE STATEMENT PDF ERROR:', err);
    res.status(500).json({ message: 'Failed to generate statement PDF' });
  }
});

// POST /expenses/:id/statement/send — Generate PDF + email it as attachment
router.post('/expenses/:id/statement/send', authMiddleware, tenantMiddleware, requirePermission(MODULES.EXPENSES, ACTIONS.EXPORT), async (req, res) => {
  const { id } = req.params;
  const { to: emailTo, subject, body: emailBody, from: fromDate, to_date: toDate } = req.body;

  try {
    const data = await getExpenseAndInvoices(id, req, fromDate, toDate);
    if (!data) {
      return res.status(404).json({ message: 'Expense not found' });
    }

    const recipientEmail = emailTo || data.recipient.email;
    if (!recipientEmail) {
      return res.status(400).json({ message: 'No recipient email address available' });
    }

    const pdfBuffer = await generateStatementPDF(
      data.recipient, data.invoices,
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

    const recipientName = data.recipient.display_name || 'Expense';

    await transporter.sendMail({
      from: process.env.FROM_EMAIL || 'noreply@tinplate.com',
      to: recipientEmail,
      subject: subject || `Statement of Accounts – ${recipientName}`,
      text: emailBody || `Dear ${recipientName},\n\nPlease find your statement of accounts attached.\n\nRegards,\nTinplate Computer Training Center`,
      attachments: [
        {
          filename: `Statement_${recipientName}.pdf`,
          content: pdfBuffer,
          contentType: 'application/pdf',
        },
      ],
    });

    res.json({ message: 'Statement sent successfully' });
  } catch (err) {
    console.error('EXPENSE STATEMENT SEND EMAIL ERROR:', err);
    res.status(500).json({ message: 'Failed to send statement email' });
  }
});

module.exports = router;