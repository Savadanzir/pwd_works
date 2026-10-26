import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:road_maintenance/user/screens/user_login.dart';

import 'district_service.dart';
import '../main.dart'; // for WebPortalScreen + UserLogin

class DistrictSelection extends StatefulWidget {
  const DistrictSelection({super.key});

  @override
  State<DistrictSelection> createState() => _DistrictSelectionState();
}

class _DistrictSelectionState extends State<DistrictSelection> {
  // 👇 All 14 Kerala districts
  static const List<String> _districts = [
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

  String? _selected;

  Future<void> _continue() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a district'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await DistrictService.set(_selected!);

    if (!mounted) return;

    // 👇 Directly open the module selection page (User / Admin / Employee)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => kIsWeb
            ? const WebPortalScreen() // Web → 3-role portal
            : const UserLogin(), // Mobile → user-only
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [
              Color(0xFF1E0B3A),
              Color(0xFF0A061E),
              Color(0xFF04060F),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.white.withOpacity(0.10),
                          const Color(0xFF3B82F6).withOpacity(0.10),
                        ]),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.22), width: 1.2),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF3B82F6),
                                  Color(0xFF8B5CF6),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF3B82F6).withOpacity(0.55),
                                  blurRadius: 26,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.location_city_rounded,
                                size: 36, color: Colors.white),
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Select Your District',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reports and works are district-based',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Dropdown
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.18)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selected,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF1B2B54),
                                    icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white),
                                    hint: const Text(
                                      'Choose a district',
                                      style: TextStyle(
                                          color: Colors.white54, fontSize: 15),
                                    ),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 15),
                                    items: _districts
                                        .map((d) => DropdownMenuItem(
                                              value: d,
                                              child: Text(d),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selected = v),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Continue
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _continue,
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 18),
                              label: const Text(
                                'Continue',
                                style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                            ),
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
      ),
    );
  }
}
