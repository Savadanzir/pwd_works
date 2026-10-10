import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContact {
  final String name;
  final String number;
  final String emoji;
  final Color color;
  const EmergencyContact({
    required this.name,
    required this.number,
    required this.emoji,
    required this.color,
  });
}

class EmergencyProvider extends ChangeNotifier {
  static const List<EmergencyContact> contacts = [
    EmergencyContact(name: 'Ambulance', number: '108', emoji: '🚑', color: Color(0xFFDC2626)),
    EmergencyContact(name: 'Police', number: '100', emoji: '🚓', color: Color(0xFF3B82F6)),
    EmergencyContact(name: 'Fire Brigade', number: '101', emoji: '🚒', color: Color(0xFFF59E0B)),
    EmergencyContact(name: 'Manager', number: '+91 98XXX 11111', emoji: '👨‍💼', color: Color(0xFFA855F7)),
    EmergencyContact(name: 'Safety Officer', number: '+91 98XXX 22222', emoji: '👮‍♀️', color: Color(0xFF10B981)),
    EmergencyContact(name: 'Emergency (All)', number: '112', emoji: '🚨', color: Color(0xFFEF4444)),
  ];

  String? _lastError;
  bool _dialing = false;

  String? get lastError => _lastError;
  bool get dialing => _dialing;

  String cleanNumber(String raw) => raw.replaceAll(RegExp(r'[^\d+]'), '');

  bool isDialable(String raw) =>
      !raw.contains('X') && cleanNumber(raw).isNotEmpty;

  Future<bool> dial(String rawNumber) async {
    _lastError = null;
    if (!isDialable(rawNumber)) {
      _lastError = 'Demo number — replace with a real one';
      notifyListeners();
      return false;
    }
    final cleaned = cleanNumber(rawNumber);
    _dialing = true;
    notifyListeners();

    final uri = Uri(scheme: 'tel', path: cleaned);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _lastError = 'Could not open dialer for $rawNumber';
        return false;
      }
      return true;
    } catch (e) {
      _lastError = 'Call failed: $e';
      return false;
    } finally {
      _dialing = false;
      notifyListeners();
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}