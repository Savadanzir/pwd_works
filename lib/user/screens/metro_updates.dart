import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/metro_update_provider.dart';

class MetroUpdates extends StatefulWidget {
  const MetroUpdates({super.key});
  @override
  State<MetroUpdates> createState() => _MetroUpdatesState();
}

class _MetroUpdatesState extends State<MetroUpdates> {
  final _captionCtrl = TextEditingController();
  File? _image;
  XFile? _webImage;

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 75, maxWidth: 1600);
      if (x == null) return;
      if (kIsWeb) {
        setState(() => _webImage = x);
      } else {
        setState(() => _image = File(x.path));
      }
    } catch (e) {
      _snack('Camera error: $e', error: true);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75, maxWidth: 1600);
      if (x == null) return;
      if (kIsWeb) {
        setState(() => _webImage = x);
      } else {
        setState(() => _image = File(x.path));
      }
    } catch (e) {
      _snack('Gallery error: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? const Color(0xFFB91C1C) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _post() async {
    if (_image == null && _webImage == null) {
      _snack('Please take or pick a photo first', error: true);
      return;
    }
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) {
      _snack('Please log in first', error: true);
      return;
    }
    final prov = Provider.of<MetroUpdateProvider>(context, listen: false);

    final bytes = kIsWeb && _webImage != null ? await _webImage!.readAsBytes() : null;
    final err = await prov.postUpdate(
      userId: user.uid,
      userName: user.name,
      caption: _captionCtrl.text.trim(),
      image: kIsWeb ? null : _image,
      webImageBytes: bytes,
    );
    if (err == null) {
      _captionCtrl.clear();
      setState(() {
        _image = null;
        _webImage = null;
      });
      _snack('Update posted ✅');
    } else {
      _snack('Failed: $err', error: true);
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      appBar: AppBar(
        title: const Text('Metro Updates', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [Color(0xFF0B1D3A), Color(0xFF060A1E), Color(0xFF04060F)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _composer(),
                const SizedBox(height: 22),
                _sectionLabel('Live Updates'),
                const SizedBox(height: 12),
                _feed(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _composer() => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                const Color(0xFF3B82F6).withOpacity(0.10),
              ]),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.28), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF22D3EE)]),
                      ),
                      child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Share a Metro Update',
                      style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
                  ),
                  child: _image != null || _webImage != null
                      ? (kIsWeb && _webImage != null
                          ? Image.network(_webImage!.path, fit: BoxFit.cover)
                          : Image.file(_image!, fit: BoxFit.cover))
                      : Center(
                          child: Text(
                            'No photo yet',
                            style: TextStyle(color: Colors.white.withOpacity(0.55)),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('Take Photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _takePhoto,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF22D3EE)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _pickFromGallery,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _captionCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a caption (optional)',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Consumer<MetroUpdateProvider>(
                  builder: (_, prov, __) => ElevatedButton.icon(
                    icon: prov.uploading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(prov.uploading ? 'Posting...' : 'Post Update'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: prov.uploading ? null : _post,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _sectionLabel(String text) => Row(
        children: [
          const Icon(Icons.newspaper_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      );

  Widget _feed() => Consumer<MetroUpdateProvider>(
        builder: (_, prov, __) => StreamBuilder<List<MetroUpdate>>(
          stream: prov.updatesStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator(color: Colors.white)),
              );
            }
            final docs = snap.data ?? [];
            if (docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Text('🚇', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 14),
                    Text(
                      'No metro updates yet.\nBe the first to share!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: docs.map((u) => _UpdateCard(update: u)).toList(),
            );
          },
        ),
      );
}

class _UpdateCard extends StatelessWidget {
  final MetroUpdate update;
  const _UpdateCard({required this.update});

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = update.createdAt != null ? _timeAgo(update.createdAt!.toDate()) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.09),
                const Color(0xFF3B82F6).withOpacity(0.08),
              ]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (update.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.network(update.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              update.userName,
                              style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(timeStr, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11.5)),
                        ],
                      ),
                      if (update.caption.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          update.caption,
                          style: TextStyle(color: Colors.white.withOpacity(0.90), fontSize: 13.5),
                        ),
                      ],
                    ],
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