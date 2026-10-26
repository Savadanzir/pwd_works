class EmployeeModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String district; // 👈 NEW

  EmployeeModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    this.district = '',
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'department': department,
        'district': district,
        'role': 'employee',
      };

  factory EmployeeModel.fromMap(Map<String, dynamic> m) => EmployeeModel(
        uid: m['uid'] ?? '',
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        department: m['department'] ?? '',
        district: m['district'] ?? '',
      );
}