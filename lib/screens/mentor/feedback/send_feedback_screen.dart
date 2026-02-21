import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  String? _selectedStudent;
  String _feedbackType = 'Progress Update';
  int _rating = 0;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  final _students = [
    'Ananya Kumar',
    'Raj Patel',
    'Priya Singh',
    'Vikram Sharma',
    'Neha Gupta',
  ];
  final _types = [
    'Progress Update',
    'Study Suggestion',
    'Encouragement',
    'Area of Improvement',
    'Achievement Recognition',
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
      appBar: AppBar(title: const Text('Send Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select student
            _label('Select Student'),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStudent,
                  hint: Text(
                    'Choose a student',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  items: _students
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedStudent = v),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Feedback type
            _label('Feedback Type'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((type) {
                final selected = type == _feedbackType;
                return ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  selectedColor: AppTheme.accentBlue.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: selected
                        ? AppTheme.accentBlue
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (_) => setState(() => _feedbackType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Rating
            _label('Overall Rating'),
            AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        i < _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppTheme.warningAmber,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            _label('Title'),
            _buildField(_titleController, 'e.g., Great work on Algebra!'),
            const SizedBox(height: 16),

            // Message
            _label('Detailed Feedback'),
            _buildField(
              _messageController,
              'Write your detailed feedback here...',
              maxLines: 5,
            ),
            const SizedBox(height: 30),

            AppButton(
              text: 'Send Feedback',
              onPressed: () {
                if (_selectedStudent == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a student')),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Feedback sent successfully!'),
                    backgroundColor: AppTheme.successGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.accentBlue, width: 2),
        ),
      ),
    );
  }
}
