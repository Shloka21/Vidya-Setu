import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';
import 'package:vidyasetu/services/localization_service.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  final FirestoreService _firestore = FirestoreService();
  String? _selectedStudentId;
  String _feedbackType = 'Progress Update';
  int _rating = 0;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  final _types = [
    'Progress Update',
    'Study Suggestion',
    'Encouragement',
    'Area of Improvement',
    'Achievement Recognition',
  ];

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

  Future<void> _sendFeedback() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_select_a_student'))),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('please_provide_title_and_messa'))),
      );
      return;
    }

    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) return;

    final selectedStudentName = _students.firstWhere((s) => s['uid'] == _selectedStudentId)['name'] as String? ?? 'Student';
    final feedbackId = FirebaseFirestore.instance.collection('_').doc().id;

    try {
      await _firestore.saveFeedback({
        'id': feedbackId,
        'mentorId': uid,
        'studentId': _selectedStudentId,
        'studentName': selectedStudentName,
        'type': _feedbackType,
        'rating': _rating,
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      // Notify the student about the feedback
      final mentorName = Provider.of<AuthProvider>(context, listen: false).userModel?.name ?? 'Your Mentor';
      await _firestore.writeNotification(_selectedStudentId!, {
        'type': 'feedback',
        'mentorName': mentorName,
        'mentorId': uid,
        'feedbackId': feedbackId,
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('feedback_sent_successfully')),
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
          SnackBar(content: Text('${context.tr('error_sending_feedback')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('send_feedback'))),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select student
                  _label(context.tr('select_student')),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStudentId,
                        hint: Text(context.tr('choose_a_student'),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        items: _students
                            .map((s) => DropdownMenuItem<String>(value: s['uid'], child: Text(s['name'] as String? ?? 'Unknown')))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedStudentId = v),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Feedback type
                  _label(context.tr('feedback_type')),
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
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        onSelected: (_) => setState(() => _feedbackType = type),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),

                  // Rating
                  _label(context.tr('overall_rating')),
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        return GestureDetector(
                          onTap: () => setState(() => _rating = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: AppTheme.warningAmber,
                              size: 40,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Title
                  _label(context.tr('title')),
                  _buildField(_titleController, 'e.g., Great work on Algebra!'),
                  SizedBox(height: 16),

                  // Message
                  _label(context.tr('detailed_feedback')),
                  _buildField(
                    _messageController,
                    'Write your detailed feedback here...',
                    maxLines: 5,
                  ),
                  SizedBox(height: 30),

                  AppButton(
                    text: context.tr('send_feedback'),
                    onPressed: _sendFeedback,
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
