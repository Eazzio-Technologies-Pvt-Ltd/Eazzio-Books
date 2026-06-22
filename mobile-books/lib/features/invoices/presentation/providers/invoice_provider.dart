import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/invoices/data/models/invoice.dart';
import 'package:mobile_books/features/invoices/data/models/invoice_item.dart';
import 'package:mobile_books/features/invoices/data/models/payment.dart';
import 'package:mobile_books/features/invoices/data/services/invoice_service.dart';

// ---------------------------------------------------------------------------
// Filter & Search state
// ---------------------------------------------------------------------------

class InvoicesListFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;
}

/// Filter state for invoices list: 'all', 'draft', 'sent', 'unpaid',
/// 'partially_paid', 'paid', 'overdue', 'cancelled'
final invoicesListFilterProvider =
    NotifierProvider<InvoicesListFilterNotifier, String>(() {
  return InvoicesListFilterNotifier();
});

class InvoiceSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

/// Search query state for invoices list
final invoiceSearchQueryProvider =
    NotifierProvider<InvoiceSearchQueryNotifier, String>(() {
  return InvoiceSearchQueryNotifier();
});

// ---------------------------------------------------------------------------
// Core Invoices list provider (AsyncNotifier)
// ---------------------------------------------------------------------------

class InvoicesNotifier extends AsyncNotifier<List<Invoice>> {
  @override
  Future<List<Invoice>> build() {
    return ref.watch(invoiceServiceProvider).getInvoices();
  }

  /// Explicitly reloads invoice listings from backend.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(invoiceServiceProvider).getInvoices();
    });
  }

  /// Dispatches invoice creation and refreshes listings.
  Future<Invoice> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
    final service = ref.read(invoiceServiceProvider);
    final result = await service.createInvoice(invoice, items);
    ref.invalidateSelf(); // Force rebuild to update list views
    return result;
  }

  /// Dispatches invoice updates and invalidates cache.
  Future<void> updateInvoice(int id, Map<String, dynamic> updates) async {
    final service = ref.read(invoiceServiceProvider);
    await service.updateInvoice(id, updates);
    ref.invalidateSelf();
    ref.invalidate(invoiceDetailsProvider(id)); // Invalidate detail cache
  }

  /// Dispatches invoice deletion and updates list views.
  Future<void> deleteInvoice(int id) async {
    final service = ref.read(invoiceServiceProvider);
    await service.deleteInvoice(id);
    ref.invalidateSelf();
    ref.invalidate(invoiceDetailsProvider(id));
  }

  /// Records a payment and refreshes invoice state.
  Future<double> recordPayment(int id, Map<String, dynamic> paymentPayload) async {
    final service = ref.read(invoiceServiceProvider);
    final newBalance = await service.recordPayment(id, paymentPayload);
    ref.invalidateSelf();
    ref.invalidate(invoiceDetailsProvider(id));
    ref.invalidate(invoicePaymentsProvider(id));
    return newBalance;
  }

  /// Sends an invoice email via backend SMTP relay.
  Future<void> sendEmail(int id, Map<String, dynamic> emailPayload) async {
    final service = ref.read(invoiceServiceProvider);
    await service.sendInvoiceEmail(id, emailPayload);
    ref.invalidateSelf();
    ref.invalidate(invoiceDetailsProvider(id));
  }
}

final invoicesProvider =
    AsyncNotifierProvider<InvoicesNotifier, List<Invoice>>(() {
  return InvoicesNotifier();
});

// ---------------------------------------------------------------------------
// Filtered list (status filter + search)
// ---------------------------------------------------------------------------

/// Filtered list of invoices matching status filter and search query
final filteredInvoicesProvider = Provider<AsyncValue<List<Invoice>>>((ref) {
  final invoicesState = ref.watch(invoicesProvider);
  final filter = ref.watch(invoicesListFilterProvider);
  final searchQuery = ref.watch(invoiceSearchQueryProvider).toLowerCase();

  return invoicesState.whenData((list) {
    var result = list;

    // Apply status filter to match backend statuses
    if (filter != 'all') {
      result =
          result.where((q) => q.status.toLowerCase() == filter).toList();
    }

    // Apply search query filter across invoice number, notes, and terms
    if (searchQuery.isNotEmpty) {
      result = result.where((q) {
        final number = q.invoiceNumber.toLowerCase();
        final notes = (q.notes ?? '').toLowerCase();
        final terms = (q.terms ?? '').toLowerCase();
        final status = q.status.toLowerCase();
        return number.contains(searchQuery) ||
            notes.contains(searchQuery) ||
            terms.contains(searchQuery) ||
            status.contains(searchQuery);
      }).toList();
    }

    return result;
  });
});

// ---------------------------------------------------------------------------
// Detail provider (FutureProvider.family)
// ---------------------------------------------------------------------------

/// Fetches invoice details (invoice + line items) by ID
final invoiceDetailsProvider =
    FutureProvider.family<InvoiceDetails, int>((ref, id) {
  return ref.watch(invoiceServiceProvider).getInvoiceById(id);
});

// ---------------------------------------------------------------------------
// Payments provider (FutureProvider.family)
// ---------------------------------------------------------------------------

/// Fetches payments list for a given invoice ID
final invoicePaymentsProvider =
    FutureProvider.family<List<Payment>, int>((ref, id) {
  return ref.watch(invoiceServiceProvider).getPayments(id);
});

class PaymentsNotifier extends AsyncNotifier<List<Payment>> {
  @override
  Future<List<Payment>> build() {
    return ref.watch(invoiceServiceProvider).getAllPayments();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(invoiceServiceProvider).getAllPayments();
    });
  }
}

final paymentsProvider =
    AsyncNotifierProvider<PaymentsNotifier, List<Payment>>(() {
  return PaymentsNotifier();
});
