import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/settings/presentation/providers/settings_providers.dart';
import 'package:mobile_books/features/quotes/presentation/providers/quote_provider.dart';
import 'package:mobile_books/features/quotes/data/services/quote_service.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_books/core/utils/pdf_helper.dart';

class QuoteDocumentPreviewScreen extends ConsumerStatefulWidget {
  final int quoteId;

  const QuoteDocumentPreviewScreen({
    super.key,
    required this.quoteId,
  });

  @override
  ConsumerState<QuoteDocumentPreviewScreen> createState() => _QuoteDocumentPreviewScreenState();
}

class _QuoteDocumentPreviewScreenState extends ConsumerState<QuoteDocumentPreviewScreen> {
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
        String msg = 'Failed to save PDF: $e';
        if (e is DioException && e.response?.statusCode == 404) {
          msg = 'Direct PDF download is not supported by the backend for quotes. Please use the "Email Statement" option on Quote Details instead.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
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
        return const Color(0xFFB45309);
      case 'accepted':
        return const Color(0xFF047857);
      case 'declined':
      case 'expired':
        return const Color(0xFFB91C1C);
      case 'invoiced':
        return const Color(0xFF0F766E);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Future<Uint8List> _generatePdfBytes(QuoteDetails details) async {
    final quote = details.quote;
    final items = details.items;
    final totalWords = _numberToWords(quote.totalAmount.floor());

    final settings = ref.read(organizationSettingsProvider).value;
    final customer = ref.read(customerDetailsProvider(quote.customerId)).value;

    final html = PdfHelper.generateQuoteHtml(
      quote: quote,
      items: items,
      customer: customer,
      settings: settings,
      totalInWords: totalWords,
    );

    return await Printing.convertHtml(
      format: PdfPageFormat.a4,
      html: html,
    );
  }

  Future<void> _printDocument(QuoteDetails details) async {
    setState(() => _isLoading = true);
    try {
      final bytes = await _generatePdfBytes(details);
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Quote_${details.quote.quoteNumber}.pdf',
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

  Future<void> _sharePdf(QuoteDetails details) async {
    setState(() => _isLoading = true);
    try {
      final bytes = await _generatePdfBytes(details);
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/Quote_${details.quote.quoteNumber}.pdf';
      final file = File(tempPath);
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(tempPath, mimeType: 'application/pdf')],
        text: 'Quote ${details.quote.quoteNumber} details.',
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

  void _shareWebLink(QuoteDetails details) {
    final quote = details.quote;
    final shareText = 'Quote ${quote.quoteNumber}\nTotal Amount: ₹${quote.totalAmount.toStringAsFixed(2)}\nExpiry Date: ${quote.expiryDate != null ? quote.expiryDate!.toLocal().toString().split(' ')[0] : '—'}\nStatus: ${quote.status.toUpperCase()}';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(quoteDetailsProvider(widget.quoteId));
    final quoteDetails = detailState.value;
    final customerState = quoteDetails != null
        ? ref.watch(customerDetailsProvider(quoteDetails.quote.customerId))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Document Preview'),
        actions: [
          if (quoteDetails != null) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share PDF',
              onPressed: _isLoading ? null : () => _sharePdf(quoteDetails),
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Print',
              onPressed: _isLoading ? null : () => _printDocument(quoteDetails),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'Share Details',
              onPressed: _isLoading ? null : () => _shareWebLink(quoteDetails),
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
          final quote = details.quote;
          final items = details.items;
          final ribbonColor = _getRibbonColor(quote.status);
          final totalWords = _numberToWords(quote.totalAmount.floor());

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
                                          quote.status.toUpperCase(),
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
                                    'QUOTE',
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
                                                  _buildMetaField('Quote Number', ': ${quote.quoteNumber}', isBold: true),
                                                  const SizedBox(height: 4),
                                                  _buildMetaField('Quote Date', ': ${quote.quoteDate.toLocal().toString().split(' ')[0]}'),
                                                  const SizedBox(height: 4),
                                                  _buildMetaField('Expiry Date', ': ${quote.expiryDate != null ? quote.expiryDate!.toLocal().toString().split(' ')[0] : '—'}'),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const Expanded(child: SizedBox.shrink()),
                                        ],
                                      ),
                                    ),

                                    // Bill To Header
                                    Container(
                                      color: const Color(0xFFF9FAFB),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: Color(0xFFD0D5DD)),
                                        ),
                                      ),
                                      child: const Text(
                                        'BILL TO',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF344054),
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),

                                    // Customer Details
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(color: Color(0xFFD0D5DD)),
                                        ),
                                      ),
                                      child: customerState == null
                                          ? const Text('Customer Details Unavailable')
                                          : customerState.when(
                                              loading: () => const Text('Loading customer...'),
                                              error: (e, _) => Text('Error loading customer: $e'),
                                              data: (cust) => Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    cust.formattedName,
                                                    style: const TextStyle(
                                                      color: Color(0xFF006EE6),
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  if (cust.email != null && cust.email!.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(cust.email!, style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
                                                  ],
                                                  if (cust.phone != null && cust.phone!.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(cust.phone!, style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
                                                  ],
                                                ],
                                              ),
                                            ),
                                    ),

                                    // Items Table
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Container(
                                        constraints: const BoxConstraints(minWidth: 600),
                                        child: Table(
                                          columnWidths: const {
                                            0: FixedColumnWidth(30),  // #
                                            1: FlexColumnWidth(3),    // Item & Description
                                            2: FixedColumnWidth(75),  // HSN/SAC
                                            3: FixedColumnWidth(50),  // Qty
                                            4: FixedColumnWidth(65),  // Rate
                                            5: FixedColumnWidth(55),  // Disc
                                            6: FixedColumnWidth(50),  // Tax%
                                            7: FixedColumnWidth(75),  // Amount
                                          },
                                          children: [
                                            // Table Header
                                            TableRow(
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFF9FAFB),
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
                                                _buildTableHeaderCell('Disc', align: TextAlign.right),
                                                _buildTableHeaderCell('Tax%', align: TextAlign.right),
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
                                              final taxRate = item.taxRate;
                                              
                                              double lineAmt = qty * rate;
                                              if (discType == 'percent') {
                                                lineAmt -= lineAmt * (disc / 100);
                                              } else {
                                                lineAmt -= disc;
                                              }
                                              final taxAmt = lineAmt * (taxRate / 100);
                                              final lineTotal = lineAmt + taxAmt;

                                              return TableRow(
                                                decoration: const BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(color: Color(0xFFD0D5DD)),
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
                                                            color: Color(0xFF344054),
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
                                                  _buildTableCell(item.hsnCode ?? '—', align: TextAlign.center, color: const Color(0xFF667085)),
                                                  _buildTableCell('${qty.toStringAsFixed(2)}${item.unit != null ? ' ${item.unit}' : ''}', align: TextAlign.right),
                                                  _buildTableCell(rate.toStringAsFixed(2), align: TextAlign.right),
                                                  _buildTableCell(
                                                    disc > 0
                                                        ? (discType == 'percent' ? '${disc.toStringAsFixed(0)}%' : '₹${disc.toStringAsFixed(2)}')
                                                        : '—',
                                                    align: TextAlign.right,
                                                    color: const Color(0xFFDC2626),
                                                  ),
                                                  _buildTableCell(taxRate > 0 ? '${taxRate.toStringAsFixed(0)}%' : '—', align: TextAlign.right),
                                                  _buildTableCell('₹${lineTotal.toStringAsFixed(2)}', align: TextAlign.right, isBold: true, color: const Color(0xFF1D2939)),
                                                ],
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Footer Row (Words & Totals)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Left Footer: Words, Notes
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
                                                  style: TextStyle(color: Color(0xFF667085), fontWeight: FontWeight.w500, fontSize: 11),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Indian Rupee $totalWords Only',
                                                  style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF344054),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                const Text(
                                                  'Notes',
                                                  style: TextStyle(color: Color(0xFF667085), fontWeight: FontWeight.w500, fontSize: 11),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  quote.notes ?? 'Looking forward for your business.',
                                                  style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Right Footer: Subtotal, Grand Total, Signature
                                        Container(
                                          width: 180,
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text('Sub Total', style: TextStyle(color: Color(0xFF667085), fontSize: 11)),
                                                  Text(quote.totalAmount.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11)),
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
                                                    '₹${quote.totalAmount.toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF006EE6),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 32),
                                              const Text(
                                                'Authorized Signature',
                                                style: TextStyle(color: Color(0xFF667085), fontWeight: FontWeight.w500, fontSize: 10),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Expiry Terms
                              if (quote.terms != null && quote.terms!.isNotEmpty) ...[
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.only(top: 16),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Color(0xFFD0D5DD), style: BorderStyle.solid),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Terms & Conditions:',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF667085), fontSize: 11),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        quote.terms!,
                                        style: const TextStyle(color: Color(0xFF667085), fontSize: 10),
                                      ),
                                    ],
                                  ),
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
          width: 90,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF667085), fontWeight: FontWeight.w500, fontSize: 11),
          ),
        ),
        Expanded(
          child: Text(
            val,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: const Color(0xFF1D2939),
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
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ],
          if (settings.country != null && settings.country!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              settings.country!,
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ],
          if (settings.organizationEmail != null && settings.organizationEmail!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              settings.organizationEmail!,
              style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
            ),
          ],
        ],
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
