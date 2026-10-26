import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_report_model.dart';

class DailyReportProvider extends ChangeNotifier {
  List<DailyReportModel> _reports = [];
  bool _loading = false;
  String? _error;

  List<DailyReportModel> get reports => _reports;
  bool get loading => _loading;
  String? get error => _error;

  Future<String?> submitReport({
    required String employeeId,
    required String employeeName,
    required String department,
    required double hoursWorked,
    required int tasksCompleted,
    required String blockers,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final model = DailyReportModel(
        employeeId: employeeId,
        employeeName: employeeName,
        department: department,
        hoursWorked: hoursWorked,
        tasksCompleted: tasksCompleted,
        blockers: blockers,
        date: DateTime.now().toIso8601String().substring(0, 10),
      );

      await FirebaseFirestore.instance
          .collection('daily_reports')
          .add(model.toMap());
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
          .collection('daily_reports')
          .where('employeeId', isEqualTo: empId)
          .orderBy('createdAt', descending: true)
          .get();
      _reports = snap.docs
          .map((d) =>
              DailyReportModel.fromMap(d.id, d.data()))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}