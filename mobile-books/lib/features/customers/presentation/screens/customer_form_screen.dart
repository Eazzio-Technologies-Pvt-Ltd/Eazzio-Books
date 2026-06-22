import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/customers/data/models/customer.dart';
import 'package:mobile_books/features/customers/data/models/customer_address.dart';
import 'package:mobile_books/features/customers/data/models/customer_contact.dart';
import 'package:mobile_books/features/customers/data/services/customer_service.dart';
import 'package:mobile_books/features/customers/presentation/providers/customer_provider.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  final int? customerId;

  const CustomerFormScreen({
    super.key,
    this.customerId,
  });

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class ContactPersonControllers {
  final int? id;
  final TextEditingController salutation = TextEditingController();
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController workPhone = TextEditingController();
  final TextEditingController mobile = TextEditingController();

  ContactPersonControllers({
    this.id,
    String? sal,
    String? first,
    String? last,
    String? mail,
    String? work,
    String? mob,
  }) {
    salutation.text = sal ?? '';
    firstName.text = first ?? '';
    lastName.text = last ?? '';
    email.text = mail ?? '';
    workPhone.text = work ?? '';
    mobile.text = mob ?? '';
  }

  void dispose() {
    salutation.dispose();
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    workPhone.dispose();
    mobile.dispose();
  }
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool get isEdit => widget.customerId != null;
  bool _isLoading = false;
  bool _isSaving = false;

  // ---------- Basic fields ----------
  String _customerType = 'Business';
  String _customerSubType = '';
  String _salutation = '';
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _workPhoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _languageController = TextEditingController(text: 'English');
  bool _isActive = true;
  bool _additionalOpen = false;

  // ---------- Financial ----------
  final _panController = TextEditingController();
  final _currencyController = TextEditingController(text: 'INR');
  final _openingBalanceController = TextEditingController(text: '0');
  final _paymentTermsController = TextEditingController();
  bool _enablePortal = false;
  final _portalLanguageController = TextEditingController(text: 'en');
  final _remarksController = TextEditingController();

  // ---------- Addresses ----------
  final _billingAttention = TextEditingController();
  final _billingCountry = TextEditingController();
  final _billingAddressLine1 = TextEditingController();
  final _billingAddressLine2 = TextEditingController();
  final _billingCity = TextEditingController();
  final _billingState = TextEditingController();
  final _billingPinCode = TextEditingController();
  final _billingPhone = TextEditingController();
  final _billingFax = TextEditingController();

  final _shippingAttention = TextEditingController();
  final _shippingCountry = TextEditingController();
  final _shippingAddressLine1 = TextEditingController();
  final _shippingAddressLine2 = TextEditingController();
  final _shippingCity = TextEditingController();
  final _shippingState = TextEditingController();
  final _shippingPinCode = TextEditingController();
  final _shippingPhone = TextEditingController();
  final _shippingFax = TextEditingController();

  bool _copyBilling = false;

  // ---------- Contact Persons ----------
  final List<ContactPersonControllers> _contacts = [];

  // ---------- Customer Owner ----------
  List<Map<String, dynamic>> _users = [];
  String? _customerOwnerId;

  @override
  void initState() {
    super.initState();
    _setupBillingListeners();
    _fetchUsers();
    if (isEdit) {
      _fetchCustomerDetails();
    } else {
      // Initialize with one contact person by default for new profiles
      _addContactPerson();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyNameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _workPhoneController.dispose();
    _mobileController.dispose();
    _languageController.dispose();
    _panController.dispose();
    _currencyController.dispose();
    _openingBalanceController.dispose();
    _paymentTermsController.dispose();
    _portalLanguageController.dispose();
    _remarksController.dispose();

    _billingAttention.dispose();
    _billingCountry.dispose();
    _billingAddressLine1.dispose();
    _billingAddressLine2.dispose();
    _billingCity.dispose();
    _billingState.dispose();
    _billingPinCode.dispose();
    _billingPhone.dispose();
    _billingFax.dispose();

    _shippingAttention.dispose();
    _shippingCountry.dispose();
    _shippingAddressLine1.dispose();
    _shippingAddressLine2.dispose();
    _shippingCity.dispose();
    _shippingState.dispose();
    _shippingPinCode.dispose();
    _shippingPhone.dispose();
    _shippingFax.dispose();

    for (final contact in _contacts) {
      contact.dispose();
    }
    super.dispose();
  }

  void _setupBillingListeners() {
    void copyIfChecked(TextEditingController source, TextEditingController dest) {
      if (_copyBilling) {
        dest.text = source.text;
      }
    }

    _billingAttention.addListener(() => copyIfChecked(_billingAttention, _shippingAttention));
    _billingCountry.addListener(() => copyIfChecked(_billingCountry, _shippingCountry));
    _billingAddressLine1.addListener(() => copyIfChecked(_billingAddressLine1, _shippingAddressLine1));
    _billingAddressLine2.addListener(() => copyIfChecked(_billingAddressLine2, _shippingAddressLine2));
    _billingCity.addListener(() => copyIfChecked(_billingCity, _shippingCity));
    _billingState.addListener(() => copyIfChecked(_billingState, _shippingState));
    _billingPinCode.addListener(() => copyIfChecked(_billingPinCode, _shippingPinCode));
    _billingPhone.addListener(() => copyIfChecked(_billingPhone, _shippingPhone));
    _billingFax.addListener(() => copyIfChecked(_billingFax, _shippingFax));
  }

  void _onCopyBillingChanged(bool? value) {
    if (value == null) return;
    setState(() {
      _copyBilling = value;
      if (_copyBilling) {
        _shippingAttention.text = _billingAttention.text;
        _shippingCountry.text = _billingCountry.text;
        _shippingAddressLine1.text = _billingAddressLine1.text;
        _shippingAddressLine2.text = _billingAddressLine2.text;
        _shippingCity.text = _billingCity.text;
        _shippingState.text = _billingState.text;
        _shippingPinCode.text = _billingPinCode.text;
        _shippingPhone.text = _billingPhone.text;
        _shippingFax.text = _billingFax.text;
      }
    });
  }

  void _addContactPerson({CustomerContact? contact}) {
    setState(() {
      _contacts.add(
        ContactPersonControllers(
          id: contact?.id,
          sal: contact?.salutation,
          first: contact?.firstName,
          last: contact?.lastName,
          mail: contact?.email,
          work: contact?.workPhone,
          mob: contact?.mobile,
        ),
      );
    });
  }

  void _removeContactPerson(int index) {
    setState(() {
      final removed = _contacts.removeAt(index);
      removed.dispose();
    });
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await ref.read(networkClientProvider).get('/users');
      final data = response.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(data['users'] ?? []);
        });
      }
    } catch (_) {
      // Safe fallback if users endpoint fails
    }
  }

  Future<void> _fetchCustomerDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final customer = await ref.read(customerServiceProvider).getCustomerById(widget.customerId!);
      if (mounted) {
        _populateFields(customer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load customer: $e'), backgroundColor: AppColors.danger),
        );
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _populateFields(Customer customer) {
    _customerType = customer.customerType;
    _customerSubType = customer.customerSubType ?? '';
    _salutation = customer.salutation ?? '';
    _firstNameController.text = customer.firstName ?? '';
    _lastNameController.text = customer.lastName ?? '';
    _companyNameController.text = customer.companyName ?? '';
    _displayNameController.text = customer.displayName ?? '';
    _emailController.text = customer.email ?? '';
    _phoneController.text = customer.phone ?? '';
    _workPhoneController.text = customer.workPhone ?? '';
    _mobileController.text = customer.mobile ?? '';
    _remarksController.text = customer.remarks ?? '';
    _panController.text = customer.pan ?? '';
    _currencyController.text = customer.currency;
    _openingBalanceController.text = customer.openingBalance.toString();
    _paymentTermsController.text = customer.paymentTerms ?? '';
    _enablePortal = customer.enablePortal;
    _portalLanguageController.text = customer.portalLanguage;
    _isActive = customer.isActive;

    // Load addresses
    final billing = customer.addresses.where((a) => a.type == 'billing').firstOrNull;
    final shipping = customer.addresses.where((a) => a.type == 'shipping').firstOrNull;

    if (billing != null) {
      _billingAttention.text = billing.attention ?? '';
      _billingCountry.text = billing.country ?? '';
      _billingAddressLine1.text = billing.addressLine1 ?? '';
      _billingAddressLine2.text = billing.addressLine2 ?? '';
      _billingCity.text = billing.city ?? '';
      _billingState.text = billing.state ?? '';
      _billingPinCode.text = billing.pinCode ?? '';
      _billingPhone.text = billing.phone ?? '';
      _billingFax.text = billing.fax ?? '';
    }

    if (shipping != null) {
      _shippingAttention.text = shipping.attention ?? '';
      _shippingCountry.text = shipping.country ?? '';
      _shippingAddressLine1.text = shipping.addressLine1 ?? '';
      _shippingAddressLine2.text = shipping.addressLine2 ?? '';
      _shippingCity.text = shipping.city ?? '';
      _shippingState.text = shipping.state ?? '';
      _shippingPinCode.text = shipping.pinCode ?? '';
      _shippingPhone.text = shipping.phone ?? '';
      _shippingFax.text = shipping.fax ?? '';
    }

    // Load contacts
    _contacts.clear();
    if (customer.contacts.isNotEmpty) {
      for (final ct in customer.contacts) {
        _addContactPerson(contact: ct);
      }
    } else {
      _addContactPerson();
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in the form.')),
      );
      return;
    }

    final displayName = _displayNameController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (displayName.isEmpty && firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a display name or first name.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Build address payload
      final addresses = [
        CustomerAddress(
          type: 'billing',
          attention: _billingAttention.text.trim(),
          country: _billingCountry.text.trim(),
          addressLine1: _billingAddressLine1.text.trim(),
          addressLine2: _billingAddressLine2.text.trim(),
          city: _billingCity.text.trim(),
          state: _billingState.text.trim(),
          pinCode: _billingPinCode.text.trim(),
          phone: _billingPhone.text.trim(),
          fax: _billingFax.text.trim(),
        ),
        CustomerAddress(
          type: 'shipping',
          attention: _shippingAttention.text.trim(),
          country: _shippingCountry.text.trim(),
          addressLine1: _shippingAddressLine1.text.trim(),
          addressLine2: _shippingAddressLine2.text.trim(),
          city: _shippingCity.text.trim(),
          state: _shippingState.text.trim(),
          pinCode: _shippingPinCode.text.trim(),
          phone: _shippingPhone.text.trim(),
          fax: _shippingFax.text.trim(),
        ),
      ];

      // Build contacts payload
      final contacts = _contacts
          .where((c) => c.firstName.text.trim().isNotEmpty || c.lastName.text.trim().isNotEmpty)
          .map((c) => CustomerContact(
                salutation: c.salutation.text,
                firstName: c.firstName.text.trim(),
                lastName: c.lastName.text.trim(),
                email: c.email.text.trim(),
                workPhone: c.workPhone.text.trim(),
                mobile: c.mobile.text.trim(),
              ))
          .toList();

      final payload = {
        'customer_type': _customerType,
        'customer_sub_type': _customerSubType.isNotEmpty ? _customerSubType : null,
        'salutation': _salutation.isNotEmpty ? _salutation : null,
        'first_name': firstName.isNotEmpty ? firstName : null,
        'last_name': lastName.isNotEmpty ? lastName : null,
        'company_name': _companyNameController.text.trim().isNotEmpty ? _companyNameController.text.trim() : null,
        'display_name': displayName.isNotEmpty ? displayName : '$firstName $lastName'.trim(),
        'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        'work_phone': _workPhoneController.text.trim().isNotEmpty ? _workPhoneController.text.trim() : null,
        'mobile': _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : null,
        'remarks': _remarksController.text.trim().isNotEmpty ? _remarksController.text.trim() : null,
        'pan': _panController.text.trim().isNotEmpty ? _panController.text.trim() : null,
        'currency': _currencyController.text.trim().isNotEmpty ? _currencyController.text.trim() : 'INR',
        'opening_balance': double.tryParse(_openingBalanceController.text.trim()) ?? 0.0,
        'payment_terms': _paymentTermsController.text.trim().isNotEmpty ? _paymentTermsController.text.trim() : null,
        'enable_portal': _enablePortal,
        'portal_language': _portalLanguageController.text.trim().isNotEmpty ? _portalLanguageController.text.trim() : 'en',
        'is_active': _isActive,
        'addresses': addresses.map((e) => e.toJson()).toList(),
        'contacts': contacts.map((e) => e.toJson()).toList(),
        'customer_owner_id': _customerOwnerId != null ? int.tryParse(_customerOwnerId!) : null,
      };

      if (isEdit) {
        await ref.read(customersProvider.notifier).updateCustomer(widget.customerId!, payload);
      } else {
        final mockCustomer = Customer.fromJson({
          'id': 0,
          ...payload,
        });
        await ref.read(customersProvider.notifier).createCustomer(mockCustomer);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Customer updated successfully' : 'Customer created successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save customer: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Edit Customer' : 'New Customer'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Basic Info'),
              Tab(text: 'Addresses'),
              Tab(text: 'Contacts'),
              Tab(text: 'Other Details'),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: TabBarView(
            children: [
              _buildBasicInfoTab(),
              _buildAddressesTab(isDark),
              _buildContactsTab(isDark),
              _buildOtherDetailsTab(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomActions(context),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Type
          DropdownButtonFormField<String>(
            value: _customerType,
            decoration: const InputDecoration(labelText: 'Customer Type *'),
            items: const [
              DropdownMenuItem(value: 'Business', child: Text('Business')),
              DropdownMenuItem(value: 'Individual', child: Text('Individual')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _customerType = val;
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.m),

          // Primary Name
          Row(
            children: [
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: _salutation,
                  decoration: const InputDecoration(labelText: 'Salutation'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('None')),
                    DropdownMenuItem(value: 'Mr.', child: Text('Mr.')),
                    DropdownMenuItem(value: 'Mrs.', child: Text('Mrs.')),
                    DropdownMenuItem(value: 'Ms.', child: Text('Ms.')),
                    DropdownMenuItem(value: 'Dr.', child: Text('Dr.')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _salutation = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  onChanged: (_) => _updateDisplayNameSuggestion(),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  onChanged: (_) => _updateDisplayNameSuggestion(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // Company Name (or Father's Name for individual)
          TextFormField(
            controller: _companyNameController,
            decoration: InputDecoration(
              labelText: _customerType == 'Individual' ? "Father's Name" : 'Company Name',
            ),
            onChanged: (_) => _updateDisplayNameSuggestion(),
          ),
          const SizedBox(height: AppSpacing.m),

          // Display Name
          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Display Name *',
              hintText: 'Select display format or type name',
            ),
            validator: (value) {
              if ((value == null || value.trim().isEmpty) && _firstNameController.text.trim().isEmpty) {
                return 'Please enter display name or first name';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.m),

          // Email & Phone
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email Address'),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegExp.hasMatch(value.trim())) {
                  return 'Please enter a valid email address';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone'),
          ),
          const SizedBox(height: AppSpacing.m),

          // Status Switch
          Row(
            children: [
              const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              ChoiceChip(
                label: const Text('Active'),
                selected: _isActive,
                onSelected: (val) {
                  setState(() {
                    _isActive = true;
                  });
                },
              ),
              const SizedBox(width: AppSpacing.s),
              ChoiceChip(
                label: const Text('Inactive'),
                selected: !_isActive,
                onSelected: (val) {
                  setState(() {
                    _isActive = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),

          // Collapsible Additional details
          GestureDetector(
            onTap: () {
              setState(() {
                _additionalOpen = !_additionalOpen;
              });
            },
            child: Row(
              children: [
                Icon(
                  _additionalOpen ? Icons.arrow_drop_down : Icons.arrow_right,
                  color: AppColors.primaryBlue,
                ),
                Text(
                  'Additional Details',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_additionalOpen) ...[
            const SizedBox(height: AppSpacing.m),
            TextFormField(
              controller: _workPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Work Phone'),
            ),
            const SizedBox(height: AppSpacing.m),
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile'),
            ),
            const SizedBox(height: AppSpacing.m),
            TextFormField(
              controller: _languageController,
              decoration: const InputDecoration(labelText: 'Language'),
            ),
            const SizedBox(height: AppSpacing.m),
            DropdownButtonFormField<String>(
              value: _customerSubType,
              decoration: const InputDecoration(labelText: 'Customer Sub‑Type'),
              items: const [
                DropdownMenuItem(value: '', child: Text('None')),
                DropdownMenuItem(value: 'Business', child: Text('Business')),
                DropdownMenuItem(value: 'Individual', child: Text('Individual')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _customerSubType = val;
                  });
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  void _updateDisplayNameSuggestion() {
    if (_displayNameController.text.isEmpty ||
        _displayNameController.text == '${_firstNameController.text} ${_lastNameController.text}'.trim() ||
        _displayNameController.text == _companyNameController.text) {
      if (_customerType == 'Individual' || _companyNameController.text.trim().isEmpty) {
        _displayNameController.text = '${_firstNameController.text} ${_lastNameController.text}'.trim();
      } else {
        _displayNameController.text = _companyNameController.text.trim();
      }
    }
  }

  Widget _buildAddressesTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Billing Address
          Text('Billing Address', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.s),
          _addressCardFields(
            attention: _billingAttention,
            country: _billingCountry,
            line1: _billingAddressLine1,
            line2: _billingAddressLine2,
            city: _billingCity,
            state: _billingState,
            pinCode: _billingPinCode,
            phone: _billingPhone,
            fax: _billingFax,
          ),
          const SizedBox(height: AppSpacing.l),

          // Shipping Address Header with copy checkbox
          Row(
            children: [
              Text('Shipping Address', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _copyBilling,
                    onChanged: _onCopyBillingChanged,
                  ),
                  const Text('Same as Billing', style: TextStyle(fontSize: 12.0)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          _addressCardFields(
            attention: _shippingAttention,
            country: _shippingCountry,
            line1: _shippingAddressLine1,
            line2: _shippingAddressLine2,
            city: _shippingCity,
            state: _shippingState,
            pinCode: _shippingPinCode,
            phone: _shippingPhone,
            fax: _shippingFax,
            disabled: _copyBilling,
          ),
        ],
      ),
    );
  }

  Widget _addressCardFields({
    required TextEditingController attention,
    required TextEditingController country,
    required TextEditingController line1,
    required TextEditingController line2,
    required TextEditingController city,
    required TextEditingController state,
    required TextEditingController pinCode,
    required TextEditingController phone,
    required TextEditingController fax,
    bool disabled = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          children: [
            TextFormField(
              controller: attention,
              enabled: !disabled,
              decoration: const InputDecoration(labelText: 'Attention'),
            ),
            const SizedBox(height: AppSpacing.s),
            TextFormField(
              controller: country,
              enabled: !disabled,
              decoration: const InputDecoration(labelText: 'Country/Region'),
            ),
            const SizedBox(height: AppSpacing.s),
            TextFormField(
              controller: line1,
              enabled: !disabled,
              decoration: const InputDecoration(labelText: 'Address Line 1'),
            ),
            const SizedBox(height: AppSpacing.s),
            TextFormField(
              controller: line2,
              enabled: !disabled,
              decoration: const InputDecoration(labelText: 'Address Line 2'),
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: city,
                    enabled: !disabled,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: TextFormField(
                    controller: state,
                    enabled: !disabled,
                    decoration: const InputDecoration(labelText: 'State'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: TextFormField(
                    controller: pinCode,
                    enabled: !disabled,
                    decoration: const InputDecoration(labelText: 'Pin Code'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: phone,
                    enabled: !disabled,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: TextFormField(
                    controller: fax,
                    enabled: !disabled,
                    decoration: const InputDecoration(labelText: 'Fax'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.m),
      itemCount: _contacts.length + 1,
      itemBuilder: (context, index) {
        if (index == _contacts.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
            child: ElevatedButton.icon(
              onPressed: () => _addContactPerson(),
              icon: const Icon(Icons.add),
              label: const Text('Add Contact Person'),
            ),
          );
        }

        final contact = _contacts[index];

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.m),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).dividerColor,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Contact Person ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_contacts.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () => _removeContactPerson(index),
                      ),
                  ],
                ),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: contact.salutation.text,
                        decoration: const InputDecoration(labelText: 'Salutation'),
                        items: const [
                          DropdownMenuItem(value: '', child: Text('None')),
                          DropdownMenuItem(value: 'Mr.', child: Text('Mr.')),
                          DropdownMenuItem(value: 'Mrs.', child: Text('Mrs.')),
                          DropdownMenuItem(value: 'Ms.', child: Text('Ms.')),
                          DropdownMenuItem(value: 'Dr.', child: Text('Dr.')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            contact.salutation.text = val;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: contact.firstName,
                        decoration: const InputDecoration(labelText: 'First Name'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: contact.lastName,
                        decoration: const InputDecoration(labelText: 'Last Name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                TextFormField(
                  controller: contact.email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: contact.workPhone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Work Phone'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: TextFormField(
                        controller: contact.mobile,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Mobile'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtherDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _panController,
                  decoration: const InputDecoration(labelText: 'PAN'),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: TextFormField(
                  controller: _currencyController,
                  decoration: const InputDecoration(labelText: 'Currency'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: _openingBalanceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Opening Balance'),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (double.tryParse(value.trim()) == null) {
                  return 'Please enter a valid numeric amount';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.m),
          TextFormField(
            controller: _paymentTermsController,
            decoration: const InputDecoration(
              labelText: 'Payment Terms',
              hintText: 'e.g. Net 30',
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          // Portal Access checkbox
          Row(
            children: [
              Checkbox(
                value: _enablePortal,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _enablePortal = val;
                    });
                  }
                },
              ),
              const Text('Allow portal access for this customer'),
            ],
          ),
          if (_enablePortal) ...[
            const SizedBox(height: AppSpacing.s),
            TextFormField(
              controller: _portalLanguageController,
              decoration: const InputDecoration(labelText: 'Portal Language'),
            ),
          ],
          const SizedBox(height: AppSpacing.m),

          // Owner Dropdown
          DropdownButtonFormField<String>(
            value: _customerOwnerId,
            decoration: const InputDecoration(labelText: 'Customer Owner'),
            items: [
              const DropdownMenuItem(value: null, child: Text('None')),
              ..._users.map(
                (u) => DropdownMenuItem(
                  value: u['id'].toString(),
                  child: Text(u['email'] as String),
                ),
              ),
            ],
            onChanged: (val) {
              setState(() {
                _customerOwnerId = val;
              });
            },
          ),
          const SizedBox(height: AppSpacing.m),

          TextFormField(
            controller: _remarksController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Remarks'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
            Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSaving ? null : () => context.pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: AppSpacing.m),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, AppSpacing.minTouchTarget),
            ),
            onPressed: _isSaving ? null : _saveForm,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isEdit ? 'Update' : 'Save'),
          ),
        ],
      ),
    );
  }
}
