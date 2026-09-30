import 'package:flutter/material.dart';
import 'package:road_maintenance/admin/admin_defaults.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

import 'admin_model.dart';

class AdminProvider extends ChangeNotifier {
  final _auth = AuthService();
  final _db = FirestoreService();
  AdminModel? _admin;
  bool _loading = false;

  AdminModel? get admin => _admin;
  bool get loading => _loading;

  /// Login flow:
  ///  1. Try to sign in with given email/password.
  ///  2. If those match the DEFAULT credentials but the account
  ///     doesn't exist yet in Firebase, auto-create it and record it.
  ///  3. Fetch admin record from Firestore.
  Future<String?> login(String email, String password) async {
    try {
      _loading = true;
      notifyListeners();

      final isDefault =
          email.trim().toLowerCase() == AdminDefaults.email.toLowerCase() &&
              password == AdminDefaults.password;

      try {
        final cred = await _auth.signIn(email, password);
        final doc = await _db.getAdmin(cred.user!.uid);
        if (!doc.exists) {
          // Edge-case: auth account exists but Firestore record missing
          await _db.addAdmin(cred.user!.uid, {
            'uid': cred.user!.uid,
            'name': AdminDefaults.name,
            'email': AdminDefaults.email,
            'role': 'admin',
          });
          _admin = AdminModel(
            uid: cred.user!.uid,
            name: AdminDefaults.name,
            email: AdminDefaults.email,
          );
        } else {
          _admin = AdminModel.fromMap(doc.data() as Map<String, dynamic>);
        }
        return null;
      } catch (signInError) {
        // If default creds given but sign-in failed → auto-provision
        if (isDefault) {
          try {
            final cred = await _auth.signUp(email, password);
            await _db.addAdmin(cred.user!.uid, {
              'uid': cred.user!.uid,
              'name': AdminDefaults.name,
              'email': AdminDefaults.email,
              'role': 'admin',
            });
            _admin = AdminModel(
              uid: cred.user!.uid,
              name: AdminDefaults.name,
              email: AdminDefaults.email,
            );
            return null;
          } catch (e) {
            return 'Failed to provision default admin: $e';
          }
        }
        return signInError.toString();
      }
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