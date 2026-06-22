import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_books/features/documents/data/models/document_model.dart';
import 'package:mobile_books/features/documents/data/services/document_service.dart';

class DocumentsNotifier extends AsyncNotifier<List<DocumentModel>> {
  @override
  Future<List<DocumentModel>> build() {
    return ref.watch(documentServiceProvider).getDocuments();
  }

  Future<void> uploadDocument({
    required String filePath,
    required String fileName,
    required String documentName,
    required String category,
    required String relatedModule,
    int? relatedRecordId,
    String? notes,
  }) async {
    final service = ref.read(documentServiceProvider);
    await service.uploadDocument(
      filePath: filePath,
      fileName: fileName,
      documentName: documentName,
      category: category,
      relatedModule: relatedModule,
      relatedRecordId: relatedRecordId,
      notes: notes,
    );
    ref.invalidateSelf();
  }

  Future<void> deleteDocument(int id) async {
    final service = ref.read(documentServiceProvider);
    await service.deleteDocument(id);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final documentsProvider = AsyncNotifierProvider<DocumentsNotifier, List<DocumentModel>>(() {
  return DocumentsNotifier();
});

class DocumentSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

final documentSearchQueryProvider = NotifierProvider<DocumentSearchQueryNotifier, String>(() {
  return DocumentSearchQueryNotifier();
});

class DocumentCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;
}

final documentCategoryFilterProvider = NotifierProvider<DocumentCategoryFilterNotifier, String>(() {
  return DocumentCategoryFilterNotifier();
});

class DocumentModuleFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  @override
  set state(String value) => super.state = value;
}

final documentModuleFilterProvider = NotifierProvider<DocumentModuleFilterNotifier, String>(() {
  return DocumentModuleFilterNotifier();
});

final filteredDocumentsProvider = Provider<List<DocumentModel>>((ref) {
  final docsState = ref.watch(documentsProvider);
  final query = ref.watch(documentSearchQueryProvider).toLowerCase();
  final categoryFilter = ref.watch(documentCategoryFilterProvider);
  final moduleFilter = ref.watch(documentModuleFilterProvider);

  return docsState.maybeWhen(
    data: (list) {
      return list.where((doc) {
        final matchesQuery = doc.documentName.toLowerCase().contains(query);
        final matchesCategory = categoryFilter == 'all' || doc.category == categoryFilter;
        final matchesModule = moduleFilter == 'all' || doc.relatedModule == moduleFilter;
        return matchesQuery && matchesCategory && matchesModule;
      }).toList();
    },
    orElse: () => [],
  );
});
