import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';   // make sure this file exists

import 'user/user_provider.dart';
import 'admin/admin_provider.dart';
import 'employee/employee_provider.dart';
import 'user/user_login.dart';
import 'admin/admin_login.dart';
import 'employee/employee_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
  } catch (e, st) {
    debugPrint('❌ Firebase init failed: $e');
    debugPrint('$st');
    runApp(_ErrorApp(error: e.toString()));
    return;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
      ],
      child: MaterialApp(
        title: 'Road Maintenance',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.grey[100],
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        home: const PlatformGate(),
      ),
    );
  }
}

/// 👇 Platform-aware entry point
class PlatformGate extends StatelessWidget {
  const PlatformGate({super.key});

  @override
  Widget build(BuildContext context) {
    // 🖥️ WEB → all three modules
    if (kIsWeb) {
      return const WebPortalScreen();
    }
    // 📱 MOBILE → User only
    return const UserLogin();
  }
}

/// Web portal – shows User, Admin & Employee login options.
class WebPortalScreen extends StatelessWidget {
  const WebPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.construction,
                            size: 80, color: Colors.blue),
                        const SizedBox(height: 16),
                        const Text(
                          'Road Maintenance\nWeb Portal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose your role to continue',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 30),

                        // ---------- USER ----------
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.person),
                            label: const Text('User Login',
                                style: TextStyle(fontSize: 17)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const UserLogin()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ---------- ADMIN ----------
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('Admin Login',
                                style: TextStyle(fontSize: 17)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminLogin()),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ---------- EMPLOYEE ----------
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.engineering),
                            label: const Text('Employee Login',
                                style: TextStyle(fontSize: 17)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EmployeeLogin()),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          'Web portal – for testing all roles.\n'
                          'Mobile app – User role only.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fallback UI when Firebase fails so we don't get a blank white screen.
class _ErrorApp extends StatelessWidget {
  final String error;
  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 70, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Firebase failed to initialize',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                const Text(
                  'Run "flutterfire configure" and make sure\n'
                  'lib/firebase_options.dart exists.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}