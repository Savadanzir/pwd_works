import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class RoadWorkProvider extends ChangeNotifier {
  List<ReportModel> _activeWorks = [];
  bool _loading = false;
  String? _error;

  List<ReportModel> get activeWorks => _activeWorks;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadActiveWorks() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final snap = await FirebaseFirestore.instance
          .collection('reports')
          .where('status', whereIn: ['Approved', 'Assigned', 'In Progress'])
          .get();

      final all = snap.docs
          .map((d) =>
            ReportModel.fromMap(d.id, d.data()))
          .where((r) => r.category.toLowerCase().contains('road'))
          .toList();

      all.sort((a, b) {
        final ta = a.createdAt?.toDate() ?? DateTime(2000);
        final tb = b.createdAt?.toDate() ?? DateTime(2000);
        return tb.compareTo(ta);
      });

      _activeWorks = all;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}