import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';
import 'package:vidyasetu/services/localization_service.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final FirestoreService _firestore = FirestoreService();
  String? _selectedStudentId;
  String _priority = 'Normal';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final students = await _firestore.getConnectedStudents(uid);
      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendReminder() async {
    if (_selectedStudentId == null || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_select_a_student_and_pr'))),
      );
      return;
    }

    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) return;

    final selectedStudentName = _students.firstWhere((s) => s['uid'] == _selectedStudentId)['name'] as String? ?? 'Student';
    final reminderId = FirebaseFirestore.instance.collection('_').doc().id;

    try {
      await _firestore.addReminder(_selectedStudentId!, {
        'id': reminderId,
        'title': _titleController.text.trim(),
        'description': _messageController.text.trim(),
        'dateTime': Timestamp.fromDate(_dueDate),
        'priority': _priority,
        'type': 'mentor_assigned',
        'isCompleted': false,
        'mentorId': uid,
        'studentId': _selectedStudentId,
        'studentName': selectedStudentName,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('reminder_sent_successfully')),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error_sending_reminder')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('create_reminder'))),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(context.tr('select_student')),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStudentId,
                        hint: Text(context.tr('choose_a_student'),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                        isExpanded: true,
                        items: _students
                            .map((s) => DropdownMenuItem<String>(value: s['uid'], child: Text(s['name'] as String? ?? 'Unknown')))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedStudentId = v),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  _label(context.tr('title')),
                  _buildField(_titleController, 'e.g., Complete Chapter 5'),
                  SizedBox(height: 16),

                  _label(context.tr('message')),
                  _buildField(
                    _messageController,
                    'Detailed instructions for the student...',
                    maxLines: 4,
                  ),
                  SizedBox(height: 20),

                  _label(context.tr('priority')),
                  Row(
                    children: ['Low', 'Normal', 'High'].map((p) {
                      final selected = p == _priority;
                      final color = p == 'High'
                          ? AppTheme.errorRed
                          : p == 'Normal'
                              ? AppTheme.accentBlue
                              : AppTheme.successGreen;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(p),
                            selected: selected,
                            selectedColor: color.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: selected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (_) => setState(() => _priority = p),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),

                  _label(context.tr('due_date')),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                    child: AppCard(
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, color: AppTheme.accentBlue, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                          Spacer(),
                          Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),

                  AppButton(
                    text: context.tr('send_reminder'),
                    onPressed: _sendReminder,
                    icon: Icons.send_rounded,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.accentBlue, width: 2),
        ),
      ),
    );
  }
}
