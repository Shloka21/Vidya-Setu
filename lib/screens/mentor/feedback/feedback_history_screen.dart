import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_card.dart';

class FeedbackHistoryScreen extends StatelessWidget {
  const FeedbackHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feedbackList = [
      {
        'student': 'Ananya Kumar',
        'title': 'Great Algebra Progress',
        'type': 'Progress Update',
        'rating': 5,
        'date': 'Feb 15, 2026',
        'message':
            'Ananya has shown excellent improvement in solving quadratic equations. Keep up the great work!',
      },
      {
        'student': 'Raj Patel',
        'title': 'Statistics Practice Needed',
        'type': 'Area of Improvement',
        'rating': 3,
        'date': 'Feb 14, 2026',
        'message':
            'Raj needs to focus more on probability distributions. I recommend extra practice sets.',
      },
      {
        'student': 'Priya Singh',
        'title': 'Outstanding Performance',
        'type': 'Achievement Recognition',
        'rating': 5,
        'date': 'Feb 12, 2026',
        'message':
            'Priya scored highest in the recent calculus test. She has been consistent throughout.',
      },
      {
        'student': 'Vikram Sharma',
        'title': 'Study Schedule Suggestion',
        'type': 'Study Suggestion',
        'rating': 4,
        'date': 'Feb 10, 2026',
        'message':
            'I suggest Vikram allocate 30 more minutes to trigonometry daily to build confidence.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback History'),
        actions: [
          IconButton(
              icon: const Icon(Icons.filter_list_rounded), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: feedbackList.length,
        itemBuilder: (context, index) {
          final fb = feedbackList[index];
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
                          color: _typeColor(fb['type'] as String)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(_typeIcon(fb['type'] as String),
                              color: _typeColor(fb['type'] as String),
                              size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fb['title'] as String,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('To: ${fb['student']}',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < (fb['rating'] as int)
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppTheme.warningAmber,
                                size: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(fb['date'] as String,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _typeColor(fb['type'] as String).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(fb['type'] as String,
                        style: TextStyle(
                            color: _typeColor(fb['type'] as String),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  Text(fb['message'] as String,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 13,
                          height: 1.5)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Progress Update':
        return AppTheme.accentBlue;
      case 'Achievement Recognition':
        return AppTheme.successGreen;
      case 'Area of Improvement':
        return AppTheme.warningAmber;
      case 'Study Suggestion':
        return AppTheme.accentPurple;
      default:
        return AppTheme.accentBlue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Progress Update':
        return Icons.trending_up_rounded;
      case 'Achievement Recognition':
        return Icons.emoji_events_rounded;
      case 'Area of Improvement':
        return Icons.flag_rounded;
      case 'Study Suggestion':
        return Icons.lightbulb_rounded;
      default:
        return Icons.feedback_rounded;
    }
  }
}
