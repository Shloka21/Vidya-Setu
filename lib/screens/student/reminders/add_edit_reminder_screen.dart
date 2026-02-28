import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_button.dart';

class AddEditReminderScreen extends StatefulWidget {
  const AddEditReminderScreen({super.key});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'Exam';
  String _selectedSubject = 'Mathematics';
  String _selectedPriority = 'Medium';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _popupNotification = true;
  bool _voiceNotification = false;
  String _repeatType = 'One-time';

  final _types = ['Exam', 'Assignment', 'Quiz', 'Study Session', 'Custom'];
  final _subjects = ['Mathematics', 'Physics', 'Chemistry', 'English', 'Biology'];
  final _priorities = ['High', 'Medium', 'Low'];
  final _repeatOptions = ['One-time', 'Daily', 'Weekly'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High': return AppTheme.errorRed;
      case 'Medium': return AppTheme.warningAmber;
      case 'Low': return AppTheme.successGreen;
      default: return AppTheme.warningAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Add Reminder'),
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
              children: _types.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedType = type),
                  selectedColor: AppTheme.primaryNavy,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _buildLabel('Subject'),
            DropdownButtonFormField<String>(
              initialValue: _selectedSubject,
              decoration: const InputDecoration(),
              items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _selectedSubject = v!),
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
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 18, color: AppTheme.textLight),
                              const SizedBox(width: 10),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
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
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 18, color: AppTheme.textLight),
                              const SizedBox(width: 10),
                              Text(
                                _selectedTime.format(context),
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 15),
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
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: p != 'Low' ? 10 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPriority = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.15) : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : AppTheme.divider,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            p,
                            style: TextStyle(
                              color: isSelected ? color : AppTheme.textSecondary,
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

            _buildLabel('Repeat'),
            Wrap(
              spacing: 8,
              children: _repeatOptions.map((r) {
                final isSelected = _repeatType == r;
                return ChoiceChip(
                  label: Text(r),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _repeatType = r),
                  selectedColor: AppTheme.primaryNavy,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            AppButton(
              text: 'Save Reminder',
              onPressed: () => Navigator.pop(context),
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
          color: AppTheme.textPrimary,
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
        Text(label, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.accentBlue,
        ),
      ],
    );
  }
}
