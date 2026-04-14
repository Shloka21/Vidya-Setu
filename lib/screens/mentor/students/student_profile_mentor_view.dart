import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme.dart';
import '../../../app/routes.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/stat_card.dart';
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
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.accentPurple,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6A11CB),
                      const Color(0xFF2575FC),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Center(
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(name,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5)),
                      if (subtitle.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(subtitle,
                              style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ),
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
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      StatCard(
                        label: context.tr('level'),
                        value: '$level',
                        icon: Icons.auto_awesome_rounded,
                        iconColor: AppTheme.accentBlue,
                      ),
                      StatCard(
                        label: context.tr('xp'),
                        value: '$points',
                        icon: Icons.bolt_rounded,
                        iconColor: AppTheme.accentPurple,
                      ),
                      StatCard(
                        label: context.tr('streak'),
                        value: '${streak}d',
                        icon: Icons.local_fire_department_rounded,
                        iconColor: AppTheme.warningAmber,
                      ),
                      StatCard(
                        label: context.tr('hours'),
                        value: '${totalHours.toInt()}h',
                        icon: Icons.timer_rounded,
                        iconColor: AppTheme.successGreen,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tasks completed
                  _section(context, context.tr('achievements') ?? 'Achievements'),
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _achievementStat(context, '📝', '$tasksCompleted', 'Tasks Done'),
                        _achievementStat(context, '🔥', '$streak', 'Day Streak'),
                        _achievementStat(context, '⏰', '${totalHours.toInt()}h', 'Study Time'),
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

  Widget _achievementStat(BuildContext context, String emoji, String value, String label) {
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
