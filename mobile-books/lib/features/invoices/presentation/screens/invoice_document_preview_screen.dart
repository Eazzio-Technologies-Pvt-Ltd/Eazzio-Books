import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/settings/presentation/providers/settings_providers.dart';
import 'package:mobile_books/features/invoices/presentation/providers/invoice_provider.dart';
import 'package:mobile_books/features/invoices/data/services/invoice_service.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_books/core/utils/pdf_helper.dart';

class InvoiceDocumentPreviewScreen extends ConsumerStatefulWidget {
  final int invoiceId;

  const InvoiceDocumentPreviewScreen({
    key,
    required this.invoiceId,
  }) : super(key: key);

  @override
  ConsumerState<InvoiceDocumentPreviewScreen> createState() => _InvoiceDocumentPreviewScreenState();
}

class _InvoiceDocumentPreviewScreenState extends ConsumerState<InvoiceDocumentPreviewScreen> {
  bool _isLoading = false;

  Future<void> _exportAndSavePdf(BuildContext context, String url, String defaultFileName) async {
    setState(() => _isLoading = true);
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      
      if (response.data == null) {
        throw Exception('Empty data received from server');
      }
      
      final bytes = Uint8List.fromList(response.data!);
      String? outputFile;
      
      if (Platform.isAndroid || Platform.isIOS) {
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/$defaultFileName';
        final file = File(tempPath);
        await file.writeAsBytes(bytes);
        
        outputFile = await FilePicker.saveFile(
          dialogTitle: 'Save PDF to...',
          fileName: defaultFileName,
          bytes: bytes,
        );
        
        if (outputFile == null) {
          final appDocDir = await getExternalStorageDirectory();
          if (appDocDir != null) {
            final downloadPath = '${appDocDir.path}/$defaultFileName';
            final downloadFile = File(downloadPath);
            await downloadFile.writeAsBytes(bytes);
            outputFile = downloadPath;
          } else {
            final docDir = await getApplicationDocumentsDirectory();
            final docPath = '${docDir.path}/$defaultFileName';
            final docFile = File(docPath);
            await docFile.writeAsBytes(bytes);
            outputFile = docPath;
          }
        }
      } else {
        outputFile = await FilePicker.saveFile(
          dialogTitle: 'Save PDF to...',
          fileName: defaultFileName,
          bytes: bytes,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved successfully: ${outputFile?.split('/').last ?? defaultFileName}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _numberToWords(int number) {
    if (number == 0) return 'Zero';
    final units = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];
    
    String convert(int n) {
      if (n < 20) return units[n];
      if (n < 100) return tens[n ~/ 10] + (n % 10 != 0 ? ' ${units[n % 10]}' : '');
      if (n < 1000) return '${units[n ~/ 100]} Hundred${n % 100 != 0 ? ' ${convert(n % 100)}' : ''}';
      if (n < 100000) return '${convert(n ~/ 1000)} Thousand${n % 1000 != 0 ? ' ${convert(n % 1000)}' : ''}';
      if (n < 10000000) return '${convert(n ~/ 100000)} Lakh${n % 100000 != 0 ? ' ${convert(n % 100000)}' : ''}';
      return '${convert(n ~/ 10000000)} Crore${n % 10000000 != 0 ? ' ${convert(n % 10000000)}' : ''}';
    }
    return convert(number).trim();
  }

  Color _getRibbonColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return const Color(0xFF475569);
      case 'sent':
      case 'unpaid':
      case 'partially_paid':
        return const Color(0xFFB45309);
      case 'paid':
        return const Color(0xFF047857);
      case 'cancelled':
        return const Color(0xFF475569);
      case 'overdue':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Future<void> _printDocument(InvoiceDetails details) async {
    setState(() => _isLoading = true);
    try {
      final bytes = await ref.read(invoiceServiceProvider).downloadInvoicePDF(widget.invoiceId);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Invoice_${details.invoice.invoiceNumber}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to print document: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sharePdf(InvoiceDetails details) async {
    setState(() => _isLoading = true);
    try {
      final bytes = await ref.read(invoiceServiceProvider).downloadInvoicePDF(widget.invoiceId);
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/Invoice_${details.invoice.invoiceNumber}.pdf';
      final file = File(tempPath);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(tempPath, mimeType: 'application/pdf')],
        text: 'Invoice ${details.invoice.invoiceNumber} details.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share document: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _shareWebLink(InvoiceDetails details) {
    final invoice = details.invoice;
    final shareText = 'Invoice ${invoice.invoiceNumber}\nTotal Amount: ₹${invoice.totalAmount.toStringAsFixed(2)}\nDue Date: ${invoice.dueDate != null ? invoice.dueDate!.toLocal().toString().split(' ')[0] : '—'}\nBalance Due: ₹${invoice.balanceDue.toStringAsFixed(2)}\nStatus: ${invoice.status.toUpperCase()}';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(invoiceDetailsProvider(widget.invoiceId));
    final invoiceDetails = detailState.value;
    final customerState = invoiceDetails != null
        ? ref.watch(customerDetailsProvider(invoiceDetails.invoice.customerId))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Document Preview'),
        actions: [
          if (invoiceDetails != null) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share PDF',
              onPressed: _isLoading ? null : () => _sharePdf(invoiceDetails),
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Print',
              onPressed: _isLoading ? null : () => _printDocument(invoiceDetails),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Share Details',
              onPressed: _isLoading ? null : () => _shareWebLink(invoiceDetails),
            ),
          ]
        ],
      ),
      body: detailState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err', style: const TextStyle(color: AppColors.danger)),
        ),
        data: (details) {
          final invoice = details.invoice;
          final items = details.items;
          final ribbonColor = _getRibbonColor(invoice.status);
          final totalWords = _numberToWords(invoice.totalAmount.floor());
          final isIntraState = invoice.gstType == 'intra_state';
          final isInterState = invoice.gstType == 'inter_state';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFEAECF0)),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        // Diagonal Ribbon Status
                        Positioned(
                          top: 0,
                          left: 0,
                          child: ClipRect(
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 16,
                                    left: -32,
                                    child: Transform.rotate(
                                      angle: -0.785398, // -45 degrees in radians
                                      child: Container(
                                        width: 140,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        color: ribbonColor,
                                        child: Text(
                                          invoice.status.toUpperCase().replaceAll('_', ' '),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Document Content
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.l,
                            right: AppSpacing.l,
                            top: 40,
                            bottom: AppSpacing.l,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Document Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildCompanyHeader(ref)),
                                  const SizedBox(width: AppSpacing.m),
                                  const Text(
                                    'TAX INVOICE',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D2939),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Redesigned Bordered Box Container
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFD0D5DD)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Meta Row Container
                                    Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: Color(0xFFD0D5DD)),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                border: Border(
                                                  right: BorderSide(color: Color(0xFFD0D5DD)),
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildMetaField('Invoice Number', ': INV-${invoice.invoiceNumber}', isBold: true),
                                                  const SizedBox(height: 4),
                                                  _buildMetaField('Invoice Date', ': ${invoice.invoiceDate.toLocal().toString().split(' ')[0]}'),
                                                  const SizedBox(height: 4),
                                                  _buildMetaField('Terms', ': ${invoice.terms ?? 'Due on Receipt'}'),
                                                  const SizedBox(height: 4),
                                                  _buildMetaField('Due Date', ': ${invoice.dueDate != null ? invoice.dueDate!.toLocal().toString().split(' ')[0] : '—'}'),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const Expanded(child: SizedBox.shrink()),
                                        ],
                                      ),
                                    ),

                                    // Bill To & GST Details Header
                                    Container(
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: Color(0xFFD0D5DD)),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Bill To Section
                                          Expanded(
                                            child: Container(
                                              decoration: const BoxDecoration(
                                                border: Border(
                                                  right: BorderSide(color: Color(0xFFD0D5DD)),
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'BILL TO',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF344054),
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  customerState == null
                                                      ? const Text('Customer details unavailable')
                                                      : customerState.when(
                                                          loading: () => const Text('Loading customer...'),
                                                          error: (e, _) => Text('Error: $e'),
                                                          data: (cust) => Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                cust.formattedName,
                                                                style: const TextStyle(
                                                                  color: Color(0xFF0BA5EC),
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 13,
                                                                ),
                                                              ),
                                                              if (cust.email != null && cust.email!.isNotEmpty) ...[
                                                                const SizedBox(height: 2),
                                                                Text(cust.email!, style: const TextStyle(color: Color(0xFF344054), fontSize: 11)),
                                                              ],
                                                              if (cust.phone != null && cust.phone!.isNotEmpty) ...[
                                                                const SizedBox(height: 2),
                                                                Text(cust.phone!, style: const TextStyle(color: Color(0xFF344054), fontSize: 11)),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                  if (invoice.customerGstin != null && invoice.customerGstin!.isNotEmpty) ...[
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'GSTIN: ${invoice.customerGstin}',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D2939), fontSize: 11),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                          // GST Details Section
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'GST DETAILS',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF344054),
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      const SizedBox(
                                                        width: 100,
                                                        child: Text(
                                                          'Place Of Supply',
                                                          style: TextStyle(color: Color(0xFF344054), fontSize: 11),
                                                        ),
                                                      ),
                                                      Text(': ${invoice.placeOfSupply ?? '—'}', style: const TextStyle(color: Color(0xFF344054), fontSize: 11)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      const SizedBox(
                                                        width: 100,
                                                        child: Text(
                                                          'GST Type',
                                                          style: TextStyle(color: Color(0xFF344054), fontSize: 11),
                                                        ),
                                                      ),
                                                      Text(
                                                        ': ${invoice.gstType == 'intra_state' ? 'Intra-State (CGST+SGST)' : invoice.gstType == 'inter_state' ? 'Inter-State (IGST)' : '—'}',
                                                        style: const TextStyle(color: Color(0xFF344054), fontSize: 11),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Items Table
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Container(
                                        constraints: const BoxConstraints(minWidth: 700),
                                        child: Table(
                                          columnWidths: {
                                            0: const FixedColumnWidth(30),  // #
                                            1: const FlexColumnWidth(3),    // Item & Description
                                            2: const FixedColumnWidth(75),  // HSN/SAC
                                            3: const FixedColumnWidth(50),  // Qty
                                            4: const FixedColumnWidth(65),  // Rate
                                            5: const FixedColumnWidth(75),  // Taxable
                                            if (isIntraState) ...{
                                              6: const FixedColumnWidth(65), // CGST
                                              7: const FixedColumnWidth(65), // SGST
                                            } else if (isInterState) ...{
                                              6: const FixedColumnWidth(65), // IGST
                                            } else ...{
                                              6: const FixedColumnWidth(65), // Tax fallback
                                            },
                                            if (isIntraState) 8: const FixedColumnWidth(80) else 7: const FixedColumnWidth(80), // Amount
                                          },
                                          children: [
                                            // Table Header
                                            TableRow(
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                border: Border(
                                                  bottom: BorderSide(color: Color(0xFFD0D5DD)),
                                                ),
                                              ),
                                              children: [
                                                _buildTableHeaderCell('#', align: TextAlign.left),
                                                _buildTableHeaderCell('Item & Description', align: TextAlign.left),
                                                _buildTableHeaderCell('HSN/SAC', align: TextAlign.center),
                                                _buildTableHeaderCell('Qty', align: TextAlign.right),
                                                _buildTableHeaderCell('Rate', align: TextAlign.right),
                                                _buildTableHeaderCell('Taxable', align: TextAlign.right),
                                                if (isIntraState) ...[
                                                  _buildTableHeaderCell('CGST', align: TextAlign.right),
                                                  _buildTableHeaderCell('SGST', align: TextAlign.right),
                                                ] else if (isInterState) ...[
                                                  _buildTableHeaderCell('IGST', align: TextAlign.right),
                                                ] else ...[
                                                  _buildTableHeaderCell('Tax', align: TextAlign.right),
                                                ],
                                                _buildTableHeaderCell('Amount', align: TextAlign.right),
                                              ],
                                            ),
                                            // Table Rows
                                            ...items.asMap().entries.map((entry) {
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

                                              return TableRow(
                                                decoration: const BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(color: Color(0xFFEAECF0)),
                                                  ),
                                                ),
                                                children: [
                                                  _buildTableCell((idx + 1).toString(), align: TextAlign.left),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          item.itemName ?? item.description ?? '—',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w600,
                                                            color: Color(0xFF1D2939),
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        if (item.itemName != null &&
                                                            item.description != null &&
                                                            item.description != item.itemName) ...[
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            item.description!,
                                                            style: const TextStyle(
                                                              color: Color(0xFF667085),
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  _buildTableCell(item.hsnCode ?? '—', align: TextAlign.center),
                                                  _buildTableCell('${qty.toStringAsFixed(2)}${item.unit != null ? ' ${item.unit}' : ''}', align: TextAlign.right),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Text(rate.toStringAsFixed(2), style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                                        if (disc > 0) ...[
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            '- ${discType == 'percent' ? '${disc.toStringAsFixed(0)}%' : '₹${disc.toStringAsFixed(2)}'}',
                                                            style: const TextStyle(fontSize: 9, color: Color(0xFFD92D20)),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  _buildTableCell(taxable.toStringAsFixed(2), align: TextAlign.right),
                                                  if (isIntraState) ...[
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          Text(cgstAmt.toStringAsFixed(2), style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                                          Text('(${item.cgstRate.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 9, color: Color(0xFF98A2B3))),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          Text(sgstAmt.toStringAsFixed(2), style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                                          Text('(${item.sgstRate.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 9, color: Color(0xFF98A2B3))),
                                                        ],
                                                      ),
                                                    ),
                                                  ] else if (isInterState) ...[
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          Text(igstAmt.toStringAsFixed(2), style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                                          Text('(${item.igstRate.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 9, color: Color(0xFF98A2B3))),
                                                        ],
                                                      ),
                                                    ),
                                                  ] else ...[
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.end,
                                                        children: [
                                                          Text(fallbackTaxAmt.toStringAsFixed(2), style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                                          Text('(${item.taxRate.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 9, color: Color(0xFF98A2B3))),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                  _buildTableCell(rowTotal.toStringAsFixed(2), align: TextAlign.right, isBold: true, color: const Color(0xFF1D2939)),
                                                ],
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Totals and Notes Footer
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Left Footer: Words & Notes
                                        Expanded(
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                right: BorderSide(color: Color(0xFFD0D5DD)),
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Total In Words',
                                                  style: TextStyle(color: Color(0xFF344054), fontWeight: FontWeight.w500, fontSize: 11),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Indian Rupee $totalWords Only',
                                                  style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1D2939),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                                                  const SizedBox(height: 16),
                                                  const Text(
                                                    'Notes',
                                                    style: TextStyle(color: Color(0xFF344054), fontWeight: FontWeight.w500, fontSize: 11),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    invoice.notes!,
                                                    style: const TextStyle(color: Color(0xFF344054), fontSize: 11),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Right Footer: Subtotal, Grand Total, Balance Due, Signature
                                        Container(
                                          width: 180,
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text('Sub Total', style: TextStyle(color: Color(0xFF667085), fontSize: 11)),
                                                  Text(invoice.totalAmount.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Total',
                                                    style: TextStyle(color: Color(0xFF1D2939), fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                  Text(
                                                    '₹${invoice.totalAmount.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF1D2939),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Balance Due',
                                                    style: TextStyle(color: Color(0xFF1D2939), fontWeight: FontWeight.bold, fontSize: 12),
                                                  ),
                                                  Text(
                                                    '₹${invoice.balanceDue.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF0BA5EC),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 32),
                                              const Center(
                                                child: Text(
                                                  'Authorized Signature',
                                                  style: TextStyle(color: Color(0xFF667085), fontWeight: FontWeight.w500, fontSize: 10),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (invoice.terms != null && invoice.terms!.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Text(
                                  'Terms & Conditions:\n${invoice.terms!}',
                                  style: const TextStyle(color: Color(0xFF667085), fontSize: 10),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetaField(String label, String val, {bool isBold = false}) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF344054), fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            val,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF344054),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text, {required TextAlign align}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1D2939),
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {required TextAlign align, bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? const Color(0xFF475569),
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(WidgetRef ref) {
    final settingsState = ref.watch(organizationSettingsProvider);
    return settingsState.maybeWhen(
      data: (settings) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settings.organizationName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2939),
            ),
          ),
          if (settings.address != null && settings.address!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              settings.address!,
              style: const TextStyle(fontSize: 11, color: Color(0xFF344054)),
            ),
          ],
          if (settings.country != null && settings.country!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              settings.country!,
              style: const TextStyle(fontSize: 11, color: Color(0xFF344054)),
            ),
          ],
          if (settings.organizationEmail != null && settings.organizationEmail!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              settings.organizationEmail!,
              style: const TextStyle(fontSize: 11, color: Color(0xFF344054)),
            ),
          ],
        ],
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
