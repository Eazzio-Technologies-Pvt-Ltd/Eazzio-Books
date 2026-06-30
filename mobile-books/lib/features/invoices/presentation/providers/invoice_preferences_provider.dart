import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/invoices/data/models/invoice_preferences.dart';
import 'package:mobile_books/features/invoices/data/services/invoice_service.dart';

class InvoicePreferencesNotifier extends AsyncNotifier<InvoicePreferences> {
  @override
  Future<InvoicePreferences> build() {
    return ref.watch(invoiceServiceProvider).getInvoicePreferences();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(invoiceServiceProvider).getInvoicePreferences();
    });
  }

  Future<void> savePreferences(InvoicePreferences preferences) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(invoiceServiceProvider).saveInvoicePreferences(preferences);
      return preferences;
    });
  }
}

final invoicePreferencesProvider =
    AsyncNotifierProvider<InvoicePreferencesNotifier, InvoicePreferences>(() {
  return InvoicePreferencesNotifier();
});
