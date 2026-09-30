import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'user_provider.dart';
import 'user_home.dart';
import 'user_register.dart';

class UserLogin extends StatefulWidget {
  const UserLogin({super.key});
  @override
  State<UserLogin> createState() => _UserLoginState();
}

class _UserLoginState extends State<UserLogin> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('User Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),
            const Icon(Icons.person, size: 90, color: Colors.blue),
            const SizedBox(height: 30),
            CustomTextField(
                controller: _email,
                label: 'Email',
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
                final err = await prov.login(_email.text.trim(), _pass.text);
                if (err == null && mounted) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const UserHome()));
                } else if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(err ?? 'Error')));
                }
              },
            ),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UserRegister())),
              child: const Text("Don't have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
}