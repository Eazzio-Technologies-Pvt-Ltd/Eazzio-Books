import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/quotes/data/models/quote.dart';
import 'package:mobile_books/features/quotes/data/models/salesperson.dart';
import 'package:mobile_books/features/quotes/data/models/project.dart';
import 'package:mobile_books/features/quotes/data/models/quote_item.dart';
import 'package:mobile_books/features/quotes/data/services/quote_service.dart';

// ---------------------------------------------------------------------------
// Filter & Search state
// ---------------------------------------------------------------------------

class QuotesListFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;
}

/// Filter state for quotes list: 'all', 'draft', 'sent', 'accepted',
/// 'declined', 'expired', 'invoiced'
final quotesListFilterProvider =
    NotifierProvider<QuotesListFilterNotifier, String>(() {
  return QuotesListFilterNotifier();
});

class QuoteSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

/// Search query state for quotes list
final quoteSearchQueryProvider =
    NotifierProvider<QuoteSearchQueryNotifier, String>(() {
  return QuoteSearchQueryNotifier();
});

// ---------------------------------------------------------------------------
// Core Quotes list provider (AsyncNotifier)
// ---------------------------------------------------------------------------

/// Notifier that manages the list of quotes fetched from backend
class QuotesNotifier extends AsyncNotifier<List<Quote>> {
  @override
  Future<List<Quote>> build() {
    return ref.watch(quoteServiceProvider).getQuotes();
  }

  /// Explicitly reloads quote listings from backend.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(quoteServiceProvider).getQuotes();
    });
  }

  /// Dispatches quote creation and refreshes listings.
  Future<Quote> createQuote(Quote quote, List<QuoteItem> items) async {
    final service = ref.read(quoteServiceProvider);
    final result = await service.createQuote(quote, items);
    ref.invalidateSelf(); // Force rebuild to update list views
    return result;
  }

  /// Dispatches quote updates and invalidates cache.
  Future<Quote> updateQuote(int id, Map<String, dynamic> updates) async {
    final service = ref.read(quoteServiceProvider);
    final result = await service.updateQuote(id, updates);
    ref.invalidateSelf();
    ref.invalidate(quoteDetailsProvider(id)); // Invalidate detail cache
    return result;
  }

  /// Dispatches quote deletion and updates list views.
  Future<void> deleteQuote(int id) async {
    final service = ref.read(quoteServiceProvider);
    await service.deleteQuote(id);
    ref.invalidateSelf();
    ref.invalidate(quoteDetailsProvider(id));
  }

  /// Converts a quote to an invoice and refreshes state.
  Future<Map<String, dynamic>> convertToInvoice(int id) async {
    final service = ref.read(quoteServiceProvider);
    final result = await service.convertQuoteToInvoice(id);
    ref.invalidateSelf();
    ref.invalidate(quoteDetailsProvider(id));
    return result;
  }

  /// Sends a quote email via backend SMTP relay.
  Future<void> sendEmail(int id, {
    required String to,
    required String subject,
    required String body,
  }) async {
    final service = ref.read(quoteServiceProvider);
    await service.sendEmail(id, to: to, subject: subject, body: body);
    // After sending, the quote status may change to 'sent' on the backend
    ref.invalidateSelf();
    ref.invalidate(quoteDetailsProvider(id));
  }

  /// Marks a quote as sent explicitly
  Future<void> markAsSent(int id) async {
    final service = ref.read(quoteServiceProvider);
    await service.markQuoteAsSent(id);
    ref.invalidateSelf();
    ref.invalidate(quoteDetailsProvider(id));
  }
}

final quotesProvider =
    AsyncNotifierProvider<QuotesNotifier, List<Quote>>(() {
  return QuotesNotifier();
});

// ---------------------------------------------------------------------------
// Filtered list (status filter + search)
// ---------------------------------------------------------------------------

/// Filtered list of quotes matching status filter and search query
final filteredQuotesProvider = Provider<AsyncValue<List<Quote>>>((ref) {
  final quotesState = ref.watch(quotesProvider);
  final filter = ref.watch(quotesListFilterProvider);
  final searchQuery = ref.watch(quoteSearchQueryProvider).toLowerCase();

  return quotesState.whenData((list) {
    var result = list;

    // Apply status filter to match backend statuses
    if (filter != 'all') {
      result =
          result.where((q) => q.status.toLowerCase() == filter).toList();
    }

    // Apply search query filter across quote number, notes, and terms
    if (searchQuery.isNotEmpty) {
      result = result.where((q) {
        final number = q.quoteNumber.toLowerCase();
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

/// Fetches quote details (quote + line items) by ID
final quoteDetailsProvider =
    FutureProvider.family<QuoteDetails, int>((ref, id) {
  return ref.watch(quoteServiceProvider).getQuoteById(id);
});

// ---------------------------------------------------------------------------
// Auxiliary lookup providers (dropdown selections in forms)
// ---------------------------------------------------------------------------

/// Fetches list of salespersons for quote assignment dropdown
final salespersonsProvider = FutureProvider<List<Salesperson>>((ref) {
  return ref.watch(quoteServiceProvider).getSalespersons();
});

/// Fetches list of projects for quote assignment dropdown
final projectsProvider = FutureProvider<List<Project>>((ref) {
  return ref.watch(quoteServiceProvider).getProjects();
});
