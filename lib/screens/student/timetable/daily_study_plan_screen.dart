import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../models/timetable_model.dart';
import '../../../widgets/common/app_card.dart';

class DailyStudyPlanScreen extends StatefulWidget {
  const DailyStudyPlanScreen({super.key});

  @override
  State<DailyStudyPlanScreen> createState() => _DailyStudyPlanScreenState();
}

class _DailyStudyPlanScreenState extends State<DailyStudyPlanScreen> {
  final DateTime _selectedDate = DateTime.now();

  // Mock Data (Updated for new Model)
  final List<TimetableSession> _sessions = [
    TimetableSession(
      id: '1',
      subject: 'Mathematics',
      topic: 'Calculus - Limits',
      date: DateTime.now(),
      startTime: DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        9,
        0,
      ),
      durationMinutes: 90,
      colorHex: '#4A7BF7',
      isCompleted: true,
    ),
    TimetableSession(
      id: '2',
      subject: 'Physics',
      topic: 'Kinematics',
      date: DateTime.now(),
      startTime: DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        11,
        0,
      ),
      durationMinutes: 60,
      colorHex: '#7C4DFF',
      isCompleted: false,
    ),
    TimetableSession(
      id: '3',
      subject: 'Chemistry',
      topic: 'Periodic Table',
      date: DateTime.now(),
      startTime: DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        14,
        0,
      ),
      durationMinutes: 90,
      colorHex: '#10B981',
      isCompleted: false,
    ),
  ];

  Color _getColorFromHex(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Daily Study Plan',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: Column(
        children: [
          _buildDateHeader(),
          _buildProgressBar(),
          Expanded(child: _buildSessionsList()),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    final totalHours =
        _sessions.fold(0, (sum, session) => sum + session.durationMinutes) / 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.cardBoxShadowDark
            : AppTheme.cardBoxShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE').format(_selectedDate),
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMMM d').format(_selectedDate),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('Goal', style: Theme.of(context).textTheme.labelSmall),
                Text(
                  '${totalHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    int completed = _sessions.where((s) => s.isCompleted).length;
    int total = _sessions.length;
    double progress = total == 0 ? 0 : completed / total;

    // Total minutes available: _sessions.fold(0, (sum, s) => sum + s.durationMinutes)
    int completedMinutes = _sessions
        .where((s) => s.isCompleted)
        .fold(0, (sum, s) => sum + s.durationMinutes);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.accentBlue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completed / $total Sessions',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${(completedMinutes / 60).toStringAsFixed(1)}h done',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final color = _getColorFromHex(session.colorHex);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${DateFormat('h:mm a').format(session.startTime)} - ${DateFormat('h:mm a').format(session.endTime)}',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.5),
                                    ),
                              ),
                              _buildStatusBadge(session.isCompleted),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            session.subject,
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.topic,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Need to find a way to update the immutable list for this mock
                              // In a real app we'd use a provider
                              ElevatedButton(
                                onPressed: () {
                                  // Can't update immutable field easily in this mock setup without setState + deep copy/replacement
                                  // For now just toggle logic visually if we could
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  backgroundColor: session.isCompleted
                                      ? AppTheme.successGreen
                                      : Theme.of(context).colorScheme.primary,
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: Text(
                                  session.isCompleted ? 'Completed' : 'Start',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(bool isCompleted) {
    Color color = isCompleted ? AppTheme.successGreen : Colors.grey;
    String text = isCompleted ? 'Completed' : 'Not Started';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
