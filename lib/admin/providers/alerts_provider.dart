import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlertsProvider extends ChangeNotifier {
  List<QueryDocumentSnapshot> _alerts = [];
  bool _loading = false;
  String? _error;

  List<QueryDocumentSnapshot> get alerts => _alerts;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    try {
      _loading = true;
      notifyListeners();
      final snap = await FirebaseFirestore.instance
          .collection('alerts')
          .orderBy('createdAt', descending: true)
          .get();
      _alerts = snap.docs;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create({
    required String title,
    required String body,
    required String severity,
  }) async {
    await FirebaseFirestore.instance.collection('alerts').add({
      'title': title, 'body': body, 'severity': severity,
      'createdAt': Timestamp.now(),
    });
    await loadAll();
  }

  Future<void> delete(String id) async {
    await FirebaseFirestore.instance.collection('alerts').doc(id).delete();
    await loadAll();
  }
}