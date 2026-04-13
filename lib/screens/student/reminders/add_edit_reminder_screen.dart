import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/notification_service.dart';
import '../../../models/reminder_model.dart';
import '../../../widgets/common/app_button.dart';
import 'package:vidyasetu/services/localization_service.dart';

class AddEditReminderScreen extends StatefulWidget {
  const AddEditReminderScreen({super.key});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FirestoreService _firestore = FirestoreService();

  String _selectedType = 'exam';
  String _selectedPriority = 'medium';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _popupNotification = true;
  bool _voiceNotification = false;
  String _repeatType = 'once';
  List<int> _reminderMinutesBefore = [0];
  bool _saving = false;

  ReminderModel? _editingReminder;
  bool _isEditing = false;
  String? _forStudentId;

  final _typeMap = {
    'exam': 'Exam',
    'assignment': 'Assignment',
    'quiz': 'Quiz',
    'studySession': 'Study Session',
    'custom': 'Custom',
  };
  final _priorities = ['high', 'medium', 'low'];
  final _repeatOptions = ['once', 'daily', 'weekly'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && !_isEditing) {
      if (args is Map<String, dynamic>) {
        if (args.containsKey('studentId')) {
          _forStudentId = args['studentId'];
        }
        if (args.containsKey('reminder')) {
          _editingReminder = args['reminder'];
        }
      } else if (args is ReminderModel) {
        _editingReminder = args;
      }
      
      if (_editingReminder != null) {
        _isEditing = true;
        _titleController.text = _editingReminder!.title;
        _descriptionController.text = _editingReminder!.description ?? '';
        _selectedType = _editingReminder!.type.name;
        _selectedPriority = _editingReminder!.priority.name;
        _selectedDate = _editingReminder!.dateTime;
        _selectedTime = TimeOfDay(hour: _editingReminder!.dateTime.hour, minute: _editingReminder!.dateTime.minute);
        _popupNotification = _editingReminder!.popupNotification;
        _voiceNotification = _editingReminder!.voiceNotification;
        _repeatType = _editingReminder!.repeatType;
        _reminderMinutesBefore = List<int>.from(_editingReminder!.reminderMinutesBefore);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return AppTheme.errorRed;
      case 'medium': return AppTheme.warningAmber;
      case 'low': return AppTheme.successGreen;
      default: return AppTheme.warningAmber;
    }
  }

  Future<void> _saveReminder() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_enter_a_title')), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    setState(() => _saving = true);
    final currentUserUid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (currentUserUid == null) return;
    
    // Target uid is the student if we're creating for a student, otherwise ourselves
    final targetUid = _forStudentId ?? currentUserUid;

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final newId = _editingReminder?.id ?? FirebaseFirestore.instance.collection('_').doc().id;

    final data = ReminderModel(
      id: newId,
      userId: targetUid,
      title: _titleController.text.trim(),
      type: ReminderType.values.firstWhere((e) => e.name == _selectedType,
          orElse: () => ReminderType.custom),
      description: _descriptionController.text.trim(),
      dateTime: dateTime,
      priority: ReminderPriority.values.firstWhere((e) => e.name == _selectedPriority,
          orElse: () => ReminderPriority.medium),
      status: _editingReminder?.status ?? ReminderStatus.pending,
      popupNotification: _popupNotification,
      voiceNotification: _voiceNotification,
      repeatType: _repeatType,
      reminderMinutesBefore: _reminderMinutesBefore,
    ).toMap();

    try {
      if (_isEditing && _editingReminder != null) {
        await _firestore.updateReminder(targetUid, _editingReminder!.id, data);
      } else {
        await _firestore.addReminder(targetUid, data);
      }
      if (mounted) Navigator.pop(context);

      // Schedule local notifications
      if (_popupNotification) {
        final notifService = NotificationService();
        await notifService.scheduleReminderAlarm(
          reminderId: newId,
          title: _titleController.text.trim(),
          body: _descriptionController.text.trim().isEmpty
              ? 'Reminder for ${_titleController.text.trim()}'
              : _descriptionController.text.trim(),
          eventTime: dateTime,
          reminderMinutesBefore: _reminderMinutesBefore,
          repeatType: _repeatType,
          priority: _selectedPriority,
          voiceNotification: _voiceNotification,
        );

        // Schedule motivational pre-notifications for exams, assignments, quizzes
        if (['exam', 'assignment', 'quiz'].contains(_selectedType)) {
          await notifService.schedulePreNotifications(
            reminderId: newId,
            title: _titleController.text.trim(),
            eventTime: dateTime,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text(_forStudentId != null ? 'Add Reminder for Student' : (_isEditing ? 'Edit Reminder' : 'Add Reminder')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Builder(
          builder: (context) {
            final dateTime = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );
            final minutesUntil = dateTime.difference(DateTime.now()).inMinutes;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            _buildLabel(context.tr('title')),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(hintText: context.tr('enter_reminder_title')),
            ),
            SizedBox(height: 20),

            _buildLabel(context.tr('type')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _typeMap.entries.map((entry) {
                final isSelected = _selectedType == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedType = entry.key),
                  selectedColor: AppTheme.primaryNavy,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
                      _buildLabel(context.tr('date')),
                      GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _selectedDate = date);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                              const SizedBox(width: 10),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(context.tr('time')),
                      GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (time != null) setState(() => _selectedTime = time);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 18, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                              const SizedBox(width: 10),
                              Text(
                                _selectedTime.format(context),
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15),
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
            SizedBox(height: 20),

            _buildLabel(context.tr('priority')),
            Row(
              children: _priorities.map((p) {
                final isSelected = _selectedPriority == p;
                final color = _getPriorityColor(p);
                final label = p[0].toUpperCase() + p.substring(1);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: p != 'low' ? 10 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPriority = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.15) : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : AppTheme.divider,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

            _buildLabel(context.tr('description')),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(hintText: context.tr('add_details_about_this_reminde')),
            ),
            SizedBox(height: 20),

            // Notification settings
            _buildLabel(context.tr('notifications_1')),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardBoxShadow,
              ),
              child: Column(
                children: [
                  _buildToggle(context.tr('popup_notification'), _popupNotification, (v) {
                    setState(() {
                      _popupNotification = v;
                      if (!v) _voiceNotification = false;
                    });
                  }),
                  Divider(height: 24),
                  Opacity(
                    opacity: _popupNotification ? 1.0 : 0.5,
                    child: IgnorePointer(
                      ignoring: !_popupNotification,
                      child: _buildToggle(context.tr('voice_notification'), _voiceNotification, (v) {
                        setState(() => _voiceNotification = v);
                      }),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Remind Before — alarm-like
            _buildLabel(context.tr('remind_before')),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardBoxShadow,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _remindChip(0, 'At exact time', minutesUntil),
                  _remindChip(5, '5 min', minutesUntil),
                  _remindChip(15, '15 min', minutesUntil),
                  _remindChip(30, '30 min', minutesUntil),
                  _remindChip(60, '1 hour', minutesUntil),
                  _remindChip(1440, '1 day', minutesUntil),
                ],
              ),
            ),
            SizedBox(height: 20),

            _buildLabel(context.tr('repeat')),
            Wrap(
              spacing: 8,
              children: _repeatOptions.map((r) {
                // Do not show daily/weekly if scheduled in less than a day
                if (minutesUntil < 1440 && r != 'once') {
                  if (_repeatType == r) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _repeatType = 'once');
                    });
                  }
                  return const SizedBox.shrink();
                }

                final isSelected = _repeatType == r;
                final label = r[0].toUpperCase() + r.substring(1);
                return ChoiceChip(
                  label: Text(label == 'Once' ? 'One-time' : label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _repeatType = r),
                  selectedColor: AppTheme.primaryNavy,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            AppButton(
              text: _saving ? 'Saving...' : (_isEditing ? 'Update Reminder' : 'Save Reminder'),
              onPressed: _saving ? () {} : _saveReminder,
              icon: Icons.check_rounded,
            ),
            const SizedBox(height: 20),
          ],
        );
      }),
    ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accentBlue,
        ),
      ],
    );
  }

  Widget _remindChip(int minutes, String label, int minutesUntil) {
    if (minutes > minutesUntil) {
      if (_reminderMinutesBefore.contains(minutes)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {
            _reminderMinutesBefore.remove(minutes);
            if (_reminderMinutesBefore.isEmpty) _reminderMinutesBefore = [0];
          });
        });
      }
      return const SizedBox.shrink();
    }

    final isSelected = _reminderMinutesBefore.contains(minutes);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _reminderMinutesBefore.add(minutes);
          } else {
            _reminderMinutesBefore.remove(minutes);
            if (_reminderMinutesBefore.isEmpty) _reminderMinutesBefore = [0];
          }
        });
      },
      selectedColor: AppTheme.accentBlue.withOpacity(0.15),
      checkmarkColor: AppTheme.accentBlue,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.accentBlue : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      avatar: Icon(
        isSelected ? Icons.alarm_on_rounded : Icons.alarm_rounded,
        size: 16,
        color: isSelected ? AppTheme.accentBlue : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
    );
  }
}

