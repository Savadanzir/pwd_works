import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:road_maintenance/services/firestore_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'user_provider.dart';

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

  File? _image;        // used on mobile
  XFile? _webImage;    // used on web

  bool _loading = false;
  double? _lat, _lng;

  final _categories = ['Road Work', 'Metro', 'Traffic Block', 'Other'];

  // ---------------- Image Picking ----------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    if (kIsWeb) {
      setState(() => _webImage = x);
    } else {
      setState(() => _image = File(x.path));
    }
  }

  // ---------------- Location ----------------
  Future<void> _getLocation() async {
    final pos = await LocationService().getCurrentLocation();
    if (pos != null) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _loc.text =
            '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      });
    }
  }

  // ---------------- Submit ----------------
  Future<void> _submit() async {
    if (_title.text.isEmpty || _desc.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill title & description')));
      return;
    }

    setState(() => _loading = true);

    try {
      final fs = FirestoreService();
      final user = Provider.of<UserProvider>(context, listen: false).user;

      // ---- Upload image (handles both web & mobile) ----
      String? imgUrl;
      if (kIsWeb && _webImage != null) {
        final bytes = await _webImage!.readAsBytes();
        imgUrl = await fs.uploadImage(
            File(_webImage!.path),
            'reports/${DateTime.now().millisecondsSinceEpoch}.jpg');
      } else if (!kIsWeb && _image != null) {
        imgUrl = await fs.uploadImage(_image!,
            'reports/${DateTime.now().millisecondsSinceEpoch}.jpg');
      }

      await fs.addReport({
        'userId': user?.uid,
        'userName': user?.name,
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'category': _category,
        'location': _loc.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
        'imageUrl': imgUrl,
        'status': 'Pending',
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report submitted successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Problem')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(
                controller: _title, label: 'Title', icon: Icons.title),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                  labelText: 'Category', border: OutlineInputBorder()),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),

            const SizedBox(height: 10),

            CustomTextField(
                controller: _desc,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3),
            CustomTextField(
                controller: _loc,
                label: 'Location',
                icon: Icons.location_on),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.my_location),
                    label: const Text('Get Location'),
                    onPressed: _getLocation,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.image),
                    label: Text(
                      (_webImage != null || _image != null)
                          ? 'Change Image'
                          : 'Pick Image',
                    ),
                    onPressed: _pickImage,
                  ),
                ),
              ],
            ),

            // ---- Image preview (web + mobile) ----
            if (kIsWeb && _webImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.network(_webImage!.path, height: 150),
              )
            else if (!kIsWeb && _image != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.file(_image!, height: 150),
              ),

            const SizedBox(height: 20),

            CustomButton(
              text: 'Submit Report',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}