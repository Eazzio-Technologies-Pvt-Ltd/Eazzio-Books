import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/quotes/data/models/quote.dart';
import 'package:mobile_books/features/quotes/data/models/quote_item.dart';
import 'package:mobile_books/features/quotes/data/models/salesperson.dart';
import 'package:mobile_books/features/quotes/data/models/project.dart';

class QuoteException implements Exception {
  final String message;
  QuoteException(this.message);

  @override
  String toString() => message;
}

class QuoteDetails {
  final Quote quote;
  final List<QuoteItem> items;

  QuoteDetails({
    required this.quote,
    required this.items,
  });
}

class QuoteService {
  final NetworkClient _networkClient;

  QuoteService(this._networkClient);

  /// Fetches all quotes belonging to the active tenant/organization
  Future<List<Quote>> getQuotes() async {
    try {
      final response = await _networkClient.get('/quotes');
      final data = response.data as Map<String, dynamic>;
      final list = data['quotes'] as List? ?? [];
      return list.map((e) => Quote.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch quotes list.';
      throw QuoteException(message);
    } catch (e) {
      throw QuoteException(e.toString());
    }
  }

  /// Fetches quote details and quote items for a single quote ID
  Future<QuoteDetails> getQuoteById(int id) async {
    try {
      final response = await _networkClient.get('/quotes/$id');
      final data = response.data as Map<String, dynamic>;
      if (data['quote'] != null) {
        final quote = Quote.fromJson(data['quote'] as Map<String, dynamic>);
        final itemsList = data['items'] as List? ?? [];
        final items = itemsList.map((e) => QuoteItem.fromJson(e as Map<String, dynamic>)).toList();
        return QuoteDetails(quote: quote, items: items);
      } else {
        throw QuoteException('Invalid quote response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch quote details.';
      throw QuoteException(message);
    } catch (e) {
      throw QuoteException(e.toString());
    }
  }

  /// Creates a new quote with associated line items
  Future<Quote> createQuote(Quote quote, List<QuoteItem> items) async {
    try {
      final body = quote.toJson();
      body.remove('id'); // generated on backend
      body['items'] = items.map((i) {
        final itemMap = i.toJson();
        itemMap.remove('id');
        itemMap.remove('quote_id');
        return itemMap;
      }).toList();

      final response = await _networkClient.post('/quotes', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['quote'] != null) {
        return Quote.fromJson(data['quote'] as Map<String, dynamic>);
      } else {
        throw QuoteException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create quote.';
      throw QuoteException(message);
    } catch (e) {
      throw QuoteException(e.toString());
    }
  }

  /// Updates details/items of an existing quote
  Future<Quote> updateQuote(int id, Map<String, dynamic> updates) async {
    try {
      final response = await _networkClient.put('/quotes/$id', data: updates);
      final data = response.data as Map<String, dynamic>;
      if (data['quote'] != null) {
        return Quote.fromJson(data['quote'] as Map<String, dynamic>);
      } else {
        throw QuoteException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to update quote.';
      throw QuoteException(message);
    } catch (e) {
      throw QuoteException(e.toString());
    }
  }

  /// Deletes a quote by ID
  Future<void> deleteQuote(int id) async {
    try {
      await _networkClient.delete('/quotes/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete quote.';
      throw QuoteException(message);
    } catch (e) {
      throw QuoteException(e.toString());
    }
  }

  /// Converts an existing quote to a sales invoice
  Future<Map<String, dynamic>> convertQuoteToInvoice(int id) async {
    try {
      final response = await _networkClient.post('/quotes/$id/convert-to-invoice');
      final data = response.data as Map<String, dynamic>;
      return data;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to convert quote to invoice.';
      throw QuoteException(message);
    } catch (e) {
      throw QuoteException(e.toString());
    }
  }

  /// Sends the quote statement/PDF via email SMTP relay
  Future<void> sendEmail(int id, {
    required String to,
    required String subject,
    required String body,
  }) async {
    try {
      await _networkClient.post(
        '/quotes/$id/send',
        data: {'to': to, 'subject': subject, 'body': body},
      );
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to send quote email.';
      throw QuoteException(message);
    } catch (e) {
      throw QuoteException(e.toString());
    }
  }

  /// Get the direct download URL for Quote PDF
  String getQuotePdfUrl(int id) {
    return '${_networkClient.dio.options.baseUrl}/quotes/$id/pdf';
  }

  /// Fetches salespersons list
  Future<List<Salesperson>> getSalespersons() async {
    try {
      final response = await _networkClient.get('/salespersons');
      final data = response.data as Map<String, dynamic>;
      final list = data['salespersons'] as List? ?? [];
      return list.map((e) => Salesperson.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch salespersons list.';
      throw QuoteException(message);
    } catch (e) {
      throw QuoteException(e.toString());
    }
  }

  /// Creates a new salesperson
  Future<Salesperson> createSalesperson(String name, {String? email, String? phone, String? employeeId}) async {
    try {
      final body = {
        'name': name,
        'email': email,
        'phone': phone,
        'employee_id': employeeId,
      };
      final response = await _networkClient.post('/salespersons', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['salesperson'] != null) {
        return Salesperson.fromJson(data['salesperson'] as Map<String, dynamic>);
      } else {
        throw QuoteException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create salesperson.';
      throw QuoteException(message);
    } catch (e) {
      throw QuoteException(e.toString());
    }
  }

  /// Fetches projects list
  Future<List<Project>> getProjects() async {
    try {
      final response = await _networkClient.get('/projects');
      final data = response.data as Map<String, dynamic>;
      final list = data['projects'] as List? ?? [];
      return list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch projects list.';
      throw QuoteException(message);
    } catch (e) {
      throw QuoteException(e.toString());
    }
  }

  /// Creates a new project
  Future<Project> createProject(Project project) async {
    try {
      final body = project.toJson();
      body.remove('id');
      final response = await _networkClient.post('/projects', data: body);
      final data = response.data as Map<String, dynamic>;
      if (data['project'] != null) {
        return Project.fromJson(data['project'] as Map<String, dynamic>);
      } else {
        throw QuoteException('Invalid response structure from server.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to create project.';
      throw QuoteException(message);
    } catch (e) {
      throw QuoteException(e.toString());
    }
  }

  /// Marks a quote as sent in the backend
  Future<void> markQuoteAsSent(int id) async {
    try {
      await _networkClient.patch('/quotes/$id/mark-sent');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to mark quote as sent.';
      throw QuoteException(message);
    } catch (e) {
      throw QuoteException(e.toString());
    }
  }
}

final quoteServiceProvider = Provider<QuoteService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return QuoteService(networkClient);
});
