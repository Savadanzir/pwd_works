import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageAuthorities extends StatefulWidget {
  const ManageAuthorities({super.key});

  @override
  State<ManageAuthorities> createState() => _ManageAuthoritiesState();
}

class _ManageAuthoritiesState extends State<ManageAuthorities> {
  bool _loading = true;
  List<QueryDocumentSnapshot> _authorities = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap =
          await FirebaseFirestore.instance.collection('authorities').get();

      if (mounted) {
        setState(() {
          _authorities = snap.docs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('❌ Failed to load: $e', Colors.redAccent);
      }
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

  Future<void> _showAddAuthorityDialog() async {
    final emojiCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    bool submitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> save() async {
              if (nameCtrl.text.trim().isEmpty ||
                  roleCtrl.text.trim().isEmpty ||
                  phoneCtrl.text.trim().isEmpty) {
                _snack('Please fill Name, Role & Phone', Colors.orangeAccent);
                return;
              }

              setDialogState(() => submitting = true);

              try {
                await FirebaseFirestore.instance.collection('authorities').add({
                  'emoji': emojiCtrl.text.trim().isEmpty
                      ? '👤'
                      : emojiCtrl.text.trim(),
                  'name': nameCtrl.text.trim(),
                  'role': roleCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'createdAt': Timestamp.now(),
                });

                if (!mounted) return;
                Navigator.pop(ctx);
                _snack('✅ Authority saved', const Color(0xFF10B981));
                _load(); // Reload the list
              } catch (e) {
                if (!mounted) return;
                setDialogState(() => submitting = false);
                _snack('❌ Save failed: $e', Colors.redAccent);
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0B1730),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('Add Authority',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(emojiCtrl, 'Emoji (Optional)'),
                    const SizedBox(height: 14),
                    _field(nameCtrl, 'Name'),
                    const SizedBox(height: 14),
                    _field(roleCtrl, 'Role'),
                    const SizedBox(height: 14),
                    _field(phoneCtrl, 'Phone'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: submitting ? null : save,
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Color(0xFFF97316), strokeWidth: 2),
                        )
                      : const Text('Save',
                          style: TextStyle(
                              color: Color(0xFFF97316),
                              fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _field(TextEditingController c, String hint) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: TextField(
          controller: c,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
    );
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
        title: const Text('Manage Authorities',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAuthorityDialog,
        backgroundColor: const Color(0xFFF97316),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Authority',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [Color(0xFF2A1505), Color(0xFF130902), Color(0xFF04060F)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _authorities.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      color: const Color(0xFFF97316),
                      backgroundColor: const Color(0xFF0B1730),
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _authorities.length,
                        itemBuilder: (context, i) =>
                            _authorityCard(_authorities[i]),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF97316).withOpacity(0.15),
                border: Border.all(
                    color: const Color(0xFFF97316).withOpacity(0.5),
                    width: 1.5),
              ),
              child: const Icon(Icons.support_agent_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            const Text('No authorities added yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Tap "+ Add Authority" to create the first contact.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55), fontSize: 12.5),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _authorityCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final emoji = data['emoji'] ?? '👤';
    final name = data['name'] ?? 'Name';
    final role = data['role'] ?? 'Role';
    final phone = data['phone'] ?? '';

    Color accentColor;
    if (role.toLowerCase().contains('emergency') ||
        role.toLowerCase().contains('police')) {
      accentColor = const Color(0xFFEF4444);
    } else if (role.toLowerCase().contains('traffic')) {
      accentColor = const Color(0xFFF59E0B);
    } else if (role.toLowerCase().contains('safety')) {
      accentColor = const Color(0xFF10B981);
    } else {
      accentColor = const Color(0xFF3B82F6);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.10),
                  accentColor.withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.22),
                    border: Border.all(
                        color: accentColor.withOpacity(0.6), width: 1.2),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(role,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(phone,
                          style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
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
