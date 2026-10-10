import 'package:flutter/material.dart';

class NotificationItem {
  final String title;
  final String body;
  final String time;
  final String emoji;
  final Color color;
  final bool unread;

  const NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.emoji,
    required this.color,
    this.unread = false,
  });
}

class NotificationsProvider extends ChangeNotifier {
  final List<NotificationItem> _notes = const [
    NotificationItem(
      title: 'New task assigned',
      body: 'Pothole repair on MG Road',
      time: '5 min ago',
      emoji: '🛠️',
      color: Color(0xFFF59E0B),
      unread: true,
    ),
    NotificationItem(
      title: 'Task marked urgent',
      body: 'Silk Board signal failure',
      time: '20 min ago',
      emoji: '🚨',
      color: Color(0xFFEF4444),
      unread: true,
    ),
    NotificationItem(
      title: 'Admin feedback',
      body: 'Great work on the guard rail install',
      time: '1 hr ago',
      emoji: '👍',
      color: Color(0xFF10B981),
    ),
    NotificationItem(
      title: 'Schedule update',
      body: 'Metro Line 3 inspection moved to 3 PM',
      time: '4 hrs ago',
      emoji: '📅',
      color: Color(0xFF3B82F6),
    ),
    NotificationItem(
      title: 'Reminder',
      body: "Submit today's work evidence by 7 PM",
      time: '6 hrs ago',
      emoji: '⏰',
      color: Color(0xFF8B5CF6),
    ),
  ];

  List<NotificationItem> get notes => _notes;
}