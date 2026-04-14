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
  String _priority = 'medium';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _dueTime = const TimeOfDay(hour: 10, minute: 0);
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
    final scheduledDateTime = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );

    try {
      await _firestore.assignReminderByMentor(_selectedStudentId!, {
        'id': reminderId,
        'title': _titleController.text.trim(),
        'description': _messageController.text.trim(),
        'dateTime': Timestamp.fromDate(scheduledDateTime),
        'priority': _priority,
        'mentorId': uid,
        'mentorName': Provider.of<AuthProvider>(context, listen: false).userModel?.name ?? 'Mentor',
        'studentName': selectedStudentName,
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('reminder_assigned_successfully')),
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
                    children: ['high', 'medium', 'low'].map((p) {
                      final selected = p == _priority;
                      final color = p == 'high'
                          ? AppTheme.errorRed
                          : p == 'medium'
                              ? AppTheme.warningAmber
                              : AppTheme.successGreen;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => setState(() => _priority = p),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected ? color.withOpacity(0.1) : AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected ? color : AppTheme.divider,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  context.tr(p),
                                  style: TextStyle(
                                    color: selected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context.tr('date')),
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
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, color: AppTheme.accentBlue, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(context.tr('time')),
                            InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _dueTime,
                                );
                                if (picked != null) setState(() => _dueTime = picked);
                              },
                              child: AppCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, color: AppTheme.accentPurple, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      _dueTime.format(context),
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
