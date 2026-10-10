import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveRequestModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String department;
  final String type;
  final String fromDate;
  final String toDate;
  final String reason;
  final String status;
  final Timestamp? createdAt;

  LeaveRequestModel({
    this.id = '',
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    this.status = 'Pending',
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'department': department,
        'type': type,
        'fromDate': fromDate,
        'toDate': toDate,
        'reason': reason,
        'status': status,
        'createdAt': createdAt ?? Timestamp.now(),
      };

  factory LeaveRequestModel.fromMap(String id, Map<String, dynamic> m) =>
      LeaveRequestModel(
        id: id,
        employeeId: m['employeeId'] ?? '',
        employeeName: m['employeeName'] ?? '',
        department: m['department'] ?? '',
        type: m['type'] ?? '',
        fromDate: m['fromDate'] ?? '',
        toDate: m['toDate'] ?? '',
        reason: m['reason'] ?? '',
        status: m['status'] ?? 'Pending',
        createdAt: m['createdAt'] is Timestamp ? m['createdAt'] : null,
      );
}