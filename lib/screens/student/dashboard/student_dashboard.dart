import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/timetable_model.dart';
import '../../../models/reminder_model.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/stat_card.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final FirestoreService _firestore = FirestoreService();
  StudyPlan? _studyPlan;
  bool _loadingPlan = true;

  @override
  void initState() {
    super.initState();
    _loadStudyPlan();
  }

  Future<void> _loadStudyPlan() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) {
      setState(() => _loadingPlan = false);
      return;
    }
    try {
      final plan = await _firestore.getStudyPlan(uid);
      if (mounted) setState(() { _studyPlan = plan; _loadingPlan = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPlan = false);
    }
  }

  List<TimetableSession> _todaySessions() {
    if (_studyPlan == null) return [];
    final now = DateTime.now();
    return _studyPlan!.sessions.where((s) =>
      s.date.year == now.year &&
      s.date.month == now.month &&
      s.date.day == now.day
    ).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  int _completedToday() => _todaySessions().where((s) => s.isCompleted).length;

  double _totalStudyHours() {
    if (_studyPlan == null) return 0;
    final completed = _studyPlan!.sessions.where((s) => s.isCompleted);
    return completed.fold<double>(0, (sum, s) => sum + s.durationMinutes / 60.0);
  }

  double _completionRate() {
    if (_studyPlan == null || _studyPlan!.sessions.isEmpty) return 0;
    final done = _studyPlan!.sessions.where((s) => s.isCompleted).length;
    return done / _studyPlan!.sessions.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStudyPlan,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildQuickStats(),
                const SizedBox(height: 24),
                _buildAnalyticsSnapshot(),
                const SizedBox(height: 24),
                _buildTodaySchedule(),
                const SizedBox(height: 24),
                _buildUpcomingSection(),
                const SizedBox(height: 24),
                _buildQuickActions(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VidyaSetu',
                        style: TextStyle(
                          color: AppTheme.primaryNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMM d').format(now).toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '$greeting,\n${user?.name ?? "Student"}!',
                style: const TextStyle(
                  color: AppTheme.primaryNavy,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            // Profile avatar
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.studentSettings),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.successGreen,
                    width: 2.5,
                  ),
                ),
                child: user?.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user!.profileImageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Center(
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            color: AppTheme.accentBlue,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            // Chat icon with unread badge
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.chatList),
              child: StreamBuilder<int>(
                stream: _firestore.totalUnreadCountStream(
                    Provider.of<AuthProvider>(context, listen: false).userModel?.uid ?? ''),
                builder: (context, snapshot) {
                  final unread = snapshot.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.cardBoxShadow,
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppTheme.textSecondary),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.errorRed,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            child: Center(
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUICK STATS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildQuickStats() {
    final user = Provider.of<AuthProvider>(context).userModel;
    final todayDone = _completedToday();
    final todayTotal = _todaySessions().length;

    return SizedBox(
      height: 160,
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: "Today's Tasks",
              value: todayTotal > 0 ? '$todayDone/$todayTotal' : '${user?.tasksCompleted ?? 0}',
              icon: Icons.task_alt_rounded,
              iconColor: AppTheme.successGreen,
              iconBgColor: AppTheme.successGreen.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: StatCard(
              label: 'Study Streak',
              value: '${user?.streak ?? 0}',
              icon: Icons.local_fire_department_rounded,
              isDark: true,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ANALYTICS SNAPSHOT (Inline)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAnalyticsSnapshot() {
    final hours = _totalStudyHours();
    final rate = _completionRate();

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.progressDashboard),
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.bar_chart_rounded, color: AppTheme.accentPurple, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics Snapshot',
                    style: TextStyle(
                      color: AppTheme.primaryNavy,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${hours.toStringAsFixed(1)}h studied • ${(rate * 100).toInt()}% complete',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TODAY'S SCHEDULE
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTodaySchedule() {
    final sessions = _todaySessions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Study Plan",
              style: TextStyle(
                color: AppTheme.primaryNavy,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.timetableOverview),
              child: const Text(
                'View',
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingPlan)
          const Center(child: CircularProgressIndicator())
        else if (_studyPlan == null)
          _buildNoTimetableCard()
        else if (sessions.isEmpty)
          _buildRestDayCard()
        else
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                for (int i = 0; i < sessions.length; i++) ...[
                  _buildScheduleItem(sessions[i]),
                  if (i < sessions.length - 1) const Divider(height: 24),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNoTimetableCard() {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 48, color: AppTheme.accentPurple.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            'No Study Plan Yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload your syllabus PDF to generate a personalized study timetable.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textLight, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.generateTimetable),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Generate Timetable'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestDayCard() {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('😌', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          const Text(
            'No sessions today',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Take a break or review previous topics!',
            style: TextStyle(color: AppTheme.textLight, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(TimetableSession session) {
    final now = DateTime.now();
    final isCurrent = session.startTime.isBefore(now) && session.endTime.isAfter(now);
    final isPast = session.endTime.isBefore(now);
    final timeStr = DateFormat('h:mm a').format(session.startTime);

    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            timeStr,
            style: TextStyle(
              color: isCurrent ? AppTheme.accentBlue : AppTheme.textLight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: session.isCompleted
                ? AppTheme.successGreen
                : isCurrent
                    ? AppTheme.accentBlue
                    : isPast
                        ? AppTheme.warningAmber
                        : AppTheme.divider,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppTheme.accentBlue.withValues(alpha: 0.1)
                  : session.isCompleted
                      ? AppTheme.successGreen.withValues(alpha: 0.06)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.subject,
                  style: TextStyle(
                    color: isCurrent ? AppTheme.accentBlue : AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  session.topic,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        if (session.isCompleted)
          const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // UPCOMING REMINDERS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildUpcomingSection() {
    final uid = Provider.of<AuthProvider>(context).userModel?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Reminders',
              style: TextStyle(
                color: AppTheme.primaryNavy,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.remindersList),
              child: const Text(
                'See All',
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.upcomingRemindersStream(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.event_available_rounded, color: AppTheme.textLight, size: 28),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'No upcoming reminders. Tap + to add one!',
                        style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }

            final reminders = snapshot.data!.docs.map((doc) {
              return ReminderModel.fromMap(doc.data() as Map<String, dynamic>);
            }).toList();

            return Column(
              children: reminders.map((r) {
                final icon = _reminderIcon(r.type);
                final timeStr = _formatReminderTime(r.dateTime);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildUpcomingItem(r.title, timeStr, icon, r.priorityColor),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  IconData _reminderIcon(ReminderType type) {
    switch (type) {
      case ReminderType.exam: return Icons.quiz_rounded;
      case ReminderType.assignment: return Icons.assignment_rounded;
      case ReminderType.quiz: return Icons.question_answer_rounded;
      case ReminderType.studySession: return Icons.menu_book_rounded;
      case ReminderType.custom: return Icons.event_rounded;
    }
  }

  String _formatReminderTime(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inDays == 0) return 'Today, ${DateFormat('h:mm a').format(dt)}';
    if (diff.inDays == 1) return 'Tomorrow, ${DateFormat('h:mm a').format(dt)}';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  Widget _buildUpcomingItem(
    String title,
    String time,
    IconData icon,
    Color priorityColor,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: priorityColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // QUICK ACTIONS – 2x3 Grid
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: AppTheme.primaryNavy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
          
            _buildActionCard(
              'Mentors',
              Icons.people_rounded,
              AppTheme.successGreen,
              () => Navigator.pushNamed(context, AppRoutes.findMentor),
            ),
            _buildActionCard(
              'Leaderboard',
              Icons.emoji_events_rounded,
              const Color(0xFFF97316),
              () => Navigator.pushNamed(context, AppRoutes.leaderboard),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
