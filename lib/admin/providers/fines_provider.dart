import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FinesProvider extends ChangeNotifier {
  List<QueryDocumentSnapshot> _fines = [];
  bool _loading = false;
  String? _error;

  List<QueryDocumentSnapshot> get fines => _fines;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    try {
      _loading = true;
      notifyListeners();
      final snap = await FirebaseFirestore.instance
          .collection('fines')
          .orderBy('createdAt', descending: true)
          .get();
      _fines = snap.docs;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create({
    required String userEmail,
    required String reason,
    required double amount,
    required String status,
  }) async {
    await FirebaseFirestore.instance.collection('fines').add({
      'userEmail': userEmail, 'reason': reason, 'amount': amount,
      'status': status, 'createdAt': Timestamp.now(),
    });
    await loadAll();
  }

  Future<void> delete(String id) async {
    await FirebaseFirestore.instance.collection('fines').doc(id).delete();
    await loadAll();
  }
}