import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../models/report_model.dart';

class ReportProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();

  bool _loading = false;
  String? _error;
  List<ReportModel> _myReports = [];

  bool get loading => _loading;
  String? get error => _error;
  List<ReportModel> get myReports => _myReports;

  // ---------- Duplicate check ----------
  Future<bool> reportAlreadyExists(String title) async {
    try {
      return await _db.reportAlreadyExists(title);
    } catch (_) {
      return false;
    }
  }

  // ---------- Submit report ----------
  Future<String?> submitReport({
    required String userId,
    required String userName,
    required String userPhone,
    required String title,
    required String description,
    required String category,
    required String location,
    double? latitude,
    double? longitude,
    File? image,
    XFileBytes? webImage,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      String? imgUrl;
      final path = 'reports/${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (webImage != null) {
        imgUrl = await _db.uploadBytes(webImage.bytes, path);
      } else if (image != null) {
        imgUrl = await _db.uploadImage(image, path);
      }

      await _db.addReport({
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'imageUrl': imgUrl,
        'status': 'Pending',
        'assignedTo': null,
        'employeeName': null,
        'adminReply': null,
        'workNote': null,
        'completionImage': null,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return null;
    } catch (e) {
      _error = e.toString();
      return _error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ---------- Load user reports ----------
  Future<void> loadMyReports(String uid) async {
    try {
      _loading = true;
      notifyListeners();

      final docs = await _db.getUserReports(uid);
      _myReports = docs
          .map((d) =>
              ReportModel.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();

      // Sort newest first
      _myReports.sort((a, b) {
        final ta = a.createdAt?.toDate() ?? DateTime(2000);
        final tb = b.createdAt?.toDate() ?? DateTime(2000);
        return tb.compareTo(ta);
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ---------- Filter by category ----------
  List<ReportModel> getByCategory(String category) {
    return _myReports.where((r) => r.category == category).toList();
  }
}

/// Simple wrapper for web image bytes (since XFile isn't cross-platform here).
class XFileBytes {
  final Uint8List bytes;
  const XFileBytes(this.bytes);
}