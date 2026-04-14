import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/notification_service.dart';
import '../../../models/timetable_model.dart';
import '../../../models/reminder_model.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/stat_card.dart';
import 'package:vidyasetu/services/localization_service.dart';
import '../../../widgets/common/translated_text.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final FirestoreService _firestore = FirestoreService();
  StudyPlan? _studyPlan;
  bool _loadingPlan = true;
  StreamSubscription? _feedbackSubscription;
  StreamSubscription? _remindersSubscription;
  StreamSubscription? _chatSubscription;
  final Set<String> _processedIds = {};
  final DateTime _sessionStart = DateTime.now().subtract(const Duration(seconds: 10));

  Timer? _activeHeartbeatTimer;

  @override
  void initState() {
    super.initState();
    _loadStudyPlan();
    _setupStreamObservers();
    _syncMissedReminders();

    // Setup WhatsApp-style lastActive heartbeat
    _activeHeartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
      if (uid != null && mounted) {
        _firestore.updateUser(uid, {'lastActive': Timestamp.now()});
      }
    });

    // Set initial heartbeat immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
      if (uid != null && mounted) {
        _firestore.updateUser(uid, {'lastActive': Timestamp.now()});
        _firestore.ensureUserInitialized(uid);
      }
    });
  }

  @override
  void dispose() {
    _feedbackSubscription?.cancel();
    _remindersSubscription?.cancel();
    _chatSubscription?.cancel();
    _activeHeartbeatTimer?.cancel();
    super.dispose();
  }

  void _setupStreamObservers() {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) return;

    final notifService = NotificationService();

    // 1. Observer for New Feedback
    _feedbackSubscription = _firestore.feedbackForStudentStream(uid).listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final id = doc.id;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

        // Only notify for new items created after app started and not processed yet
        if (createdAt.isAfter(_sessionStart) && !_processedIds.contains(id)) {
          _processedIds.add(id);
          
          final type = data['type'] as String? ?? '';
          
          if (type == 'mentor_reminder') {
            // Schedule actual alarm for the mentor reminder
            final scheduledDate = (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
            final title = data['title'] ?? 'Mentor Task';
            final desc = data['description'] ?? '';
            
            notifService.scheduleReminderAlarm(
              reminderId: id,
              title: '📅 $title',
              body: desc.isEmpty ? 'Task assigned by your mentor' : desc,
              eventTime: scheduledDate,
              reminderMinutesBefore: [0, 15], // Notify at time and 15 mins before
              priority: data['priority'] ?? 'medium',
              repeatType: 'once',
            );

            notifService.showInstantNotification(
              '📅 $title',
              'Your mentor assigned you a task for ${DateFormat('MMM d, h:mm a').format(scheduledDate)}',
              payload: '{"type": "reminder"}',
            );
          } else if (type != 'acknowledgement' && !type.startsWith('reminder_')) {
            // If it's not a technical token, it's real feedback (Progress Update, Encouragement, etc.)
            notifService.showFeedbackNotification(
              mentorName: data['mentorName'] ?? 'Your Mentor',
              feedbackTitle: data['title'] ?? 'New Feedback',
              feedbackPreview: data['message'] ?? 'Check your feedback gallery.',
            );
          }
        }
      }
    });

    // 2. Observer for New Reminders
    _remindersSubscription = _firestore.remindersStream(uid).listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final id = doc.id;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final type = data['type'] as String? ?? '';

        // Only notify for mentor-assigned reminders created after app started
        if (type == 'mentor_assigned' && createdAt.isAfter(_sessionStart) && !_processedIds.contains(id)) {
          _processedIds.add(id);
          notifService.showInstantNotification(
            '📅 ${data['title'] ?? 'New Reminder'}',
            'Your mentor assigned you a new task: ${data['description'] ?? ''}',
            payload: '{"type": "reminder"}',
          );
        }
      }
    });

    // 3. Observer for Chat Messages
    _chatSubscription = _firestore.chatRoomsStream(uid).listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lastMessageSenderId = data['lastMessageSenderId'] as String?;
        final lastMessageTime = (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now();
        final roomId = doc.id;
        final lastMsgText = data['lastMessage'] as String? ?? '';

        // Only notify if the last message is from someone else and arrived after app start
        if (lastMessageSenderId != null && 
            lastMessageSenderId != uid && 
            lastMessageTime.isAfter(_sessionStart) &&
            !_processedIds.contains('$roomId-$lastMessageTime')) {
          
          _processedIds.add('$roomId-$lastMessageTime');
          
          // We don't have the sender's name in the chatRoom doc easily without a fetch, 
          // but we can pass 'Mentor/Student' or fetch it.
          notifService.showChatNotification(
            senderName: 'Vidyasetu',
            message: lastMsgText,
            roomId: roomId,
            senderId: lastMessageSenderId,
          );
        }
      }
    });
  }

  Future<void> _syncMissedReminders() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) return;

    final notifService = NotificationService();
    
    try {
      // Get all feedback items once to sync any mentor reminders sent while app was killed
      final snapshot = await _firestore.feedbackForStudentStream(uid).first;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['type'] == 'mentor_reminder') {
          final id = doc.id;
          final scheduledDate = (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
          
          if (scheduledDate.isAfter(DateTime.now())) {
            final title = data['title'] ?? 'Mentor Task';
            final desc = data['description'] ?? '';
            
            await notifService.scheduleReminderAlarm(
              reminderId: id,
              title: '📅 $title',
              body: desc.isEmpty ? 'Task assigned by your mentor' : desc,
              eventTime: scheduledDate,
              reminderMinutesBefore: [0, 15],
              priority: data['priority'] ?? 'medium',
              repeatType: 'once',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing missed reminders: $e');
    }
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
                _buildIncomingRequests(),
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
        ? context.tr('good_morning')
        : now.hour < 17
            ? context.tr('good_afternoon')
            : context.tr('good_evening');

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
                      Text(
                        context.tr('vidyasetu'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              letterSpacing: -0.5,
                            ),
                      ),
                      Text(
                        DateFormat('EEEE, MMM d', Provider.of<LocalizationService>(context).locale).format(now).toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            // Profile avatar
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.studentProfile),
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
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.cardBoxShadow,
                        ),
                        child: Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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

    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: context.tr('todays_tasks'),
              value: todayTotal > 0 ? '$todayDone/$todayTotal' : '${user?.tasksCompleted ?? 0}',
              icon: Icons.task_alt_rounded,
              iconColor: AppTheme.successGreen,
              iconBgColor: AppTheme.successGreen.withValues(alpha: 0.1),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: StatCard(
              label: context.tr('study_streak'),
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
    const Color purple = AppTheme.accentPurple;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.progressDashboard),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: purple.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: purple.withOpacity(0.1), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -2,
                top: -2,
                child: Icon(Icons.bar_chart_rounded, size: 90, color: purple.withOpacity(0.08)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            context.tr('analytics_snapshot').toUpperCase(),
                            style: GoogleFonts.inter(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                              children: [
                                TextSpan(text: hours.toStringAsFixed(1)),
                                TextSpan(
                                  text: ' ${context.tr('hours')} ',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: ' • ',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                ),
                                TextSpan(text: '${(rate * 100).toInt()}%'),
                                TextSpan(
                                  text: ' ${context.tr('complete')}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: purple.withOpacity(0.4)),
                  ],
                ),
              ),
            ],
          ),
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
            Text(
              context.tr('todays_study_plan'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.timetableOverview),
              child: Text(
                context.tr('view'),
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
          SizedBox(height: 12),
          Text(
            context.tr('no_study_plan_yet'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.tr('upload_your_syllabus_pdf_to_generate_a_p'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.generateTimetable),
              icon: Icon(Icons.add_rounded, size: 20),
              label: Text(context.tr('generate_timetable')),
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
          Text('😌', style: TextStyle(fontSize: 40)),
          SizedBox(height: 10),
          Text(
            context.tr('no_sessions_today'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            context.tr('take_a_break_or_review_previous_topics'),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13),
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
              color: isCurrent ? AppTheme.accentBlue : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.sessionDetail, arguments: {
                'session': session,
                'planId': _studyPlan?.id,
              });
            },
            borderRadius: BorderRadius.circular(10),
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
                  TranslatedText(
                    session.subject,
                    style: TextStyle(
                      color: session.isCompleted ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration: session.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  TranslatedText(
                    session.topic,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (session.isCompleted)
          const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // INCOMING REQUESTS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildIncomingRequests() {
    final uid = Provider.of<AuthProvider>(context).userModel?.uid;
    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.studentConnectionsStream(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        final incomingRequests = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? '';
          final requestedBy = data['requestedBy'] as String?;
          // If status is pending and we didn't send it, it's incoming
          return status == 'pending' && requestedBy != uid && requestedBy != null;
        }).toList();

        if (incomingRequests.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('pending_requests') ?? 'Pending Requests',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...incomingRequests.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['mentorName'] ?? 'Mentor';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.accentPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.person_add_rounded, color: AppTheme.accentPurple, size: 22),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                            Text(context.tr('wants_to_connect') ?? 'Wants to connect', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _firestore.updateConnectionStatus(doc.id, 'declined'),
                            icon: Icon(Icons.close_rounded, color: AppTheme.errorRed, size: 22),
                            style: IconButton.styleFrom(backgroundColor: AppTheme.errorRed.withOpacity(0.1)),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _firestore.updateConnectionStatus(doc.id, 'approved'),
                            icon: Icon(Icons.check_rounded, color: AppTheme.successGreen, size: 22),
                            style: IconButton.styleFrom(backgroundColor: AppTheme.successGreen.withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
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
            Text(
              context.tr('upcoming_reminders'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.remindersList),
              child: Text(
                context.tr('see_all'),
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ReminderModel>>(
          stream: _firestore.upcomingRemindersStream(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return InkWell(
                onTap: () => Navigator.pushNamed(context, AppRoutes.addReminder),
                borderRadius: BorderRadius.circular(20),
                child: AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.event_available_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 28),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          context.tr('no_upcoming_reminders_tap__to_add_one'),
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final reminders = snapshot.data!;

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
    final timeFormat = DateFormat('h:mm a');
    final dateFormat = DateFormat('MMM d');
    
    if (diff.inDays == 0) return '${context.tr('today')}, ${timeFormat.format(dt)}';
    if (diff.inDays == 1) return '${context.tr('tomorrow')}, ${timeFormat.format(dt)}';
    return '${dateFormat.format(dt)}, ${timeFormat.format(dt)}';
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
                TranslatedText(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
  // QUICK ACTIONS – Premium Cards
  // ═══════════════════════════════════════════════════════════════════
  // Widget _buildQuickActions() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         context.tr('quick_actions'),
  //         style: TextStyle(
  //           color: Theme.of(context).colorScheme.onSurface,
  //           fontSize: 20,
  //           fontWeight: FontWeight.w700,
  //         ),
  //       ),
  //       const SizedBox(height: 14),
  //       // Row 1: Focus Mode (Full Width)
  //       _buildPremiumCard(
  //         title: context.tr('focus_mode') ?? 'Focus Mode',
  //         subtitle: context.tr('deep_study') ?? 'Deep study and block apps',
  //         icon: Icons.self_improvement_rounded,
  //         gradient: const LinearGradient(
  //           colors: [Color(0xFF0acffe), Color(0xFF495aff)],
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //         ),
  //         onTap: () => Navigator.pushNamed(context, AppRoutes.focusMode),
  //       ),
  //       const SizedBox(height: 12),
  //       // Row 2: Mentors and Leaderboard
  //       Row(
  //         children: [
  //           Expanded(
  //             child: _buildPremiumCard(
  //               title: context.tr('mentors'),
  //               subtitle: context.tr('find_guidance') ?? 'Find guidance',
  //               icon: Icons.people_rounded,
  //               gradient: const LinearGradient(
  //                 colors: [Color(0xFF667eea), Color(0xFF764ba2)],
  //                 begin: Alignment.topLeft,
  //                 end: Alignment.bottomRight,
  //               ),
  //               onTap: () => Navigator.pushNamed(context, AppRoutes.findMentor),
  //             ),
  //           ),
  //           const SizedBox(width: 12),
  //           Expanded(
  //             child: _buildPremiumCard(
  //               title: context.tr('leaderboard'),
  //               subtitle: context.tr('compete_rank') ?? 'Compete & rank',
  //               icon: Icons.emoji_events_rounded,
  //               gradient: const LinearGradient(
  //                 colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
  //                 begin: Alignment.topLeft,
  //                 end: Alignment.bottomRight,
  //               ),
  //               onTap: () => Navigator.pushNamed(context, AppRoutes.pointSystem),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildPremiumCard({
  //   required String title,
  //   required String subtitle,
  //   required IconData icon,
  //   required Gradient gradient,
  //   required VoidCallback onTap,
  // }) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       height: 100,
  //       decoration: BoxDecoration(
  //         gradient: gradient,
  //         borderRadius: BorderRadius.circular(20),
  //         boxShadow: [
  //           BoxShadow(
  //             color: (gradient as LinearGradient).colors.first.withOpacity(0.35),
  //             blurRadius: 16,
  //             offset: const Offset(0, 6),
  //           ),
  //         ],
  //       ),
  //       child: Stack(
  //         children: [
  //           // Decorative circle
  //           Positioned(
  //             right: -12,
  //             top: -12,
  //             child: Container(
  //               width: 64,
  //               height: 64,
  //               decoration: BoxDecoration(
  //                 color: Colors.white.withOpacity(0.12),
  //                 shape: BoxShape.circle,
  //               ),
  //             ),
  //           ),
  //           Positioned(
  //             right: 8,
  //             bottom: -8,
  //             child: Container(
  //               width: 40,
  //               height: 40,
  //               decoration: BoxDecoration(
  //                 color: Colors.white.withOpacity(0.08),
  //                 shape: BoxShape.circle,
  //               ),
  //             ),
  //           ),
  //           // Content
  //           Padding(
  //             padding: const EdgeInsets.all(16),
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Container(
  //                   width: 36,
  //                   height: 36,
  //                   decoration: BoxDecoration(
  //                     color: Colors.white.withOpacity(0.2),
  //                     borderRadius: BorderRadius.circular(10),
  //                   ),
  //                   child: Icon(icon, color: Colors.white, size: 20),
  //                 ),
  //                 Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text(
  //                       title,
  //                       style: const TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 15,
  //                         fontWeight: FontWeight.w700,
  //                         height: 1.1,
  //                       ),
  //                       maxLines: 1,
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                     const SizedBox(height: 2),
  //                     Text(
  //                       subtitle,
  //                       style: TextStyle(
  //                         color: Colors.white.withOpacity(0.7),
  //                         fontSize: 11,
  //                         fontWeight: FontWeight.w500,
  //                       ),
  //                       maxLines: 1,
  //                       overflow: TextOverflow.ellipsis,
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  Widget _buildQuickActions() {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('quick_actions'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.divider),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(  
            children: [
              // 🔵 Main Button
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.focusMode);
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.self_improvement_rounded,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('focus_mode'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ⚪ Bottom Small Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMiniCard(
                      icon: Icons.people_rounded,
                      label: context.tr('mentors'),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.findMentor),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildMiniCard(
                      icon: Icons.emoji_events_rounded,
                      label: context.tr('leaderboard'),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.leaderboard),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


