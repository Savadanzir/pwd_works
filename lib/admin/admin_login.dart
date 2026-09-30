import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:road_maintenance/admin/admin_defaults.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'admin_home.dart';
import 'admin_provider.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});
  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  late final TextEditingController _email;
  late final TextEditingController _pass;

  @override
  void initState() {
    super.initState();
    // Pre-fill with the default admin credentials
    _email = TextEditingController(text: AdminDefaults.email);
    _pass = TextEditingController(text: AdminDefaults.password);
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Prevent Admin UI on non-web platforms
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Admin panel is only available on the Web.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final prov = Provider.of<AdminProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.admin_panel_settings,
                        size: 80, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text('Admin Login',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Default credentials are pre-filled',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 24),
                    CustomTextField(
                        controller: _email,
                        label: 'Admin Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress),
                    CustomTextField(
                        controller: _pass,
                        label: 'Password',
                        icon: Icons.lock,
                        obscure: true),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Login',
                      loading: prov.loading,
                      onPressed: () async {
                        final err = await prov.login(
                            _email.text.trim(), _pass.text);
                        if (err == null && mounted) {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AdminHome()));
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err ?? 'Error')));
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Default admin account is auto-created on first login.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}