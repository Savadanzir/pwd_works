class WorkModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final String status;
  final String? imageUrl;
  final String? workNote;
  final String? completionImage;

  WorkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    this.imageUrl,
    this.workNote,
    this.completionImage,
  });

  factory WorkModel.fromMap(String id, Map<String, dynamic> m) => WorkModel(
        id: id,
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        location: m['location'] ?? '',
        status: m['status'] ?? 'Pending',
        imageUrl: m['imageUrl'],
        workNote: m['workNote'],
        completionImage: m['completionImage'],
      );
}