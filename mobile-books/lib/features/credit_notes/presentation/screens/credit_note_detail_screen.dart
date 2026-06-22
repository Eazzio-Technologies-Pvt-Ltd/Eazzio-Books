import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/credit_notes/presentation/providers/credit_note_provider.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';
import 'package:mobile_books/features/invoices/presentation/providers/invoice_provider.dart';

class CreditNoteDetailScreen extends ConsumerStatefulWidget {
  final int creditNoteId;

  const CreditNoteDetailScreen({super.key, required this.creditNoteId});

  @override
  ConsumerState<CreditNoteDetailScreen> createState() => _CreditNoteDetailScreenState();
}

class _CreditNoteDetailScreenState extends ConsumerState<CreditNoteDetailScreen> {
  bool _actionLoading = false;

  Future<void> _deleteCreditNote() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Credit Note'),
        content: const Text('Are you sure you want to delete this credit note? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _actionLoading = true;
    });

    try {
      await ref.read(creditNotesProvider.notifier).deleteCreditNote(widget.creditNoteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credit Note deleted successfully.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  Future<void> _cancelCreditNote() async {
    setState(() {
      _actionLoading = true;
    });

    try {
      await ref.read(creditNotesProvider.notifier).cancelCreditNote(widget.creditNoteId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credit Note cancelled.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  void _showApplyCreditDialog(int customerId, double remainingAmount) {
    final invoicesState = ref.read(invoicesProvider);
    invoicesState.when(
      loading: () {},
      error: (e, s) {},
      data: (list) {
        final unpaidInvoices = list.where((inv) => inv.customerId == customerId && inv.balanceDue > 0).toList();

        if (unpaidInvoices.isEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Apply Credit'),
              content: const Text('No unpaid invoices found for this customer.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
              ],
            ),
          );
          return;
        }

        showDialog(
          context: context,
          builder: (context) {
            int? selectedInvoiceId;
            final amountController = TextEditingController();

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text('Apply Credit to Invoice'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Select Invoice'),
                        items: unpaidInvoices.map((inv) {
                          return DropdownMenuItem<int>(
                            value: inv.id,
                            child: Text('${inv.invoiceNumber} (Due: ₹${inv.balanceDue.toStringAsFixed(2)})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedInvoiceId = val;
                            if (val != null) {
                              final invoice = unpaidInvoices.firstWhere((i) => i.id == val);
                              final maxApply = invoice.balanceDue < remainingAmount ? invoice.balanceDue : remainingAmount;
                              amountController.text = maxApply.toStringAsFixed(2);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount to Apply',
                          prefixText: '₹ ',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedInvoiceId == null) return;
                        final amt = double.tryParse(amountController.text) ?? 0.0;
                        if (amt <= 0 || amt > remainingAmount) return;

                        Navigator.pop(context);
                        setState(() {
                          _actionLoading = true;
                        });

                        try {
                          await ref.read(creditNotesProvider.notifier).applyCreditToInvoice(
                                widget.creditNoteId,
                                selectedInvoiceId!,
                                amt,
                              );
                          ref.invalidate(invoicesProvider);
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Successfully applied credit note to invoice.')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _actionLoading = false;
                            });
                          }
                        }
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showEmailDialog(String toEmail, String cnNumber) {
    final toController = TextEditingController(text: toEmail);
    final subjectController = TextEditingController(text: 'Credit Note $cnNumber from Tinplate');
    final bodyController = TextEditingController(text: 'Please find attached the credit note details in PDF.');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Credit Note via Email'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: toController,
                decoration: const InputDecoration(labelText: 'To Email *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Body Text'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (toController.text.trim().isEmpty) return;
              Navigator.pop(context);
              setState(() {
                _actionLoading = true;
              });
              try {
                await ref.read(creditNotesProvider.notifier).sendEmail(widget.creditNoteId, {
                  'to': toController.text.trim(),
                  'subject': subjectController.text.trim(),
                  'body': bodyController.text.trim(),
                });
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(content: Text('Email dispatched successfully.')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              } finally {
                if (mounted) {
                  setState(() {
                    _actionLoading = false;
                  });
                }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(creditNoteDetailsProvider(widget.creditNoteId));
    final customersState = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credit Note Details'),
      ),
      body: _actionLoading
          ? const Center(child: CircularProgressIndicator())
          : detailState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text(err.toString(), style: const TextStyle(color: AppColors.danger))),
              data: (details) {
                final cn = details.creditNote;
                final items = details.items;
                final dateStr = DateFormat('dd MMM yyyy').format(cn.creditNoteDate);

                String customerName = 'Loading customer...';
                String customerEmail = '';
                String billingAddress = '';

                customersState.whenData((customers) {
                  final customer = customers.where((c) => c.id == cn.customerId).firstOrNull;
                  if (customer != null) {
                    customerName = customer.displayName ?? '${customer.firstName ?? ""} ${customer.lastName ?? ""}'.trim();
                    customerEmail = customer.email ?? '';
                    billingAddress = customer.billingAddress ?? '';
                  }
                });

                final canModify = cn.appliedAmount == 0 && cn.status != 'Cancelled';

                return Column(
                  children: [
                    // Action Buttons Row
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (canModify) ...[
                              ElevatedButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                                onPressed: () => context.push('/credit-notes/${cn.id}/edit'),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancel CN'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.textSecondaryLight),
                                onPressed: _cancelCreditNote,
                              ),
                              const SizedBox(width: AppSpacing.s),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                onPressed: _deleteCreditNote,
                              ),
                              const SizedBox(width: AppSpacing.s),
                            ],
                            if (cn.remainingAmount > 0 && cn.status != 'Cancelled') ...[
                              ElevatedButton.icon(
                                icon: const Icon(Icons.payment),
                                label: const Text('Apply to Invoice'),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F80ED)),
                                onPressed: () => _showApplyCreditDialog(cn.customerId!, cn.remainingAmount),
                              ),
                              const SizedBox(width: AppSpacing.s),
                            ],
                            ElevatedButton.icon(
                              icon: const Icon(Icons.email),
                              label: const Text('Email PDF'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF475569)),
                              onPressed: () => _showEmailDialog(customerEmail, cn.creditNoteNumber),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    // Main overview
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                cn.creditNoteNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBlue),
                              ),
                              Text(
                                cn.status.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: cn.status == 'Cancelled' ? AppColors.danger : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                          // Customer Address section
                          const Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(customerName, style: const TextStyle(fontSize: 14)),
                          if (customerEmail.isNotEmpty) Text(customerEmail, style: const TextStyle(color: AppColors.textSecondaryLight)),
                          if (billingAddress.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(billingAddress, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                          ],
                          const SizedBox(height: AppSpacing.m),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Date: $dateStr'),
                              if (cn.referenceNumber != null) Text('Ref: ${cn.referenceNumber}'),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                          const Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: AppSpacing.s),
                          // List of lines
                          ...items.map((item) => Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.s),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            if (item.description != null)
                                              Text(item.description!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                                            Text('${item.quantity} × ₹${item.rate.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      Text('₹${item.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              )),
                          const SizedBox(height: AppSpacing.xl),
                          // Summary block
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              width: 250,
                              padding: const EdgeInsets.all(AppSpacing.s),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6)),
                              child: Column(
                                children: [
                                  _summaryRow('Subtotal', cn.subtotal),
                                  _summaryRow('Discount', cn.discountTotal),
                                  _summaryRow('Tax', cn.taxTotal),
                                  const Divider(),
                                  _summaryRow('Total', cn.total, isBold: true),
                                  _summaryRow('Applied', cn.appliedAmount),
                                  _summaryRow('Remaining', cn.remainingAmount, isBold: true, isRemaining: true),
                                ],
                              ),
                            ),
                          ),
                          if (cn.reason != null && cn.reason!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.m),
                            Text('Reason: ${cn.reason}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                          ],
                          if (cn.notes != null && cn.notes!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.m),
                            Text('Notes:\n${cn.notes}', style: const TextStyle(fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false, bool isRemaining = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isRemaining && amount > 0 ? const Color(0xFF1D4ED8) : null,
            ),
          ),
        ],
      ),
    );
  }
}
