import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RepairEvidenceProvider extends ChangeNotifier {
  bool _uploading = false;
  String? _error;

  bool get uploading => _uploading;
  String? get error => _error;

  Future<String?> uploadEvidence({
    required String reportId,
    File? image,
    Uint8List? webImageBytes,
    String? workNote,
  }) async {
    try {
      _uploading = true;
      _error = null;
      notifyListeners();

      String? url;
      final path =
          'evidence/${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (webImageBytes != null) {
        final ref = FirebaseStorage.instance.ref().child(path);
        await ref.putData(webImageBytes);
        url = await ref.getDownloadURL();
      } else if (image != null) {
        final ref = FirebaseStorage.instance.ref().child(path);
        await ref.putFile(image);
        url = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({
        'completionImage': url,
        'status': 'In Progress',
        if (workNote != null && workNote.isNotEmpty) 'workNote': workNote,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return _error = e.toString();
    } finally {
      _uploading = false;
      notifyListeners();
    }
  }
}