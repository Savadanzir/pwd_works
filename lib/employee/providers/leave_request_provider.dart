import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/leave_request_model.dart';

class LeaveRequestProvider extends ChangeNotifier {
  List<LeaveRequestModel> _requests = [];
  bool _loading = false;
  String? _error;

  List<LeaveRequestModel> get requests => _requests;
  bool get loading => _loading;
  String? get error => _error;

  Future<String?> submitRequest({
    required String employeeId,
    required String employeeName,
    required String department,
    required String type,
    required DateTime from,
    required DateTime to,
    required String reason,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final model = LeaveRequestModel(
        employeeId: employeeId,
        employeeName: employeeName,
        department: department,
        type: type,
        fromDate: DateFormat('yyyy-MM-dd').format(from),
        toDate: DateFormat('yyyy-MM-dd').format(to),
        reason: reason,
      );

      await FirebaseFirestore.instance
          .collection('leave_requests')
          .add(model.toMap());
      await loadForEmployee(employeeId);
      return null;
    } catch (e) {
      return _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadForEmployee(String empId) async {
    try {
      _loading = true;
      notifyListeners();
      final snap = await FirebaseFirestore.instance
          .collection('leave_requests')
          .where('employeeId', isEqualTo: empId)
          .get();
      _requests = snap.docs
          .map((d) =>
              LeaveRequestModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
      _requests.sort((a, b) {
        final ta = a.createdAt?.toDate() ?? DateTime(2000);
        final tb = b.createdAt?.toDate() ?? DateTime(2000);
        return tb.compareTo(ta);
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}