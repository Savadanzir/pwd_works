import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../models/employee_model.dart';

class EmployeeProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final FirestoreService _db = FirestoreService();

  EmployeeModel? _employee;
  bool _loading = false;
  String? _error;

  EmployeeModel? get employee => _employee;
  bool get loading => _loading;
  String? get error => _error;

  Future<String?> login(String email, String password) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();
      final cred = await _auth.signIn(email, password);
      final doc = await _db.getEmployee(cred.user!.uid);
      if (!doc.exists) {
        await _auth.signOut();
        return _error = 'This account is not an employee account.';
      }
      _employee = EmployeeModel.fromMap(doc.data() as Map<String, dynamic>);
      return null;
    } catch (e) {
      return _error = _friendlyError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _employee = null;
    notifyListeners();
  }

  String _friendlyError(dynamic e) {
    final s = e.toString();
    if (s.contains('user-not-found')) return 'No account found with this email.';
    if (s.contains('wrong-password')) return 'Incorrect password.';
    if (s.contains('invalid-email')) return 'Invalid email address.';
    if (s.contains('too-many-requests')) return 'Too many attempts. Try again later.';
    return s;
  }
}