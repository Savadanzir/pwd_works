import 'package:cloud_firestore/cloud_firestore.dart';

class WorkModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String location;
  final String status;
  final String? imageUrl;
  final String? completionImage;
  final String? workNote;
  final String? assignedTo;
  final String? employeeName;
  final String? adminReply;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  WorkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    this.imageUrl,
    this.completionImage,
    this.workNote,
    this.assignedTo,
    this.employeeName,
    this.adminReply,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkModel.fromMap(String id, Map<String, dynamic> m) => WorkModel(
        id: id,
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        category: m['category'] ?? '',
        location: m['location'] ?? '',
        status: m['status'] ?? 'Assigned',
        imageUrl: m['imageUrl'],
        completionImage: m['completionImage'],
        workNote: m['workNote'],
        assignedTo: m['assignedTo'],
        employeeName: m['employeeName'],
        adminReply: m['adminReply'],
        createdAt: m['createdAt'] is Timestamp ? m['createdAt'] : null,
        updatedAt: m['updatedAt'] is Timestamp ? m['updatedAt'] : null,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'category': category,
        'location': location,
        'status': status,
        'imageUrl': imageUrl,
        'completionImage': completionImage,
        'workNote': workNote,
        'assignedTo': assignedTo,
        'employeeName': employeeName,
        'adminReply': adminReply,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}