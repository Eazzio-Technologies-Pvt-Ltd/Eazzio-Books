import 'package:mobile_books/features/quotes/data/models/quote.dart';
import 'package:mobile_books/features/quotes/data/models/quote_item.dart';
import 'package:mobile_books/features/invoices/data/models/invoice.dart';
import 'package:mobile_books/features/invoices/data/models/invoice_item.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/features/settings/data/models/organization_settings.dart';

class PdfHelper {
  static String generateQuoteHtml({
    required Quote quote,
    required List<QuoteItem> items,
    required Customer? customer,
    required OrganizationSettings? settings,
    required String totalInWords,
  }) {
    final orgName = settings?.organizationName ?? 'Your Organization';
    final orgAddress = settings?.address ?? '';
    final orgEmail = settings?.organizationEmail ?? '';
    final orgCountry = settings?.country ?? 'India';

    final customerName = customer?.displayName ?? 
        '${customer?.firstName ?? ""} ${customer?.lastName ?? ""}'.trim();
    final displayCustomerName = customerName.isNotEmpty ? customerName : 'Customer';
    final customerEmail = customer?.email;
    final customerPhone = customer?.phone;

    double subtotal = 0.0;
    for (final item in items) {
      subtotal += item.quantity * item.unitPrice;
    }

    final itemsRows = items.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final qty = item.quantity;
      final rate = item.unitPrice;
      final disc = item.discount;
      final discType = item.discountType;
      final taxRate = item.taxRate;

      double lineAmt = qty * rate;
      if (discType == 'percent') {
        lineAmt -= lineAmt * (disc / 100);
      } else {
        lineAmt -= disc;
      }
      final taxAmt = lineAmt * (taxRate / 100);
      final lineTotal = lineAmt + taxAmt;

      return '''
        <tr>
          <td>${idx + 1}</td>
          <td style="text-align: left;">
            <strong>${item.itemName ?? item.description ?? '—'}</strong>
            ${item.description != null && item.description != item.itemName ? '<br/><span style="font-size: 10px; color: #667085;">' + item.description! + '</span>' : ''}
          </td>
          <td>${item.hsnCode ?? '—'}</td>
          <td style="text-align: right;">${qty.toStringAsFixed(2)}${item.unit != null ? ' ' + item.unit! : ''}</td>
          <td style="text-align: right;">₹${rate.toStringAsFixed(2)}</td>
          <td style="text-align: right; color: #DC2626;">${disc > 0 ? (discType == 'percent' ? disc.toStringAsFixed(0) + '%' : '₹' + disc.toStringAsFixed(2)) : '—'}</td>
          <td style="text-align: right;">${taxRate > 0 ? taxRate.toStringAsFixed(0) + '%' : '—'}</td>
          <td style="text-align: right; font-weight: bold;">₹${lineTotal.toStringAsFixed(2)}</td>
        </tr>
      ''';
    }).join('\n');

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          @page { size: A4 portrait; margin: 10mm 12mm; }
          body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            color: #333;
            margin: 0;
            padding: 20px;
            font-size: 12px;
            line-height: 1.4;
          }
          .header {
            margin-bottom: 30px;
          }
          .company-info {
            text-align: right;
            float: right;
          }
          .title {
            font-size: 28px;
            font-weight: bold;
            color: #1D2939;
            margin-top: 10px;
            clear: both;
          }
          .meta-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            margin-bottom: 20px;
            border: 1px solid #D0D5DD;
            border-radius: 4px;
          }
          .meta-table td {
            padding: 10px;
            border: 1px solid #D0D5DD;
            vertical-align: top;
          }
          .section-header {
            background-color: #F9FAFB;
            font-weight: bold;
            color: #344054;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
          }
          .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            margin-bottom: 20px;
            border: 1px solid #D0D5DD;
          }
          .items-table th, .items-table td {
            border: 1px solid #D0D5DD;
            padding: 8px;
            text-align: center;
          }
          .items-table th {
            background-color: #F9FAFB;
            font-weight: bold;
            color: #1D2939;
          }
          .footer-section {
            width: 100%;
            margin-top: 30px;
          }
          .footer-left {
            width: 60%;
            float: left;
            padding-right: 20px;
          }
          .footer-right {
            width: 35%;
            float: right;
            text-align: right;
          }
          .total-row {
            font-weight: bold;
            font-size: 13px;
            color: #006EE6;
          }
          .signature-area {
            margin-top: 50px;
            text-align: right;
          }
          .signature-line {
            width: 150px;
            border-top: 1px solid #667085;
            display: inline-block;
            margin-top: 5px;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <div class="company-info">
            <h2 style="margin: 0; color: #1D2939;">$orgName</h2>
            <p style="margin: 2px 0;">$orgAddress</p>
            <p style="margin: 2px 0;">$orgCountry, $orgEmail</p>
          </div>
          <div style="clear: both;"></div>
        </div>

        <div class="title">QUOTE</div>

        <table class="meta-table">
          <tr>
            <td style="width: 50%;">
              <strong>Quote Number:</strong> ${quote.quoteNumber}<br/>
              <strong>Quote Date:</strong> ${quote.quoteDate.toLocal().toString().split(' ')[0]}<br/>
              <strong>Expiry Date:</strong> ${quote.expiryDate != null ? quote.expiryDate!.toLocal().toString().split(' ')[0] : '—'}
            </td>
            <td style="width: 50%;">
              <div class="section-header" style="padding: 2px 0; margin-bottom: 5px;">Bill To</div>
              <strong style="color: #006EE6;">$displayCustomerName</strong><br/>
              ${customerEmail != null && customerEmail.isNotEmpty ? customerEmail + '<br/>' : ''}
              ${customerPhone != null && customerPhone.isNotEmpty ? customerPhone : ''}
            </td>
          </tr>
        </table>

        <table class="items-table">
          <thead>
            <tr>
              <th style="width: 5%;">#</th>
              <th style="text-align: left; width: 45%;">Item & Description</th>
              <th style="width: 10%;">HSN/SAC</th>
              <th style="width: 8%;">Qty</th>
              <th style="width: 10%;">Rate</th>
              <th style="width: 8%;">Disc</th>
              <th style="width: 6%;">Tax%</th>
              <th style="width: 12%;">Amount</th>
            </tr>
          </thead>
          <tbody>
            $itemsRows
          </tbody>
        </table>

        <div class="footer-section">
          <div class="footer-left">
            <p style="margin: 0; font-weight: bold; color: #667085; font-size: 10px;">Total In Words</p>
            <p style="margin: 4px 0; font-style: italic; font-weight: bold; color: #344054;">Indian Rupee $totalInWords Only</p>
            
            <p style="margin: 15px 0 0 0; font-weight: bold; color: #667085; font-size: 10px;">Notes</p>
            <p style="margin: 4px 0; color: #475569;">${quote.notes ?? 'Looking forward for your business.'}</p>

            ${quote.terms != null && quote.terms!.isNotEmpty ? '<p style="margin: 15px 0 0 0; font-weight: bold; color: #667085; font-size: 10px;">Terms & Conditions</p><p style="margin: 4px 0; color: #667085; font-size: 10px;">' + quote.terms! + '</p>' : ''}
          </div>
          <div class="footer-right">
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="padding: 5px 0; color: #667085; text-align: left;">Sub Total</td>
                <td style="padding: 5px 0; font-weight: 500; text-align: right;">₹${subtotal.toStringAsFixed(2)}</td>
              </tr>
              <tr class="total-row">
                <td style="padding: 8px 0; border-top: 1px solid #D0D5DD; text-align: left;">Total</td>
                <td style="padding: 8px 0; border-top: 1px solid #D0D5DD; text-align: right;">₹${quote.totalAmount.toStringAsFixed(2)}</td>
              </tr>
            </table>
            <div class="signature-area">
              <p style="margin: 0; color: #667085; font-size: 9px; font-weight: 500;">Authorized Signature</p>
              <div class="signature-line"></div>
            </div>
          </div>
          <div style="clear: both;"></div>
        </div>
        <div style="text-align: center; margin-top: 40px; padding: 12px 0; border-top: 1px solid #E5E7EB; color: #98A2B3; font-size: 9px;">
          Powered by Eazzio Technology
        </div>
      </body>
      </html>
    ''';
  }

  static String generateInvoiceHtml({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required Customer? customer,
    required OrganizationSettings? settings,
    required String totalInWords,
  }) {
    final orgName = settings?.organizationName ?? 'Your Organization';
    final orgAddress = settings?.address ?? '';
    final orgEmail = settings?.organizationEmail ?? '';
    final orgCountry = settings?.country ?? 'India';

    final customerName = customer?.displayName ?? 
        '${customer?.firstName ?? ""} ${customer?.lastName ?? ""}'.trim();
    final displayCustomerName = customerName.isNotEmpty ? customerName : 'Customer';
    final customerEmail = customer?.email;
    final customerPhone = customer?.phone;
    final isIntraState = invoice.gstType == 'intra_state';
    final isInterState = invoice.gstType == 'inter_state';

    double subtotal = 0.0;
    double discountAmount = 0.0;
    double cgstAmount = 0.0;
    double sgstAmount = 0.0;
    double igstAmount = 0.0;
    double taxAmount = 0.0;

    for (final item in items) {
      final qty = item.quantity;
      final rate = item.unitPrice;
      final disc = item.discount;
      final discType = item.discountType;

      double itemSubtotal = qty * rate;
      subtotal += itemSubtotal;

      double itemDiscount = 0.0;
      if (discType == 'percent') {
        itemDiscount = itemSubtotal * (disc / 100);
      } else {
        itemDiscount = disc;
      }
      discountAmount += itemDiscount;

      double taxable = item.taxableValue;
      if (taxable == 0.0) {
        taxable = itemSubtotal - itemDiscount;
      }

      if (isIntraState) {
        cgstAmount += item.cgstAmount;
        sgstAmount += item.sgstAmount;
      } else if (isInterState) {
        igstAmount += item.igstAmount;
      } else {
        taxAmount += taxable * (item.taxRate / 100);
      }
    }

    final itemsRows = items.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final qty = item.quantity;
      final rate = item.unitPrice;
      final disc = item.discount;
      final discType = item.discountType;

      double taxable = item.taxableValue;
      if (taxable == 0.0) {
        taxable = qty * rate;
        if (discType == 'percent') {
          taxable -= taxable * (disc / 100);
        } else {
          taxable -= disc;
        }
      }

      final cgstAmt = item.cgstAmount;
      final sgstAmt = item.sgstAmount;
      final igstAmt = item.igstAmount;
      final fallbackTaxAmt = taxable * (item.taxRate / 100);

      final rowTotal = taxable +
          cgstAmt +
          sgstAmt +
          igstAmt +
          (cgstAmt == 0 && igstAmt == 0 && item.taxRate > 0 ? fallbackTaxAmt : 0);

      String taxCellsHtml = '';
      if (isIntraState) {
        taxCellsHtml = '''
          <td>₹${cgstAmt.toStringAsFixed(2)}<br/><span style="font-size: 9px; color: #98A2B3;">(${item.cgstRate.toStringAsFixed(0)}%)</span></td>
          <td>₹${sgstAmt.toStringAsFixed(2)}<br/><span style="font-size: 9px; color: #98A2B3;">(${item.sgstRate.toStringAsFixed(0)}%)</span></td>
        ''';
      } else if (isInterState) {
        taxCellsHtml = '''
          <td>₹${igstAmt.toStringAsFixed(2)}<br/><span style="font-size: 9px; color: #98A2B3;">(${item.igstRate.toStringAsFixed(0)}%)</span></td>
        ''';
      } else {
        taxCellsHtml = '''
          <td>₹${fallbackTaxAmt.toStringAsFixed(2)}<br/><span style="font-size: 9px; color: #98A2B3;">(${item.taxRate.toStringAsFixed(0)}%)</span></td>
        ''';
      }

      return '''
        <tr>
          <td>${idx + 1}</td>
          <td style="text-align: left;">
            <strong>${item.itemName ?? item.description ?? '—'}</strong>
            ${item.description != null && item.description != item.itemName ? '<br/><span style="font-size: 10px; color: #667085;">' + item.description! + '</span>' : ''}
          </td>
          <td>${item.hsnCode ?? '—'}</td>
          <td style="text-align: right;">${qty.toStringAsFixed(2)}${item.unit != null ? ' ' + item.unit! : ''}</td>
          <td style="text-align: right;">
            ₹${rate.toStringAsFixed(2)}
            ${disc > 0 ? '<br/><span style="font-size: 9px; color: #D92D20;">- ' + (discType == 'percent' ? disc.toStringAsFixed(0) + '%' : '₹' + disc.toStringAsFixed(2)) + '</span>' : ''}
          </td>
          <td style="text-align: right;">₹${taxable.toStringAsFixed(2)}</td>
          $taxCellsHtml
          <td style="text-align: right; font-weight: bold;">₹${rowTotal.toStringAsFixed(2)}</td>
        </tr>
      ''';
    }).join('\n');

    String taxHeaderHtml = '';
    if (isIntraState) {
      taxHeaderHtml = '<th style="width: 10%;">CGST</th><th style="width: 10%;">SGST</th>';
    } else if (isInterState) {
      taxHeaderHtml = '<th style="width: 12%;">IGST</th>';
    } else {
      taxHeaderHtml = '<th style="width: 12%;">Tax</th>';
    }

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          @page { size: A4 portrait; margin: 10mm 12mm; }
          body {
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            color: #333;
            margin: 0;
            padding: 20px;
            font-size: 12px;
            line-height: 1.4;
          }
          .header {
            margin-bottom: 30px;
          }
          .company-info {
            text-align: right;
            float: right;
          }
          .title {
            font-size: 28px;
            font-weight: bold;
            color: #1D2939;
            margin-top: 10px;
            clear: both;
          }
          .meta-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            margin-bottom: 20px;
            border: 1px solid #D0D5DD;
          }
          .meta-table td {
            padding: 10px;
            border: 1px solid #D0D5DD;
            vertical-align: top;
          }
          .section-header {
            background-color: #F9FAFB;
            font-weight: bold;
            color: #344054;
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            margin-bottom: 5px;
          }
          .items-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
            margin-bottom: 20px;
            border: 1px solid #D0D5DD;
          }
          .items-table th, .items-table td {
            border: 1px solid #D0D5DD;
            padding: 8px;
            text-align: center;
          }
          .items-table th {
            background-color: #F9FAFB;
            font-weight: bold;
            color: #1D2939;
          }
          .footer-section {
            width: 100%;
            margin-top: 30px;
          }
          .footer-left {
            width: 60%;
            float: left;
            padding-right: 20px;
          }
          .footer-right {
            width: 35%;
            float: right;
            text-align: right;
          }
          .total-row {
            font-weight: bold;
            font-size: 13px;
          }
          .signature-area {
            margin-top: 50px;
            text-align: right;
          }
          .signature-line {
            width: 150px;
            border-top: 1px solid #667085;
            display: inline-block;
            margin-top: 5px;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <div class="company-info">
            <h2 style="margin: 0; color: #1D2939;">$orgName</h2>
            <p style="margin: 2px 0;">$orgAddress</p>
            <p style="margin: 2px 0;">$orgCountry, $orgEmail</p>
          </div>
          <div style="clear: both;"></div>
        </div>

        <div class="title">TAX INVOICE</div>

        <table class="meta-table">
          <tr>
            <td style="width: 33%;">
              <strong>Invoice Number:</strong> ${invoice.invoiceNumber}<br/>
              <strong>Invoice Date:</strong> ${invoice.invoiceDate.toLocal().toString().split(' ')[0]}<br/>
              <strong>Terms:</strong> ${invoice.terms ?? 'Due on Receipt'}<br/>
              <strong>Due Date:</strong> ${invoice.dueDate != null ? invoice.dueDate!.toLocal().toString().split(' ')[0] : '—'}
            </td>
            <td style="width: 33%;">
              <div class="section-header">Bill To</div>
              <strong style="color: #0BA5EC;">$displayCustomerName</strong><br/>
              ${customerEmail != null && customerEmail.isNotEmpty ? customerEmail + '<br/>' : ''}
              ${customerPhone != null && customerPhone.isNotEmpty ? customerPhone + '<br/>' : ''}
              ${invoice.customerGstin != null && invoice.customerGstin!.isNotEmpty ? '<strong>GSTIN:</strong> ' + invoice.customerGstin! : ''}
            </td>
            <td style="width: 34%;">
              <div class="section-header">GST Details</div>
              <strong>Place Of Supply:</strong> ${invoice.placeOfSupply ?? '—'}<br/>
              <strong>GST Type:</strong> ${invoice.gstType == 'intra_state' ? 'Intra-State (CGST+SGST)' : invoice.gstType == 'inter_state' ? 'Inter-State (IGST)' : '—'}
            </td>
          </tr>
        </table>

        <table class="items-table">
          <thead>
            <tr>
              <th style="width: 4%;">#</th>
              <th style="text-align: left; width: 30%;">Item & Description</th>
              <th style="width: 8%;">HSN/SAC</th>
              <th style="width: 8%;">Qty</th>
              <th style="width: 12%;">Rate</th>
              <th style="width: 10%;">Taxable</th>
              $taxHeaderHtml
              <th style="width: 12%;">Amount</th>
            </tr>
          </thead>
          <tbody>
            $itemsRows
          </tbody>
        </table>

        <div class="footer-section">
          <div class="footer-left">
            <p style="margin: 0; font-weight: bold; color: #344054; font-size: 10px;">Total In Words</p>
            <p style="margin: 4px 0; font-style: italic; font-weight: bold; color: #1D2939;">Indian Rupee $totalInWords Only</p>
            
            ${invoice.notes != null && invoice.notes!.isNotEmpty ? '<p style="margin: 15px 0 0 0; font-weight: bold; color: #344054; font-size: 10px;">Notes</p><p style="margin: 4px 0; color: #344054;">' + invoice.notes! + '</p>' : ''}
            ${invoice.terms != null && invoice.terms!.isNotEmpty ? '<p style="margin: 15px 0 0 0; font-weight: bold; color: #344054; font-size: 10px;">Terms & Conditions</p><p style="margin: 4px 0; color: #344054;">' + invoice.terms! + '</p>' : ''}
          </div>
          <div class="footer-right">
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="padding: 5px 0; color: #667085; text-align: left;">Sub Total</td>
                <td style="padding: 5px 0; font-weight: 500; text-align: right;">₹${subtotal.toStringAsFixed(2)}</td>
              </tr>
              ${discountAmount > 0 ? '<tr><td style="padding: 5px 0; color: #DC2626; text-align: left;">Discount</td><td style="padding: 5px 0; color: #DC2626; text-align: right;">-₹' + discountAmount.toStringAsFixed(2) + '</td></tr>' : ''}
              ${cgstAmount > 0 ? '<tr><td style="padding: 5px 0; color: #667085; text-align: left;">CGST</td><td style="padding: 5px 0; text-align: right;">₹' + cgstAmount.toStringAsFixed(2) + '</td></tr>' : ''}
              ${sgstAmount > 0 ? '<tr><td style="padding: 5px 0; color: #667085; text-align: left;">SGST</td><td style="padding: 5px 0; text-align: right;">₹' + sgstAmount.toStringAsFixed(2) + '</td></tr>' : ''}
              ${igstAmount > 0 ? '<tr><td style="padding: 5px 0; color: #667085; text-align: left;">IGST</td><td style="padding: 5px 0; text-align: right;">₹' + igstAmount.toStringAsFixed(2) + '</td></tr>' : ''}
              ${taxAmount > 0 ? '<tr><td style="padding: 5px 0; color: #667085; text-align: left;">Tax</td><td style="padding: 5px 0; text-align: right;">₹' + taxAmount.toStringAsFixed(2) + '</td></tr>' : ''}
              <tr class="total-row">
                <td style="padding: 8px 0; border-top: 1px solid #D0D5DD; text-align: left;">Total</td>
                <td style="padding: 8px 0; border-top: 1px solid #D0D5DD; text-align: right;">₹${invoice.totalAmount.toStringAsFixed(2)}</td>
              </tr>
              <tr class="total-row" style="color: #0BA5EC;">
                <td style="padding: 5px 0; text-align: left;">Balance Due</td>
                <td style="padding: 5px 0; text-align: right;">₹${invoice.balanceDue.toStringAsFixed(2)}</td>
              </tr>
            </table>
            <div class="signature-area">
              <p style="margin: 0; color: #667085; font-size: 9px; font-weight: 500;">Authorized Signature</p>
              <div class="signature-line"></div>
            </div>
          </div>
          <div style="clear: both;"></div>
        </div>
        <div style="text-align: center; margin-top: 40px; padding: 12px 0; border-top: 1px solid #E5E7EB; color: #98A2B3; font-size: 9px;">
          Powered by Eazzio Technology
        </div>
      </body>
      </html>
    ''';
  }
}
