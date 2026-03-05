import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../app/routes.dart';
import '../../../models/timetable_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/common/app_card.dart';

class TimetableOverviewScreen extends StatefulWidget {
  const TimetableOverviewScreen({super.key});

  @override
  State<TimetableOverviewScreen> createState() => _TimetableOverviewScreenState();
}

class _TimetableOverviewScreenState extends State<TimetableOverviewScreen> {
  DateTime _selectedDate = DateTime.now();
  final FirestoreService _firestore = FirestoreService();
  StudyPlan? _studyPlan;
  bool _loading = true;
  int _weekOffset = 0;

  DateTime get _startOfCurrentWeek {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final plan = await _firestore.getStudyPlan(uid);
      if (mounted) {
        setState(() { _studyPlan = plan; _loading = false; });
        if (plan != null) _scheduleNotifications(plan);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scheduleNotifications(StudyPlan plan) {
    final notifService = NotificationService();
    for (int i = 0; i < plan.sessions.length; i++) {
      final s = plan.sessions[i];
      if (!s.isCompleted && s.startTime.isAfter(DateTime.now())) {
        notifService.scheduleStudyNotification(
          id: i + 1000,
          title: s.subject,
          body: '${s.topic} starts in 15 minutes',
          scheduledTime: s.startTime,
        );
      }
    }
  }

  List<TimetableSession> _sessionsForDate(DateTime date) {
    if (_studyPlan == null) return [];
    return _studyPlan!.sessions.where((s) =>
      s.date.year == date.year && s.date.month == date.month && s.date.day == date.day
    ).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _jumpToNextSession() {
    if (_studyPlan == null) return;
    final now = DateTime.now();
    final upcomingSessions = _studyPlan!.sessions
        .where((s) => !s.isCompleted && s.date.isAfter(now.subtract(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (upcomingSessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No upcoming sessions found'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final target = upcomingSessions.first.date;
    final startOfTargetWeek = target.subtract(Duration(days: target.weekday - 1));
    final diff = startOfTargetWeek.difference(_startOfCurrentWeek).inDays;
    setState(() {
      _weekOffset = diff ~/ 7;
      _selectedDate = target;
    });
  }

  Color _getColor(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

  Future<void> _markComplete(TimetableSession session) async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null || _studyPlan == null) return;

    if (!session.isCompleted) {
      // Navigate to quiz
      Navigator.pushNamed(context, AppRoutes.sessionQuiz, arguments: {
        'session': session,
        'planId': _studyPlan!.id,
      }).then((_) => _loadPlan());
    } else {
      // Undo completion
      await _firestore.updateSessionStatus(uid, _studyPlan!.id, session.id, false);
      await _loadPlan();
    }
  }

  Future<void> _rescheduleSession(TimetableSession session) async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null || _studyPlan == null) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: session.date.add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: 'Reschedule "${session.topic}"',
    );

    if (picked != null) {
      await _firestore.rescheduleSession(uid, _studyPlan!.id, session.id, picked);
      await _loadPlan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rescheduled to ${DateFormat('MMM d, yyyy').format(picked)}'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _openSession(TimetableSession session) {
    Navigator.pushNamed(context, AppRoutes.sessionDetail, arguments: {
      'session': session,
      'planId': _studyPlan?.id,
    }).then((_) => _loadPlan());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text('My Timetable', style: Theme.of(context).textTheme.headlineSmall),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'generate') {
                Navigator.of(context).pushNamed(AppRoutes.generateTimetable).then((_) => _loadPlan());
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'generate', child: Row(children: [
                Icon(Icons.auto_awesome_outlined, size: 20), SizedBox(width: 8), Text('Generate New'),
              ])),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _studyPlan == null
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPlan,
                  child: Column(
                    children: [
                      _buildWeekSelector(),
                      const SizedBox(height: 12),
                      _buildProgressBar(),
                      const SizedBox(height: 8),
                      Expanded(child: _buildSessionsList()),
                    ],
                  ),
                ),
      floatingActionButton: _studyPlan != null
          ? FloatingActionButton.extended(
              onPressed: _jumpToNextSession,
              icon: const Icon(Icons.skip_next_rounded),
              label: const Text('Next Session'),
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_outlined, size: 80, color: AppTheme.textLight.withOpacity(0.4)),
            const SizedBox(height: 20),
            Text('No Study Plan Yet', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Upload your syllabus PDF and generate a smart study timetable.',
                textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.generateTimetable).then((_) => _loadPlan()),
              icon: const Icon(Icons.auto_awesome_rounded, size: 20),
              label: const Text('Generate Timetable'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    final sessions = _sessionsForDate(_selectedDate);
    if (sessions.isEmpty) return const SizedBox.shrink();
    final done = sessions.where((s) => s.isCompleted).length;
    final pct = done / sessions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$done/${sessions.length} completed', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              Text('${(pct * 100).toInt()}%', style: TextStyle(color: AppTheme.accentBlue, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct, minHeight: 6, backgroundColor: AppTheme.divider, valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    final startOfWeek = _startOfCurrentWeek.add(Duration(days: _weekOffset * 7));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final now = DateTime.now();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () => setState(() => _weekOffset--), icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.textSecondary), splashRadius: 20),
              GestureDetector(
                onTap: () => setState(() { _weekOffset = 0; _selectedDate = DateTime.now(); }),
                child: Column(children: [
                  Text('${DateFormat('MMM d').format(startOfWeek)} – ${DateFormat('MMM d').format(endOfWeek)}', style: const TextStyle(color: AppTheme.primaryNavy, fontSize: 15, fontWeight: FontWeight.w700)),
                  if (_weekOffset != 0) const Text('Tap to return to today', style: TextStyle(color: AppTheme.textLight, fontSize: 11)),
                ]),
              ),
              IconButton(onPressed: () => setState(() => _weekOffset++), icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary), splashRadius: 20),
            ],
          ),
        ),
        SizedBox(
          height: 85,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final date = startOfWeek.add(Duration(days: index));
              final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month && date.year == _selectedDate.year;
              final isToday = date.day == now.day && date.month == now.month && date.year == now.year;
              final hasSession = _sessionsForDate(date).isNotEmpty;

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  width: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryNavy : AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: isToday && !isSelected ? Border.all(color: AppTheme.accentBlue, width: 2) : null,
                    boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryNavy.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : AppTheme.cardBoxShadow,
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(DateFormat('E').format(date).toUpperCase(), style: TextStyle(color: isSelected ? Colors.white70 : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(DateFormat('d').format(date), style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    if (hasSession) ...[const SizedBox(height: 4), Container(width: 6, height: 6, decoration: BoxDecoration(color: isSelected ? Colors.white : AppTheme.accentBlue, shape: BoxShape.circle))],
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSessionsList() {
    final sessions = _sessionsForDate(_selectedDate);

    if (sessions.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.event_note_outlined, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text('No sessions on this day', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: sessions.map((session) {
          final color = _getColor(session.colorHex);
          final startStr = DateFormat('h:mm a').format(session.startTime);
          final endStr = DateFormat('h:mm a').format(session.endTime);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _openSession(session),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardBoxShadow,
                ),
                child: Column(
                  children: [
                    // Main content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Color bar + time
                          Column(
                            children: [
                              Container(
                                width: 4, height: 50,
                                decoration: BoxDecoration(
                                  color: session.isCompleted ? AppTheme.successGreen : color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          // Subject & topic
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(child: Text(session.subject, style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700,
                                    color: session.isCompleted ? AppTheme.successGreen : color,
                                    decoration: session.isCompleted ? TextDecoration.lineThrough : null,
                                  ))),
                                  if (session.isCompleted) Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
                                  if (session.quizCompleted) ...[const SizedBox(width: 4), Icon(Icons.quiz_rounded, color: AppTheme.accentBlue, size: 18)],
                                ]),
                                const SizedBox(height: 4),
                                Text(session.topic, style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                                if (session.moduleName != null) ...[
                                  const SizedBox(height: 2),
                                  Text(session.moduleName!, style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                                ],
                                const SizedBox(height: 8),
                                // Time range
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    Icon(Icons.schedule_rounded, size: 14, color: color),
                                    const SizedBox(width: 4),
                                    Text('$startStr – $endStr', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    Text('${session.durationMinutes} min', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Action bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          _actionChip(
                            icon: session.isCompleted ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                            label: session.isCompleted ? 'Undo' : 'Complete',
                            color: session.isCompleted ? AppTheme.warningAmber : AppTheme.successGreen,
                            onTap: () => _markComplete(session),
                          ),
                          const SizedBox(width: 8),
                          _actionChip(
                            icon: Icons.calendar_month_rounded,
                            label: 'Reschedule',
                            color: AppTheme.accentPurple,
                            onTap: () => _rescheduleSession(session),
                          ),
                          const Spacer(),
                          Icon(Icons.chevron_right_rounded, color: AppTheme.textLight, size: 22),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
