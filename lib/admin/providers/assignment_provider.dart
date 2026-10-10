import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class AssignmentProvider extends ChangeNotifier {
  List<ReportModel> _approvedReports = [];
  bool _loading = false;
  String? _error;

  List<ReportModel> get approvedReports => _approvedReports;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadApproved() async {
    try {
      _loading = true;
      notifyListeners();
      final snap = await FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'Approved')
          .get();
      _approvedReports = snap.docs
          .map((d) => ReportModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<QueryDocumentSnapshot>> employeesByDepartment(String dept) async {
    final snap = await FirebaseFirestore.instance
        .collection('employees')
        .where('department', isEqualTo: dept)
        .get();
    return snap.docs;
  }

  Future<List<QueryDocumentSnapshot>> allEmployees() async {
    final snap = await FirebaseFirestore.instance.collection('employees').get();
    return snap.docs;
  }

  Future<void> assign({
    required String reportId,
    required String employeeUid,
    required String employeeName,
    required String employeeDepartment,
    required String adminName,
  }) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
      'status': 'Assigned',
      'assignedTo': employeeUid,
      'employeeName': employeeName,
      'employeeDepartment': employeeDepartment,
      'assignedAt': FieldValue.serverTimestamp(),
      'assignedBy': adminName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await loadApproved();
  }
}