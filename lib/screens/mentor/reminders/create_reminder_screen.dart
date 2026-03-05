import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';

class CreateReminderScreen extends StatefulWidget {
  const CreateReminderScreen({super.key});

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  String? _selectedStudent;
  String _priority = 'Normal';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  final _students = [
    'Ananya Kumar',
    'Raj Patel',
    'Priya Singh',
    'Vikram Sharma',
    'Neha Gupta',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(title: const Text('Create Reminder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Select Student'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStudent,
                  hint: Text('Choose a student',
                      style: TextStyle(color: AppTheme.textLight)),
                  isExpanded: true,
                  items: _students
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStudent = v),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _label('Title'),
            _buildField(_titleController, 'e.g., Complete Chapter 5'),
            const SizedBox(height: 16),

            _label('Message'),
            _buildField(
              _messageController,
              'Detailed instructions for the student...',
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            _label('Priority'),
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
                        color: selected ? color : AppTheme.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (_) => setState(() => _priority = p),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _label('Due Date'),
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
                    Icon(Icons.calendar_today_rounded,
                        color: AppTheme.accentBlue, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            AppButton(
              text: 'Send Reminder',
              onPressed: () {
                if (_selectedStudent == null ||
                    _titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Please fill in student and title')),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Reminder sent successfully!'),
                    backgroundColor: AppTheme.successGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
                Navigator.pop(context);
              },
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
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildField(TextEditingController controller, String hint,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textLight),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppTheme.accentBlue, width: 2),
        ),
      ),
    );
  }
}
