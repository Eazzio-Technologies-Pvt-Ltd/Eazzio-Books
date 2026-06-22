import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/delivery_challans/presentation/providers/delivery_challan_provider.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';

class DeliveryChallanDetailScreen extends ConsumerStatefulWidget {
  final int challanId;

  const DeliveryChallanDetailScreen({super.key, required this.challanId});

  @override
  ConsumerState<DeliveryChallanDetailScreen> createState() => _DeliveryChallanDetailScreenState();
}

class _DeliveryChallanDetailScreenState extends ConsumerState<DeliveryChallanDetailScreen> {
  bool _actionLoading = false;

  Future<void> _deleteChallan() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Delivery Challan'),
        content: const Text('Are you sure you want to delete this challan? This action cannot be undone.'),
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
      await ref.read(deliveryChallansProvider.notifier).deleteDeliveryChallan(widget.challanId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery Challan deleted successfully.')),
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

  Future<void> _cancelChallan() async {
    setState(() {
      _actionLoading = true;
    });

    try {
      await ref.read(deliveryChallansProvider.notifier).cancelDeliveryChallan(widget.challanId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery Challan cancelled.')),
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

  Future<void> _markDelivered() async {
    setState(() {
      _actionLoading = true;
    });

    try {
      await ref.read(deliveryChallansProvider.notifier).markDelivered(widget.challanId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challan marked as Delivered. Inventory stocks reduced.')),
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

  Future<void> _convertToInvoice() async {
    setState(() {
      _actionLoading = true;
    });

    try {
      final invoiceId = await ref.read(deliveryChallansProvider.notifier).convertDeliveryChallanToInvoice(widget.challanId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery Challan converted to Invoice successfully.')),
        );
        // Redirect directly to the invoice detail screen
        context.pushReplacement('/invoices/$invoiceId');
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

  void _showEmailDialog(String toEmail, String dcNumber) {
    final toController = TextEditingController(text: toEmail);
    final subjectController = TextEditingController(text: 'Delivery Challan $dcNumber from Tinplate');
    final bodyController = TextEditingController(text: 'Please find attached your Delivery Challan details in PDF format.');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Delivery Challan'),
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
                await ref.read(deliveryChallansProvider.notifier).sendEmail(widget.challanId, {
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
    final detailState = ref.watch(deliveryChallanDetailsProvider(widget.challanId));
    final customersState = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Challan Details'),
      ),
      body: _actionLoading
          ? const Center(child: CircularProgressIndicator())
          : detailState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text(err.toString(), style: const TextStyle(color: AppColors.danger))),
              data: (details) {
                final dc = details.deliveryChallan;
                final items = details.items;
                final dateStr = DateFormat('dd MMM yyyy').format(dc.challanDate);
                final delivDateStr = dc.deliveryDate != null ? DateFormat('dd MMM yyyy').format(dc.deliveryDate!) : '—';

                String customerName = 'Loading customer...';
                String customerEmail = '';

                customersState.whenData((customers) {
                  final customer = customers.where((c) => c.id == dc.customerId).firstOrNull;
                  if (customer != null) {
                    customerName = customer.displayName ?? '${customer.firstName ?? ""} ${customer.lastName ?? ""}'.trim();
                    customerEmail = customer.email ?? '';
                  }
                });

                final canModify = !dc.stockReduced && dc.status != 'Cancelled';

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
                                onPressed: () => context.push('/delivery-challans/${dc.id}/edit'),
                              ),
                              const SizedBox(width: AppSpacing.s),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.cancel),
                                label: const Text('Cancel Challan'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.textSecondaryLight),
                                onPressed: _cancelChallan,
                              ),
                              const SizedBox(width: AppSpacing.s),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                                onPressed: _deleteChallan,
                              ),
                              const SizedBox(width: AppSpacing.s),
                            ],
                            if (!dc.stockReduced && dc.status != 'Cancelled') ...[
                              ElevatedButton.icon(
                                icon: const Icon(Icons.local_shipping),
                                label: const Text('Mark Delivered'),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                onPressed: _markDelivered,
                              ),
                              const SizedBox(width: AppSpacing.s),
                            ],
                            if (dc.status == 'Delivered') ...[
                              ElevatedButton.icon(
                                icon: const Icon(Icons.receipt),
                                label: const Text('Convert to Invoice'),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2F80ED)),
                                onPressed: _convertToInvoice,
                              ),
                              const SizedBox(width: AppSpacing.s),
                            ],
                            ElevatedButton.icon(
                              icon: const Icon(Icons.email),
                              label: const Text('Email PDF'),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF475569)),
                              onPressed: () => _showEmailDialog(customerEmail, dc.deliveryChallanNumber),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    // Main layout details
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dc.deliveryChallanNumber,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBlue),
                              ),
                              Text(
                                dc.status.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: dc.status == 'Cancelled' ? AppColors.danger : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                          // Ship To (Customer) details
                          const Text('Ship To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(customerName, style: const TextStyle(fontSize: 14)),
                          if (customerEmail.isNotEmpty) Text(customerEmail, style: const TextStyle(color: AppColors.textSecondaryLight)),
                          if (dc.deliveryAddress != null && dc.deliveryAddress!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(dc.deliveryAddress!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                          ],
                          const SizedBox(height: AppSpacing.m),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Challan Date: $dateStr'),
                              Text('Delivery Date: $delivDateStr'),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                          const Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: AppSpacing.s),
                          // Items loop card
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
                                            Text('${item.quantity} ${item.unit ?? ''}'.trim(), style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                          if (dc.notes != null && dc.notes!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.m),
                            Text('Notes:\n${dc.notes}', style: const TextStyle(fontSize: 13)),
                          ],
                          if (dc.termsConditions != null && dc.termsConditions!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.m),
                            Text('Terms & Conditions:\n${dc.termsConditions}', style: const TextStyle(fontSize: 13)),
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
}
