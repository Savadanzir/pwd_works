import 'dart:ui';
import 'package:flutter/material.dart';

import '../../services/district_service.dart';
import '../../services/firestore_service.dart';

class ManageEmployees extends StatefulWidget {
  const ManageEmployees({super.key});

  @override
  State<ManageEmployees> createState() => _ManageEmployeesState();
}

class _ManageEmployeesState extends State<ManageEmployees> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();

  String _department = 'Staff';
  String? _district;

  bool _showPass = false;
  bool _showConfirm = false;
  bool _submitting = false;

  final _departments = ['Staff', 'Engineer', 'Traffic Controller', 'Supervisor'];

  final _districts = const [
    'Thiruvananthapuram',
    'Kollam',
    'Pathanamthitta',
    'Alappuzha',
    'Kottayam',
    'Idukki',
    'Ernakulam',
    'Thrissur',
    'Palakkad',
    'Malappuram',
    'Kozhikode',
    'Wayanad',
    'Kannur',
    'Kasaragod',
  ];

  @override
  void initState() {
    super.initState();
    // Default to the admin's own district
    _district = DistrictService.current;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _create() async {
    if (_submitting) return;

    if (_name.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _pass.text.isEmpty) {
      _snack('Please fill all fields', Colors.orangeAccent);
      return;
    }
    if (_district == null || _district!.isEmpty) {
      _snack('Please select a district', Colors.orangeAccent);
      return;
    }
    if (_pass.text != _confirm.text) {
      _snack('Passwords do not match', Colors.redAccent);
      return;
    }
    if (_pass.text.length < 6) {
      _snack('Password must be at least 6 characters', Colors.redAccent);
      return;
    }

    setState(() => _submitting = true);

    try {
      final fs = FirestoreService();

      // Create the auth user + Firestore doc
      final uid = await fs.createEmployeeAccount(
        email: _email.text.trim(),
        password: _pass.text,
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        department: _department,
      );

      // 👇 Save the district the admin picked
      await fs.updateEmployee(uid, {'district': _district});

      if (!mounted) return;
      _snack('✅ Employee created for $_district', const Color(0xFF10B981));

      _name.clear();
      _phone.clear();
      _email.clear();
      _pass.clear();
      _confirm.clear();
      setState(() {
        _department = 'Staff';
        _district = DistrictService.current;
      });
    } catch (e) {
      _snack('❌ Failed: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Manage Employees',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [Color(0xFF2A1B4A), Color(0xFF10061E), Color(0xFF04060F)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _headerCard(),
              const SizedBox(height: 20),
              _glassField(_name, 'Full Name', Icons.person_rounded),
              const SizedBox(height: 14),
              _glassField(_phone, 'Phone Number', Icons.phone_rounded,
                  keyboard: TextInputType.phone),
              const SizedBox(height: 14),

              // 👇 NEW: District picker
              _districtDropdown(),
              const SizedBox(height: 14),

              _departmentDropdown(),
              const SizedBox(height: 14),
              _glassField(_email, 'Email ID', Icons.email_rounded,
                  keyboard: TextInputType.emailAddress),
              const SizedBox(height: 14),
              _passwordField(_pass, 'Password', _showPass,
                  () => setState(() => _showPass = !_showPass)),
              const SizedBox(height: 14),
              _passwordField(_confirm, 'Confirm Password', _showConfirm,
                  () => setState(() => _showConfirm = !_showConfirm)),
              const SizedBox(height: 24),
              _submitButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                const Color(0xFFA855F7).withOpacity(0.10),
              ]),
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                        colors: [Color(0xFFA855F7), Color(0xFF8B5CF6)]),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFA855F7).withOpacity(0.55),
                          blurRadius: 20)
                    ],
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Create Employee',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(
                        'Assign a district for the new employee',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _glassField(TextEditingController c, String hint, IconData icon,
      {TextInputType? keyboard}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.white.withOpacity(0.10),
              Colors.white.withOpacity(0.04),
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withOpacity(0.28), width: 1.2),
          ),
          child: TextField(
            controller: c,
            keyboardType: keyboard,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: const Color(0xFFA855F7),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 14.5),
              prefixIcon:
                  Icon(icon, color: Colors.white.withOpacity(0.85), size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField(TextEditingController c, String hint, bool visible,
          VoidCallback toggle) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.28), width: 1.2),
            ),
            child: TextField(
              controller: c,
              obscureText: !visible,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: const Color(0xFFA855F7),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.55), fontSize: 14.5),
                prefixIcon: Icon(Icons.lock_rounded,
                    color: Colors.white.withOpacity(0.85), size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    visible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: toggle,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              ),
            ),
          ),
        ),
      );

  // 👇 NEW: District dropdown
  Widget _districtDropdown() => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.28), width: 1.2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _district,
                isExpanded: true,
                dropdownColor: const Color(0xFF1B2B54),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white),
                hint: Row(
                  children: [
                    Icon(Icons.location_city_rounded,
                        color: Colors.white.withOpacity(0.85), size: 20),
                    const SizedBox(width: 12),
                    Text('Select District',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 14.5)),
                  ],
                ),
                selectedItemBuilder: (context) => _districts
                    .map((d) => Row(children: [
                          Icon(Icons.location_city_rounded,
                              color: Colors.white.withOpacity(0.85), size: 20),
                          const SizedBox(width: 12),
                          Text(d,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500)),
                        ]))
                    .toList(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500),
                items: _districts
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _district = v),
              ),
            ),
          ),
        ),
      );

  Widget _departmentDropdown() => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.28), width: 1.2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _department,
                isExpanded: true,
                dropdownColor: const Color(0xFF1B2B54),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                items: _departments
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _department = v!),
              ),
            ),
          ),
        ),
      );

  Widget _submitButton() => GestureDetector(
        onTap: _submitting ? null : _create,
        child: Container(
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
                colors: [Color(0xFFA855F7), Color(0xFF8B5CF6)]),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFA855F7).withOpacity(0.55),
                  blurRadius: 26,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Center(
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Text('Create Account',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
        ),
      );
}