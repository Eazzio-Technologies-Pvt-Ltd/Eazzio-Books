import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/quotes/presentation/providers/quote_provider.dart';
import 'package:mobile_books/features/quotes/data/services/quote_service.dart';

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

  Future<void> _handleShare(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(quoteServiceProvider);
      final url = service.getQuotePdfUrl(widget.quoteId);
      
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote PDF URL copied to clipboard!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(quoteDetailsProvider(widget.quoteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Document Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isLoading ? null : () => _handleShare(context),
          ),
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
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QUOTE STATEMENT',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const Divider(),
                          const SizedBox(height: AppSpacing.s),
                          Text('Quote Number: ${quote.quoteNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Quote Date: ${quote.quoteDate.toLocal().toString().split(' ')[0]}'),
                          Text('Expiry Date: ${quote.expiryDate != null ? quote.expiryDate!.toLocal().toString().split(' ')[0] : '—'}'),
                          const SizedBox(height: AppSpacing.m),
                          const Text('Items Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: AppSpacing.xs),
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2),
                              1: FlexColumnWidth(1),
                              2: FlexColumnWidth(1.2),
                            },
                            border: TableBorder.all(color: AppColors.borderLight),
                            children: [
                              const TableRow(
                                decoration: BoxDecoration(color: AppColors.backgroundLight),
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                                  ),
                                ],
                              ),
                              ...items.map((item) {
                                return TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(item.itemName ?? item.description ?? '—'),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(item.quantity.toStringAsFixed(0), textAlign: TextAlign.right),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('₹${(item.quantity * item.unitPrice).toStringAsFixed(2)}', textAlign: TextAlign.right),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.l),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Total: ₹${quote.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                              ),
                            ],
                          ),
                          if (quote.notes != null && quote.notes!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.m),
                            const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(quote.notes!),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download PDF Link'),
                    onPressed: () {
                      final url = ref.read(quoteServiceProvider).getQuotePdfUrl(widget.quoteId);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Quote PDF URL'),
                          content: SelectableText(url),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
