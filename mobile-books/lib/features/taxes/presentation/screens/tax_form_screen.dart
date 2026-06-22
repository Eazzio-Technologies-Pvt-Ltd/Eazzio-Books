import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/taxes/data/models/tax_rate.dart';
import 'package:mobile_books/features/taxes/presentation/providers/tax_provider.dart';

class TaxFormScreen extends ConsumerStatefulWidget {
  final int? taxId;

  const TaxFormScreen({super.key, this.taxId});

  @override
  ConsumerState<TaxFormScreen> createState() => _TaxFormScreenState();
}

class _TaxFormScreenState extends ConsumerState<TaxFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _saving = false;

  // Form Fields
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _taxType = 'GST';
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    if (widget.taxId != null) {
      _loadTaxData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTaxData() async {
    setState(() => _loading = true);
    try {
      final tax = await ref.read(taxDetailsProvider(widget.taxId!).future);
      _nameController.text = tax.taxName;
      _rateController.text = tax.rate.toString();
      _descriptionController.text = tax.description ?? '';
      setState(() {
        _taxType = tax.taxType;
        _status = tax.status;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load tax details: $e'), backgroundColor: AppColors.danger),
      );
      context.pop();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveTax() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final rateVal = double.tryParse(_rateController.text.trim()) ?? 0.0;
      final payload = {
        'tax_name': _nameController.text.trim(),
        'tax_type': _taxType,
        'rate': rateVal,
        'description': _descriptionController.text.trim(),
        'status': _status,
      };

      if (widget.taxId != null) {
        await ref.read(taxesProvider.notifier).updateTax(widget.taxId!, payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tax rate updated successfully'), backgroundColor: AppColors.success),
          );
        }
      } else {
        final newTax = TaxRate(
          id: 0,
          userId: 0,
          taxName: _nameController.text.trim(),
          taxType: _taxType,
          rate: rateVal,
          description: _descriptionController.text.trim(),
          status: _status,
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(taxesProvider.notifier).createTax(newTax);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tax rate created successfully'), backgroundColor: AppColors.success),
          );
        }
      }
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save tax rate: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStr = widget.taxId != null ? 'Edit Tax Rate' : 'New Tax Rate';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(titleStr)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titleStr),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tax Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tax Name *',
                        hintText: 'e.g. GST 18%',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Tax name is required' : null,
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Tax Type
                    DropdownButtonFormField<String>(
                      initialValue: _taxType,
                      decoration: const InputDecoration(
                        labelText: 'Tax Type *',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'GST', child: Text('GST')),
                        DropdownMenuItem(value: 'IGST', child: Text('IGST')),
                        DropdownMenuItem(value: 'CGST', child: Text('CGST')),
                        DropdownMenuItem(value: 'SGST', child: Text('SGST')),
                        DropdownMenuItem(value: 'CESS', child: Text('CESS')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _taxType = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Rate
                    TextFormField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Rate (%) *',
                        hintText: 'e.g. 18.00',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Rate is required';
                        final doubleVal = double.tryParse(val.trim());
                        if (doubleVal == null || doubleVal < 0) return 'Enter a valid rate';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Status
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status *',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            ElevatedButton(
              onPressed: _saving ? null : _saveTax,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: _saving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Save Tax Rate', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
