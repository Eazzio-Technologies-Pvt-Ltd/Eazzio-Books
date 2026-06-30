const PDFDocument = require("pdfkit");
const numberToWords = require("number-to-words");
const pool = require("../config/db");

async function generateInvoicePDF(invoice, items, customer, userId) {
  // Fetch user preferences
  const prefsRes = await pool.query(
    "SELECT * FROM invoice_preferences WHERE user_id = $1",
    [userId]
  );
  const prefs = prefsRes.rows[0] || {};

  const bizName = "Tinplate Computer Training Center";
  const bizAddress1 = "2nd Floor, Thakur Pyare Singh Road";
  const bizAddress2 = "Jamshedpur - 831001";
  const bizEmail = "india.technologyhelp88@gmail.com";
  const bizGSTIN = "YOUR_GSTIN"; // Replace with actual
  const bizPAN = "YOUR_PAN"; // Replace with actual

  const invoiceNumber = invoice.invoice_number || `INV-${String(invoice.id).padStart(6, "0")}`;
  const invoiceDate = new Date(invoice.invoice_date).toLocaleDateString("en-IN");
  const dueDate = invoice.due_date ? new Date(invoice.due_date).toLocaleDateString("en-IN") : "—";
  const terms = invoice.payment_terms || "Due on Receipt";
  const customerName = customer?.display_name || "Customer";
  const customerAddress = customer?.address || "";
  const customerEmail = customer?.email || "";
  const notes = invoice.notes || "Looking forward for your business.";
  const total = parseFloat(invoice.total_amount) || 0;
  const balanceDue = parseFloat(invoice.balance_due) || total;

  let totalWords = "";
  try {
    totalWords = numberToWords.toWords(Math.floor(total));
    totalWords = totalWords.charAt(0).toUpperCase() + totalWords.slice(1);
  } catch (e) {
    totalWords = "Indian Rupee " + total.toFixed(0);
  }

  // CGST/SGST calculation
  const showCGSTSGST = prefs.show_cgst_sgst || false;
  const cgst = showCGSTSGST ? (total * 0.09) : 0; // Example: 9% CGST
  const sgst = showCGSTSGST ? (total * 0.09) : 0;
  const grandTotal = total + cgst + sgst;

  const showHSN = prefs.show_hsn || false;

  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 50, size: "A4", bufferPages: true });
    const buffers = [];
    doc.on("data", chunk => buffers.push(chunk));
    doc.on("end", () => resolve(Buffer.concat(buffers)));
    doc.on("error", reject);

    const drawLine = (y, from = 50, to = 545, color = "#cccccc") =>
      doc.moveTo(from, y).lineTo(to, y).strokeColor(color).stroke().strokeColor("#000000");

    let y = 50;

    // ── Header: Title & Company Info ───────────────────────────
    doc.fontSize(20).font("Helvetica-Bold").text("TAX INVOICE", 50, y, { align: "right" });
    doc.fontSize(14).font("Helvetica-Bold").text(bizName, 50, y, { width: 300 });
    y += 18;
    doc.fontSize(9).font("Helvetica").fillColor("#555555");
    doc.text(bizAddress1, 50, y, { width: 300 });
    y += 12;
    doc.text(bizAddress2, 50, y, { width: 300 });
    y += 12;
    doc.text(bizEmail, 50, y, { width: 300 });
    y += 12;

    if (prefs.show_gstin) {
      doc.text(`GSTIN: ${bizGSTIN}`, 50, y, { width: 300 });
      y += 12;
    }
    if (prefs.show_pan) {
      doc.text(`PAN: ${bizPAN}`, 50, y, { width: 300 });
      y += 12;
    }

    y += 8;
    drawLine(y, 50, 545, "#888888");
    y += 10;

    // ── Metadata Grid: Invoice details ───────────────────────────
    doc.fillColor("#000000").fontSize(9);
    doc.font("Helvetica-Bold").text("Invoice No:", 50, y).font("Helvetica").text(invoiceNumber, 120, y);
    doc.font("Helvetica-Bold").text("Date:", 320, y).font("Helvetica").text(invoiceDate, 400, y);
    y += 14;

    if (prefs.show_due_date !== false) {
      doc.font("Helvetica-Bold").text("Due Date:", 50, y).font("Helvetica").text(dueDate, 120, y);
    }
    if (prefs.show_payment_mode) {
      doc.font("Helvetica-Bold").text("Payment Mode:", 320, y).font("Helvetica").text("___________", 400, y);
    }
    y += 14;

    y += 2;
    drawLine(y, 50, 545, "#888888");
    y += 10;

    // ── Bill To Block ──────────────────────────────────────────
    doc.fontSize(10).font("Helvetica-Bold").text("Bill To:", 50, y);
    y += 14;
    doc.fontSize(12).font("Helvetica-Bold").fillColor("#1a56db").text(customerName, 50, y);
    doc.fillColor("#333333").fontSize(9).font("Helvetica");
    
    if (customerAddress) {
      y += 14;
      doc.text(customerAddress, 50, y, { width: 495 });
    }
    if (customerEmail) {
      y += 14;
      doc.text(customerEmail, 50, y);
    }

    y += 18;
    drawLine(y, 50, 545, "#888888");
    y += 12;

    // ── Items Table Columns & Header ───────────────────────────
    const cols = {
      sNo: 50,
      desc: 80,
      hsn: showHSN ? 255 : null,
      qty: 315,
      rate: 375,
      amount: 455
    };
    const colW = {
      sNo: 30,
      desc: showHSN ? 175 : 235,
      hsn: 60,
      qty: 60,
      rate: 80,
      amount: 90
    };

    doc.rect(50, y, 495, 20).fill("#f3f4f6");
    doc.fillColor("#1f2937").font("Helvetica-Bold").fontSize(9);
    doc.text("#", cols.sNo + 4, y + 6);
    doc.text("Description", cols.desc, y + 6);
    if (showHSN) {
      doc.text("HSN Code", cols.hsn, y + 6, { align: "center", width: colW.hsn });
    }
    doc.text("Qty", cols.qty, y + 6, { align: "center", width: colW.qty });
    doc.text("Rate", cols.rate, y + 6, { align: "right", width: colW.rate });
    doc.text("Amount", cols.amount, y + 6, { align: "right", width: colW.amount });
    doc.fillColor("#000000");
    y += 20;

    // ── Items Rows ─────────────────────────────────────────────
    if (items.length > 0) {
      items.forEach((item, idx) => {
        const qty = parseFloat(item.quantity) || 0;
        const rate = parseFloat(item.unit_price) || 0;
        const amount = qty * rate;

        // Auto Page Break check
        if (y + 24 > 740) {
          doc.addPage();
          y = 50;
        }

        // Row background striping
        if (idx % 2 === 1) {
          doc.rect(50, y, 495, 20).fill("#f9fafb");
        }
        
        doc.fillColor("#000000").font("Helvetica").fontSize(9);
        doc.text(String(idx + 1), cols.sNo + 4, y + 5);
        doc.text(item.description || "—", cols.desc, y + 5, { width: colW.desc, ellipsis: true });
        
        if (showHSN) {
          doc.text(item.hsn_code || "—", cols.hsn, y + 5, { align: "center", width: colW.hsn });
        }
        doc.text(qty.toFixed(2), cols.qty, y + 5, { align: "center", width: colW.qty });
        doc.text(`₹${rate.toFixed(2)}`, cols.rate, y + 5, { align: "right", width: colW.rate });
        doc.text(`₹${amount.toFixed(2)}`, cols.amount, y + 5, { align: "right", width: colW.amount });
        
        y += 20;
      });
    } else {
      doc.rect(50, y, 495, 30).fill("#ffffff");
      doc.fillColor("#888888").font("Helvetica").fontSize(9);
      doc.text("No items", 50, y + 10, { align: "center", width: 495 });
      y += 30;
    }

    y += 4;
    drawLine(y, 50, 545, "#888888");
    y += 12;

    // ── Totals Section ──────────────────────────────────────────
    if (y + 130 > 750) {
      doc.addPage();
      y = 50;
    }

    const totalsX = 330;
    const labelW = 110;
    const valueW = 105;

    doc.font("Helvetica").fontSize(9).fillColor("#4b5563");
    
    // Subtotal
    doc.text("Sub Total:", totalsX, y).font("Helvetica-Bold").fillColor("#111827")
       .text(`₹${total.toFixed(2)}`, totalsX + labelW, y, { align: "right", width: valueW });
    y += 16;

    // Taxes
    if (showCGSTSGST) {
      doc.font("Helvetica").fillColor("#4b5563").text("CGST @9%:", totalsX, y)
         .text(`₹${cgst.toFixed(2)}`, totalsX + labelW, y, { align: "right", width: valueW });
      y += 16;
      doc.text("SGST @9%:", totalsX, y)
         .text(`₹${sgst.toFixed(2)}`, totalsX + labelW, y, { align: "right", width: valueW });
      y += 16;
    }

    // Grand Total
    drawLine(y, totalsX, 545, "#dddddd");
    y += 6;
    doc.font("Helvetica-Bold").fillColor("#111827").text("Total:", totalsX, y)
       .text(`₹${grandTotal.toFixed(2)}`, totalsX + labelW, y, { align: "right", width: valueW });
    y += 16;

    // Amount Paid
    const amountPaid = grandTotal - balanceDue;
    if (amountPaid > 0) {
      doc.font("Helvetica-Bold").fillColor("#111827").text("Amount Paid:", totalsX, y)
         .text(`₹${amountPaid.toFixed(2)}`, totalsX + labelW, y, { align: "right", width: valueW });
      y += 16;
    }

    // Balance Due
    doc.font("Helvetica-Bold").fillColor("#1a56db").text("Balance Due:", totalsX, y)
       .text(`₹${balanceDue.toFixed(2)}`, totalsX + labelW, y, { align: "right", width: valueW });
    y += 20;

    drawLine(y, 50, 545, "#888888");
    y += 10;

    // ── Words, Notes & Signatures ────────────────────────────────
    if (y + 110 > 760) {
      doc.addPage();
      y = 50;
    }

    doc.font("Helvetica-Bold").fillColor("#111827").text("Total in Words:");
    doc.font("Helvetica").fillColor("#374151").text(`Indian Rupee ${totalWords} Only`, 50, y + 12);
    y += 32;

    if (prefs.show_terms !== false) {
      doc.font("Helvetica-Bold").fillColor("#111827").text("Terms & Conditions:");
      doc.font("Helvetica").fillColor("#4b5563").fontSize(8).text(terms, 50, y + 12, { width: 495, lineHeight: 1.3 });
      y += 40;
    }

    if (prefs.show_signature !== false) {
      const sigY = y + 20;
      doc.fontSize(9).font("Helvetica-Bold").fillColor("#111827")
         .text("Authorised Signatory", 380, sigY)
         .text("_________________", 380, sigY + 30);
    }

    // ── Footer (on every page) ──────────────────────────────────
    const pages = doc.bufferedPageRange();
    for (let i = 0; i < pages.count; i++) {
      doc.switchToPage(i);
      const footerY = doc.page.height - 40;
      doc.moveTo(50, footerY).lineTo(545, footerY).strokeColor("#eeeeee").stroke();
      doc.fontSize(8).font("Helvetica").fillColor("#9ca3af")
         .text(`POWERED BY ${bizName}`, 50, footerY + 8, { align: "center", width: 495 });
    }

    doc.end();
  });
}

module.exports = generateInvoicePDF;