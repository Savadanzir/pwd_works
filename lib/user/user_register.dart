import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'user_provider.dart';
import 'user_home.dart';

class UserRegister extends StatefulWidget {
  const UserRegister({super.key});
  @override
  State<UserRegister> createState() => _UserRegisterState();
}

class _UserRegisterState extends State<UserRegister> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('User Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CustomTextField(
                controller: _name, label: 'Full Name', icon: Icons.person),
            CustomTextField(
                controller: _email,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress),
            CustomTextField(
                controller: _phone,
                label: 'Phone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone),
            CustomTextField(
                controller: _pass,
                label: 'Password',
                icon: Icons.lock,
                obscure: true),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Register',
              loading: prov.loading,
              onPressed: () async {
                final err = await prov.register(_name.text.trim(),
                    _email.text.trim(), _phone.text.trim(), _pass.text);
                if (err == null && mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const UserHome()),
                      (_) => false);
                } else if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(err ?? 'Error')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
