import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import 'my_reports.dart';
import 'user_login.dart';

class UserProfile extends StatelessWidget {
  final bool isEmbedded;
  const UserProfile({super.key, this.isEmbedded = false});

  void _showEditDialog(BuildContext context, String currentName, String currentPhone) {
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.person, color: Color(0xFF38BDF8)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.phone, color: Color(0xFF38BDF8)),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              final newPhone = phoneCtrl.text.trim();
              if (newName.isNotEmpty) {
                await Provider.of<UserProvider>(context, listen: false)
                    .updateProfile(name: newName, phone: newPhone);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<UserProvider>(context);
    final u = prov.user;
    final fbUser = FirebaseAuth.instance.currentUser;

    // Use UserModel details, falling back to Firebase Auth if UserModel is still loading
    final displayName = (u?.name != null && u!.name.isNotEmpty)
        ? u.name
        : (fbUser?.displayName?.isNotEmpty == true
            ? fbUser!.displayName!
            : (fbUser?.email?.split('@').first ?? 'Citizen'));

    final displayEmail = (u?.email != null && u!.email.isNotEmpty)
        ? u.email
        : (fbUser?.email ?? 'Not provided');

    final displayPhone = (u?.phone != null && u!.phone.isNotEmpty)
        ? u.phone
        : (fbUser?.phoneNumber?.isNotEmpty == true
            ? fbUser!.phoneNumber!
            : 'Not set');

    final body = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, isEmbedded ? 8 : 20, 20, isEmbedded ? 140 : 30),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // Glowing Profile Avatar
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF6366F1)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.45),
                    blurRadius: 28,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: const Color(0xFF0B1730),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF38BDF8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // User Name
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),

          // User Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
            ),
            child: const Text(
              'Public Citizen',
              style: TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Profile Info Cards
          _glassCard(
            child: Column(
              children: [
                _infoTile(
                  icon: Icons.person_rounded,
                  color: const Color(0xFF38BDF8),
                  label: 'Full Name',
                  value: displayName,
                  onEdit: () => _showEditDialog(context, displayName, displayPhone),
                ),
                _divider(),
                _infoTile(
                  icon: Icons.email_rounded,
                  color: const Color(0xFFA855F7),
                  label: 'Email',
                  value: displayEmail,
                ),
                _divider(),
                _infoTile(
                  icon: Icons.phone_rounded,
                  color: const Color(0xFF10B981),
                  label: 'Phone',
                  value: displayPhone,
                  onEdit: () => _showEditDialog(context, displayName, displayPhone),
                ),
                _divider(),
                _infoTile(
                  icon: Icons.shield_rounded,
                  color: const Color(0xFFF59E0B),
                  label: 'Account Status',
                  value: 'Verified Citizen',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // "My Reports" shortcut
          _glassCard(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment_rounded, color: Color(0xFF60A5FA), size: 22),
              ),
              title: const Text('My Reported Issues', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('View history and status of your reports', style: TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MyReports()));
              },
            ),
          ),

          const SizedBox(height: 24),

          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
                shadowColor: const Color(0xFFDC2626).withOpacity(0.5),
              ),
              onPressed: () async {
                await prov.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const UserLogin()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );

    if (isEmbedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: body,
    );
  }

  Widget _glassCard({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.16), width: 1.2),
            ),
            child: child,
          ),
        ),
      );

  Widget _infoTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white54),
                onPressed: onEdit,
                splashRadius: 18,
              ),
          ],
        ),
      );

  Widget _divider() => Divider(height: 1, color: Colors.white.withOpacity(0.08));
}
