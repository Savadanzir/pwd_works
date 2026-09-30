import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'employee_model.dart';

class EmployeeProvider extends ChangeNotifier {
  final _auth = AuthService();
  final _db = FirestoreService();
  EmployeeModel? _employee;
  bool _loading = false;

  EmployeeModel? get employee => _employee;
  bool get loading => _loading;

  Future<String?> login(String email, String password) async {
    try {
      _loading = true;
      notifyListeners();
      final cred = await _auth.signIn(email, password);
      final doc = await _db.getEmployee(cred.user!.uid);
      if (!doc.exists) return 'Not an employee account';
      _employee = EmployeeModel.fromMap(doc.data() as Map<String, dynamic>);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> register(String name, String email, String phone,
      String department, String password) async {
    try {
      _loading = true;
      notifyListeners();
      final cred = await _auth.signUp(email, password);
      final e = EmployeeModel(
          uid: cred.user!.uid,
          name: name,
          email: email,
          phone: phone,
          department: department);
      await _db.addEmployee(e.uid, e.toMap());
      _employee = e;
      return null;
    } catch (e) {
      return e.toString();
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
}