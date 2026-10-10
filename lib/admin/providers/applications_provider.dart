import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ApplicationsProvider extends ChangeNotifier {
  List<ReportModel> _allReports = [];
  bool _loading = false;
  String? _error;
  String _filter = 'Pending';

  List<ReportModel> get allReports => _allReports;
  bool get loading => _loading;
  String? get error => _error;
  String get filter => _filter;

  List<ReportModel> get visibleReports {
    if (_filter == 'All') return _allReports;
    return _allReports.where((r) {
      if (_filter == 'Pending') return r.status == 'Pending';
      if (_filter == 'Approved') {
        return ['Approved', 'Assigned', 'In Progress', 'Completed'].contains(r.status);
      }
      if (_filter == 'Rejected') return r.status == 'Rejected';
      return true;
    }).toList();
  }

  void setFilter(String f) {
    _filter = f;
    notifyListeners();
  }

  Future<void> loadAll() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();
      final snap = await FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .get();
      _allReports = snap.docs
          .map((d) => ReportModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> approve(String id, String? adminName) async {
    await FirebaseFirestore.instance.collection('reports').doc(id).update({
      'status': 'Approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': adminName ?? 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await loadAll();
  }

  Future<void> reject(String id, String reason, String? adminName) async {
    await FirebaseFirestore.instance.collection('reports').doc(id).update({
      'status': 'Rejected',
      'adminReply': reason,
      'rejectedReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': adminName ?? 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
      'replySeen': false,
    });
    await loadAll();
  }
}