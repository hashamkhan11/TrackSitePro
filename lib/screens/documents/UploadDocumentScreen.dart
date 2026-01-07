import 'dart:convert'; // for base64 encoding
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadDocumentScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const UploadDocumentScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _expiryDate;
  Uint8List? _selectedBytes;
  String? _fileName;
  bool _loading = false;
  double _progress = 0.0;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    if (_isUploading) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xls', 'xlsx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.single.bytes!;
        final sizeKB = bytes.lengthInBytes / 1024;

        if (sizeKB > 800) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("File too large! Max 800 KB allowed.")),
            );
          }
          return;
        }

        setState(() {
          _fileName = result.files.single.name;
          _selectedBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to pick file: $e")),
        );
      }
    }
  }

  Future<void> _saveDocument() async {
    if (_isUploading) return;

    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all required fields.")),
        );
      }
      return;
    }

    if (_selectedBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a file to upload.")),
        );
      }
      return;
    }

    setState(() {
      _loading = true;
      _isUploading = true;
      _progress = 0.3;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userEmail = FirebaseAuth.instance.currentUser!.email ?? 'Unknown';

      // Convert file to Base64
      final base64File = base64Encode(_selectedBytes!);

      setState(() => _progress = 0.6);

      final docData = {
        "title": _titleController.text.trim(),
        "description": _descriptionController.text.trim(),
        "fileName": _fileName,
        "fileData": base64File,
        "uploadDate": Timestamp.now(),
        "expiryDate": _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        "uploadedBy": userEmail,
        "uploadedById": uid,
        "createdAt": Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection("projects")
          .doc(widget.projectId)
          .collection("documents")
          .add(docData);

      setState(() => _progress = 1.0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Document uploaded successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        
        // Wait a moment to show completion then navigate back
        await Future.delayed(const Duration(milliseconds: 300));
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _isUploading = false;
        });
      }
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _expiryDate = null;
      _fileName = null;
      _selectedBytes = null;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Upload Document - ${widget.projectTitle}"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Document Title *",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              // Description (Optional)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description (Optional)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Expiry Date
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Expiry Date (Optional)",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _expiryDate == null
                                  ? "No expiry date selected"
                                  : "Expiry: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}",
                              style: TextStyle(
                                color: _expiryDate == null
                                    ? Colors.grey
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => _expiryDate = picked);
                              }
                            },
                          ),
                          if (_expiryDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() => _expiryDate = null);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // File picker
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Document File *",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fileName ?? "No file selected",
                                  style: TextStyle(
                                    color: _fileName == null
                                        ? Colors.grey
                                        : colorScheme.onSurface,
                                    fontWeight: _fileName == null
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                                  ),
                                ),
                                if (_selectedBytes != null)
                                  Text(
                                    "Size: ${(_selectedBytes!.lengthInBytes / 1024).toStringAsFixed(2)} KB",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: const Text("Choose File"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      if (_selectedBytes != null)
                        Column(
                          children: [
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: 1.0,
                                    backgroundColor: Colors.green.withOpacity(0.2),
                                    color: Colors.green,
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // File size warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Maximum file size: 800 KB\nSupported formats: PDF, JPG, PNG, DOC, DOCX, XLS, XLSX",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Upload button or progress bar
              if (_loading)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _progress,
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Uploading... ${(_progress * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isUploading ? null : _saveDocument,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text("Upload Document"),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _clearForm,
                      icon: const Icon(Icons.clear_all),
                      label: const Text("Clear Form"),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}