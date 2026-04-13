import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/theme.dart';
import '../../../app/routes.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';
import '../../../services/firestore_service.dart';
import 'package:vidyasetu/services/localization_service.dart';

class StudentProfileMentorView extends StatefulWidget {
  const StudentProfileMentorView({super.key});

  @override
  State<StudentProfileMentorView> createState() => _StudentProfileMentorViewState();
}

class _StudentProfileMentorViewState extends State<StudentProfileMentorView> {
  Map<String, dynamic>? _studentData;
  List<Map<String, dynamic>> _recentActivity = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _studentData == null) {
      _loadStudentData(args);
    }
  }

  Future<void> _loadStudentData(Map<String, dynamic> args) async {
    final studentId = args['studentId'] as String? ?? args['uid'] as String? ?? '';
    if (studentId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(studentId).get();
      final data = doc.data() ?? {};
      data['uid'] = studentId;

      // Load recent study sessions
      final sessions = <Map<String, dynamic>>[];
      try {
        final plansSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .collection('timetable_plans')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (plansSnap.docs.isNotEmpty) {
          final planDoc = plansSnap.docs.first;
          final sessionsSnap = await planDoc.reference
              .collection('sessions')
              .where('isCompleted', isEqualTo: true)
              .orderBy('date', descending: true)
              .limit(5)
              .get();

          for (var s in sessionsSnap.docs) {
            sessions.add(s.data());
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _studentData = data;
          _recentActivity = sessions;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading student data: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final data = _studentData ?? {};
    final name = data['name']?.toString() ?? 'Student';
    final course = data['course']?.toString() ?? '';
    final institution = data['institution']?.toString() ?? '';
    final level = (data['level'] as num?)?.toInt() ?? 1;
    final points = (data['points'] as num?)?.toInt() ?? 0;
    final streak = (data['streak'] as num?)?.toInt() ?? 0;
    final totalHours = (data['totalStudyHours'] as num?)?.toDouble() ?? 0;
    final tasksCompleted = (data['tasksCompleted'] as num?)?.toInt() ?? 0;
    final subtitle = [course, institution].where((s) => s.isNotEmpty).join(' • ');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.accentPurple, AppTheme.accentBlue],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(name,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats
                  Row(
                    children: [
                      _stat(context.tr('level'), '$level', AppTheme.accentBlue),
                      _stat(context.tr('xp'), '$points', AppTheme.accentPurple),
                      _stat(context.tr('streak'), '${streak}d', AppTheme.warningAmber),
                      _stat(context.tr('hours'), '${totalHours.toInt()}', AppTheme.successGreen),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tasks completed
                  _section(context, context.tr('achievements') ?? 'Achievements'),
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _achievementStat('📝', '$tasksCompleted', 'Tasks Done'),
                        _achievementStat('🔥', '$streak', 'Day Streak'),
                        _achievementStat('⏰', '${totalHours.toInt()}h', 'Study Time'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent activity
                  _section(context, context.tr('recent_activity') ?? 'Recent Activity'),
                  if (_recentActivity.isEmpty)
                    AppCard(
                      child: Center(
                        child: Text('No recent activity.',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
                      ),
                    )
                  else
                    ..._recentActivity.map((session) {
                      final subject = session['subject']?.toString() ?? 'Study';
                      final topic = session['topic']?.toString() ?? '';
                      return _activityItem(
                        context,
                        Icons.check_circle_rounded,
                        'Completed: $subject${topic.isNotEmpty ? ' - $topic' : ''}',
                        '',
                        AppTheme.successGreen,
                      );
                    }),
                  SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: context.tr('send_feedback'),
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.sendFeedback, arguments: _studentData);
                          },
                          icon: Icons.feedback_rounded,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: context.tr('message'),
                          onPressed: () async {
                            final studentId = data['uid'] as String? ?? '';
                            if (studentId.isNotEmpty) {
                              final roomId = await FirestoreService().getOrCreateChatRoom(
                                ModalRoute.of(context)?.settings.arguments is Map
                                    ? ((ModalRoute.of(context)?.settings.arguments as Map)['mentorId'] ?? '')
                                    : '',
                                studentId,
                              );
                              if (mounted) {
                                Navigator.pushNamed(context, AppRoutes.chatConversation, arguments: {
                                  'roomId': roomId,
                                  'otherUserId': studentId,
                                  'otherUserName': name,
                                });
                              }
                            }
                          },
                          icon: Icons.chat_rounded,
                          isOutlined: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _achievementStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 11)),
      ],
    );
  }

  Widget _section(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _activityItem(
      BuildContext context, IconData icon, String text, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
