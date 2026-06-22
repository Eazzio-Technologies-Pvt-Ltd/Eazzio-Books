import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  final int? customerId;

  const AddCustomerScreen({super.key, this.customerId});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  final _panController = TextEditingController();
  final _remarksController = TextEditingController();

  String _customerType = 'Business';
  String _salutation = 'Mr.';
  String _currency = 'INR';
  String _paymentTerms = 'Due on receipt';
  bool _isSubmitting = false;

  bool get _isEditMode => widget.customerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _prepopulateFields();
    }
  }

  void _prepopulateFields() {
    final customerState = ref.read(customerProvider);
    final customer = customerState.customers.firstWhere(
      (c) => c.id == widget.customerId,
      orElse: () => throw Exception('Customer not found'),
    );

    _firstNameController.text = customer.firstName ?? '';
    _lastNameController.text = customer.lastName ?? '';
    _companyController.text = customer.companyName ?? '';
    _displayNameController.text = customer.displayName ?? '';
    _emailController.text = customer.email ?? '';
    _phoneController.text = customer.phone ?? '';
    _mobileController.text = customer.mobile ?? '';
    _openingBalanceController.text = customer.openingBalance.toString();
    _panController.text = customer.pan ?? '';
    _remarksController.text = customer.remarks ?? '';

    _customerType = customer.customerType;
    _salutation = customer.salutation ?? 'Mr.';
    _currency = customer.currency;
    _paymentTerms = customer.paymentTerms ?? 'Due on receipt';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _openingBalanceController.dispose();
    _panController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final customerData = {
      'customer_type': _customerType,
      'salutation': _customerType == 'Individual' ? _salutation : null,
      'first_name': _customerType == 'Individual' ? _firstNameController.text.trim() : null,
      'last_name': _customerType == 'Individual' ? _lastNameController.text.trim() : null,
      'company_name': _customerType == 'Business' ? _companyController.text.trim() : null,
      'display_name': _displayNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'mobile': _mobileController.text.trim(),
      'currency': _currency,
      'opening_balance': double.tryParse(_openingBalanceController.text) ?? 0.0,
      'payment_terms': _paymentTerms,
      'pan': _panController.text.trim(),
      'remarks': _remarksController.text.trim(),
    };

    bool success;
    if (_isEditMode) {
      success = await ref.read(customerProvider.notifier).editCustomer(widget.customerId!, customerData);
    } else {
      success = await ref.read(customerProvider.notifier).addCustomer(customerData);
    }

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Customer updated successfully' : 'Customer added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } else {
      setState(() => _isSubmitting = false);
      if (mounted) {
        final error = ref.read(customerProvider).errorMessage ?? 'An error occurred';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Customer' : 'New Customer',
          style: AppTextStyles.h3.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormSection(
                  title: 'CONTACT TYPE',
                  children: [
                    // Customer Type Toggle (Business / Individual)
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Business', style: AppTextStyles.bodyMedium),
                            value: 'Business',
                            groupValue: _customerType,
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() => _customerType = value!);
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: Text('Individual', style: AppTextStyles.bodyMedium),
                            value: 'Individual',
                            groupValue: _customerType,
                            activeColor: AppColors.primary,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) {
                              setState(() => _customerType = value!);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFormSection(
                  title: 'PRIMARY DETAILS',
                  children: [
                    if (_customerType == 'Individual') ...[
                      // Salutation select
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salutation',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _salutation,
                                isExpanded: true,
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                                onChanged: (value) {
                                  setState(() => _salutation = value!);
                                },
                                items: const [
                                  DropdownMenuItem(value: 'Mr.', child: Text('Mr.')),
                                  DropdownMenuItem(value: 'Mrs.', child: Text('Mrs.')),
                                  DropdownMenuItem(value: 'Ms.', child: Text('Ms.')),
                                  DropdownMenuItem(value: 'Dr.', child: Text('Dr.')),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'First Name *',
                        placeholder: 'e.g. Rahul',
                        controller: _firstNameController,
                        validator: (val) => AppValidators.validateRequired(val, 'First name'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Last Name *',
                        placeholder: 'e.g. Kumar',
                        controller: _lastNameController,
                        validator: (val) => AppValidators.validateRequired(val, 'Last name'),
                      ),
                    ] else ...[
                      AppTextField(
                        label: 'Company Name *',
                        placeholder: 'e.g. Eazzio Technologies Pvt Ltd',
                        controller: _companyController,
                        validator: (val) => AppValidators.validateRequired(val, 'Company name'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Display Name (Visible in Invoices) *',
                      placeholder: 'e.g. Rahul Kumar - Eazzio',
                      controller: _displayNameController,
                      validator: (val) => AppValidators.validateRequired(val, 'Display name'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFormSection(
                  title: 'CONTACT CHANNELS',
                  children: [
                    AppTextField(
                      label: 'Email Address',
                      placeholder: 'contact@organization.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Work Phone',
                      placeholder: 'e.g. 011-4523-XXXX',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Mobile Phone',
                      placeholder: 'e.g. +91 99999-XXXXX',
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFormSection(
                  title: 'FINANCIAL CONFIGURATIONS',
                  children: [
                    // Currency dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Billing Currency',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _currency,
                              isExpanded: true,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                              onChanged: (value) {
                                setState(() => _currency = value!);
                              },
                              items: const [
                                DropdownMenuItem(value: 'INR', child: Text('Indian Rupee (INR - ₹)')),
                                DropdownMenuItem(value: 'USD', child: Text('US Dollar (USD - \$)')),
                                DropdownMenuItem(value: 'EUR', child: Text('Euro (EUR - €)')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Opening Balance (₹)',
                      placeholder: '0.00',
                      controller: _openingBalanceController,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
                          return 'Opening balance must be a number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Payment Terms dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Terms',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _paymentTerms,
                              isExpanded: true,
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                              onChanged: (value) {
                                setState(() => _paymentTerms = value!);
                              },
                              items: const [
                                DropdownMenuItem(value: 'Due on receipt', child: Text('Due on receipt')),
                                DropdownMenuItem(value: 'Net 15', child: Text('Net 15 days')),
                                DropdownMenuItem(value: 'Net 30', child: Text('Net 30 days')),
                                DropdownMenuItem(value: 'Net 45', child: Text('Net 45 days')),
                                DropdownMenuItem(value: 'Net 60', child: Text('Net 60 days')),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'PAN / Tax ID',
                      placeholder: 'e.g. ABCDE1234F',
                      controller: _panController,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFormSection(
                  title: 'ADDITIONAL NOTES',
                  children: [
                    AppTextField(
                      label: 'Remarks',
                      placeholder: 'Add specific notes regarding this customer...',
                      controller: _remarksController,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: _isEditMode ? 'Update Customer' : 'Save Customer',
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  isLoading: _isSubmitting,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({required String title, required List<Widget> children}) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
          const Divider(height: 20, color: AppColors.border),
          ...children,
        ],
      ),
    );
  }
}
