import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/vendor_credits/presentation/providers/vendor_credit_provider.dart';
import 'package:mobile_books/features/vendor_credits/data/services/vendor_credit_service.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile_books/features/bills/presentation/providers/bill_provider.dart';

class VendorCreditDetailScreen extends ConsumerStatefulWidget {
  final int vendorCreditId;

  const VendorCreditDetailScreen({super.key, required this.vendorCreditId});

  @override
  ConsumerState<VendorCreditDetailScreen> createState() => _VendorCreditDetailScreenState();
}

class _VendorCreditDetailScreenState extends ConsumerState<VendorCreditDetailScreen> {
  bool _actionLoading = false;

  Future<void> _deleteVendorCredit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vendor Credit'),
        content: const Text('Are you sure you want to delete this vendor credit? This action cannot be undone.'),
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
      await ref.read(vendorCreditsProvider.notifier).deleteVendorCredit(widget.vendorCreditId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor Credit deleted successfully.')),
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

  void _showApplyCreditDialog(int vendorId, double remainingAmount) {
    final billsState = ref.read(billsProvider);
    billsState.when(
      loading: () {},
      error: (e, s) {},
      data: (list) {
        final unpaidBills = list.where((b) => b.vendorId == vendorId && b.balanceDue > 0).toList();

        if (unpaidBills.isEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Apply Credit'),
              content: const Text('No unpaid bills found for this vendor.'),
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
            int? selectedBillId;
            final amountController = TextEditingController();

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text('Apply Credit to Bill'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: 'Select Bill'),
                        items: unpaidBills.map((b) {
                          return DropdownMenuItem<int>(
                            value: b.id,
                            child: Text('${b.billNumber} (Due: ₹${b.balanceDue.toStringAsFixed(2)})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedBillId = val;
                            if (val != null) {
                              final bill = unpaidBills.firstWhere((b) => b.id == val);
                              final maxApply = bill.balanceDue < remainingAmount ? bill.balanceDue : remainingAmount;
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
                        if (selectedBillId == null) return;
                        final amt = double.tryParse(amountController.text) ?? 0.0;
                        if (amt <= 0 || amt > remainingAmount) return;

                        Navigator.pop(context);
                        setState(() {
                          _actionLoading = true;
                        });

                        try {
                          await ref.read(vendorCreditsProvider.notifier).applyCredit(
                                widget.vendorCreditId,
                                selectedBillId!,
                                amt,
                              );
                          ref.invalidate(billsProvider);
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(content: Text('Successfully applied vendor credit to bill.')),
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

  void _showEmailDialog(String toEmail, String vcNumber) {
    final toController = TextEditingController(text: toEmail);
    final subjectController = TextEditingController(text: 'Vendor Credit $vcNumber details');
    final bodyController = TextEditingController(text: 'Please find details of vendor credit $vcNumber below.');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send via Email'),
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
                await ref.read(vendorCreditServiceProvider).sendEmail(widget.vendorCreditId, {
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
    final detailState = ref.watch(vendorCreditDetailsProvider(widget.vendorCreditId));
    final vendorsState = ref.watch(vendorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Credit Details'),
      ),
      body: _actionLoading
          ? const Center(child: CircularProgressIndicator())
          : detailState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text(err.toString(), style: const TextStyle(color: AppColors.danger))),
              data: (details) {
                final vc = details.vendorCredit;
                final items = details.items;
                final dateStr = DateFormat('dd MMM yyyy').format(vc.vendorCreditDate);

                String vendorName = 'Loading vendor...';
                String vendorEmail = '';
                String billingAddress = '';

                vendorsState.whenData((vendors) {
                  final vendor = vendors.where((v) => v.id == vc.vendorId).firstOrNull;
                  if (vendor != null) {
                    vendorName = vendor.displayName;
                    vendorEmail = vendor.email ?? '';
                    billingAddress = vendor.billingAddress ?? '';
                  }
                });

                final canModify = vc.appliedAmount == 0 && vc.status != 'Void';

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
                                onPressed: () => context.push('/vendor-credits/${vc.id}/edit'),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                onPressed: _deleteVendorCredit,
                              ),
                              const SizedBox(width: AppSpacing.s),
                            ],
                            if (vc.remainingAmount > 0 && vc.status != 'Void') ...[
                              ElevatedButton.icon(
                                icon: const Icon(Icons.compare_arrows),
                                label: const Text('Apply to Bill'),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F80ED)),
                                onPressed: () => _showApplyCreditDialog(vc.vendorId!, vc.remainingAmount),
                              ),
                              const SizedBox(width: AppSpacing.s),
                            ],
                            ElevatedButton.icon(
                              icon: const Icon(Icons.email),
                              label: const Text('Email Details'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF475569)),
                              onPressed: () => _showEmailDialog(vendorEmail, vc.vendorCreditNumber),
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
                                vc.vendorCreditNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBlue),
                              ),
                              Text(
                                vc.status.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: vc.status == 'Void' ? AppColors.danger : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                          // Vendor Address section
                          const Text('Vendor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(vendorName, style: const TextStyle(fontSize: 14)),
                          if (vendorEmail.isNotEmpty) Text(vendorEmail, style: const TextStyle(color: AppColors.textSecondaryLight)),
                          if (billingAddress.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(billingAddress, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                          ],
                          const SizedBox(height: AppSpacing.m),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Date: $dateStr'),
                              if (vc.referenceNumber != null) Text('Ref: ${vc.referenceNumber}'),
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
                                  _summaryRow('Subtotal', vc.subtotal),
                                  _summaryRow('Discount', vc.discountTotal),
                                  _summaryRow('Tax', vc.taxTotal),
                                  const Divider(),
                                  _summaryRow('Total', vc.total, isBold: true),
                                  _summaryRow('Applied', vc.appliedAmount),
                                  _summaryRow('Remaining', vc.remainingAmount, isBold: true, isRemaining: true),
                                ],
                              ),
                            ),
                          ),
                          if (vc.reason != null && vc.reason!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.m),
                            Text('Reason: ${vc.reason}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                          ],
                          if (vc.notes != null && vc.notes!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.m),
                            Text('Notes:\n${vc.notes}', style: const TextStyle(fontSize: 13)),
                          ],
                          if (vc.termsConditions != null && vc.termsConditions!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.m),
                            Text('Terms & Conditions:\n${vc.termsConditions}', style: const TextStyle(fontSize: 13)),
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
