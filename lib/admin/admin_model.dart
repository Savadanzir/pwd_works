class AdminModel {
  final String uid;
  final String name;
  final String email;

  AdminModel({required this.uid, required this.name, required this.email});

  Map<String, dynamic> toMap() =>
      {'uid': uid, 'name': name, 'email': email, 'role': 'admin'};

  factory AdminModel.fromMap(Map<String, dynamic> m) => AdminModel(
      uid: m['uid'] ?? '', name: m['name'] ?? '', email: m['email'] ?? '');
}