import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewsProvider extends ChangeNotifier {
  List<QueryDocumentSnapshot> _news = [];
  bool _loading = false;
  String? _error;

  List<QueryDocumentSnapshot> get news => _news;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    try {
      _loading = true;
      notifyListeners();
      final snap = await FirebaseFirestore.instance
          .collection('news')
          .orderBy('createdAt', descending: true)
          .get();
      _news = snap.docs;
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
    required String tag,
    required String emoji,
  }) async {
    await FirebaseFirestore.instance.collection('news').add({
      'title': title, 'body': body,
      'tag': tag.toUpperCase(), 'emoji': emoji,
      'createdAt': Timestamp.now(),
    });
    await loadAll();
  }

  Future<void> delete(String id) async {
    await FirebaseFirestore.instance.collection('news').doc(id).delete();
    await loadAll();
  }
}