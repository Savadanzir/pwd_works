import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String title;
  final String description;
  final String category;
  final String location;
  final String status;
  final String? imageUrl;
  final String? assignedTo;
  final String? employeeName;
  final String? employeeDepartment;
  final String? adminReply;
  final String? rejectedReason;
  final String? workNote;
  final String? completionImage;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  ReportModel({
    this.id = '',
    required this.userId,
    required this.userName,
    this.userPhone = '',
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.status = 'Pending',
    this.imageUrl,
    this.assignedTo,
    this.employeeName,
    this.employeeDepartment,
    this.adminReply,
    this.rejectedReason,
    this.workNote,
    this.completionImage,
    this.createdAt,
    this.updatedAt,
  });

  factory ReportModel.fromMap(String id, Map<String, dynamic> m) => ReportModel(
        id: id,
        userId: m['userId'] ?? '',
        userName: m['userName'] ?? '',
        userPhone: m['userPhone'] ?? '',
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        category: m['category'] ?? '',
        location: m['location'] ?? '',
        status: m['status'] ?? 'Pending',
        imageUrl: m['imageUrl'],
        assignedTo: m['assignedTo'],
        employeeName: m['employeeName'],
        employeeDepartment: m['employeeDepartment'],
        adminReply: m['adminReply'],
        rejectedReason: m['rejectedReason'],
        workNote: m['workNote'],
        completionImage: m['completionImage'],
        createdAt: m['createdAt'] is Timestamp ? m['createdAt'] : null,
        updatedAt: m['updatedAt'] is Timestamp ? m['updatedAt'] : null,
      );
}