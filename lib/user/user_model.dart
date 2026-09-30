class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': 'user',
      };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        uid: m['uid'] ?? '',
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
      );
}