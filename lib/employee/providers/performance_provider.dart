import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PerformanceProvider extends ChangeNotifier {
  int _total = 0;
  int _completed = 0;
  int _inProgress = 0;
  bool _loading = false;
  String? _error;

  int get total => _total;
  int get completed => _completed;
  int get inProgress => _inProgress;
  bool get loading => _loading;
  String? get error => _error;

  double get completionRate =>
      _total == 0 ? 0 : (_completed / _total) * 100;

  Future<void> loadStats(String empId) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final snap = await FirebaseFirestore.instance
          .collection('reports')
          .where('assignedTo', isEqualTo: empId)
          .get();

      _total = snap.docs.length;
      _completed = snap.docs
          .where((d) => (d.data() as Map)['status'] == 'Completed')
          .length;
      _inProgress = _total - _completed;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}