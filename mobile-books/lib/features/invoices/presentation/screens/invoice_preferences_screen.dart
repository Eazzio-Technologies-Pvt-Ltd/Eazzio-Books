import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/invoices/data/models/invoice_preferences.dart';
import 'package:mobile_books/features/invoices/presentation/providers/invoice_preferences_provider.dart';

class InvoicePreferencesScreen extends ConsumerStatefulWidget {
  const InvoicePreferencesScreen({super.key});

  @override
  ConsumerState<InvoicePreferencesScreen> createState() => _InvoicePreferencesScreenState();
}

class _InvoicePreferencesScreenState extends ConsumerState<InvoicePreferencesScreen> {
  bool _saving = false;
  InvoicePreferences? _localPrefs;

  void _initLocal(InvoicePreferences serverData) {
    _localPrefs ??= serverData;
  }

  Future<void> _save() async {
    if (_localPrefs == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(invoicePreferencesProvider.notifier).savePreferences(_localPrefs!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(invoicePreferencesProvider);

    return ResponsiveScaffold(
      currentRoute: '/invoices/preferences',
      appBar: AppBar(
        title: const Text('Invoice Preferences'),
      ),
      body: prefsAsync.when(
        data: (serverData) {
          _initLocal(serverData);
          final current = _localPrefs!;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.m),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Invoice Template Columns',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      SwitchListTile(
                        title: const Text('Show GSTIN'),
                        subtitle: const Text('Render organization GSTIN header info'),
                        value: current.showGstin,
                        onChanged: (val) {
                          setState(() => _localPrefs = current.copyWith(showGstin: val));
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Show PAN'),
                        subtitle: const Text('Render PAN column records'),
                        value: current.showPan,
                        onChanged: (val) {
                          setState(() => _localPrefs = current.copyWith(showPan: val));
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Show HSN'),
                        subtitle: const Text('Render HSN code detail grids'),
                        value: current.showHsn,
                        onChanged: (val) {
                          setState(() => _localPrefs = current.copyWith(showHsn: val));
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Show Payment Mode'),
                        subtitle: const Text('Display default transaction payments details'),
                        value: current.showPaymentMode,
                        onChanged: (val) {
                          setState(() => _localPrefs = current.copyWith(showPaymentMode: val));
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Show Due Date'),
                        subtitle: const Text('Display due date header'),
                        value: current.showDueDate,
                        onChanged: (val) {
                          setState(() => _localPrefs = current.copyWith(showDueDate: val));
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Show Terms & Conditions'),
                        subtitle: const Text('Render terms footer note'),
                        value: current.showTerms,
                        onChanged: (val) {
                          setState(() => _localPrefs = current.copyWith(showTerms: val));
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Show Signature'),
                        subtitle: const Text('Render signature signoff block'),
                        value: current.showSignature,
                        onChanged: (val) {
                          setState(() => _localPrefs = current.copyWith(showSignature: val));
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Show CGST & SGST'),
                        subtitle: const Text('Split GST totals in template breakdown list'),
                        value: current.showCgstSgst,
                        onChanged: (val) {
                          setState(() => _localPrefs = current.copyWith(showCgstSgst: val));
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Preferences', style: TextStyle(fontSize: 16)),
              ),
            ],
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
                onPressed: () => ref.read(invoicePreferencesProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
