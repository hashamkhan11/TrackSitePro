import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Data access for a project's payment certificates
/// (projects/{projectId}/payments) and their receipt files in Storage
/// (payments/{projectId}/{fileName}).
///
/// This wraps the Firestore/Storage calls that previously lived directly
/// inside PaymentHistoryScreen so the screen only deals with UI state, and
/// so the read/write shape of "a payment" lives in one place.
class PaymentRepository {
  PaymentRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _payments(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('payments');
  }

  /// Live-updating list of payments for a project, newest first.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamPayments(
      String projectId) {
    return _payments(projectId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// One-off read of every payment for a project (used to figure out which
  /// certificate types - 50%/80%/100% - are still available to add).
  Future<QuerySnapshot<Map<String, dynamic>>> fetchPayments(
      String projectId) {
    return _payments(projectId).get();
  }

  Future<void> addPayment(String projectId, Map<String, dynamic> data) {
    data['createdAt'] = FieldValue.serverTimestamp();
    return _payments(projectId).add(data);
  }

  Future<void> updatePayment(
      String projectId, String paymentId, Map<String, dynamic> data) {
    return _payments(projectId).doc(paymentId).update(data);
  }

  Future<void> deletePayment(String projectId, String paymentId) {
    return _payments(projectId).doc(paymentId).delete();
  }

  /// Best-effort delete of a receipt file given its download URL. Callers
  /// should swallow failures here the same way the screen already did -
  /// a missing/already-deleted Storage object shouldn't block deleting the
  /// Firestore record.
  Future<void> deleteReceiptFile(String documentUrl) {
    return _storage.refFromURL(documentUrl).delete();
  }

  /// Uploads a receipt file for [projectId] and returns its download URL.
  Future<String> uploadReceipt(String projectId, File file) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref =
        _storage.ref().child('payments').child(projectId).child(fileName);
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
