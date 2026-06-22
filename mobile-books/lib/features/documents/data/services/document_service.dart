import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/core/network/network_client.dart';
import 'package:mobile_books/features/documents/data/models/document_model.dart';

class DocumentException implements Exception {
  final String message;
  DocumentException(this.message);

  @override
  String toString() => message;
}

class DocumentService {
  final NetworkClient _networkClient;

  DocumentService(this._networkClient);

  Future<List<DocumentModel>> getDocuments() async {
    try {
      final response = await _networkClient.get('/documents');
      final data = response.data as Map<String, dynamic>;
      final list = data['documents'] as List? ?? [];
      return list.map((e) => DocumentModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to fetch documents.';
      throw DocumentException(message);
    } catch (e) {
      throw DocumentException(e.toString());
    }
  }

  Future<void> deleteDocument(int id) async {
    try {
      await _networkClient.delete('/documents/$id');
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to delete document.';
      throw DocumentException(message);
    } catch (e) {
      throw DocumentException(e.toString());
    }
  }

  Future<DocumentModel> uploadDocument({
    required String filePath,
    required String fileName,
    required String documentName,
    required String category,
    required String relatedModule,
    int? relatedRecordId,
    String? notes,
  }) async {
    try {
      final multipartFile = await MultipartFile.fromFile(filePath, filename: fileName);
      final map = {
        'file': multipartFile,
        'document_name': documentName,
        'category': category,
        'related_module': relatedModule,
      };
      if (relatedRecordId != null) {
        map['related_record_id'] = relatedRecordId;
      }
      if (notes != null) {
        map['notes'] = notes;
      }

      final formData = FormData.fromMap(map);
      final response = await _networkClient.post('/documents', data: formData);
      final data = response.data as Map<String, dynamic>;
      if (data['document'] != null) {
        return DocumentModel.fromJson(data['document'] as Map<String, dynamic>);
      } else {
        throw DocumentException('Failed to upload document.');
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] as String? ?? 'Failed to upload document.';
      throw DocumentException(message);
    } catch (e) {
      throw DocumentException(e.toString());
    }
  }

  // Returns URL for downloading document
  String getDownloadUrl(int id) {
    return '/documents/$id/download';
  }
}

final documentServiceProvider = Provider<DocumentService>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return DocumentService(networkClient);
});
