import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class TrafficProvider extends ChangeNotifier {
  List<ReportModel> _trafficBlocks = [];
  bool _loading = false;
  String? _error;

  List<ReportModel> get trafficBlocks => _trafficBlocks;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadTrafficBlocks() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final snap = await FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .get();

      _trafficBlocks = snap.docs
            .map((d) => ReportModel.fromMap(d.id, d.data()))
          .where((r) => r.category.toLowerCase().contains('traffic'))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}