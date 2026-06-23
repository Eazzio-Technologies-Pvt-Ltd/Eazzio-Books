import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/core/navigation/responsive_scaffold.dart';
import 'package:mobile_books/features/documents/data/models/document_model.dart';
import 'package:mobile_books/features/documents/presentation/providers/document_provider.dart';

class DocumentsListScreen extends ConsumerStatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  ConsumerState<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends ConsumerState<DocumentsListScreen> {
  late final TextEditingController _searchController;

  String _formatBytes(int? bytes) {
    if (bytes == null) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(documentSearchQueryProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docsList = ref.watch(filteredDocumentsProvider);
    final docsState = ref.watch(documentsProvider);
    final searchController = _searchController;

    return ResponsiveScaffold(
      currentRoute: '/documents',
      appBar: AppBar(
        title: const Text('All Documents'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/documents/upload'),
        child: const Icon(Icons.upload_file),
      ),
      body: Column(
        children: [
          // Filters & Search
          Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  onChanged: (val) => ref.read(documentSearchQueryProvider.notifier).state = val,
                  decoration: InputDecoration(
                    hintText: 'Search documents...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              ref.read(documentSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: ref.watch(documentCategoryFilterProvider),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Categories')),
                          DropdownMenuItem(value: 'Invoice', child: Text('Invoice')),
                          DropdownMenuItem(value: 'Bill', child: Text('Bill')),
                          DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                          DropdownMenuItem(value: 'Receipt', child: Text('Receipt')),
                          DropdownMenuItem(value: 'Customer', child: Text('Customer')),
                          DropdownMenuItem(value: 'Vendor', child: Text('Vendor')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(documentCategoryFilterProvider.notifier).state = val;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: ref.watch(documentModuleFilterProvider),
                        decoration: const InputDecoration(
                          labelText: 'Module',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Modules')),
                          DropdownMenuItem(value: 'invoices', child: Text('Invoices')),
                          DropdownMenuItem(value: 'bills', child: Text('Bills')),
                          DropdownMenuItem(value: 'expenses', child: Text('Expenses')),
                          DropdownMenuItem(value: 'customers', child: Text('Customers')),
                          DropdownMenuItem(value: 'vendors', child: Text('Vendors')),
                          DropdownMenuItem(value: 'items', child: Text('Items')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(documentModuleFilterProvider.notifier).state = val;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // List View
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(documentsProvider.notifier).refresh(),
              child: docsState.when(
                data: (_) {
                  if (docsList.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.folder_open, size: 64, color: AppColors.textSecondaryLight),
                              SizedBox(height: AppSpacing.m),
                              Text(
                                'No documents found.',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                    itemCount: docsList.length,
                    itemBuilder: (context, index) {
                      final doc = docsList[index];
                      final dateStr = DateFormat.yMMMd().format(doc.createdAt);
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSpacing.m),
                        child: ListTile(
                          leading: const Icon(Icons.insert_drive_file, size: 36, color: AppColors.primaryBlue),
                          title: Text(doc.documentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Cat: ${doc.category ?? "Other"}  •  Module: ${doc.relatedModule ?? "other"}'),
                              const SizedBox(height: 2),
                              Text(
                                'File: ${doc.fileName ?? "—"} (${_formatBytes(doc.fileSize)})',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              ),
                              Text('Uploaded: $dateStr', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.download, size: 20),
                                onPressed: () => _viewDownloadInfo(context, doc),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: AppColors.danger),
                                onPressed: () => _confirmDelete(context, ref, doc),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewDownloadInfo(BuildContext context, DocumentModel doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Document Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Document Name: ${doc.documentName}'),
            const SizedBox(height: 8),
            Text('File Name: ${doc.fileName ?? "—"}'),
            const SizedBox(height: 8),
            Text('File Size: ${_formatBytes(doc.fileSize)}'),
            const SizedBox(height: 8),
            Text('Mime Type: ${doc.fileType ?? "—"}'),
            const SizedBox(height: 8),
            Text('Server Path: ${doc.filePath ?? "—"}'),
            if (doc.notes != null && doc.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notes: ${doc.notes}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, DocumentModel doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete ${doc.documentName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(documentsProvider.notifier).deleteDocument(doc.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Document deleted successfully'), backgroundColor: AppColors.success),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete document: $e'), backgroundColor: AppColors.danger),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
