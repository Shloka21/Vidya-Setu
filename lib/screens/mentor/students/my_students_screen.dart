import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';

class MyStudentsScreen extends StatelessWidget {
  MyStudentsScreen({super.key});

  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final mentorId = authProvider.userModel?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Students'),
        actions: [
          IconButton(
              icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      body: mentorId.isEmpty
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<QuerySnapshot>(
              stream:
                  _firestoreService.mentorConnectionsStream(mentorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: AppTheme.errorRed, size: 48),
                        const SizedBox(height: 12),
                        Text('Error loading students',
                            style:
                                TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            color: AppTheme.textLight, size: 64),
                        const SizedBox(height: 16),
                        Text('No students yet',
                            style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Students will appear here when they connect',
                            style: TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 14)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final connection =
                        docs[index].data() as Map<String, dynamic>;
                    final studentId =
                        connection['studentId'] as String? ?? '';
                    final studentName =
                        connection['studentName'] as String? ?? 'Student';

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _firestoreService.getUser(studentId),
                      builder: (context, userSnap) {
                        final studentData = userSnap.data;
                        final name =
                            studentData?['name'] as String? ?? studentName;
                        final level = studentData?['level'] ?? 1;
                        final streak = studentData?['streak'] ?? 0;
                        final hours =
                            (studentData?['totalStudyHours'] ?? 0).toDouble();
                        final points = studentData?['points'] ?? 0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.studentProfileMentorView,
                              arguments: studentData ?? {'uid': studentId},
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentBlue
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      name.isNotEmpty ? name[0] : 'S',
                                      style: TextStyle(
                                          color: AppTheme.accentBlue,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Level $level • 🔥 ${streak}d • ${hours.toStringAsFixed(0)}h studied',
                                        style: TextStyle(
                                            color:
                                                AppTheme.textSecondary,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentPurple
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Text('$points XP',
                                      style: TextStyle(
                                          color: AppTheme.accentPurple,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
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
}
