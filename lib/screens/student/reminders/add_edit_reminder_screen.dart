import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/notification_service.dart';
import '../../../models/reminder_model.dart';
import '../../../widgets/common/app_button.dart';

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
  List<int> _reminderMinutesBefore = [60];
  bool _saving = false;

  ReminderModel? _editingReminder;
  bool _isEditing = false;

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
    if (args is ReminderModel && !_isEditing) {
      _editingReminder = args;
      _isEditing = true;
      _titleController.text = args.title;
      _descriptionController.text = args.description ?? '';
      _selectedType = args.type.name;
      _selectedPriority = args.priority.name;
      _selectedDate = args.dateTime;
      _selectedTime = TimeOfDay(hour: args.dateTime.hour, minute: args.dateTime.minute);
      _popupNotification = args.popupNotification;
      _voiceNotification = args.voiceNotification;
      _repeatType = args.repeatType;
      _reminderMinutesBefore = List<int>.from(args.reminderMinutesBefore);
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
        const SnackBar(content: Text('Please enter a title'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }

    setState(() => _saving = true);
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) return;

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
      userId: uid,
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
        await _firestore.updateReminder(uid, _editingReminder!.id, data);
      } else {
        await _firestore.addReminder(uid, data);
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
        );
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
        title: Text(_isEditing ? 'Edit Reminder' : 'Add Reminder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Title'),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Enter reminder title'),
            ),
            const SizedBox(height: 20),

            _buildLabel('Type'),
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
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Date'),
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Time'),
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
            const SizedBox(height: 20),

            _buildLabel('Priority'),
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
            const SizedBox(height: 20),

            _buildLabel('Description'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Add details about this reminder'),
            ),
            const SizedBox(height: 20),

            // Notification settings
            _buildLabel('Notifications'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardBoxShadow,
              ),
              child: Column(
                children: [
                  _buildToggle('Popup Notification', _popupNotification, (v) {
                    setState(() => _popupNotification = v);
                  }),
                  const Divider(height: 24),
                  _buildToggle('Voice Notification', _voiceNotification, (v) {
                    setState(() => _voiceNotification = v);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Remind Before — alarm-like
            _buildLabel('Remind Before'),
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
                  _remindChip(5, '5 min'),
                  _remindChip(15, '15 min'),
                  _remindChip(30, '30 min'),
                  _remindChip(60, '1 hour'),
                  _remindChip(1440, '1 day'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('Repeat'),
            Wrap(
              spacing: 8,
              children: _repeatOptions.map((r) {
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
        ),
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

  Widget _remindChip(int minutes, String label) {
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
            if (_reminderMinutesBefore.isEmpty) _reminderMinutesBefore = [60];
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

