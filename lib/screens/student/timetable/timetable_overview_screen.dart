import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../app/routes.dart';
import '../../../models/timetable_model.dart';
import '../../../widgets/common/app_card.dart';

class TimetableOverviewScreen extends StatefulWidget {
  const TimetableOverviewScreen({super.key});

  @override
  State<TimetableOverviewScreen> createState() =>
      _TimetableOverviewScreenState();
}

class _TimetableOverviewScreenState extends State<TimetableOverviewScreen> {
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'Grid'; // Grid, List
  final List<bool> _studyDays = List.generate(7, (index) => true); // Mon-Sun

  // Mock Data
  late List<TimetableSession> _allSessions;

  @override
  void initState() {
    super.initState();
    // Initialize mock data with dates relative to today
    final now = DateTime.now();
    _allSessions = [
      TimetableSession(
        id: '1',
        subject: 'Mathematics',
        topic: 'Integration',
        date: now, // Today
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        durationMinutes: 90,
        colorHex: '#4A7BF7',
      ),
      TimetableSession(
        id: '2',
        subject: 'Physics',
        topic: 'Mechanics',
        date: now, // Today
        startTime: DateTime(now.year, now.month, now.day, 11, 0),
        durationMinutes: 60,
        colorHex: '#7C4DFF',
      ),
      TimetableSession(
        id: '3',
        subject: 'Chemistry',
        topic: 'Organic',
        date: now.add(const Duration(days: 1)), // Tomorrow
        startTime: DateTime(now.year, now.month, now.day + 1, 10, 0),
        durationMinutes: 90,
        colorHex: '#10B981',
      ),
    ];
  }

  Color _getColorFromHex(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Timetable Overview',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              // Download PDF
            },
            tooltip: 'Download PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Share
            },
            tooltip: 'Share',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'generate') {
                Navigator.of(context).pushNamed(AppRoutes.generateTimetable);
              } else if (value == 'edit') {
                // Edit Timetable logic
                Navigator.of(context).pushNamed(AppRoutes.editTimetableSlot);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'generate',
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Generate New'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Timetable'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekSelector(),
          const SizedBox(height: 16),
          _buildStudyDaysToggle(),
          const SizedBox(height: 16),
          _buildViewToggle(),
          const SizedBox(height: 16),
          Expanded(child: _buildTimetableContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(AppRoutes.editTimetableSlot);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWeekSelector() {
    // Simplified Week Selector: Just showing current week days
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return SizedBox(
      height: 85,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = startOfWeek.add(Duration(days: index));
          final isSelected =
              date.day == _selectedDate.day &&
              date.month == _selectedDate.month;
          final isToday = date.day == now.day && date.month == now.month;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: AppTheme.accentBlue, width: 2)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : AppTheme.cardBoxShadow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white70
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudyDaysToggle() {
    // 7-day toggle switches
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(7, (index) {
          final dayName = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index];
          final isActive = _studyDays[index];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _studyDays[index] = !_studyDays[index];
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? AppTheme.accentBlue : Colors.transparent,
                  border: Border.all(
                    color: isActive
                        ? AppTheme.accentBlue
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  dayName,
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: ['Grid', 'List'].map((mode) {
          final isSelected = _viewMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _viewMode = mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  mode,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimetableContent() {
    // Filter sessions for the selected date
    final sessions = _allSessions
        .where(
          (s) =>
              s.startTime.year == _selectedDate.year &&
              s.startTime.month == _selectedDate.month &&
              s.startTime.day == _selectedDate.day,
        )
        .toList();

    // Check if the selected day is a rest day (based on toggle)
    // _studyDays index 0 is Mon, index 6 is Sun
    // _selectedDate.weekday 1 is Mon, 7 is Sun
    // So index is weekday - 1
    final isRestDay = !_studyDays[_selectedDate.weekday - 1];

    if (isRestDay) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.weekend_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Rest Day',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enjoy your break!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No sessions scheduled',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.editTimetableSlot);
              },
              child: const Text('Add Session'),
            ),
          ],
        ),
      );
    }

    if (_viewMode == 'Grid') {
      return _buildGridView(sessions);
    } else {
      return _buildListView(sessions);
    }
  }

  Widget _buildGridView(List<TimetableSession> sessions) {
    // Simplified Grid View (Time on Y, single column for the day)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: sessions.map((session) {
          final color = _getColorFromHex(session.colorHex);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    DateFormat('h:mm a').format(session.startTime),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.editTimetableSlot);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        border: Border(
                          left: BorderSide(color: color, width: 4),
                        ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.subject,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.topic,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${session.durationMinutes} mins',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.4),
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
          );
        }).toList(),
      ),
    );
  }

  Widget _buildListView(List<TimetableSession> sessions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final color = _getColorFromHex(session.colorHex);
        return AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(Icons.book, color: color),
            ),
            title: Text(
              session.subject,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${session.topic}\n${DateFormat('h:mm a').format(session.startTime)} - ${DateFormat('h:mm a').format(session.endTime)}',
            ),
            isThreeLine: true,
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.editTimetableSlot),
            ),
          ),
        );
      },
    );
  }
}
