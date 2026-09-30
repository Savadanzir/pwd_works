import 'package:flutter/material.dart';
import 'update_work.dart';

class WorkDetails extends StatelessWidget {
  final String reportId;
  final Map<String, dynamic> data;
  const WorkDetails(
      {super.key, required this.reportId, required this.data});

  @override  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Work Details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['imageUrl'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(data['imageUrl'],
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover),
                  ),
                const SizedBox(height: 16),
                _tile('Title', data['title'] ?? '-'),
                _tile('Description', data['description'] ?? '-'),
                _tile('Location', data['location'] ?? '-'),
                _tile('Status', data['status'] ?? '-'),
                if (data['workNote'] != null)
                  _tile('Your Note', data['workNote']),
                if (data['completionImage'] != null) ...[
                  const SizedBox(height: 10),
                  const Text('Completion Image',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(data['completionImage'],
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Update Work'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UpdateWork(reportId: reportId, data: data),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 120,
                child: Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}