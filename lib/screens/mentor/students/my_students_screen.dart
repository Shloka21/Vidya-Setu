import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';
import 'package:vidyasetu/services/localization_service.dart';

class MyStudentsScreen extends StatelessWidget {
  MyStudentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final uid = auth.userModel?.uid ?? '';
    final firestore = FirestoreService();

    return Scaffold(
      
      appBar: AppBar(
        title: Text(context.tr('my_students')),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.browseStudents),
            icon: Icon(Icons.person_search_rounded, size: 20, color: AppTheme.accentPurple),
            label: Text(context.tr('find_students'), style: TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.scheduleGroupMeeting),
        icon: const Icon(Icons.groups_rounded),
        label: Text(context.tr('schedule_group_meeting') ?? 'Group Meeting'),
        backgroundColor: AppTheme.accentPurple,
        foregroundColor: Colors.white,
      ),
      body: uid.isEmpty
          ? Center(child: Text(context.tr('not_logged_in')))
          : StreamBuilder<QuerySnapshot>(
              stream: firestore.mentorConnectionsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 64),
                          SizedBox(height: 16),
                          Text(context.tr('no_students_yet_1'),
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          Text(context.tr('students_can_send_you_connection_request'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final connData = docs[index].data() as Map<String, dynamic>;
                    final studentId = connData['studentId'] as String? ?? '';
                    final studentName = connData['studentName'] as String? ?? 'Student';

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: firestore.getUser(studentId),
                      builder: (context, userSnap) {
                        final studentData = userSnap.data;
                        final name = studentData?['name'] as String? ?? studentName;
                        final course = studentData?['course'] as String? ?? '';
                        final institution = studentData?['institution'] as String? ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentBlue.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: studentData?['profileImageUrl'] != null
                                          ? ClipOval(child: Image.network(studentData!['profileImageUrl'], fit: BoxFit.cover, width: 50, height: 50))
                                          : Center(
                                              child: Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                                style: TextStyle(color: AppTheme.accentBlue, fontSize: 20, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                                          if (course.isNotEmpty)
                                            Text(course, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13)),
                                          if (institution.isNotEmpty)
                                            Text(institution, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        _actionButton(
                                          icon: Icons.chat_rounded,
                                          label: context.tr('message'),
                                          color: AppTheme.primaryNavy,
                                          onTap: () async {
                                            final roomId = await firestore.getOrCreateChatRoom(uid, studentId);
                                            if (context.mounted) {
                                              Navigator.pushNamed(context, AppRoutes.chatConversation, arguments: {
                                                'roomId': roomId,
                                                'otherUserId': studentId,
                                                'otherUserName': name,
                                              });
                                            }
                                          },
                                        ),
                                        SizedBox(width: 8),
                                        _actionButton(
                                          icon: Icons.videocam_rounded,
                                          label: context.tr('video_call'),
                                          color: AppTheme.successGreen,
                                          onTap: () async {
                                            final roomId = await firestore.getOrCreateChatRoom(uid, studentId);
                                            if (context.mounted) {
                                              Navigator.pushNamed(context, AppRoutes.videoCall, arguments: {
                                                'roomId': roomId,
                                                'otherUserName': name,
                                              });
                                            }
                                          },
                                        ),
                                        SizedBox(width: 8),
                                        _actionButton(
                                          icon: Icons.calendar_month_rounded,
                                          label: context.tr('schedule'),
                                          color: AppTheme.accentPurple,
                                          onTap: () => _showScheduleDialog(context, uid, studentId, name, firestore),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _actionButton(
                                          icon: Icons.feedback_rounded,
                                          label: context.tr('feedback'),
                                          color: AppTheme.warningAmber,
                                          onTap: () => Navigator.pushNamed(context, AppRoutes.feedbackHistory),
                                        ),
                                        SizedBox(width: 8),
                                        _actionButton(
                                          icon: Icons.alarm_add_rounded,
                                          label: context.tr('reminder') ?? 'Reminder',
                                          color: AppTheme.errorRed,
                                          onTap: () => Navigator.pushNamed(
                                            context, 
                                            AppRoutes.addReminder, 
                                            arguments: {'studentId': studentId}
                                          ),
                                        ),
                                        // Empty placeholder for alignment
                                        SizedBox(width: 8),
                                        Expanded(child: SizedBox()),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  void _showScheduleDialog(BuildContext context, String mentorId, String studentId, String studentName, FirestoreService firestore) {
    DateTime selectedDate = DateTime.now().add(Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay(hour: 10, minute: 0);
    final titleController = TextEditingController(text: 'Study Session with $studentName');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(context.tr('schedule_meeting'), style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: context.tr('meeting_title'),
                  filled: true, fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                dense: true, contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today_rounded, color: AppTheme.accentBlue),
                title: Text(DateFormat('EEE, MMM d, yyyy').format(selectedDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx, initialDate: selectedDate,
                    firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
              ListTile(
                dense: true, contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.access_time_rounded, color: AppTheme.accentPurple),
                title: Text(selectedTime.format(ctx)),
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (picked != null) setDialogState(() => selectedTime = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))),
            ElevatedButton(
              onPressed: () async {
                final scheduledAt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                final meetingId = FirebaseFirestore.instance.collection('_').doc().id;

                // Create chat room if not exists
                final roomId = await firestore.getOrCreateChatRoom(mentorId, studentId);

                await firestore.scheduleMeeting({
                  'id': meetingId,
                  'title': titleController.text.trim(),
                  'scheduledAt': Timestamp.fromDate(scheduledAt),
                  'createdBy': mentorId,
                  'participants': [mentorId, studentId],
                  'roomId': roomId,
                  'status': 'scheduled',
                });

                // Send system message
                final msgId = FirebaseFirestore.instance.collection('_').doc().id;
                await firestore.sendMessage(roomId, {
                  'id': msgId,
                  'content': '📅 Meeting scheduled: ${titleController.text.trim()} on ${DateFormat('MMM d').format(scheduledAt)} at ${selectedTime.format(ctx)}',
                  'senderId': mentorId,
                  'receiverId': studentId,
                  'timestamp': Timestamp.now(),
                  'type': 'system',
                });

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.tr('meeting_scheduled')),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
              child: Text(context.tr('schedule')),
            ),
          ],
        ),
      ),
    );
  }
}

