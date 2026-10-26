import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/work_model.dart';

class WorkHistoryProvider extends ChangeNotifier {
  List<WorkModel> _history = [];
  bool _loading = false;
  String? _error;

  List<WorkModel> get history => _history;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadHistory(String empId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final snap = await FirebaseFirestore.instance
          .collection('reports')
          .where('assignedTo', isEqualTo: empId)
          .get();

      _history = snap.docs
            .map((d) => WorkModel.fromMap(d.id, d.data()))
          .where((w) => w.status == 'Completed')
          .toList();

      _history.sort((a, b) {
        final ta = a.updatedAt?.toDate() ?? DateTime(2000);
        final tb = b.updatedAt?.toDate() ?? DateTime(2000);
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