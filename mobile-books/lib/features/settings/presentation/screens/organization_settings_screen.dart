import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/settings/data/models/organization_settings.dart';
import 'package:mobile_books/features/settings/presentation/providers/settings_providers.dart';

class OrganizationSettingsScreen extends ConsumerStatefulWidget {
  const OrganizationSettingsScreen({super.key});

  @override
  ConsumerState<OrganizationSettingsScreen> createState() => _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState extends ConsumerState<OrganizationSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _gstinController = TextEditingController();
  final _panController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _financialYearStart = 'April';
  String _defaultCurrency = 'INR';

  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _businessTypeController.dispose();
    _gstinController.dispose();
    _panController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initFields(OrganizationSettings data) {
    if (_initialized) return;
    _nameController.text = data.organizationName;
    _businessTypeController.text = data.businessType ?? '';
    _gstinController.text = data.gstin ?? '';
    _panController.text = data.pan ?? '';
    _addressController.text = data.address ?? '';
    _cityController.text = data.city ?? '';
    _stateController.text = data.state ?? '';
    _countryController.text = data.country ?? 'India';
    _phoneController.text = data.phone ?? '';
    _emailController.text = data.organizationEmail ?? '';
    _financialYearStart = data.financialYearStart;
    _defaultCurrency = data.defaultCurrency;
    _initialized = true;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final updated = OrganizationSettings(
        organizationName: _nameController.text.trim(),
        businessType: _businessTypeController.text.trim().isEmpty ? null : _businessTypeController.text.trim(),
        gstin: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim(),
        pan: _panController.text.trim().isEmpty ? null : _panController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        organizationEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        financialYearStart: _financialYearStart,
        defaultCurrency: _defaultCurrency,
      );

      await ref.read(organizationSettingsProvider.notifier).updateSettings(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update settings: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(organizationSettingsProvider);

    return ResponsiveScaffold(
      currentRoute: '/settings/organization',
      appBar: AppBar(
        title: const Text('Organization Settings'),
      ),
      body: settingsAsync.when(
        data: (data) {
          _initFields(data);

          return Form(
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
                        const Text(
                          'General Information',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Org Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Organization Name *',
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Organization name is required' : null,
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Business Type
                        TextFormField(
                          controller: _businessTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Business Type',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // GSTIN
                        TextFormField(
                          controller: _gstinController,
                          decoration: const InputDecoration(
                            labelText: 'GSTIN (For automated Tax calculation)',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // PAN
                        TextFormField(
                          controller: _panController,
                          decoration: const InputDecoration(
                            labelText: 'PAN',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Address
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Street Address',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // City & State
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: TextFormField(
                                controller: _stateController,
                                decoration: const InputDecoration(
                                  labelText: 'State / Province',
                                  hintText: 'e.g. Maharashtra',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Country
                        TextFormField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Email & Phone
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Regional Settings',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // FY Start
                        DropdownButtonFormField<String>(
                          initialValue: _financialYearStart,
                          decoration: const InputDecoration(
                            labelText: 'Financial Year Start',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'January', child: Text('January')),
                            DropdownMenuItem(value: 'April', child: Text('April')),
                            DropdownMenuItem(value: 'July', child: Text('July')),
                            DropdownMenuItem(value: 'October', child: Text('October')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _financialYearStart = val);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Currency
                        DropdownButtonFormField<String>(
                          initialValue: _defaultCurrency,
                          decoration: const InputDecoration(
                            labelText: 'Default Currency',
                          ),
                          items: const [
                            DropdownMenuItem(value: 'INR', child: Text('INR - Indian Rupee')),
                            DropdownMenuItem(value: 'USD', child: Text('USD - US Dollar')),
                            DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _defaultCurrency = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),

                ElevatedButton(
                  onPressed: _saving ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Settings', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err', style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(organizationSettingsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
