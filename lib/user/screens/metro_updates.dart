import 'dart:io';
import 'dart:typed_data'; // Required for Uint8List
import 'package:flutter/foundation.dart' show kIsWeb; // Required for web check
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Import your provider here (adjust the path if needed)
import '../providers/user_provider.dart'; 

class MetroUpdates extends StatefulWidget {
  const MetroUpdates({super.key});

  @override
  State<MetroUpdates> createState() => _MetroUpdatesState();
}

class _MetroUpdatesState extends State<MetroUpdates> {
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  // 🔴 Changed from File to Uint8List to support Web
  Uint8List? _imageBytes;
  
  // This variable controls the loading state of the button
  bool _isLoading = false; 

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Compress image to speed up upload
      );
      if (pickedFile != null) {
        // Read the image as bytes (works on Web and Mobile)
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _submitUpdate() async {
    // 1. Validation
    if (_imageBytes == null && _descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a photo or write a description.')),
      );
      return;
    }

    // 2. Start loading
    setState(() => _isLoading = true);

    try {
      // ---------------------------------------------------------
      // TODO: REPLACE THIS SIMULATED DELAY WITH YOUR ACTUAL BACKEND UPLOAD
      // For web, you will likely need to upload the Uint8List bytes.
      // Example: await Provider.of<MetroProvider>(context, listen: false)
      //    .submitUpdate(imageBytes: _imageBytes, description: _descController.text);
      // ---------------------------------------------------------
      
      await Future.delayed(const Duration(seconds: 2)); // Simulated network delay

      // 3. Success State
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Update shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear the form
        setState(() {
          _imageBytes = null;
          _descController.clear();
        });
      }
    } catch (error) {
      // 4. Error State (If the backend fails, this catches it)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share update: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 5. Stop loading (This runs NO MATTER WHAT)
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF04060F);
    const cardColor = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Metro Updates',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 📸 UPLOAD CARD
            // ==========================================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Share a Metro Update',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Image Preview Area
                  if (_imageBytes != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory( // ✅ Uses Image.memory to work on Web & Mobile
                        _imageBytes!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: const Icon(Icons.image_outlined, color: Colors.white38, size: 50),
                    ),
                  const SizedBox(height: 16),

                  // Image Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          label: const Text('Take Photo', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, color: Colors.white, size: 18),
                          label: const Text('Gallery', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Text Input
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Describe what you see...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      filled: true,
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ==========================================
                  // 🚀 SUBMIT BUTTON
                  // ==========================================
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitUpdate, 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        disabledBackgroundColor: Colors.blueAccent.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Share Update',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ==========================================
            // 📋 LIVE UPDATES LIST
            // ==========================================
            Row(
              children: [
                Icon(Icons.format_list_bulleted, color: Colors.white.withOpacity(0.7), size: 20),
                const SizedBox(width: 8),
                Text(
                  'LIVE UPDATES',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.mark_email_unread_outlined, color: Colors.blueAccent, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No metro updates yet.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to share!',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}