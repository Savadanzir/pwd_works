import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ---------------- Users ----------------
  Future<void> addUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).set(data);

  Future<DocumentSnapshot> getUser(String uid) =>
      _db.collection('users').doc(uid).get();

  // ---------------- Admins ----------------
  Future<void> addAdmin(String uid, Map<String, dynamic> data) =>
      _db.collection('admins').doc(uid).set(data);

  Future<DocumentSnapshot> getAdmin(String uid) =>
      _db.collection('admins').doc(uid).get();

  // ---------------- Employees ----------------
  Future<void> addEmployee(String uid, Map<String, dynamic> data) =>
      _db.collection('employees').doc(uid).set(data);

  Future<DocumentSnapshot> getEmployee(String uid) =>
      _db.collection('employees').doc(uid).get();

  Future<List<QueryDocumentSnapshot>> getAllEmployees() async {
    final snap = await _db.collection('employees').get();
    return snap.docs;
  }

  // ---------------- Reports ----------------
  Future<void> addReport(Map<String, dynamic> data) =>
      _db.collection('reports').add(data);

  Future<List<QueryDocumentSnapshot>> getUserReports(String uid) async {
    final snap =
        await _db.collection('reports').where('userId', isEqualTo: uid).get();
    return snap.docs;
  }

  Future<List<QueryDocumentSnapshot>> getAllReports() async {
    final snap = await _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs;
  }

  Future<void> updateReport(String id, Map<String, dynamic> data) =>
      _db.collection('reports').doc(id).update(data);

  Future<List<QueryDocumentSnapshot>> getEmployeeWorks(String empId) async {
    final snap = await _db
        .collection('reports')
        .where('assignedTo', isEqualTo: empId)
        .get();
    return snap.docs;
  }

  // ---------------- Storage ----------------
  /// Upload from a File (mobile / desktop).
  Future<String> uploadImage(File file, String path) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Upload from raw bytes (web).
  Future<String> uploadBytes(Uint8List bytes, String path) async {
    final ref = _storage.ref().child(path);
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }
}