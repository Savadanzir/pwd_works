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
  final String? workNote;
  final String? completionImage;

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
    this.workNote,
    this.completionImage,
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
        'workNote': workNote,
        'completionImage': completionImage,
      };
}