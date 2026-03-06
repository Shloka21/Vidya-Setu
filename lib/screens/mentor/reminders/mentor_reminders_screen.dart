import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../app/routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';

class MentorRemindersScreen extends StatelessWidget {
  const MentorRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<AuthProvider>(context).userModel?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Reminders')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Reminders'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createReminder),
        backgroundColor: AppTheme.accentBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Create Reminder',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService().mentorRemindersStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          // Sort manually since we aren't using an index
          final reminders = docs.map((d) => d.data() as Map<String, dynamic>).toList();
          reminders.sort((a, b) {
            final aTime = (a['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime = (b['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime); // Descending
          });

          if (reminders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.notifications_active_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                   const SizedBox(height: 16),
                   Text('No reminders sent yet.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
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
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(initial,
                                  style: TextStyle(
                                      color: AppTheme.accentBlue,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['title'] as String? ?? 'Reminder',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                                Text('To: $studentName',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? AppTheme.successGreen.withOpacity(0.1)
                                  : AppTheme.warningAmber.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isRead ? 'Done' : 'Sent',
                              style: TextStyle(
                                color: isRead
                                    ? AppTheme.successGreen
                                    : AppTheme.warningAmber,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(r['description'] as String? ?? '',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 13,
                              height: 1.4)),
                      const SizedBox(height: 8),
                      Text(dateStr,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 11)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
