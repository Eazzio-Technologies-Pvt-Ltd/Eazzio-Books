import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_books/core/theme/theme.dart';
import 'package:mobile_books/features/documents/presentation/providers/document_provider.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _saving = false;
  String? _selectedFilePath;
  String? _selectedFileName;

  // Form Fields
  final _nameController = TextEditingController();
  final _relatedRecordIdController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = 'Other';
  String _relatedModule = 'other';

  @override
  void dispose() {
    _nameController.dispose();
    _relatedRecordIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Files / Documents'),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    String? filePath;
    String? fileName;

    try {
      if (source == 'camera' || source == 'gallery') {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        );
        if (image != null) {
          filePath = image.path;
          fileName = image.name;
        }
      } else if (source == 'file') {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: [
            'pdf',
            'doc',
            'docx',
            'xls',
            'xlsx',
            'jpg',
            'jpeg',
            'png',
            'txt',
          ],
        );
        if (result != null && result.files.single.path != null) {
          filePath = result.files.single.path;
          fileName = result.files.single.name;
        }
      }

      if (filePath == null || fileName == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No file selected.')));
        }
        return;
      }

      setState(() {
        _selectedFilePath = filePath;
        _selectedFileName = fileName;
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = fileName!;
        }
      });
    } on PlatformException catch (e) {
      if (mounted) {
        String errMsg = 'Permission denied or picker error.';
        if (e.code == 'photo_access_denied' ||
            e.code == 'camera_access_denied') {
          errMsg =
              'Access denied. Please enable camera/storage permissions in settings.';
        } else if (e.message != null) {
          errMsg = e.message!;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _upload() async {
    if (_selectedFilePath == null || _selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final recordIdVal = int.tryParse(_relatedRecordIdController.text.trim());

      await ref
          .read(documentsProvider.notifier)
          .uploadDocument(
            filePath: _selectedFilePath!,
            fileName: _selectedFileName!,
            documentName: _nameController.text.trim(),
            category: _category,
            relatedModule: _relatedModule,
            relatedRecordId: recordIdVal,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload document: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.m),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Select File Button
                    const Text(
                      'Select File *',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        _selectedFileName == null
                            ? 'Choose File'
                            : 'Change File',
                      ),
                    ),
                    if (_selectedFileName != null) ...[
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        'Selected: $_selectedFileName',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.m),

                    // Document Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Document Name *',
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Document name is required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Category
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Invoice',
                          child: Text('Invoice'),
                        ),
                        DropdownMenuItem(value: 'Bill', child: Text('Bill')),
                        DropdownMenuItem(
                          value: 'Expense',
                          child: Text('Expense'),
                        ),
                        DropdownMenuItem(
                          value: 'Receipt',
                          child: Text('Receipt'),
                        ),
                        DropdownMenuItem(
                          value: 'Customer',
                          child: Text('Customer'),
                        ),
                        DropdownMenuItem(
                          value: 'Vendor',
                          child: Text('Vendor'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _category = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Related Module
                    DropdownButtonFormField<String>(
                      initialValue: _relatedModule,
                      decoration: const InputDecoration(
                        labelText: 'Related Module *',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'invoices',
                          child: Text('Invoices'),
                        ),
                        DropdownMenuItem(value: 'bills', child: Text('Bills')),
                        DropdownMenuItem(
                          value: 'expenses',
                          child: Text('Expenses'),
                        ),
                        DropdownMenuItem(
                          value: 'customers',
                          child: Text('Customers'),
                        ),
                        DropdownMenuItem(
                          value: 'vendors',
                          child: Text('Vendors'),
                        ),
                        DropdownMenuItem(value: 'items', child: Text('Items')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _relatedModule = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Related Record ID
                    TextFormField(
                      controller: _relatedRecordIdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Related Record ID (Optional)',
                        hintText: 'e.g. 104',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Notes
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            ElevatedButton(
              onPressed: _saving || _selectedFilePath == null ? null : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Upload Document',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
