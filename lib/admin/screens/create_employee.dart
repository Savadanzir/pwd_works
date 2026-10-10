import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/employee_management_provider.dart';

class CreateEmployee extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final String? uid;
  const CreateEmployee({super.key, this.existing, this.uid});

  @override
  State<CreateEmployee> createState() => _CreateEmployeeState();
}

class _CreateEmployeeState extends State<CreateEmployee>
    with TickerProviderStateMixin {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirmPass = TextEditingController();

  String _department = 'Staff';
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _emailError;
  String? _passError;

  bool get _isEdit => widget.existing != null;

  late AnimationController _bgCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _dustCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _dustRise;
  Offset _parallax = Offset.zero;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.existing!;
      _name.text = e['name'] ?? '';
      _phone.text = e['phone'] ?? '';
      _email.text = e['email'] ?? '';
      _department = e['department'] ?? 'Staff';
    }

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);
    _dustCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _dustRise = CurvedAnimation(parent: _dustCtrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _orbCtrl.dispose();
    _dustCtrl.dispose();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _pass.dispose();
    _confirmPass.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent e, Size size) {
    final dx = (e.localPosition.dx / size.width - 0.5) * 2;
    final dy = (e.localPosition.dy / size.height - 0.5) * 2;
    setState(() => _parallax = Offset(dx, dy));
  }

  String? _validate() {
    setState(() { _emailError = null; _passError = null; });
    if (_name.text.trim().isEmpty) return 'Enter full name';
    if (_phone.text.trim().isEmpty) return 'Enter phone number';
    if (_email.text.trim().isEmpty) return 'Enter email';
    if (!_email.text.contains('@')) { setState(() => _emailError = 'Invalid email'); return 'Invalid email'; }
    if (!_isEdit) {
      if (_pass.text.length < 6) { setState(() => _passError = 'Password must be 6+ characters'); return 'Password too short'; }
      if (_pass.text != _confirmPass.text) { setState(() => _passError = 'Passwords do not match'); return 'Passwords do not match'; }
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: const Color(0xFFB91C1C), behavior: SnackBarBehavior.floating));
      return;
    }

    final prov = Provider.of<EmployeeManagementProvider>(context, listen: false);

    if (_isEdit) {
      await prov.updateEmployee(widget.uid!, {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'department': _department,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Employee updated'), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating));
        Navigator.pop(context);
      }
    } else {
      final err = await prov.createEmployee(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _pass.text,
        department: _department,
      );
      if (err == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Employee account created'), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating));
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $err'), backgroundColor: const Color(0xFFB91C1C), behavior: SnackBarBehavior.floating));
      }
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
        title: Text(
          _isEdit ? 'Edit Employee' : 'Create Employee',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return MouseRegion(
            onHover: (e) => _onHover(e, size),
            child: AnimatedBuilder(
              animation: Listenable.merge([_bgAnim, _orbAnim, _dustRise]),
              builder: (context, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _gradientBase(),
                    _orbs(size),
                    _dust(size),
                    SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: _glassForm(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _glassForm() {
    final prov = Provider.of<EmployeeManagementProvider>(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.white.withOpacity(0.10),
              const Color(0xFFA855F7).withOpacity(0.10)]),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 40, offset: const Offset(0, 18)),
              BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.20), blurRadius: 30, offset: const Offset(0, 8)),
            ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF8B5CF6)]),
                    boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.55), blurRadius: 18, spreadRadius: 1)]),
                  child: Icon(_isEdit ? Icons.edit_rounded : Icons.person_add_alt_1_rounded,
                    color: Colors.white, size: 22)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_isEdit ? 'Edit Employee' : 'Create Employee',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  const SizedBox(height: 3),
                  Text(_isEdit ? 'Update the employee details' : 'Create an account for a field worker',
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12)),
                ])),
              ]),
              const SizedBox(height: 20),

              if (_isEdit)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.35), width: 1)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline, color: Color(0xFF60A5FA), size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      'Email & password cannot be changed here. Delete and re-create the employee to change them.',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75), height: 1.4))),
                  ]),
                ),

              _glassField(_name, 'Full Name', Icons.person_rounded),
              const SizedBox(height: 12),
              _glassField(_phone, 'Phone Number', Icons.phone_rounded, keyboard: TextInputType.phone),
              const SizedBox(height: 12),
              _glassDepartmentDropdown(prov),
              const SizedBox(height: 12),

              if (!_isEdit) ...[
                _glassField(_email, 'Email ID', Icons.email_rounded,
                    keyboard: TextInputType.emailAddress, error: _emailError),
                const SizedBox(height: 12),
                _glassField(_pass, 'Password', Icons.lock_rounded,
                    obscure: _obscurePass, error: _passError,
                    suffix: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20, color: Colors.white.withOpacity(0.70)),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass))),
                const SizedBox(height: 12),
                _glassField(_confirmPass, 'Confirm Password', Icons.lock_rounded,
                    obscure: _obscureConfirm,
                    suffix: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 20, color: Colors.white.withOpacity(0.70)),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
              ] else ...[
                _glassField(_email, 'Email ID (read-only)', Icons.email_rounded, readOnly: true),
              ],

              const SizedBox(height: 24),
              SizedBox(height: 56,
                child: ElevatedButton.icon(
                  icon: prov.loading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Icon(_isEdit ? Icons.save_rounded : Icons.person_add_alt_1_rounded, size: 20),
                  label: Text(_isEdit ? 'Save Changes' : 'Create Account',
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0),
                  onPressed: prov.loading ? null : _submit)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassField(TextEditingController c, String label, IconData icon,
      {bool obscure = false, bool readOnly = false, String? error, TextInputType? keyboard, Widget? suffix}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.white.withOpacity(0.10),
              Colors.white.withOpacity(0.04)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: error != null ? const Color(0xFFEF4444).withOpacity(0.65) : Colors.white.withOpacity(0.25),
              width: 1.2)),
          child: TextField(
            controller: c,
            obscureText: obscure,
            readOnly: readOnly,
            keyboardType: keyboard,
            style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w500),
            cursorColor: const Color(0xFFA855F7),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 13.5),
              floatingLabelStyle: const TextStyle(color: Color(0xFFA855F7), fontSize: 13, fontWeight: FontWeight.w600),
              prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.70), size: 20),
              suffixIcon: suffix,
              errorText: error,
              errorStyle: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11.5),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4)),
          ),
        ),
      ),
    );
  }

  Widget _glassDepartmentDropdown(EmployeeManagementProvider prov) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.white.withOpacity(0.10),
              Colors.white.withOpacity(0.04)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _department,
              isExpanded: true,
              dropdownColor: const Color(0xFF1B2B54),
              borderRadius: BorderRadius.circular(16),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withOpacity(0.85), size: 20),
              style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600),
              selectedItemBuilder: (context) => EmployeeManagementProvider.departments.map((d) {
                return Row(children: [
                  Icon(Icons.work_rounded, color: Colors.white.withOpacity(0.70), size: 18),
                  const SizedBox(width: 10),
                  Text(d['label']!,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
                ]);
              }).toList(),
              items: EmployeeManagementProvider.departments.map((d) {
                return DropdownMenuItem<String>(
                  value: d['label'],
                  child: Row(children: [
                    Text(d['emoji']!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Text(d['label']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ]));
              }).toList(),
              onChanged: (v) { if (v != null) setState(() => _department = v); }),
          ),
        ),
      ),
    );
  }

  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
            radius: 1.5,
            colors: const [Color(0xFF1E0B3A), Color(0xFF0A061E), Color(0xFF04060F)],
            stops: const [0.0, 0.55, 1.0]),
        ),
      );

  Widget _orbs(Size size) => Stack(children: [
        Positioned(
          left: -size.width * 0.15 + _parallax.dx * -14,
          top: -size.height * 0.18 + _parallax.dy * -10,
          child: _orb(380, const Color(0xFFA855F7), 0.30)),
        Positioned(
          right: -size.width * 0.12 + _parallax.dx * 14,
          bottom: -size.height * 0.15 + _parallax.dy * 10,
          child: _orb(420, const Color(0xFF8B5CF6), 0.24)),
      ]);

  Widget _orb(double size, Color color, double opacity) => IgnorePointer(
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withOpacity(opacity * (0.85 + _orbAnim.value * 0.3)),
              color.withOpacity(0.0)]))),
      );

  Widget _dust(Size size) {
    final list = <Widget>[];
    for (int i = 0; i < 18; i++) {
      final seed = (i * 0.137) % 1.0;
      final p = (_dustRise.value + seed) % 1.0;
      final x = size.width * (0.05 + (i % 9) * 0.11) + math.sin((p + i) * 5) * 20;
      final y = size.height - p * size.height * 0.9;
      final opacity = ((1.0 - p) * 0.35).clamp(0.0, 1.0);
      final r = 1.6 + (i % 3) * 1.4;
      list.add(Positioned(left: x, top: y,
        child: IgnorePointer(child: Opacity(opacity: opacity,
          child: Container(width: r * 2, height: r * 2,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.55)))))));
    }
    return Stack(children: list);
  }
}