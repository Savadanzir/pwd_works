import 'package:flutter/material.dart';

/// Reusable Road Maintenance logo widget.
///
/// The logo is a wide rectangular graphic (icon + ROAD MAINTENANCE WORK text),
/// so it's shown as-is with an optional soft glow behind it.
///
/// Usage:
///   const RoadLogo(width: 220),
///   const RoadLogo(width: 260, glowColor: Color(0xFFF59E0B)),
class RoadLogo extends StatelessWidget {
  final double width;
  final Color? glowColor;
  final bool showGlow;

  const RoadLogo({
    super.key,
    this.width = 220,
    this.glowColor,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = glowColor ?? const Color(0xFFF59E0B);
    final height = width * 0.75; // approximate aspect ratio

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'lib/assets/images/road_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}