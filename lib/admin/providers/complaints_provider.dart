import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintsProvider extends ChangeNotifier {
  List<QueryDocumentSnapshot> _complaints = [];
  bool _loading = false;
  String? _error;

  List<QueryDocumentSnapshot> get complaints => _complaints;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    try {
      _loading = true;
      notifyListeners();
      final snap = await FirebaseFirestore.instance
          .collection('complaints')
          .orderBy('createdAt', descending: true)
          .get();
      _complaints = snap.docs;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> reply(String id, String reply) async {
    await FirebaseFirestore.instance.collection('complaints').doc(id).update({
      'adminReply': reply, 'status': 'Resolved', 'repliedAt': Timestamp.now(),
    });
    await loadAll();
  }

  Future<void> resolve(String id) async {
    await FirebaseFirestore.instance
        .collection('complaints').doc(id).update({'status': 'Resolved'});
    await loadAll();
  }

  Future<void> delete(String id) async {
    await FirebaseFirestore.instance.collection('complaints').doc(id).delete();
    await loadAll();
  }
}