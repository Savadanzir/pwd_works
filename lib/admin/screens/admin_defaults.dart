class AdminDefaults {
  /// Per-district admin credentials.
  /// These will be auto-created in Firebase the first time you log in
  /// as an admin of that district.
  static const Map<String, Map<String, String>> byDistrict = {
    'Thiruvananthapuram': {
      'email': 'admin.tvm@roadfix.com',
      'password': 'Tvm@2026',
      'name': 'Thiruvananthapuram Admin',
    },
    'Kollam': {
      'email': 'admin.kollam@roadfix.com',
      'password': 'Kollam@2026',
      'name': 'Kollam Admin',
    },
    'Pathanamthitta': {
      'email': 'admin.pathanamthitta@roadfix.com',
      'password': 'Patha@2026',
      'name': 'Pathanamthitta Admin',
    },
    'Alappuzha': {
      'email': 'admin.alappuzha@roadfix.com',
      'password': 'Alap@2026',
      'name': 'Alappuzha Admin',
    },
    'Kottayam': {
      'email': 'admin.kottayam@roadfix.com',
      'password': 'Kotta@2026',
      'name': 'Kottayam Admin',
    },
    'Idukki': {
      'email': 'admin.idukki@roadfix.com',
      'password': 'Idukki@2026',
      'name': 'Idukki Admin',
    },
    'Ernakulam': {
      'email': 'admin.ernakulam@roadfix.com',
      'password': 'Ernak@2026',
      'name': 'Ernakulam Admin',
    },
    'Thrissur': {
      'email': 'admin.thrissur@roadfix.com',
      'password': 'Thri@2026',
      'name': 'Thrissur Admin',
    },
    'Palakkad': {
      'email': 'admin.palakkad@roadfix.com',
      'password': 'Palak@2026',
      'name': 'Palakkad Admin',
    },
    'Malappuram': {
      'email': 'admin.malappuram@roadfix.com',
      'password': 'Mala@2026',
      'name': 'Malappuram Admin',
    },
    'Kozhikode': {
      'email': 'admin.kozhikode@roadfix.com',
      'password': 'Kozhi@2026',
      'name': 'Kozhikode Admin',
    },
    'Wayanad': {
      'email': 'admin.wayanad@roadfix.com',
      'password': 'Wayan@2026',
      'name': 'Wayanad Admin',
    },
    'Kannur': {
      'email': 'admin.kannur@roadfix.com',
      'password': 'Kannur@2026',
      'name': 'Kannur Admin',
    },
    'Kasaragod': {
      'email': 'admin.kasaragod@roadfix.com',
      'password': 'Kasa@2026',
      'name': 'Kasaragod Admin',
    },
  };

  /// Fallback generic credentials
  static const String email = 'admin@roadfix.com';
  static const String password = 'admin123';
  static const String name = 'Admin';
}