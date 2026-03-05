import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_card.dart';

class MentorRemindersScreen extends StatelessWidget {
  const MentorRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reminders = [
      {
        'student': 'Ananya Kumar',
        'title': 'Review Calculus Chapter 5',
        'message': 'Please complete exercises 1-20 before our next session',
        'date': 'Feb 16, 2026',
        'status': 'sent',
      },
      {
        'student': 'Raj Patel',
        'title': 'Practice Statistics Problems',
        'message': 'Focus on probability distributions - textbook pg 45-60',
        'date': 'Feb 15, 2026',
        'status': 'read',
      },
      {
        'student': 'Priya Singh',
        'title': 'Prepare for Mock Test',
        'message': 'Mock test will cover chapters 1-8. Good luck!',
        'date': 'Feb 14, 2026',
        'status': 'read',
      },
      {
        'student': 'Vikram Sharma',
        'title': 'Submit Lab Assignment',
        'message': 'Chemistry lab assignment is due this Friday',
        'date': 'Feb 13, 2026',
        'status': 'sent',
      },
    ];

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Student Reminders'),
        actions: [
          IconButton(
              icon: const Icon(Icons.filter_list_rounded), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/createMentorReminder'),
        backgroundColor: AppTheme.accentBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Create Reminder',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: reminders.length,
        itemBuilder: (context, index) {
          final r = reminders[index];
          final isRead = r['status'] == 'read';
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text((r['student'] as String)[0],
                              style: TextStyle(
                                  color: AppTheme.accentBlue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['title'] as String,
                                style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            Text('To: ${r['student']}',
                                style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isRead
                              ? AppTheme.successGreen.withOpacity(0.1)
                              : AppTheme.warningAmber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isRead ? 'Read' : 'Sent',
                          style: TextStyle(
                            color: isRead
                                ? AppTheme.successGreen
                                : AppTheme.warningAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(r['message'] as String,
                      style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          height: 1.4)),
                  const SizedBox(height: 8),
                  Text(r['date'] as String,
                      style: TextStyle(
                          color: AppTheme.textLight, fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
