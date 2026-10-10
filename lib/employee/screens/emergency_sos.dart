import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/emergency_provider.dart';

class EmergencySOS extends StatelessWidget {
  const EmergencySOS({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmergencyProvider>(context);

    // Show snackbar when a new error appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.lastError != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(provider.lastError!),
            backgroundColor: const Color(0xFFB91C1C),
            behavior: SnackBarBehavior.floating));
        provider.clearError();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Emergency SOS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
              center: Alignment(-0.4, -0.6),
              radius: 1.5,
              colors: [Color(0xFF3A0A0A), Color(0xFF160404), Color(0xFF04060F)],
              stops: [0.0, 0.55, 1.0]),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              // SOS Button
              GestureDetector(
                onTap: provider.dialing ? null : () => provider.dial('112'),
                child: Container(
                  height: 130,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFDC2626).withOpacity(0.65),
                            blurRadius: 40,
                            offset: const Offset(0, 16)),
                      ]),
                  child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                        provider.dialing
                            ? Icons.phone_in_talk_rounded
                            : Icons.sos_rounded,
                        color: Colors.white,
                        size: 44),
                    const SizedBox(height: 8),
                    Text(
                        provider.dialing
                            ? 'DIALING...'
                            : 'SOS — TAP TO CALL 112',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2)),
                  ])),
                ),
              ),
              const SizedBox(height: 22),
              Text('QUICK DIAL',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5)),
              const SizedBox(height: 12),
              ...EmergencyProvider.contacts.map((c) => _ContactCard(
                  contact: c, onCall: () => provider.dial(c.number))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onCall;
  const _ContactCard({required this.contact, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.10),
                  contact.color.withOpacity(0.10)
                ]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25), width: 1.2)),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: contact.color.withOpacity(0.20),
                      border: Border.all(
                          color: contact.color.withOpacity(0.55), width: 1.2)),
                  child: Text(contact.emoji,
                      style: const TextStyle(fontSize: 20))),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(contact.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(contact.number,
                        style: TextStyle(
                            color: contact.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                  ])),
              GestureDetector(
                  onTap: onCall,
                  child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            contact.color,
                            contact.color.withOpacity(0.65)
                          ]),
                          boxShadow: [
                            BoxShadow(
                                color: contact.color.withOpacity(0.55),
                                blurRadius: 14)
                          ]),
                      child: const Icon(Icons.call_rounded,
                          color: Colors.white, size: 18))),
            ]),
          ),
        ),
      ),
    );
  }
}
