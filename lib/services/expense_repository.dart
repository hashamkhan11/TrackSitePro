import 'package:cloud_firestore/cloud_firestore.dart';

/// Data access for a project's expenses (projects/{projectId}/expenses),
/// including keeping the project's cached `totalExpenses` field in sync.
class ExpenseRepository {
  ExpenseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _project(String projectId) {
    return _firestore.collection('projects').doc(projectId);
  }

  CollectionReference<Map<String, dynamic>> _expenses(String projectId) {
    return _project(projectId).collection('expenses');
  }

  /// Live-updating list of expenses for a project, newest date first.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamExpenses(
      String projectId) {
    return _expenses(projectId)
        .orderBy('date', descending: true)
        .snapshots();
  }

  Future<void> addExpense(String projectId, Map<String, dynamic> data) {
    return _expenses(projectId).add(data);
  }

  Future<void> updateExpense(
      String projectId, String expenseId, Map<String, dynamic> data) {
    return _expenses(projectId).doc(expenseId).update(data);
  }

  Future<void> deleteExpense(String projectId, String expenseId) {
    return _expenses(projectId).doc(expenseId).delete();
  }

  /// Recomputes the project's cached `totalExpenses` field by summing every
  /// expense document. Mirrors the previous inline logic in
  /// AddExpenseScreen - best-effort, callers are expected to swallow
  /// failures the same way the screen already did.
  Future<void> recomputeTotalExpenses(String projectId) async {
    final snap = await _expenses(projectId).get();
    double total = 0;
    for (final doc in snap.docs) {
      total += ((doc.data())['amount'] ?? 0).toDouble();
    }
    await _project(projectId).update({
      'totalExpenses': total,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
