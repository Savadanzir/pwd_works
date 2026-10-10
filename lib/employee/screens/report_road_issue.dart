import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/employee_provider.dart';
import '../../services/firestore_service.dart';

class ReportRoadIssue extends StatefulWidget {
  const ReportRoadIssue({super.key});
  @override
  State<ReportRoadIssue> createState() => _ReportRoadIssueState();
}

class _ReportRoadIssueState extends State<ReportRoadIssue> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _loc = TextEditingController();
  String _severity = 'Medium';
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _loc.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.isEmpty || _desc.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final emp =
          Provider.of<EmployeeProvider>(context, listen: false).employee;
      await FirestoreService().addReport({
        'userId': emp?.uid,
        'userName': emp?.name,
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'category': 'Field Report',
        'location': _loc.text.trim(),
        'severity': _severity,
        'status': 'Pending',
        'reportedBy': 'employee',
        'createdAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Road issue reported'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFB91C1C),
            behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
        title: const Text('Report Road Issue',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
            gradient: RadialGradient(
                center: Alignment(-0.4, -0.6),
                radius: 1.5,
                colors: [
              Color(0xFF3A0A0A),
              Color(0xFF160404),
              Color(0xFF04060F)
            ],
                stops: [
              0.0,
              0.55,
              1.0
            ])),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.white.withOpacity(0.10),
                        const Color(0xFFEF4444).withOpacity(0.10)
                      ]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1.2)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _field(_title, 'Issue Title', Icons.title_rounded),
                        const SizedBox(height: 14),
                        _severityDropdown(),
                        const SizedBox(height: 14),
                        _field(_desc, 'Description', Icons.description_rounded,
                            maxLines: 3),
                        const SizedBox(height: 14),
                        _field(_loc, 'Location', Icons.location_on_rounded),
                        const SizedBox(height: 24),
                        SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                                icon: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Icon(Icons.send_rounded, size: 18),
                                label: const Text('Submit Report',
                                    style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 0),
                                onPressed: _loading ? null : _submit)),
                      ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {int maxLines = 1}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.28), width: 1.2)),
          child: TextField(
              controller: c,
              maxLines: maxLines,
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
              cursorColor: const Color(0xFFEF4444),
              decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.55), fontSize: 14),
                  prefixIcon: Icon(icon,
                      color: Colors.white.withOpacity(0.80), size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 4))),
        ),
      ),
    );
  }

  Widget _severityDropdown() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.28), width: 1.2)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
                value: _severity,
                isExpanded: true,
                dropdownColor: const Color(0xFF1B2B54),
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white.withOpacity(0.85), size: 20),
                style: const TextStyle(color: Colors.white, fontSize: 14.5),
                items: const [
                  DropdownMenuItem(value: 'Low', child: Text('🟢 Low')),
                  DropdownMenuItem(value: 'Medium', child: Text('🟡 Medium')),
                  DropdownMenuItem(value: 'High', child: Text('🟠 High')),
                  DropdownMenuItem(
                      value: 'Critical', child: Text('🔴 Critical')),
                ],
                onChanged: (v) => setState(() => _severity = v!)),
          ),
        ),
      ),
    );
  }
}
