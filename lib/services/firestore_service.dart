import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  /// Get every registered employee (used by admin's Assign Work screen).
  Future<List<QueryDocumentSnapshot>> getAllEmployees() async {
    final snap = await _db
        .collection('employees')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs;
  }

  /// Get employees filtered by department.
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

  /// Creates a Firebase Auth user for an employee WITHOUT signing out
  /// the currently signed-in admin (uses a secondary Firebase app).
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

  /// Get all reports ordered by newest first (used by Admin Applications).
  Future<List<QueryDocumentSnapshot>> getAllReports() async {
    final snap = await _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs;
  }

  /// Get only the reports submitted by a specific user.
  Future<List<QueryDocumentSnapshot>> getUserReports(String uid) async {
    final snap =
        await _db.collection('reports').where('userId', isEqualTo: uid).get();
    return snap.docs;
  }

  /// Get only the reports assigned to a specific employee.
  Future<List<QueryDocumentSnapshot>> getEmployeeWorks(String empId) async {
    final snap = await _db
        .collection('reports')
        .where('assignedTo', isEqualTo: empId)
        .get();
    return snap.docs;
  }

  /// Update a report (used for approving, assigning, marking complete, etc.)
  Future<void> updateReport(String id, Map<String, dynamic> data) =>
      _db.collection('reports').doc(id).update(data);

  // ============================================================
  // 🔍 DUPLICATE DETECTION (simple — title only)
  // ============================================================
  /// Returns true if a similar report (same title, case-insensitive) exists
  /// with a non-rejected status — i.e., someone already reported it.
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
  // 🔍 DUPLICATE DETECTION (advanced — title + category + GPS)
  // ============================================================
  /// Returns the existing report document if a duplicate is found, else null.
  /// A duplicate is:
  ///   - Same title (case-insensitive, trimmed) AND same category, OR
  ///   - Same category AND GPS within ~50 m (~0.0005 degrees)
  Future<QueryDocumentSnapshot?> findDuplicateReport({
    required String title,
    required String category,
    double? latitude,
    double? longitude,
  }) async {
    final normalizedTitle = title.trim().toLowerCase();

    // Load reports of the same category
    final snap = await _db
        .collection('reports')
        .where('category', isEqualTo: category)
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();

      // Skip already-rejected reports — user is allowed to report them again
      final status = (data['status'] ?? '').toString();
      if (status == 'Rejected') continue;

      final existingTitle =
          (data['title'] ?? '').toString().trim().toLowerCase();
      final existingLat = data['latitude'];
      final existingLng = data['longitude'];

      // 1. Title match
      if (existingTitle.isNotEmpty && existingTitle == normalizedTitle) {
        return doc;
      }

      // 2. GPS proximity match (~50 m)
      if (latitude != null &&
          longitude != null &&
          existingLat is num &&
          existingLng is num) {
        final dLat = (existingLat - latitude).abs();
        final dLng = (existingLng - longitude).abs();
        // ~0.0005 degrees ≈ 50 m
        if (dLat < 0.0005 && dLng < 0.0005) {
          return doc;
        }
      }
    }
    return null;
  }

  /// Adds the current user's uid to the report's `supporters` array.
  Future<void> supportReport(String reportId, String userId) async {
    await _db.collection('reports').doc(reportId).update({
      'supporters': FieldValue.arrayUnion([userId]),
    });
  }

  // ============================================================
  // ✅ APPROVAL FLOW — report status queries
  // ============================================================

  /// Reports waiting for admin approval (Pending)
  Future<List<QueryDocumentSnapshot>> getPendingReports() async {
    return (await _db
            .collection('reports')
            .where('status', isEqualTo: 'Pending')
            .get())
        .docs;
  }

  /// Reports approved by admin, ready to be assigned
  Future<List<QueryDocumentSnapshot>> getApprovedReports() async {
    return (await _db
            .collection('reports')
            .where('status', isEqualTo: 'Approved')
            .get())
        .docs;
  }

  /// Reports rejected by admin
  Future<List<QueryDocumentSnapshot>> getRejectedReports() async {
    return (await _db
            .collection('reports')
            .where('status', isEqualTo: 'Rejected')
            .get())
        .docs;
  }

  /// Reports currently being worked on (assigned, in progress)
  Future<List<QueryDocumentSnapshot>> getActiveReports() async {
    final results = <QueryDocumentSnapshot>[];

    for (final s in ['Assigned', 'In Progress']) {
      final snap = await _db
          .collection('reports')
          .where('status', isEqualTo: s)
          .get();
      results.addAll(snap.docs);
    }

    // Sort client-side by createdAt desc
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

  /// Reports that are completed
  Future<List<QueryDocumentSnapshot>> getCompletedReports() async {
    return (await _db
            .collection('reports')
            .where('status', isEqualTo: 'Completed')
            .get())
        .docs;
  }

  /// Admin approves a report
  Future<void> approveReport(String id, {String? adminName}) async {
    await _db.collection('reports').doc(id).update({
      'status': 'Approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': adminName ?? 'admin',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Admin rejects a report (with reply message sent to user)
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

  /// Admin assigns an approved report to an employee
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

  /// Employee starts work
  Future<void> markInProgress(String id, {String? workNote}) async {
    await _db.collection('reports').doc(id).update({
      'status': 'In Progress',
      'workNote': workNote,
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Employee submits completion with evidence
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

  /// Marks the admin reply as seen by the user
  Future<void> markReplySeen(String id) async {
    await _db.collection('reports').doc(id).update({'replySeen': true});
  }

  // ============================================================
  // 📦 STORAGE — Image uploads
  // ============================================================

  /// Upload image using a File (mobile only).
  Future<String> uploadImage(File file, String path) async {
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Upload image using raw bytes (works on Web AND Mobile).
  /// Use this for Flutter Web compatibility.
  Future<String> uploadImageBytes(Uint8List bytes, String path) async {
    final ref = _storage.ref().child(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  /// Alias for uploadImageBytes — kept for backwards compatibility.
  Future<String> uploadBytes(Uint8List bytes, String path) =>
      uploadImageBytes(bytes, path);
}