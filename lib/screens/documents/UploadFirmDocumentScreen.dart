import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class UploadFirmDocumentScreen extends StatefulWidget {
  final String firmId;
  const UploadFirmDocumentScreen({super.key, required this.firmId});

  @override
  State<UploadFirmDocumentScreen> createState() =>
      _UploadFirmDocumentScreenState();
}

class _UploadFirmDocumentScreenState extends State<UploadFirmDocumentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _expiryDate;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  Uint8List? _fileBytes;
  String? _fileName;

  final List<String> _documentTypes = [
    "PEC License",
    "Company Registration",
    "Tax Certificate",
    "Insurance Policy",
    "Bank Guarantee",
    "Performance Bond",
    "Safety Certificate",
    "Quality Certificate",
    "Other"
  ];
  String _selectedType = "PEC License";
  bool _showTitleField = false;

  @override
  void initState() {
    super.initState();
    // Initially hide title field since default is not "Other"
    _showTitleField = false;
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xls', 'xlsx'],
      );
      
      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes!;
        final sizeMB = bytes.lengthInBytes / (1024 * 1024);

        if (sizeMB > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("File too large! Maximum 5 MB allowed."),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _fileBytes = bytes;
          _fileName = result.files.first.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to pick file: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadDocument() async {
    // Validate title only if "Other" is selected
    if (_selectedType == "Other" && _titleController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enter document title for 'Other' type"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_fileBytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a file to upload"),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.3;
    });

    try {
      // Simulate upload progress
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _uploadProgress = 0.6);

      final base64File = base64Encode(_fileBytes!);
      final fileSizeKB = _fileBytes!.lengthInBytes / 1024;

      // Determine final title
      final finalTitle = _selectedType == "Other" 
          ? _titleController.text.trim()
          : _selectedType;

      await FirebaseFirestore.instance
          .collection('firms')
          .doc(widget.firmId)
          .collection('documents')
          .add({
        'title': finalTitle,
        'documentType': _selectedType,
        'description': _descriptionController.text.trim(),
        'fileName': _fileName,
        'fileData': base64File,
        'fileSize': fileSizeKB,
        'uploadDate': Timestamp.now(),
        'expiryDate': _expiryDate != null ? Timestamp.fromDate(_expiryDate!) : null,
        'createdAt': Timestamp.now(),
      });

      setState(() => _uploadProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Firm document uploaded successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
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
          _isUploading = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _expiryDate = null;
      _fileName = null;
      _fileBytes = null;
      _selectedType = "PEC License";
      _showTitleField = false;
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
        title: const Text("Upload Firm Document"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Type (Always shown)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Document Type *",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: _documentTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value ?? "PEC License";
                          // Show title field only if "Other" is selected
                          _showTitleField = (_selectedType == "Other");
                          // Clear title when switching away from "Other"
                          if (!_showTitleField) {
                            _titleController.clear();
                          }
                        });
                      },
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.category),
                        hintText: "Select document type",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Document Title (Only shown when "Other" is selected)
            if (_showTitleField)
              Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: "Document Title *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                          hintText: "Enter custom document title",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Description (Optional)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: "Description (Optional)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    hintText: "Additional notes or details",
                  ),
                  maxLines: 3,
                ),
              ),
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
                              firstDate: DateTime(2000),
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

            // File Picker
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
                              if (_fileBytes != null)
                                Text(
                                  "Size: ${(_fileBytes!.lengthInBytes / (1024 * 1024)).toStringAsFixed(2)} MB",
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
                    if (_fileBytes != null)
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
            const SizedBox(height: 16),

            // File Requirements
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
                      "Maximum file size: 5 MB\nSupported formats: PDF, JPG, PNG, DOC, DOCX, XLS, XLSX",
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

            // Upload Status or Button
            if (_isUploading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: colorScheme.primary,
                    minHeight: 8,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _uploadProgress,
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%",
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
                    onPressed: _uploadDocument,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text("Upload Firm Document"),
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
    );
  }
}