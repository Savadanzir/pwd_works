import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String category;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final String status;
  final String? assignedTo;
  final String? employeeName;
  final String? adminReply;
  final String? workNote;
  final String? completionImage;
  final Timestamp? createdAt;

  ReportModel({
    this.id = '',
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.status = 'Pending',
    this.assignedTo,
    this.employeeName,
    this.adminReply,
    this.workNote,
    this.completionImage,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'imageUrl': imageUrl,
        'status': status,
        'assignedTo': assignedTo,
        'employeeName': employeeName,
        'adminReply': adminReply,
        'workNote': workNote,
        'completionImage': completionImage,
        'createdAt': createdAt ?? Timestamp.now(),
      };

  factory ReportModel.fromMap(String id, Map<String, dynamic> m) => ReportModel(
        id: id,
        userId: m['userId'] ?? '',
        userName: m['userName'] ?? '',
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        category: m['category'] ?? 'Road Work',
        location: m['location'] ?? '',
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        imageUrl: m['imageUrl'],
        status: m['status'] ?? 'Pending',
        assignedTo: m['assignedTo'],
        employeeName: m['employeeName'],
        adminReply: m['adminReply'],
        workNote: m['workNote'],
        completionImage: m['completionImage'],
        createdAt: m['createdAt'] is Timestamp ? m['createdAt'] : null,
      );
}