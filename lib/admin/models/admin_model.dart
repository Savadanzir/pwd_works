class AdminModel {
  final String uid;
  final String name;
  final String email;
  final String district; // 👈 NEW

  AdminModel({
    required this.uid,
    required this.name,
    required this.email,
    this.district = '',
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'district': district,
        'role': 'admin',
      };

  factory AdminModel.fromMap(Map<String, dynamic> m) => AdminModel(
        uid: m['uid'] ?? '',
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        district: m['district'] ?? '',
      );
}