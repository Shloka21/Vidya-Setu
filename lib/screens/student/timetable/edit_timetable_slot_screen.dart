import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_card.dart';

class EditTimetableSlotScreen extends StatefulWidget {
  const EditTimetableSlotScreen({super.key});

  @override
  State<EditTimetableSlotScreen> createState() => _EditTimetableSlotScreenState();
}

class _EditTimetableSlotScreenState extends State<EditTimetableSlotScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Data
  String? _selectedSubject;
  final TextEditingController _topicController = TextEditingController();
  int _selectedDay = 1; // Mon
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  Color _selectedColor = AppTheme.accentBlue;

  final List<String> _subjects = ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'English', 'History'];
  final List<Color> _colors = [
    AppTheme.accentBlue,
    AppTheme.accentPurple,
    AppTheme.successGreen,
    AppTheme.warningAmber,
    AppTheme.errorRed,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  void dispose() {
    _topicController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Edit Slot', style: Theme.of(context).textTheme.headlineSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
            onPressed: () {
              // Delete confirmation
              _showDeleteConfirmation();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubjectDropdown(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _topicController,
                label: 'Topic / Chapter',
                hint: 'e.g. Integration',
                icon: Icons.topic_outlined,
              ),
              const SizedBox(height: 16),
              _buildDaySelector(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTimePicker(isStart: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimePicker(isStart: false)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _locationController,
                label: 'Location (Optional)',
                hint: 'e.g. Room 101 or Online',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              _buildColorPicker(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Add any specific instructions...',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: ElevatedButton(
          onPressed: _saveSlot,
          child: const Text('Save Changes'),
        ),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedSubject,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.book_outlined, color: _selectedColor),
            fillColor: AppTheme.surface,
          ),
          items: _subjects.map((subject) {
            return DropdownMenuItem(
              value: subject,
              child: Text(subject),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedSubject = val;
            });
          },
          validator: (val) => val == null ? 'Please select a subject' : null,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines == 1 ? Icon(icon, color: AppTheme.textLight) : null,
            fillColor: AppTheme.surface,
            alignLabelWithHint: maxLines > 1,
          ),
          validator: (val) {
            if (label.contains('Optional')) return null;
            return (val == null || val.isEmpty) ? 'Required' : null;
          },
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Day', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(7, (index) {
              final isSelected = _selectedDay == index + 1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(days[index]),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedDay = index + 1);
                  },
                  selectedColor: AppTheme.primaryNavy,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker({required bool isStart}) {
    final time = isStart ? _startTime : _endTime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isStart ? 'Start Time' : 'End Time', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) {
              setState(() {
                if (isStart) {
                  _startTime = picked;
                } else {
                  _endTime = picked;
                }
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: AppTheme.textLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  time.format(context),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: AppTheme.primaryNavy, width: 3) : null,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _saveSlot() {
    if (_formKey.currentState!.validate()) {
      // Save logic (mock)
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot Saved Successfully')),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Slot?'),
        content: const Text('Are you sure you want to delete this timetable slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Slot Deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
