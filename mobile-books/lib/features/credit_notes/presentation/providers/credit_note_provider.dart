import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/credit_notes/data/models/credit_note.dart';
import 'package:mobile_books/features/credit_notes/data/models/credit_note_item.dart';
import 'package:mobile_books/features/credit_notes/data/services/credit_note_service.dart';

class CreditNotesNotifier extends AsyncNotifier<List<CreditNote>> {
  @override
  Future<List<CreditNote>> build() {
    return ref.watch(creditNoteServiceProvider).getCreditNotes();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(creditNoteServiceProvider).getCreditNotes();
    });
  }

  Future<CreditNote> createCreditNote(CreditNote cn, List<CreditNoteItem> items) async {
    final service = ref.read(creditNoteServiceProvider);
    final result = await service.createCreditNote(cn, items);
    ref.invalidateSelf();
    return result;
  }

  Future<void> updateCreditNote(int id, Map<String, dynamic> updates) async {
    final service = ref.read(creditNoteServiceProvider);
    await service.updateCreditNote(id, updates);
    ref.invalidateSelf();
    ref.invalidate(creditNoteDetailsProvider(id));
  }

  Future<void> deleteCreditNote(int id) async {
    final service = ref.read(creditNoteServiceProvider);
    await service.deleteCreditNote(id);
    ref.invalidateSelf();
    ref.invalidate(creditNoteDetailsProvider(id));
  }

  Future<void> cancelCreditNote(int id) async {
    final service = ref.read(creditNoteServiceProvider);
    await service.cancelCreditNote(id);
    ref.invalidateSelf();
    ref.invalidate(creditNoteDetailsProvider(id));
  }

  Future<void> applyCreditToInvoice(int id, int invoiceId, double amountToApply) async {
    final service = ref.read(creditNoteServiceProvider);
    await service.applyCreditToInvoice(id, invoiceId, amountToApply);
    ref.invalidateSelf();
    ref.invalidate(creditNoteDetailsProvider(id));
  }

  Future<void> sendEmail(int id, Map<String, dynamic> emailPayload) async {
    final service = ref.read(creditNoteServiceProvider);
    await service.sendCreditNoteEmail(id, emailPayload);
    ref.invalidateSelf();
    ref.invalidate(creditNoteDetailsProvider(id));
  }

  /// Marks a credit note as sent explicitly
  Future<void> markAsSent(int id) async {
    final service = ref.read(creditNoteServiceProvider);
    await service.markCreditNoteAsSent(id);
    ref.invalidateSelf();
    ref.invalidate(creditNoteDetailsProvider(id));
  }
}

final creditNotesProvider =
    AsyncNotifierProvider<CreditNotesNotifier, List<CreditNote>>(() {
  return CreditNotesNotifier();
});

final creditNoteDetailsProvider =
    FutureProvider.family<CreditNoteDetails, int>((ref, id) {
  return ref.watch(creditNoteServiceProvider).getCreditNoteById(id);
});
