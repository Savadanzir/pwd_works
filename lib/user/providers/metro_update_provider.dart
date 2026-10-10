import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class MetroUpdate {
  final String id;
  final String userId;
  final String userName;
  final String caption;
  final String imageUrl;
  final Timestamp? createdAt;

  MetroUpdate({
    required this.id,
    required this.userId,
    required this.userName,
    required this.caption,
    required this.imageUrl,
    this.createdAt,
  });

  factory MetroUpdate.fromMap(String id, Map<String, dynamic> m) =>
      MetroUpdate(
        id: id,
        userId: m['userId'] ?? '',
        userName: m['userName'] ?? 'User',
        caption: m['caption'] ?? '',
        imageUrl: m['imageUrl'] ?? '',
        createdAt: m['createdAt'] is Timestamp ? m['createdAt'] : null,
      );
}

class MetroUpdateProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _uploading = false;
  String? _error;

  bool get uploading => _uploading;
  String? get error => _error;

  Stream<List<MetroUpdate>> get updatesStream {
    return _db
        .collection('metro_updates')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                MetroUpdate.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList());
  }

  Future<String?> postUpdate({
    required String userId,
    required String userName,
    required String caption,
    File? image,
    Uint8List? webImageBytes,
  }) async {
    try {
      _uploading = true;
      _error = null;
      notifyListeners();

      String imgUrl = '';
      final path =
          'metro_updates/${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (webImageBytes != null) {
        final ref = _storage.ref().child(path);
        await ref.putData(webImageBytes);
        imgUrl = await ref.getDownloadURL();
      } else if (image != null) {
        final ref = _storage.ref().child(path);
        await ref.putFile(image);
        imgUrl = await ref.getDownloadURL();
      }

      await _db.collection('metro_updates').add({
        'userId': userId,
        'userName': userName,
        'caption': caption,
        'imageUrl': imgUrl,
        'status': 'Posted',
        'createdAt': Timestamp.now(),
      });
      return null;
    } catch (e) {
      _error = e.toString();
      return _error;
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }
}