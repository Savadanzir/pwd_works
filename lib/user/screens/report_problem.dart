import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import '../providers/user_provider.dart';
import '../providers/report_provider.dart';

class ReportProblem extends StatefulWidget {
  const ReportProblem({super.key});
  @override
  State<ReportProblem> createState() => _ReportProblemState();
}

class _ReportProblemState extends State<ReportProblem> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _loc = TextEditingController();
  String _category = 'Road Work';

  File? _image;
  XFile? _webImage;
  double? _lat, _lng;

  final _categories = ['Road Work', 'Metro', 'Traffic Block', 'Other'];

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _loc.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1600);
      if (x == null) return;
      setState(() {
        if (kIsWeb) {
          _webImage = x;
        } else {
          _image = File(x.path);
        }
      });
    } catch (e) {
      _showError('Image picker failed: $e');
    }
  }

  Future<void> _getLocation() async {
    try {
      final pos = await LocationService().getCurrentLocation();
      if (pos != null) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _loc.text = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        });
      } else {
        _showError('Location not available.');
      }
    } catch (e) {
      _showError('Location error: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFB91C1C), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) return _showError('Please enter a title');
    if (_desc.text.trim().isEmpty) return _showError('Please describe the problem');

    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return _showError('You must be logged in');

    final prov = Provider.of<ReportProvider>(context, listen: false);

    final dup = await prov.reportAlreadyExists(_title.text.trim());
    if (dup) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF0B1730),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 54),
            title: const Text('Already Reported', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            content: const Text('This problem has already been reported.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Color(0xFFF59E0B))),
              ),
            ],
          ),
        );
      }
      return;
    }

    final bytes = kIsWeb && _webImage != null ? await _webImage!.readAsBytes() : null;
    final err = await prov.submitReport(
      userId: user.uid,
      userName: user.name,
      userPhone: user.phone,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      category: _category,
      location: _loc.text.trim(),
      latitude: _lat,
      longitude: _lng,
      image: kIsWeb ? null : _image,
      webImage: bytes != null ? XFileBytes(bytes) : null,
    );

    if (err == null && mounted) {
      _title.clear();
      _desc.clear();
      _loc.clear();
      setState(() {
        _image = null;
        _webImage = null;
        _lat = null;
        _lng = null;
      });
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF0B1730),
          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 54),
          title: const Text('Report Submitted', textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
          content: const Text('Sent to the admin for approval.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } else if (mounted) {
      _showError('Submission failed: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ReportProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      appBar: AppBar(
        title: const Text('Report Problem', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _glassField(_title, 'Title', Icons.title_rounded),
                const SizedBox(height: 14),
                _dropdown(),
                const SizedBox(height: 14),
                _glassField(_desc, 'Description', Icons.description_rounded, maxLines: 3),
                const SizedBox(height: 14),
                _glassField(_loc, 'Location', Icons.location_on_rounded),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _iconBtn(Icons.my_location_rounded, 'Get GPS', _getLocation)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _iconBtn(
                        Icons.image_rounded,
                        (_image != null || _webImage != null) ? 'Change' : 'Pick Image',
                        _pickImage,
                      ),
                    ),
                  ],
                ),
                if (kIsWeb && _webImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(_webImage!.path, height: 180),
                    ),
                  )
                else if (!kIsWeb && _image != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(_image!, height: 180),
                    ),
                  ),
                const SizedBox(height: 24),
                _submitButton(prov),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassField(TextEditingController c, String hint, IconData icon, {int maxLines = 1}) => ClipRRect(
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
              border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.2),
            ),
            child: TextField(
              controller: c,
              maxLines: maxLines,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: const Color(0xFFA855F7),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14.5),
                prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.85), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              ),
            ),
          ),
        ),
      );

  Widget _dropdown() => ClipRRect(
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
              border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _category,
                isExpanded: true,
                dropdownColor: const Color(0xFF1B2B54),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ),
          ),
        ),
      );

  Widget _iconBtn(IconData icon, String label, VoidCallback onTap) => GestureDetector(
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
                  const Color(0xFFA855F7).withOpacity(0.10),
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _submitButton(ReportProvider prov) => GestureDetector(
        onTap: prov.loading ? null : _submit,
        child: Container(
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF6366F1)]),
            boxShadow: [
              BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.55), blurRadius: 26, offset: const Offset(0, 10)),
            ],
          ),
          child: Center(
            child: prov.loading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Report', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}