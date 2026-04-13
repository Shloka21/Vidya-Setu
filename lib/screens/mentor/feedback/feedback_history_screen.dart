import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../app/routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';
import 'package:vidyasetu/services/localization_service.dart';

class FeedbackHistoryScreen extends StatelessWidget {
  FeedbackHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<AuthProvider>(context).userModel?.uid;
    final isMentor = Provider.of<AuthProvider>(context).userModel?.role == 'mentor';

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('feedback__reminders'))),
        body: Center(child: Text(context.tr('not_logged_in'))),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('feedback__reminders')),
          bottom: TabBar(
            indicatorColor: AppTheme.accentBlue,
            labelColor: AppTheme.accentBlue,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: [
              Tab(icon: Icon(Icons.feedback_rounded, size: 20), text: context.tr('feedback')),
              Tab(icon: Icon(Icons.notification_add_rounded, size: 20), text: context.tr('reminders')),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (BuildContext innerContext) {
            return FloatingActionButton.extended(
              onPressed: () {
                final tabIndex = DefaultTabController.of(innerContext).index;
                if (tabIndex == 0) {
                  Navigator.pushNamed(innerContext, AppRoutes.sendFeedback);
                } else {
                  Navigator.pushNamed(innerContext, AppRoutes.createReminder);
                }
              },
              backgroundColor: AppTheme.accentBlue,
              icon: Icon(Icons.add_rounded, color: Colors.white),
              label: Text(context.tr('create'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            );
          }
        ),
        body: TabBarView(
          children: [
            _FeedbackTab(uid: uid, isMentor: isMentor),
            _RemindersTab(uid: uid),
          ],
        ),
      ),
    );
  }
}

// ═══ FEEDBACK TAB ═══
class _FeedbackTab extends StatelessWidget {
  final String uid;
  final bool isMentor;
  const _FeedbackTab({required this.uid, required this.isMentor});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().getFeedbackStream(uid, isMentor: isMentor),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feedback_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                SizedBox(height: 16),
                Text(context.tr('no_feedback_yet'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16)),
                SizedBox(height: 8),
                Text(context.tr('tap__to_send_feedback_to_a_stu'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 13)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final fb = docs[index].data() as Map<String, dynamic>;
            final dateStr = fb['createdAt'] != null
                ? DateFormat('MMM d, yyyy').format((fb['createdAt'] as Timestamp).toDate())
                : 'Unknown Date';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: _typeColor(fb['type'] as String? ?? '').withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_typeIcon(fb['type'] as String? ?? ''), color: _typeColor(fb['type'] as String? ?? ''), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fb['title'] as String? ?? 'Feedback',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(isMentor ? 'To: ${fb['studentName']}' : 'From Mentor',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (i) => Icon(
                                i < (fb['rating'] as int? ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                                color: AppTheme.warningAmber, size: 14,
                              )),
                            ),
                            const SizedBox(height: 4),
                            Text(dateStr, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _typeColor(fb['type'] as String? ?? '').withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(fb['type'] as String? ?? 'Feedback',
                          style: TextStyle(color: _typeColor(fb['type'] as String? ?? ''), fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 10),
                    Text(fb['message'] as String? ?? '',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13, height: 1.5)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Progress Update': return AppTheme.accentBlue;
      case 'Achievement Recognition': return AppTheme.successGreen;
      case 'Area of Improvement': return AppTheme.warningAmber;
      case 'Study Suggestion': return AppTheme.accentPurple;
      default: return AppTheme.accentBlue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Progress Update': return Icons.trending_up_rounded;
      case 'Achievement Recognition': return Icons.emoji_events_rounded;
      case 'Area of Improvement': return Icons.flag_rounded;
      case 'Study Suggestion': return Icons.lightbulb_rounded;
      default: return Icons.feedback_rounded;
    }
  }
}

// ═══ REMINDERS TAB ═══
class _RemindersTab extends StatelessWidget {
  final String uid;
  const _RemindersTab({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().mentorRemindersStream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        final reminders = docs.map((d) => d.data() as Map<String, dynamic>).toList();
        reminders.sort((a, b) {
          final aTime = (a['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime = (b['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        if (reminders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_active_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                SizedBox(height: 16),
                Text(context.tr('no_reminders_sent_yet'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16)),
                SizedBox(height: 8),
                Text(context.tr('tap__to_create_a_reminder_for'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 13)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final r = reminders[index];
            final isRead = r['isCompleted'] == true;
            final dateStr = r['dateTime'] != null
                ? DateFormat('MMM d, yyyy').format((r['dateTime'] as Timestamp).toDate())
                : 'Unknown';
            final studentName = r['studentName'] as String? ?? 'Student';
            final initial = studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: AppTheme.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(initial, style: TextStyle(color: AppTheme.accentBlue, fontSize: 18, fontWeight: FontWeight.w700))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['title'] as String? ?? 'Reminder',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w700)),
                              Text('${context.tr('to_label')}: $studentName',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isRead ? AppTheme.successGreen.withOpacity(0.1) : AppTheme.warningAmber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(isRead ? 'Done' : 'Sent',
                              style: TextStyle(color: isRead ? AppTheme.successGreen : AppTheme.warningAmber, fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(r['description'] as String? ?? '',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13, height: 1.4)),
                    const SizedBox(height: 8),
                    Text(dateStr, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 11)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
