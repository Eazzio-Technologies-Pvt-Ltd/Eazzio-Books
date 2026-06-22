import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/invoices/data/models/invoice.dart';
import 'package:mobile_books/features/recurring_invoices/data/models/recurring_invoice.dart';
import 'package:mobile_books/features/recurring_invoices/data/models/recurring_invoice_item.dart';
import 'package:mobile_books/features/recurring_invoices/data/services/recurring_invoice_service.dart';

class RecurringInvoicesNotifier extends AsyncNotifier<List<RecurringInvoice>> {
  @override
  Future<List<RecurringInvoice>> build() {
    return ref.watch(recurringInvoiceServiceProvider).getRecurringInvoices();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(recurringInvoiceServiceProvider).getRecurringInvoices();
    });
  }

  Future<int> createRecurringInvoice(RecurringInvoice ri, List<RecurringInvoiceItem> items) async {
    final service = ref.read(recurringInvoiceServiceProvider);
    final id = await service.createRecurringInvoice(ri, items);
    ref.invalidateSelf();
    return id;
  }

  Future<void> updateRecurringInvoice(int id, Map<String, dynamic> updates) async {
    final service = ref.read(recurringInvoiceServiceProvider);
    await service.updateRecurringInvoice(id, updates);
    ref.invalidateSelf();
    ref.invalidate(recurringInvoiceDetailsProvider(id));
  }

  Future<void> pauseRecurringInvoice(int id) async {
    final service = ref.read(recurringInvoiceServiceProvider);
    await service.pauseRecurringInvoice(id);
    ref.invalidateSelf();
    ref.invalidate(recurringInvoiceDetailsProvider(id));
  }

  Future<void> resumeRecurringInvoice(int id) async {
    final service = ref.read(recurringInvoiceServiceProvider);
    await service.resumeRecurringInvoice(id);
    ref.invalidateSelf();
    ref.invalidate(recurringInvoiceDetailsProvider(id));
  }

  Future<void> stopRecurringInvoice(int id) async {
    final service = ref.read(recurringInvoiceServiceProvider);
    await service.stopRecurringInvoice(id);
    ref.invalidateSelf();
    ref.invalidate(recurringInvoiceDetailsProvider(id));
  }

  Future<int> generateNow(int id) async {
    final service = ref.read(recurringInvoiceServiceProvider);
    final invId = await service.generateNow(id);
    ref.invalidateSelf();
    ref.invalidate(recurringInvoiceDetailsProvider(id));
    ref.invalidate(recurringInvoiceGeneratedInvoicesProvider(id));
    return invId;
  }
}

final recurringInvoicesProvider =
    AsyncNotifierProvider<RecurringInvoicesNotifier, List<RecurringInvoice>>(() {
  return RecurringInvoicesNotifier();
});

final recurringInvoiceDetailsProvider =
    FutureProvider.family<RecurringInvoice, int>((ref, id) {
  return ref.watch(recurringInvoiceServiceProvider).getRecurringInvoiceById(id);
});

final recurringInvoiceGeneratedInvoicesProvider =
    FutureProvider.family<List<Invoice>, int>((ref, id) {
  return ref.watch(recurringInvoiceServiceProvider).getGeneratedInvoices(id);
});
