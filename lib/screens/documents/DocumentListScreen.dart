// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:io' show File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_saver/file_saver.dart';
import 'UploadDocumentScreen.dart';

class DocumentListScreen extends StatelessWidget {
  final String projectId;
  final String projectTitle;

  const DocumentListScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
  });

  Future<void> _openDocument(BuildContext context, Map<String, dynamic> data) async {
    try {
      final base64File = data['fileData'];
      if (base64File == null) return;

      final bytes = base64Decode(base64File);

      if (kIsWeb) {
        await FileSaver.instance.saveFile(
          name: data['fileName'] ?? "document",
          bytes: bytes,
          mimeType: MimeType.other,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("File downloaded (check browser downloads).")),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final filePath = "${dir.path}/${data['fileName'] ?? 'document'}";
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        await OpenFilex.open(file.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to open file: $e")),
      );
    }
  }

  Future<void> _downloadDocument(BuildContext context, Map<String, dynamic> data) async {
    try {
      final base64File = data['fileData'];
      if (base64File == null) return;

      final bytes = base64Decode(base64File);

      await FileSaver.instance.saveFile(
        name: data['fileName'] ?? "document",
        bytes: bytes,
        mimeType: MimeType.other,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File saved successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  Future<void> _deleteDocument(
      BuildContext context, String docId, String fileName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Document"),
        content: Text("Are you sure you want to delete '$fileName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('documents')
            .doc(docId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("'$fileName' deleted successfully.")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Delete failed: $e")),
          );
        }
      }
    }
  }

  void _showImagePreview(BuildContext context, Map<String, dynamic> data) {
    try {
      final base64File = data['fileData'];
      if (base64File == null) return;

      final fileName = data['fileName']?.toString().toLowerCase() ?? '';
      final isImage = fileName.endsWith('.jpg') || 
                      fileName.endsWith('.jpeg') || 
                      fileName.endsWith('.png');

      if (!isImage) return;

      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      title: Text(
                        data['title'] ?? 'Image Preview',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Hero(
                        tag: 'image_${data['fileName']}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(base64File),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: 400,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 300,
                                height: 300,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to preview image: $e")),
      );
    }
  }

  Widget _getFileIcon(String fileName, ColorScheme colors, bool isExpired) {
    final fileLower = fileName.toLowerCase();
    final color = isExpired ? Colors.red : colors.primary;

    if (fileLower.endsWith('.pdf')) {
      return Icon(Icons.picture_as_pdf, color: color);
    } else if (fileLower.endsWith('.jpg') || fileLower.endsWith('.jpeg') || fileLower.endsWith('.png')) {
      return Icon(Icons.image, color: color);
    } else if (fileLower.endsWith('.doc') || fileLower.endsWith('.docx')) {
      return Icon(Icons.description, color: color);
    } else if (fileLower.endsWith('.xls') || fileLower.endsWith('.xlsx')) {
      return Icon(Icons.table_chart, color: color);
    } else {
      return Icon(Icons.insert_drive_file_outlined, color: color);
    }
  }

  Widget _buildDocumentCard(BuildContext context, DocumentSnapshot doc, ColorScheme colors) {
    final data = doc.data() as Map<String, dynamic>;
    final expiry = (data['expiryDate'] as Timestamp?)?.toDate();
    final uploadDate = (data['uploadDate'] as Timestamp?)?.toDate();
    final isExpired = expiry != null && expiry.isBefore(DateTime.now());
    final fileName = data['fileName']?.toString() ?? '';
    final isImage = fileName.toLowerCase().endsWith('.jpg') || 
                    fileName.toLowerCase().endsWith('.jpeg') || 
                    fileName.toLowerCase().endsWith('.png');
    final fileSize = data['fileData'] != null 
        ? (base64Decode(data['fileData']).lengthInBytes / 1024).toStringAsFixed(1)
        : '0.0';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isImage ? () => _showImagePreview(context, data) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Icon/Preview
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isExpired 
                      ? Colors.red.withOpacity(0.1) 
                      : colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExpired ? Colors.red.withOpacity(0.3) : colors.primary.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: _getFileIcon(fileName, colors, isExpired),
                ),
              ),
              const SizedBox(width: 12),

              // Document Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isExpired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Expired',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      children: [
                        _buildDetailItem(
                          icon: Icons.calendar_today,
                          text: uploadDate != null 
                              ? "${uploadDate.day}/${uploadDate.month}/${uploadDate.year}"
                              : "-",
                          color: colors.onSurfaceVariant,
                        ),
                        _buildDetailItem(
                          icon: Icons.calendar_month,
                          text: expiry != null 
                              ? "${expiry.day}/${expiry.month}/${expiry.year}"
                              : "No expiry",
                          color: isExpired ? Colors.red : colors.onSurfaceVariant,
                        ),
                        _buildDetailItem(
                          icon: Icons.storage,
                          text: "$fileSize KB",
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
                onSelected: (value) {
                  if (value == 'download') {
                    _downloadDocument(context, data);
                  } else if (value == 'delete') {
                    _deleteDocument(context, doc.id, data['fileName'] ?? "document");
                  } else if (value == 'preview' && isImage) {
                    _showImagePreview(context, data);
                  }
                },
                itemBuilder: (context) => [
                  if (isImage)
                    const PopupMenuItem(
                      value: 'preview',
                      child: Row(
                        children: [
                          Icon(Icons.remove_red_eye, size: 18),
                          SizedBox(width: 8),
                          Text("Preview"),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 18),
                        SizedBox(width: 8),
                        Text("Download"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text("Delete", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String text, required Color color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentGridItem(BuildContext context, DocumentSnapshot doc, ColorScheme colors) {
    final data = doc.data() as Map<String, dynamic>;
    final fileName = data['fileName']?.toString() ?? '';
    final isImage = fileName.toLowerCase().endsWith('.jpg') || 
                    fileName.toLowerCase().endsWith('.jpeg') || 
                    fileName.toLowerCase().endsWith('.png');
    final isExpired = (data['expiryDate'] as Timestamp?)?.toDate().isBefore(DateTime.now()) ?? false;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isImage ? () => _showImagePreview(context, data) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Large File Icon/Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _getFileIcon(fileName, colors, isExpired),
                ),
              ),
              const SizedBox(height: 8),
              // File Name
              Text(
                data['title'] ?? 'Untitled',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // File Type
              Text(
                fileName.split('.').last.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Documents - $projectTitle"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .collection('documents')
            .orderBy('uploadDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 80,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No documents uploaded yet",
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Upload your first document by tapping the + button",
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Choose between List View or Grid View:
          // Option 1: List View (default)
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16, top: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildDocumentCard(context, docs[index], colorScheme);
            },
          );

          // Option 2: Grid View (uncomment to use)
          /*
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildDocumentGridItem(context, docs[index], colorScheme);
            },
          );
          */
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UploadDocumentScreen(
                projectId: projectId,
                projectTitle: projectTitle,
              ),
            ),
          );
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text("Upload Document"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}