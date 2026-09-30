import 'package:flutter/material.dart';
import 'repair_evidence.dart';
import '../services/firestore_service.dart';

class UpdateWork extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> data;
  const UpdateWork(
      {super.key, required this.reportId, required this.data});

  @override
  State<UpdateWork> createState() => _UpdateWorkState();
}

class _UpdateWorkState extends State<UpdateWork> {
  String _status = 'Assigned';
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.data['status'] ?? 'Assigned';
    if (widget.data['workNote'] != null) {
      _note.text = widget.data['workNote'];
    }
  }

  Future<void> _save() async {
    await FirestoreService().updateReport(widget.reportId, {
      'status': _status,
      'workNote': _note.text.trim(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work updated successfully')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Work')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                      labelText: 'Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(
                        value: 'Assigned', child: Text('Assigned')),
                    DropdownMenuItem(
                        value: 'In Progress', child: Text('In Progress')),
                    DropdownMenuItem(
                        value: 'Completed', child: Text('Completed')),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _note,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Work Note / Remarks',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save Update'),
                    onPressed: _save,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Upload Repair Evidence'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              RepairEvidence(reportId: widget.reportId)),
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
}