import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_card.dart';

class StudentAnalyticsMentorScreen extends StatelessWidget {
  const StudentAnalyticsMentorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final students = [
      {
        'name': 'Ananya Kumar',
        'hours': 86,
        'subjects': 4,
        'streak': 12,
        'progress': 0.75,
        'trend': 'up',
      },
      {
        'name': 'Raj Patel',
        'hours': 64,
        'subjects': 3,
        'streak': 7,
        'progress': 0.55,
        'trend': 'same',
      },
      {
        'name': 'Priya Singh',
        'hours': 92,
        'subjects': 5,
        'streak': 14,
        'progress': 0.85,
        'trend': 'up',
      },
      {
        'name': 'Vikram Sharma',
        'hours': 48,
        'subjects': 3,
        'streak': 3,
        'progress': 0.40,
        'trend': 'down',
      },
      {
        'name': 'Neha Gupta',
        'hours': 72,
        'subjects': 4,
        'streak': 11,
        'progress': 0.65,
        'trend': 'up',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Student Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview cards
            Row(
              children: [
                _overviewCard(
                  context,
                  'Total Students',
                  '${students.length}',
                  Icons.people_rounded,
                  AppTheme.accentBlue,
                ),
                const SizedBox(width: 12),
                _overviewCard(
                  context,
                  'Avg Hours',
                  '${(students.fold<int>(0, (s, e) => s + (e['hours'] as int)) / students.length).toStringAsFixed(0)}h',
                  Icons.timer_rounded,
                  AppTheme.accentPurple,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _overviewCard(
                  context,
                  'Active Streaks',
                  '${students.where((s) => (s['streak'] as int) > 5).length}',
                  Icons.local_fire_department_rounded,
                  AppTheme.warningAmber,
                ),
                const SizedBox(width: 12),
                _overviewCard(
                  context,
                  'Avg Progress',
                  '${(students.fold<double>(0, (s, e) => s + (e['progress'] as double)) / students.length * 100).toStringAsFixed(0)}%',
                  Icons.trending_up_rounded,
                  AppTheme.successGreen,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Student cards
            Text(
              'Individual Progress',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...students.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                (s['name'] as String)[0],
                                style: TextStyle(
                                  color: AppTheme.accentBlue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s['name'] as String,
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${s['hours']}h studied • ${s['subjects']} subjects • 🔥 ${s['streak']}d',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            s['trend'] == 'up'
                                ? Icons.trending_up_rounded
                                : s['trend'] == 'down'
                                ? Icons.trending_down_rounded
                                : Icons.trending_flat_rounded,
                            color: s['trend'] == 'up'
                                ? AppTheme.successGreen
                                : s['trend'] == 'down'
                                ? AppTheme.errorRed
                                : AppTheme.warningAmber,
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: s['progress'] as double,
                                minHeight: 8,
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation(
                                  (s['progress'] as double) >= 0.7
                                      ? AppTheme.successGreen
                                      : (s['progress'] as double) >= 0.5
                                      ? AppTheme.warningAmber
                                      : AppTheme.errorRed,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${((s['progress'] as double) * 100).toInt()}%',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
