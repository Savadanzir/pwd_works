import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final FirestoreService _db = FirestoreService();

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  bool get loading => _loading;
  String? get error => _error;

  Future<String?> login(String email, String password) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final cred = await _auth.signIn(email, password);
      final doc = await _db.getUser(cred.user!.uid);
      if (!doc.exists) {
        _error = 'User record not found';
        return _error;
      }
      _user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      return null;
    } catch (e) {
      _error = e.toString();
      return _error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> register(
      String name, String email, String phone, String password) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      final cred = await _auth.signUp(email, password);
      final u = UserModel(
        uid: cred.user!.uid,
        name: name,
        email: email,
        phone: phone,
      );
      await _db.addUser(u.uid, u.toMap());
      _user = u;
      return null;
    } catch (e) {
      _error = e.toString();
      return _error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _error = null;
    notifyListeners();
  }
}