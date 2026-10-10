import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/work_update_provider.dart';
import '../models/work_model.dart';
import 'repair_evidence.dart';

class UpdateWork extends StatefulWidget {
  final WorkModel work;
  const UpdateWork({super.key, required this.work});
  @override
  State<UpdateWork> createState() => _UpdateWorkState();
}

class _UpdateWorkState extends State<UpdateWork> {
  String _status = 'Assigned';
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = widget.work.status;
    if (widget.work.workNote != null) _note.text = widget.work.workNote!;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final prov = Provider.of<WorkUpdateProvider>(context, listen: false);
    final err = await prov.updateWork(
      reportId: widget.work.id,
      status: _status,
      workNote: _note.text.trim(),
    );
    if (err == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Work updated successfully'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $err'),
          backgroundColor: const Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<WorkUpdateProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Update Work',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
            gradient: RadialGradient(
                center: Alignment(-0.4, -0.6),
                radius: 1.5,
                colors: [
              Color(0xFF2E1E06),
              Color(0xFF140D02),
              Color(0xFF04060F)
            ],
                stops: [
              0.0,
              0.55,
              1.0
            ])),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.white.withOpacity(0.10),
                        const Color(0xFFF59E0B).withOpacity(0.10)
                      ]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1.2)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(widget.work.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 20),
                        // Status dropdown
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.28),
                                      width: 1.2)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                    value: _status,
                                    isExpanded: true,
                                    dropdownColor: const Color(0xFF1B2B54),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 15),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'Assigned',
                                          child: Text('Assigned')),
                                      DropdownMenuItem(
                                          value: 'In Progress',
                                          child: Text('In Progress')),
                                      DropdownMenuItem(
                                          value: 'Completed',
                                          child: Text('Completed')),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _status = v!)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Work note field
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.28),
                                      width: 1.2)),
                              child: TextField(
                                  controller: _note,
                                  maxLines: 4,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14.5),
                                  cursorColor: const Color(0xFFF59E0B),
                                  decoration: InputDecoration(
                                      labelText: 'Work Note / Remarks',
                                      labelStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.60),
                                          fontSize: 13.5),
                                      floatingLabelStyle: const TextStyle(
                                          color: Color(0xFFF59E0B),
                                          fontSize: 13),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.all(16))),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Save button
                        SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                                icon: prov.loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Icon(Icons.save),
                                label: const Text('Save Update',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 0),
                                onPressed: prov.loading ? null : _save)),
                        const SizedBox(height: 12),
                        // Evidence button
                        SizedBox(
                          height: 54,
                          child: OutlinedButton.icon(
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text('Upload Repair Evidence',
                                  style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                      color: Color(0xFFF59E0B), width: 1.4),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16))),
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => RepairEvidence(
                                          reportId: widget.work.id)))),
                        ),
                      ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
