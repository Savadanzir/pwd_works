import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/work_model.dart';

class AssignedWorksProvider extends ChangeNotifier {
  List<WorkModel> _works = [];
  bool _loading = false;
  String? _error;

  List<WorkModel> get works => _works;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadForEmployee(String empId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final snap = await FirebaseFirestore.instance
          .collection('reports')
          .where('assignedTo', isEqualTo: empId)
          .get();

      _works = snap.docs
            .map((d) => WorkModel.fromMap(d.id, d.data()))
          .toList();

      _works.sort((a, b) {
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

  /// Works that are still active (not completed)
  List<WorkModel> get activeWorks => _works
      .where((w) =>
          w.status == 'Assigned' ||
          w.status == 'In Progress')
      .toList();
}