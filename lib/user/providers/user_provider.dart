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

  UserProvider() {
    loadCurrentUser();
  }

  /// Automatically loads the existing user profile details from Firestore / Auth.
  Future<void> loadCurrentUser() async {
    final current = _auth.currentUser;
    if (current == null) {
      _user = null;
      notifyListeners();
      return;
    }

    try {
      _loading = true;
      notifyListeners();

      final doc = await _db.getUser(current.uid);
      if (doc.exists && doc.data() != null) {
        _user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        // Fallback from Firebase Auth
        _user = UserModel(
          uid: current.uid,
          name: (current.displayName != null && current.displayName!.isNotEmpty)
              ? current.displayName!
              : (current.email?.split('@').first ?? 'User'),
          email: current.email ?? '',
          phone: current.phoneNumber ?? '',
        );
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

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

  Future<void> updateProfile({required String name, required String phone}) async {
    final current = _auth.currentUser;
    if (current == null) return;

    try {
      _loading = true;
      notifyListeners();

      await _db.addUser(current.uid, {
        'uid': current.uid,
        'name': name.trim(),
        'email': current.email ?? (_user?.email ?? ''),
        'phone': phone.trim(),
        'role': 'user',
      });

      _user = _user?.copyWith(name: name.trim(), phone: phone.trim()) ??
          UserModel(
            uid: current.uid,
            name: name.trim(),
            email: current.email ?? '',
            phone: phone.trim(),
          );
    } catch (e) {
      _error = e.toString();
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
