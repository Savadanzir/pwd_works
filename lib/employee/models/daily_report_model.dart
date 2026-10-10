import 'package:cloud_firestore/cloud_firestore.dart';

class DailyReportModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String department;
  final double hoursWorked;
  final int tasksCompleted;
  final String blockers;
  final String date;
  final Timestamp? createdAt;

  DailyReportModel({
    this.id = '',
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.hoursWorked,
    required this.tasksCompleted,
    required this.blockers,
    required this.date,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'employeeId': employeeId,
        'employeeName': employeeName,
        'department': department,
        'hoursWorked': hoursWorked,
        'tasksCompleted': tasksCompleted,
        'blockers': blockers,
        'date': date,
        'createdAt': createdAt ?? Timestamp.now(),
      };

  factory DailyReportModel.fromMap(String id, Map<String, dynamic> m) =>
      DailyReportModel(
        id: id,
        employeeId: m['employeeId'] ?? '',
        employeeName: m['employeeName'] ?? '',
        department: m['department'] ?? '',
        hoursWorked: (m['hoursWorked'] as num?)?.toDouble() ?? 0,
        tasksCompleted: (m['tasksCompleted'] as num?)?.toInt() ?? 0,
        blockers: m['blockers'] ?? '',
        date: m['date'] ?? '',
        createdAt: m['createdAt'] is Timestamp ? m['createdAt'] : null,
      );
}