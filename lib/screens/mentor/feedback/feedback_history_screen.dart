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
  const FeedbackHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<AuthProvider>(context).userModel?.uid;
    final isMentor = Provider.of<AuthProvider>(context).userModel?.role == 'mentor';

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('feedback'))),
        body: Center(child: Text(context.tr('not_logged_in'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('feedback')),
      ),
      floatingActionButton: isMentor ? FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.sendFeedback),
        backgroundColor: AppTheme.accentBlue,
        icon: Icon(Icons.add_rounded, color: Colors.white),
        label: Text(context.tr('create'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ) : null,
      body: _FeedbackTab(uid: uid, isMentor: isMentor),
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
                              if (isMentor)
                                Text('To: ${fb['studentName']}',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12))
                              else
                                FutureBuilder<Map<String, dynamic>?>(
                                  future: (fb['mentorName'] != null) ? null : FirestoreService().getUser(fb['mentorId'] ?? ''),
                                  builder: (context, snapshot) {
                                    final name = fb['mentorName'] ?? snapshot.data?['name'] ?? 'Your Mentor';
                                    return Text('From: $name',
                                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12));
                                  },
                                ),
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
