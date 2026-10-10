import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/repair_evidence_provider.dart';

class RepairEvidence extends StatefulWidget {
  final String reportId;
  const RepairEvidence({super.key, required this.reportId});
  @override
  State<RepairEvidence> createState() => _RepairEvidenceState();
}

class _RepairEvidenceState extends State<RepairEvidence> {
  File? _image;
  XFile? _webImage;

  Future<void> _pick() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 75, maxWidth: 1600);
      if (x == null) return;
      if (kIsWeb) {
        setState(() => _webImage = x);
      } else {
        setState(() => _image = File(x.path));
      }
    } catch (e) {
      _snack('Image picker error: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor:
            error ? const Color(0xFFB91C1C) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _upload() async {
    if (_image == null && _webImage == null) {
      _snack('Please pick an image first', error: true);
      return;
    }

    final prov = Provider.of<RepairEvidenceProvider>(context, listen: false);
    final bytes =
        kIsWeb && _webImage != null ? await _webImage!.readAsBytes() : null;

    final err = await prov.uploadEvidence(
      reportId: widget.reportId,
      image: kIsWeb ? null : _image,
      webImageBytes: bytes,
    );

    if (err == null && mounted) {
      _snack('Evidence uploaded ✅');
      Navigator.pop(context);
    } else if (mounted) {
      _snack('Upload failed: $err', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<RepairEvidenceProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Repair Evidence',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
            gradient: RadialGradient(
                center: Alignment(-0.4, -0.6),
                radius: 1.5,
                colors: [
              Color(0xFF2E1E06),
              Color(0xFF140D02),
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
                        const Color(0xFFF59E0B).withOpacity(0.10)
                      ]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1.2)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                            height: 250,
                            decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 1.2)),
                            child: _preview()),
                        const SizedBox(height: 16),
                        SizedBox(
                            height: 54,
                            child: OutlinedButton.icon(
                                icon: const Icon(Icons.photo_library, size: 18),
                                label: Text(
                                    (_image != null || _webImage != null)
                                        ? 'Change Image'
                                        : 'Pick Image',
                                    style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600)),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                        color: Color(0xFFF59E0B), width: 1.4),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16))),
                                onPressed: _pick)),
                        const SizedBox(height: 12),
                        SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                                icon: prov.uploading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Icon(Icons.cloud_upload, size: 18),
                                label: const Text('Upload Evidence',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 0),
                                onPressed: prov.uploading ? null : _upload)),
                      ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _preview() {
    if (kIsWeb && _webImage != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(_webImage!.path,
              fit: BoxFit.cover, width: double.infinity));
    }
    if (!kIsWeb && _image != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child:
              Image.file(_image!, fit: BoxFit.cover, width: double.infinity));
    }
    return const Center(
        child: Icon(Icons.image_outlined, size: 60, color: Colors.white38));
  }
}
