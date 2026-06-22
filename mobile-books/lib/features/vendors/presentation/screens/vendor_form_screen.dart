import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/vendors/data/models/vendor.dart';
import 'package:mobile_books/features/vendors/presentation/providers/vendor_provider.dart';

class VendorFormScreen extends ConsumerStatefulWidget {
  final int? vendorId;

  const VendorFormScreen({super.key, this.vendorId});

  @override
  ConsumerState<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends ConsumerState<VendorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isEdit = false;

  final _displayNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _paymentTermsController = TextEditingController();
  final _notesController = TextEditingController();
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    _isEdit = widget.vendorId != null;
    if (_isEdit) {
      _loadVendorData();
    }
  }

  Future<void> _loadVendorData() async {
    setState(() => _isLoading = true);
    try {
      final vendor = await ref.read(vendorDetailsProvider(widget.vendorId!).future);
      _displayNameController.text = vendor.displayName;
      _companyNameController.text = vendor.companyName ?? '';
      _emailController.text = vendor.email ?? '';
      _phoneController.text = vendor.phone ?? '';
      _gstinController.text = vendor.gstin ?? '';
      _panController.text = vendor.pan ?? '';
      _billingAddressController.text = vendor.billingAddress ?? '';
      _shippingAddressController.text = vendor.shippingAddress ?? '';
      _openingBalanceController.text = vendor.openingBalance.toString();
      _paymentTermsController.text = vendor.paymentTerms ?? '';
      _notesController.text = vendor.notes ?? '';
      _status = vendor.status;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading vendor: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _companyNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _billingAddressController.dispose();
    _shippingAddressController.dispose();
    _openingBalanceController.dispose();
    _paymentTermsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final vendorData = Vendor(
      id: widget.vendorId ?? 0,
      userId: 0, // Assigned by server
      displayName: _displayNameController.text.trim(),
      companyName: _companyNameController.text.trim().isEmpty ? null : _companyNameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      gstin: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim(),
      pan: _panController.text.trim().isEmpty ? null : _panController.text.trim(),
      billingAddress: _billingAddressController.text.trim().isEmpty ? null : _billingAddressController.text.trim(),
      shippingAddress: _shippingAddressController.text.trim().isEmpty ? null : _shippingAddressController.text.trim(),
      openingBalance: double.tryParse(_openingBalanceController.text.trim()) ?? 0.0,
      paymentTerms: _paymentTermsController.text.trim().isEmpty ? null : _paymentTermsController.text.trim(),
      status: _status,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    try {
      if (_isEdit) {
        await ref.read(vendorsProvider.notifier).updateVendor(
          widget.vendorId!,
          vendorData.toJson(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor updated successfully.')),
        );
      } else {
        await ref.read(vendorsProvider.notifier).createVendor(vendorData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor created successfully.')),
        );
      }
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving vendor: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _isEdit) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Edit Vendor' : 'New Vendor')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Vendor' : 'New Vendor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isLoading ? null : _save,
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.m),
              children: [
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'Display Name *'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Display name is required' : null,
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(labelText: 'Company Name'),
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.m),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gstinController,
                        decoration: const InputDecoration(labelText: 'GSTIN'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: TextFormField(
                        controller: _panController,
                        decoration: const InputDecoration(labelText: 'PAN'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _openingBalanceController,
                  decoration: const InputDecoration(labelText: 'Opening Balance'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _paymentTermsController,
                  decoration: const InputDecoration(labelText: 'Payment Terms'),
                ),
                const SizedBox(height: AppSpacing.m),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _status = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _billingAddressController,
                  decoration: const InputDecoration(labelText: 'Billing Address'),
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _shippingAddressController,
                  decoration: const InputDecoration(labelText: 'Shipping Address'),
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.m),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
