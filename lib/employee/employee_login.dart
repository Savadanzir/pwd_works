import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'employee_home.dart';
import 'employee_provider.dart';

class EmployeeLogin extends StatefulWidget {
  const EmployeeLogin({super.key});
  @override
  State<EmployeeLogin> createState() => _EmployeeLoginState();
}

class _EmployeeLoginState extends State<EmployeeLogin> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _dept = TextEditingController();
  bool _registerMode = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Employee portal is only available on the Web.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final prov = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      appBar: AppBar(
          title: Text(_registerMode ? 'Employee Register' : 'Employee Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.engineering,
                        size: 70, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text(
                        _registerMode
                            ? 'Employee Register'
                            : 'Employee Login',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (_registerMode)
                      CustomTextField(
                          controller: _name,
                          label: 'Full Name',
                          icon: Icons.person),
                    CustomTextField(
                        controller: _email,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress),
                    if (_registerMode)
                      CustomTextField(
                          controller: _phone,
                          label: 'Phone',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone),
                    if (_registerMode)
                      CustomTextField(
                          controller: _dept,
                          label: 'Department',
                          icon: Icons.work),
                    CustomTextField(
                        controller: _pass,
                        label: 'Password',
                        icon: Icons.lock,
                        obscure: true),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: _registerMode ? 'Register' : 'Login',
                      loading: prov.loading,
                      onPressed: () async {
                        String? err;
                        if (_registerMode) {
                          err = await prov.register(
                              _name.text.trim(),
                              _email.text.trim(),
                              _phone.text.trim(),
                              _dept.text.trim(),
                              _pass.text);
                        } else {
                          err = await prov.login(
                              _email.text.trim(), _pass.text);
                        }
                        if (err == null && mounted) {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const EmployeeHome()),
                              (_) => false);
                        } else if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err ?? 'Error')));
                        }
                      },
                    ),
                    TextButton(
                      onPressed: () =>
                          setState(() => _registerMode = !_registerMode),
                      child: Text(_registerMode
                          ? 'Already registered? Login'
                          : "New employee? Register"),
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