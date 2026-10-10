import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthoritiesProvider extends ChangeNotifier {
  List<QueryDocumentSnapshot> _authorities = [];
  bool _loading = false;
  String? _error;

  List<QueryDocumentSnapshot> get authorities => _authorities;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    try {
      _loading = true;
      notifyListeners();
      final snap = await FirebaseFirestore.instance.collection('authorities').get();
      _authorities = snap.docs;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('authorities').add(data);
    await loadAll();
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('authorities').doc(id).update(data);
    await loadAll();
  }

  Future<void> delete(String id) async {
    await FirebaseFirestore.instance.collection('authorities').doc(id).delete();
    await loadAll();
  }
}