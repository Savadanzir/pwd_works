import 'dart:ui';
import 'package:flutter/material.dart';

class ManageFines extends StatelessWidget {
  const ManageFines({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Fines & Challans',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [Color(0xFF320A0A), Color(0xFF140404), Color(0xFF04060F)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Text(
              'Fines management coming soon...',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}