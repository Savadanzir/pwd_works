import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkUpdateProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  Future<String?> updateWork({
    required String reportId,
    required String status,
    required String workNote,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'status': status,
        'workNote': workNote,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> markInProgress(String reportId, {String? workNote}) async {
    try {
      _loading = true;
      notifyListeners();
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'status': 'In Progress',
        'workNote': workNote,
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}