import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ============================================================
  // 👤 USERS
  // ============================================================
  Future<void> addUser(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).set(data);

  Future<DocumentSnapshot> getUser(String uid) =>
      _db.collection('users').doc(uid).get();

  // ============================================================
  // 🛡️ ADMINS
  // ============================================================
  Future<void> addAdmin(String uid, Map<String, dynamic> data) =>
      _db.collection('admins').doc(uid).set(data);

  Future<DocumentSnapshot> getAdmin(String uid) =>
      _db.collection('admins').doc(uid).get();

  // ============================================================
  // 👷 EMPLOYEES
  // ============================================================
  Future<void> addEmployee(String uid, Map<String, dynamic> data) =>
      _db.collection('employees').doc(uid).set(data);

  Future<DocumentSnapshot> getEmployee(String uid) =>
      _db.collection('employees').doc(uid).get();

  Future<List<QueryDocumentSnapshot>> getAllEmployees() async {
    final snap = await _db
        .collection('employees')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs;
  }

  Future<List<QueryDocumentSnapshot>> getEmployeesByDepartment(
      String department) async {
    final snap = await _db
        .collection('employees')
        .where('department', isEqualTo: department)
        .get();
    return snap.docs;
  }

  Future<void> updateEmployee(String uid, Map<String, dynamic> data) =>
      _db.collection('employees').doc(uid).update(data);

  Future<void> deleteEmployee(String uid) async {
    await _db.collection('employees').doc(uid).delete();
  }

  Future<String> createEmployeeAccount({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String department,
  }) async {
    const secondaryAppName = 'employeeCreator';
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

      final uid = cred.user!.uid;

      await _db.collection('employees').doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'department': department,
        'role': 'employee',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await secondaryAuth.signOut();
      return uid;
    } finally {
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {}
      }
    }
  }

  // ============================================================
  // 📋 REPORTS / APPLICATIONS
  // ============================================================
  Future<void> addReport(Map<String, dynamic> data) =>
      _db.collection('reports').add(data);

  Future<List<QueryDocumentSnapshot>> getAllReports() async {
    final snap = await _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs;
  }

  Future<List<QueryDocumentSnapshot>> getUserReports(String uid) async {
    final snap =
        await _db.collection('reports').where('userId', isEqualTo: uid).get();
    return snap.docs;
  }

  Future<List<QueryDocumentSnapshot>> getEmployeeWorks(String empId) async {
    final snap = await _db
        .collection('reports')
        .where('assignedTo', isEqualTo: empId)
        .get();
    return snap.docs;
  }

  Future<void> updateReport(String id, Map<String, dynamic> data) =>
      _db.collection('reports').doc(id).update(data);

  Future<bool> reportAlreadyExists(String title) async {
    final normalized = title.trim().toLowerCase();
    final snap = await _db.collection('reports').get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final existing = (data['title'] ?? '').toString().trim().toLowerCase();
      final status = data['status'] ?? '';
      if (existing == normalized && status != 'Rejected') {
        return true;
      }
    }
    return false;
  }

  // ============================================================
  // 🕵️ DUPLICATE CHECK LOGIC (Distance-based)
  // ============================================================
  Future<QueryDocumentSnapshot?> findDuplicateReport({
    required String title,
    required String category,
    double? latitude,
    double? longitude,
  }) async {
    // 1. If no GPS, just check exact title + category matches.
    if (latitude == null || longitude == null) {
      final normalizedTitle = title.trim().toLowerCase();
      final snap = await _db
          .collection('reports')
          .where('category', isEqualTo: category)
          .get();
          
      for (final doc in snap.docs) {
        final data = doc.data();
        final status = (data['status'] ?? '').toString();
        if (status == 'Rejected') continue;

        final existingTitle = (data['title'] ?? '').toString().trim().toLowerCase();
        if (existingTitle.isNotEmpty && existingTitle == normalizedTitle) {
          return doc;
        }
      }
      return null;
    }

    // 2. If GPS exists, fetch reports in the same category.
    // Note: This specific query requires a Composite Index in Firebase.
    // If the red error shows up, click the link in the error to create it.
    final snap = await _db
        .collection('reports')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(20) // Check only the 20 most recent
        .get();

    // 3. Loop through them and calculate the distance.
    for (final doc in snap.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString();
      if (status == 'Rejected') continue;

      final existingLat = data['latitude'];
      final existingLng = data['longitude'];

      if (existingLat is num && existingLng is num) {
        final double distanceInMeters = Geolocator.distanceBetween(
          existingLat.toDouble(),
          existingLng.toDouble(),
          latitude,
          longitude,
        );

        // If an existing report is within 100 meters, it's a duplicate!
        if (distanceInMeters <= 100.0) {
          return doc;
        }
      }
    }

    return null;
  }

  Future<void> supportReport(String reportId, String userId) async {
    await _db.collection('reports').doc(reportId).update({
      'supporters': FieldValue.arrayUnion([userId]),
    });
  }

  Future<List<QueryDocumentSnapshot>> getPendingReports() async {
    return (await _db
            .collection('reports')
            .where('status', isEqualTo: 'Pending')
            .get())
        .docs;
  }

  Future<List<QueryDocumentSnapshot>> getApprovedReports() async {
    return (await _db
            .collection('reports')
            .where('status', isEqualTo: 'Approved')
            .get())
        .docs;
  }

  Future<List<QueryDocumentSnapshot>> getRejectedReports() async {
    return (await _db
            .collection('reports')
            .where('status', isEqualTo: 'Rejected')
            .get())
        .docs;
  }

  Future<List<QueryDocumentSnapshot>> getActiveReports() async {
    final results = <QueryDocumentSnapshot>[];

    for (final s in ['Assigned', 'In Progress']) {
      final snap = await _db
          .collection('reports')
          .where('status', isEqualTo: s)
          .get();
      results.addAll(snap.docs);
    }

    results.sort((a, b) {
      final ta = (a.data() as Map)['createdAt'];
      final tb = (b.data() as Map)['createdAt'];
      if (ta is Timestamp && tb is Timestamp) {
        return tb.compareTo(ta);
      }
      return 0;
    });
    return results;
  }

  Future<List<QueryDocumentSnapshot>> getCompletedReports() async {
    return (await _db
            .collection('reports')
            .where('status', isEqualTo: 'Completed')
            .get())
        .docs;
  }

  Future<void> approveReport(String id, {String? adminName}) async {
    await _db.collection('reports').doc(id).update({
      'status': 'Approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': adminName ?? 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectReport(
    String id, {
    required String reason,
    String? adminName,
  }) async {
    await _db.collection('reports').doc(id).update({
      'status': 'Rejected',
      'adminReply': reason,
      'rejectedReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': adminName ?? 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
      'replySeen': false,
    });
  }

  Future<void> assignReport({
    required String reportId,
    required String employeeUid,
    required String employeeName,
    required String employeeDepartment,
    required String adminName,
  }) async {
    await _db.collection('reports').doc(reportId).update({
      'status': 'Assigned',
      'assignedTo': employeeUid,
      'employeeName': employeeName,
      'employeeDepartment': employeeDepartment,
      'assignedAt': FieldValue.serverTimestamp(),
      'assignedBy': adminName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markInProgress(String id, {String? workNote}) async {
    await _db.collection('reports').doc(id).update({
      'status': 'In Progress',
      'workNote': workNote,
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markCompleted(
    String id, {
    String? workNote,
    String? completionImage,
  }) async {
    await _db.collection('reports').doc(id).update({
      'status': 'Completed',
      'workNote': workNote,
      'completionImage': completionImage,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markReplySeen(String id) async {
    await _db.collection('reports').doc(id).update({'replySeen': true});
  }

  // ============================================================
  // 📦 STORAGE — Image uploads
  // ============================================================

  Future<String> uploadImage(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final UploadTask uploadTask = ref.putFile(file);
      
      final TaskSnapshot snapshot = await uploadTask; 
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Storage Error: ${e.code} - ${e.message}');
    }
  }

  // ✅ FIXED: Waits for upload and adds a 30s timeout to prevent infinite loading on mobile
  Future<String> uploadImageBytes(Uint8List bytes, String path) async {
    try {
      final ref = _storage.ref().child(path);
      
      // 1. Start the upload
      final UploadTask uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      // 2. ⚠️ CRITICAL: Wait for the upload, but fail gracefully if it hangs
      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Upload timed out. Please check your connection.'),
      );
      
      // 3. Now it's safe to get the URL
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw Exception('Storage Error: ${e.code} - ${e.message}');
    }
  }

  Future<String> uploadBytes(Uint8List bytes, String path) =>
      uploadImageBytes(bytes, path);
}