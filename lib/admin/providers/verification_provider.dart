import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class VerificationProvider extends ChangeNotifier {
  List<ReportModel> _toVerify = [];
  bool _loading = false;
  String? _error;

  List<ReportModel> get toVerify => _toVerify;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadToVerify() async {
    try {
      _loading = true;
      notifyListeners();
      final results = <ReportModel>[];
      for (final status in ['Assigned', 'In Progress']) {
        final snap = await FirebaseFirestore.instance
            .collection('reports')
            .where('status', isEqualTo: status)
            .get();
        results.addAll(snap.docs.map(
            (d) => ReportModel.fromMap(d.id, d.data() as Map<String, dynamic>)));
      }
      _toVerify = results;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> markCompleted(String id) async {
    await FirebaseFirestore.instance.collection('reports').doc(id).update({
      'status': 'Completed',
      'verifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await loadToVerify();
  }
}