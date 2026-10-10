import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class EmployeeManagementProvider extends ChangeNotifier {
  final FirestoreService _fs = FirestoreService();
  List<QueryDocumentSnapshot> _employees = [];
  bool _loading = false;
  String? _error;

  List<QueryDocumentSnapshot> get employees => _employees;
  bool get loading => _loading;
  String? get error => _error;

  static const List<Map<String, String>> departments = [
    {'label': 'Staff', 'emoji': '🛠️'},
    {'label': 'Engineer', 'emoji': '👷'},
    {'label': 'Team Leading Head', 'emoji': '🧑‍💼'},
    {'label': 'Supervisor', 'emoji': '🚧'},
    {'label': 'Inspector', 'emoji': '📋'},
    {'label': 'Traffic Controller', 'emoji': '🚦'},
    {'label': 'Electrician', 'emoji': '⚡'},
    {'label': 'Mechanic', 'emoji': '🔧'},
    {'label': 'Materials Manager', 'emoji': '📦'},
    {'label': 'Trainee', 'emoji': '🎓'},
  ];

  Future<void> loadAll() async {
    try {
      _loading = true;
      notifyListeners();
      _employees = await _fs.getAllEmployees();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> createEmployee({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String department,
  }) async {
    try {
      _loading = true;
      notifyListeners();
      await _fs.createEmployeeAccount(
        email: email, password: password, name: name,
        phone: phone, department: department,
      );
      await loadAll();
      return null;
    } catch (e) {
      return _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateEmployee(String uid, Map<String, dynamic> data) async {
    await _fs.updateEmployee(uid, data);
    await loadAll();
  }

  Future<void> deleteEmployee(String uid) async {
    await _fs.deleteEmployee(uid);
    await loadAll();
  }
}