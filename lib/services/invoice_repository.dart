import 'package:cloud_firestore/cloud_firestore.dart';

/// Data access for a project's invoices (projects/{projectId}/invoices),
/// plus the one project-level read the invoice screens need (job/work-order
/// numbers to pre-fill a new invoice).
class InvoiceRepository {
  InvoiceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _invoices(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('invoices');
  }

  /// Live-updating list of invoices for a project, most recent date first.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamInvoices(
      String projectId) {
    return _invoices(projectId).orderBy('date', descending: true).snapshots();
  }

  Future<void> addInvoice(String projectId, Map<String, dynamic> data) {
    data['createdAt'] = FieldValue.serverTimestamp();
    return _invoices(projectId).add(data);
  }

  Future<void> deleteInvoice(String projectId, String invoiceId) {
    return _invoices(projectId).doc(invoiceId).delete();
  }

  /// The project document, used to pre-fill jobNo/workOrderNo when starting
  /// a new invoice.
  Future<DocumentSnapshot<Map<String, dynamic>>> fetchProject(
      String projectId) {
    return _firestore.collection('projects').doc(projectId).get();
  }
}
