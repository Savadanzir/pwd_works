import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../models/admin_model.dart';

class AdminProvider extends ChangeNotifier {
  final _auth = AuthService();
  final _db = FirestoreService();
  AdminModel? _admin;
  bool _loading = false;
  String? _error;

  AdminModel? get admin => _admin;
  bool get loading => _loading;
  String? get error => _error;

  Future<String?> login(String email, String password) async {
    try {
      _loading = true;
      notifyListeners();
      final cred = await _auth.signIn(email, password);
      final doc = await _db.getAdmin(cred.user!.uid);
      if (!doc.exists) return _error = 'Not an admin account';
      _admin = AdminModel.fromMap(doc.data() as Map<String, dynamic>);
      return null;
    } catch (e) {
      return _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _admin = null;
    notifyListeners();
  }
}