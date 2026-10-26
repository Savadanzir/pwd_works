import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../models/admin_model.dart';

class AdminProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final FirestoreService _db = FirestoreService();

  AdminModel? _admin;
  bool _loading = false;

  AdminModel? get admin => _admin;
  bool get loading => _loading;

  // ============================================================
  // Standard login
  // ============================================================
  Future<String?> login(String email, String password) async {
    try {
      _loading = true;
      notifyListeners();

      final cred = await _auth.signIn(email, password);
      final doc = await _db.getAdmin(cred.user!.uid);

      if (!doc.exists) {
        return 'Admin record not found in Firestore.';
      }

      _admin = AdminModel.fromMap(doc.data() as Map<String, dynamic>);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // 🔑 Auto-login / auto-create per district
  // ============================================================
  Future<String?> loginOrCreateForDistrict({
    required String district,
    required String email,
    required String password,
    required String name,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      // 1. Try to sign in
      UserCredential? cred;
      try {
        cred = await _auth.signIn(email, password);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'invalid-credential' ||
            e.code == 'user-not-found' ||
            e.code == 'wrong-password') {
          // 2. Account doesn't exist → create it via secondary app
          cred = await _createAdminAccount(
            email: email,
            password: password,
          );
        } else {
          return e.message ?? 'Login failed.';
        }
      }

      final uid = cred.user!.uid;

      // 3. Ensure Firestore doc exists
      final doc = await _db.getAdmin(uid);
      if (!doc.exists) {
        await _db.addAdmin(uid, {
          'uid': uid,
          'name': name,
          'email': email,
          'district': district,
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Ensure district is set (in case the doc was created without one)
        final data = doc.data() as Map<String, dynamic>;
        if ((data['district'] ?? '') != district) {
          await FirebaseFirestore.instance
              .collection('admins')
              .doc(uid)
              .update({'district': district});
        }
      }

      // 4. Reload and cache admin
      final updated = await _db.getAdmin(uid);
      _admin = AdminModel.fromMap(updated.data() as Map<String, dynamic>);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // Creates the admin user in Firebase Auth using a
  // secondary Firebase App so we don't sign out the current user.
  // ------------------------------------------------------------
  Future<UserCredential> _createAdminAccount({
    required String email,
    required String password,
  }) async {
    const secondaryAppName = 'adminCreator';
    FirebaseApp? secondaryApp;

    try {
      secondaryApp = Firebase.apps.any((a) => a.name == secondaryAppName)
          ? Firebase.app(secondaryAppName)
          : await Firebase.initializeApp(
              name: secondaryAppName,
              options: Firebase.app().options,
            );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Keep the created user in the main auth session
      // (i.e. sign in on the primary app as well)
      await secondaryAuth.signOut();

      // Now sign in on the primary auth
      final primaryCred = await _auth.signIn(email, password);
      return primaryCred;
    } finally {
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _admin = null;
    notifyListeners();
  }
}