import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../providers/employee_provider.dart';

class ReportRoadIssue extends StatefulWidget {
  const ReportRoadIssue({super.key});
  @override
  State<ReportRoadIssue> createState() => _ReportRoadIssueState();
}

class _ReportRoadIssueState extends State<ReportRoadIssue> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _loc = TextEditingController();

  String _category = 'Traffic Block';
  Uint8List? _imageBytes;
  String? _imageName;
  double? _lat, _lng;
  bool _submitting = false;

  final _categories = ['Traffic Block', 'Road Work', 'Metro', 'Other'];

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _loc.dispose();
    super.dispose();
  }

  // ---------- Image picker with compression ----------
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60, // 👈 compress
        maxWidth: 1024, // 👈 resize
        maxHeight: 1024,
      );
      if (x == null) return;

      final bytes = await x.readAsBytes().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Image read timed out'),
          );

      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageName = x.name;
      });
    } catch (e) {
      _snack('Image picker failed: $e', Colors.redAccent);
    }
  }

  Future<void> _getLocation() async {
    try {
      final pos = await LocationService().getCurrentLocation();
      if (pos != null) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _loc.text =
              '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      _snack('Location error: $e', Colors.redAccent);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ============================================================
  // 🚀 SUBMIT — with timeouts + image fallback
  // ============================================================
  Future<void> _submit() async {
    if (_submitting) return;

    if (_title.text.trim().isEmpty || _desc.text.trim().isEmpty) {
      _snack('Please fill title & description', Colors.orangeAccent);
      return;
    }

    setState(() => _submitting = true);

    String? imageUrl;

    // 1. Try uploading the image — but do NOT fail the whole report if it times out
    if (_imageBytes != null) {
      try {
        imageUrl = await FirestoreService()
            .uploadImageBytes(
              _imageBytes!,
              'reports/${DateTime.now().millisecondsSinceEpoch}_${_imageName ?? "img.jpg"}',
            )
            .timeout(const Duration(seconds: 20));
      } on TimeoutException {
        imageUrl = null;
        _snack('⌛ Image upload timed out — sending report without the image',
            Colors.orangeAccent);
      } catch (e) {
        imageUrl = null;
        _snack('⚠️ Image upload failed ($e) — sending without the image',
            Colors.orangeAccent);
      }
    }

    // 2. Save the report to Firestore (this is the important part)
    try {
      final emp =
          Provider.of<EmployeeProvider>(context, listen: false).employee;

      await FirestoreService().addReport({
        'userId': emp?.uid ?? '',
        'userName': emp?.name ?? 'Employee',
        'reportedBy': 'employee',
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'category': _category,
        'district': '',
        'location': _loc.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
        'imageUrl': imageUrl,
        'status': 'Approved',
        'createdAt': Timestamp.now(),
        'supporters': <String>[emp?.uid ?? ''],
      }).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Saving timed out'),
      );

      if (!mounted) return;
      _snack('✅ Report sent to user & admin', const Color(0xFF10B981));
      Navigator.pop(context);
    } on TimeoutException {
      _snack('⌛ Saving timed out. Please check your connection and retry.',
          Colors.orangeAccent);
    } catch (e) {
      _snack('❌ Failed: $e', Colors.redAccent);
    } finally {
      // 👈 Guaranteed spinner reset
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
        title: const Text('Report Road Issue',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [Color(0xFF3A0A18), Color(0xFF16040A), Color(0xFF04060F)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _glassField(_title, 'Title', Icons.title_rounded),
              const SizedBox(height: 14),
              _categoryDropdown(),
              const SizedBox(height: 14),
              _glassField(_desc, 'Description', Icons.description_rounded,
                  maxLines: 3),
              const SizedBox(height: 14),
              _glassField(_loc, 'Location', Icons.location_on_rounded),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _iconBtn(
                        Icons.my_location_rounded, 'Get GPS', _getLocation),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _iconBtn(
                      Icons.image_rounded,
                      _imageBytes == null ? 'Pick Image' : 'Change',
                      _pickImage,
                    ),
                  ),
                ],
              ),
              if (_imageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(
                      _imageBytes!,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _submitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassField(TextEditingController c, String hint, IconData icon,
          {int maxLines = 1}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ]),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.28), width: 1.2),
            ),
            child: TextField(
              controller: c,
              maxLines: maxLines,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: const Color(0xFFEF4444),
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

  Widget _categoryDropdown() => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ]),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.28), width: 1.2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _category,
                isExpanded: true,
                dropdownColor: const Color(0xFF1B2B54),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Colors.white),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ),
          ),
        ),
      );

  Widget _iconBtn(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.12),
                  const Color(0xFFEF4444).withOpacity(0.10),
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.28), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _submitButton() => GestureDetector(
        onTap: _submitting ? null : _submit,
        child: Container(
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFB91C1C)]),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.55),
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
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Report to User & Admin',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700)),
          ),
        ),
      );
}
