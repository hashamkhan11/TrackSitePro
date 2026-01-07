// ignore_for_file: deprecated_member_use, unused_local_variable

import 'dart:convert';
import 'dart:io' show File, Directory, Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:open_filex/open_filex.dart';
import 'package:file_saver/file_saver.dart';
import 'UploadFirmDocumentScreen.dart';

// For Flutter Web
import 'dart:html' as html;

class FirmDocumentListScreen extends StatefulWidget {
  const FirmDocumentListScreen({super.key});

  @override
  State<FirmDocumentListScreen> createState() => _FirmDocumentListScreenState();
}

class _FirmDocumentListScreenState extends State<FirmDocumentListScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cleanupOldNotifications();
    });
  }

  Future<String?> _getFirmId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data()?['assignedFirmId'];
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return "-";
    final date = ts.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  /// 🔹 Request storage permission for Android
  Future<bool> _checkPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (status.isDenied || status.isRestricted) {
        status = await Permission.storage.request();
      }
      return status.isGranted;
    }
    return true; // iOS & Web don't need manual storage permission
  }

  /// 🔹 Preview/Open document
  Future<void> _openDocument(BuildContext context, Map<String, dynamic> data) async {
    try {
      final base64File = data['fileData'];
      if (base64File == null) return;

      final bytes = base64Decode(base64File);
      final fileName = data['fileName'] ?? 'document';

      if (kIsWeb) {
        // Web: Trigger browser download for now (could be enhanced with PDF viewer)
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File downloaded (check browser downloads).")),
          );
        }
      } else {
        // Mobile: Save to temp and open
        final dir = await getTemporaryDirectory();
        final filePath = "${dir.path}/$fileName";
        final file = File(filePath);
        await file.writeAsBytes(bytes);

        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to open file: $e")),
        );
      }
    }
  }

  /// 🔹 Download and save file (Mobile + Web)
  Future<void> _downloadFile(
      String base64Data, String fileName, BuildContext context) async {
    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.2;
      });

      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _downloadProgress = 0.6);

      final bytes = base64Decode(base64Data);

      if (kIsWeb) {
        // ✅ Flutter Web → use file_saver for better experience
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          mimeType: MimeType.other,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File downloaded successfully.")),
          );
        }
      } else {
        // ✅ Android / iOS
        if (!await _checkPermission()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Storage permission denied")),
            );
          }
          setState(() {
            _isDownloading = false;
            _downloadProgress = 0.0;
          });
          return;
        }

        Directory? dir;
        if (Platform.isAndroid) {
          dir = Directory("/storage/emulated/0/Download");
          if (!await dir.exists()) {
            dir = await getExternalStorageDirectory();
          }
        } else if (Platform.isIOS) {
          dir = await getApplicationDocumentsDirectory();
        } else {
          dir = await getApplicationDocumentsDirectory();
        }

        final file = File("${dir!.path}/$fileName");
        await file.writeAsBytes(bytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("File saved to: ${file.path}")),
          );
        }
      }

      setState(() => _downloadProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Download failed: $e")),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  /// 🔹 Delete document with confirmation
  Future<void> _deleteDocument(
      BuildContext context, String docId, String fileName, String firmId) async {
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
            .collection('firms')
            .doc(firmId)
            .collection('documents')
            .doc(docId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("'$fileName' deleted successfully.")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Delete failed: $e")),
          );
        }
      }
    }
  }

  /// 🔹 Show image preview dialog
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

  /// 🔹 Get appropriate file icon
  Widget _getFileIcon(String fileName, ColorScheme colors, bool isExpired) {
    final fileLower = fileName.toLowerCase();
    final color = isExpired ? Colors.red : colors.primary;

    if (fileLower.endsWith('.pdf')) {
      return Icon(Icons.picture_as_pdf, color: color, size: 24);
    } else if (fileLower.endsWith('.jpg') || fileLower.endsWith('.jpeg') || fileLower.endsWith('.png')) {
      return Icon(Icons.image, color: color, size: 24);
    } else if (fileLower.endsWith('.doc') || fileLower.endsWith('.docx')) {
      return Icon(Icons.description, color: color, size: 24);
    } else if (fileLower.endsWith('.xls') || fileLower.endsWith('.xlsx')) {
      return Icon(Icons.table_chart, color: color, size: 24);
    } else {
      return Icon(Icons.insert_drive_file_outlined, color: color, size: 24);
    }
  }

  /// 🔹 Get expiry status text with clear day count
  String _getExpiryStatusText(DateTime? expiryDate) {
    if (expiryDate == null) return "No expiry";
    
    final now = DateTime.now();
    if (expiryDate.isBefore(now)) {
      return "Expired";
    }
    
    final difference = expiryDate.difference(now);
    final days = difference.inDays;
    
    if (days == 0) {
      final hours = difference.inHours;
      if (hours == 0) {
        return "Expires in ${difference.inMinutes} min";
      }
      return "Expires in $hours hours";
    } else if (days == 1) {
      return "Expires in 1 day";
    } else {
      return "Expires in $days days";
    }
  }

  /// 🔹 Get expiry status color
  Color _getExpiryStatusColor(DateTime? expiryDate, ColorScheme colors) {
    if (expiryDate == null) return colors.onSurfaceVariant;
    
    final now = DateTime.now();
    if (expiryDate.isBefore(now)) {
      return Colors.red;
    }
    
    final days = expiryDate.difference(now).inDays;
    if (days <= 7) {
      return Colors.red;
    } else if (days <= 30) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  /// 🔹 Check expiry and create a notification if within 7 days (ONLY ONCE)
  Future<void> _checkAndNotify(Map<String, dynamic> data, String docId) async {
    final expiry = (data['expiryDate'] as Timestamp?)?.toDate();
    if (expiry == null) return;

    final now = DateTime.now();
    final daysLeft = expiry.difference(now).inDays;

    // Only notify for documents expiring within 7 days (0 to 7 days)
    if (daysLeft <= 7 && daysLeft >= 0) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      
      // Check if we've already notified about this specific document expiry
      final existingNotif = await FirebaseFirestore.instance
          .collection("notifications")
          .doc(uid)
          .collection("user_notifications")
          .where("documentId", isEqualTo: docId)
          .where("notificationType", isEqualTo: "expiry_alert")
          .get();

      // Only create notification if it doesn't exist
      if (existingNotif.docs.isEmpty) {
        await FirebaseFirestore.instance
            .collection("notifications")
            .doc(uid)
            .collection("user_notifications")
            .add({
          "documentId": docId, // Store which document this notification is for
          "notificationType": "expiry_alert", // Mark as expiry notification
          "title": "Firm Document Expiry Alert",
          "body": "${data['title']} will expire in $daysLeft days (${_formatDate(data['expiryDate'])})",
          "timestamp": Timestamp.now(),
          "read": false,
          "expiryDate": data['expiryDate'], // Store expiry date to avoid duplicates
        });
      }
    }
  }

  /// 🔹 Clean up old notifications for deleted or long-expired documents
  Future<void> _cleanupOldNotifications() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firmId = await _getFirmId();
    
    if (firmId == null) return;
    
    // Get all expiry notifications
    final notifications = await FirebaseFirestore.instance
        .collection("notifications")
        .doc(uid)
        .collection("user_notifications")
        .where("notificationType", isEqualTo: "expiry_alert")
        .get();

    // Check if the document still exists or has been deleted/expired
    for (var notif in notifications.docs) {
      final notifData = notif.data();
      final documentId = notifData['documentId'];
      
      try {
        // Check if document still exists
        final docSnapshot = await FirebaseFirestore.instance
            .collection('firms')
            .doc(firmId)
            .collection('documents')
            .doc(documentId)
            .get();

        if (!docSnapshot.exists) {
          // Document no longer exists, delete the notification
          await notif.reference.delete();
        } else {
          // Check if document has already expired (more than 7 days ago)
          final docData = docSnapshot.data();
          final expiry = (docData?['expiryDate'] as Timestamp?)?.toDate();
          
          if (expiry != null) {
            final now = DateTime.now();
            final daysSinceExpiry = now.difference(expiry).inDays;
            
            // If document expired more than 7 days ago, remove the notification
            if (daysSinceExpiry > 7) {
              await notif.reference.delete();
            }
          }
        }
      } catch (e) {
        print("Error cleaning up notification: $e");
      }
    }
  }

  /// 🔹 Build compact document card
  Widget _buildDocumentCard(BuildContext context, DocumentSnapshot doc, String firmId, ColorScheme colors) {
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

    // Check for expiry notifications (ONLY ONCE per document)
    _checkAndNotify(data, doc.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isExpired ? Colors.red.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: isImage ? () => _showImagePreview(context, data) : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // Document Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isExpired 
                      ? Colors.red.withOpacity(0.05) 
                      : colors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExpired ? Colors.red.withOpacity(0.2) : colors.primary.withOpacity(0.2),
                    width: 1.5,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Compact expiry and file info
                    Row(
                      children: [
                        // Expiry status
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getExpiryStatusColor(expiry, colors).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getExpiryStatusColor(expiry, colors).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isExpired ? Icons.error_outline : Icons.calendar_today,
                                size: 12,
                                color: _getExpiryStatusColor(expiry, colors),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getExpiryStatusText(expiry),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: _getExpiryStatusColor(expiry, colors),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Upload date
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.upload,
                              size: 10,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              uploadDate != null 
                                  ? _formatDate(data['uploadDate'])
                                  : "-",
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        
                        // File size
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.storage,
                              size: 10,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "$fileSize KB",
                              style: TextStyle(
                                fontSize: 10,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions Menu
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert, 
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                onSelected: (value) async {
                  if (value == 'open') {
                    await _openDocument(context, data);
                  } else if (value == 'download') {
                    await _downloadFile(
                      data['fileData'],
                      data['fileName'] ?? "document.bin",
                      context,
                    );
                  } else if (value == 'delete') {
                    await _deleteDocument(context, doc.id, data['fileName'] ?? "document", firmId);
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
                          Icon(Icons.remove_red_eye, size: 16),
                          SizedBox(width: 8),
                          Text("Preview", style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(Icons.download, size: 16),
                        SizedBox(width: 8),
                        Text("Download", style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text("Delete", style: TextStyle(color: Colors.red, fontSize: 13)),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<String?>(
      future: _getFirmId(),
      builder: (context, firmSnap) {
        if (!firmSnap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final firmId = firmSnap.data!;
        if (firmId.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 60,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No firm assigned",
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please contact your administrator",
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          body: Column(
            children: [
              if (_isDownloading)
                LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: colorScheme.surfaceVariant,
                  color: colorScheme.primary,
                  minHeight: 2,
                ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('firms')
                      .doc(firmId)
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
                              size: 60,
                              color: colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No firm documents uploaded yet",
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

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        return _buildDocumentCard(context, docs[index], firmId, colorScheme);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UploadFirmDocumentScreen(firmId: firmId),
                ),
              );
            },
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text("Upload"),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }
}