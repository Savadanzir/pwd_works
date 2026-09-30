import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';

class RepairEvidence extends StatefulWidget {
  final String reportId;
  const RepairEvidence({super.key, required this.reportId});

  @override
  State<RepairEvidence> createState() => _RepairEvidenceState();
}

class _RepairEvidenceState extends State<RepairEvidence> {
  File? _image;         // mobile
  XFile? _webImage;     // web
  bool _loading = false;

  Future<void> _pick() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    if (kIsWeb) {
      setState(() => _webImage = x);
    } else {
      setState(() => _image = File(x.path));
    }
  }

  Future<void> _upload() async {
    final file = _image ?? (_webImage != null ? File(_webImage!.path) : null);
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please pick an image first')));
      return;
    }
    setState(() => _loading = true);
    try {
      final url = await FirestoreService().uploadImage(file,
          'evidence/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await FirestoreService().updateReport(
          widget.reportId, {'completionImage': url, 'status': 'In Progress'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Evidence uploaded')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Repair Evidence')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (kIsWeb && _webImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_webImage!.path,
                        height: 250, fit: BoxFit.cover),
                  )
                else if (!kIsWeb && _image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, height: 250),
                  )
                else
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                        child:
                            Icon(Icons.image, size: 60, color: Colors.grey)),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library),
                    label: Text(
                        (_image != null || _webImage != null)
                            ? 'Change Image'
                            : 'Pick Image'),
                    onPressed: _pick,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_upload),
                    label: const Text('Upload Evidence'),
                    onPressed: _loading ? null : _upload,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}