import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/credit_notes/data/models/credit_note.dart';
import 'package:mobile_books/features/credit_notes/data/models/credit_note_item.dart';

class CreditNoteException implements Exception {
  final String message;
  CreditNoteException(this.message);

  @override
  String toString() => message;
}

class CreditNoteDetails {
  final CreditNote creditNote;
  final List<CreditNoteItem> items;

  CreditNoteDetails({
    required this.creditNote,
    required this.items,
  });
}

class CreditNoteService {
  final NetworkClient _networkClient;

  CreditNoteService(this._networkClient);

  Future<List<CreditNote>> getCreditNotes() async {
    try {
      final response = await _networkClient.get('/credit-notes');
      final data = response.data as Map<String, dynamic>;
      final list = data['credit_notes'] as List? ?? [];
      return list.map((e) => CreditNote.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch credit notes.';
      throw CreditNoteException(message);
    } catch (e) {
      throw CreditNoteException(e.toString());
    }
  }

  Future<CreditNoteDetails> getCreditNoteById(int id) async {
    try {
      final response = await _networkClient.get('/credit-notes/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['credit_note'] != null) {
        final creditNote = CreditNote.fromJson(data['credit_note'] as Map<String, dynamic>);
        final itemsList = data['items'] as List? ?? [];
        final items = itemsList.map((e) => CreditNoteItem.fromJson(e as Map<String, dynamic>)).toList();
        return CreditNoteDetails(creditNote: creditNote, items: items);
      } else {
        throw CreditNoteException('Invalid credit note response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch credit note details.';
      throw CreditNoteException(message);
    } catch (e) {
      throw CreditNoteException(e.toString());
    }
  }

  Future<CreditNote> createCreditNote(CreditNote cn, List<CreditNoteItem> items) async {
    try {
      final body = cn.toJson();
      body.remove('id');
      body['items'] = items.map((i) {
        final itemMap = i.toJson();
        itemMap.remove('id');
        itemMap.remove('credit_note_id');
        return itemMap;
      }).toList();

      final response = await _networkClient.post('/credit-notes', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['credit_note'] != null) {
        return CreditNote.fromJson(data['credit_note'] as Map<String, dynamic>);
      } else {
        throw CreditNoteException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create credit note.';
      throw CreditNoteException(message);
    } catch (e) {
      throw CreditNoteException(e.toString());
    }
  }

  Future<void> updateCreditNote(int id, Map<String, dynamic> updates) async {
    try {
      await _networkClient.put('/credit-notes/$id', data: updates);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update credit note.';
      throw CreditNoteException(message);
    } catch (e) {
      throw CreditNoteException(e.toString());
    }
  }

  Future<void> deleteCreditNote(int id) async {
    try {
      await _networkClient.delete('/credit-notes/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete credit note.';
      throw CreditNoteException(message);
    } catch (e) {
      throw CreditNoteException(e.toString());
    }
  }

  Future<CreditNote> cancelCreditNote(int id) async {
    try {
      final response = await _networkClient.put('/credit-notes/$id/cancel');
      final data = response.data as Map<String, dynamic>;
      if (data['credit_note'] != null) {
        return CreditNote.fromJson(data['credit_note'] as Map<String, dynamic>);
      } else {
        throw CreditNoteException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to cancel credit note.';
      throw CreditNoteException(message);
    } catch (e) {
      throw CreditNoteException(e.toString());
    }
  }

  Future<CreditNote> applyCreditToInvoice(int id, int invoiceId, double amountToApply) async {
    try {
      final response = await _networkClient.post(
        '/credit-notes/$id/apply-to-invoice',
        data: {
          'invoice_id': invoiceId,
          'amount_to_apply': amountToApply,
        },
      );
      final data = response.data as Map<String, dynamic>;
      if (data['credit_note'] != null) {
        return CreditNote.fromJson(data['credit_note'] as Map<String, dynamic>);
      } else {
        throw CreditNoteException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to apply credit to invoice.';
      throw CreditNoteException(message);
    } catch (e) {
      throw CreditNoteException(e.toString());
    }
  }

  Future<void> sendCreditNoteEmail(int id, Map<String, dynamic> emailPayload) async {
    try {
      await _networkClient.post('/credit-notes/$id/send', data: emailPayload);
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to send credit note email.';
      throw CreditNoteException(message);
    } catch (e) {
      throw CreditNoteException(e.toString());
    }
  }
}

final creditNoteServiceProvider = Provider<CreditNoteService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return CreditNoteService(networkClient);
});
