import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';
import 'package:vidyasetu/services/localization_service.dart';

class StudentAnalyticsMentorScreen extends StatefulWidget {
  const StudentAnalyticsMentorScreen({super.key});

  @override
  State<StudentAnalyticsMentorScreen> createState() => _StudentAnalyticsMentorScreenState();
}

class _StudentAnalyticsMentorScreenState extends State<StudentAnalyticsMentorScreen> {
  final FirestoreService _firestore = FirestoreService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final studentsData = await _firestore.getConnectedStudents(uid);
      
      final enrichedStudents = studentsData.map((s) {
        final hours = (s['totalStudyHours'] as num?)?.toDouble() ?? 0.0;
        final streak = s['streak'] as int? ?? 0;
        
        // Mock progress for now if missing, as studyplans take complex querying to check overall completeness
        // Ideally we would query the user's study plans and check completed vs total sessions.
        final progress = (s['level'] as int? ?? 1) * 0.1; // Rough estimation based on level for analytics
        final cappedProgress = progress > 1.0 ? 1.0 : progress;

        final trend = (cappedProgress >= 0.1 || streak > 3) ? 'up' : ((cappedProgress > 0 || streak > 0) ? 'same' : 'down');

        return {
          'id': s['uid'],
          'name': s['name'] as String? ?? 'Student',
          'hours': hours,
          'subjects': 4, // Mock subjects count, could be fetched from study plans
          'streak': streak,
          'progress': cappedProgress,
          'trend': trend,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _students = enrichedStudents;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching analytics: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('student_analytics'))),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    int totalStudents = _students.length;
    double totalHours = _students.fold<double>(0.0, (s, e) => s + ((e['hours'] as num?)?.toDouble() ?? 0.0));
    double avgHours = totalStudents > 0 ? (totalHours / totalStudents) : 0.0;
    int activeStreaks = _students.where((s) => (s['streak'] as num? ?? 0).toInt() > 0).length;
    double totalProgress = _students.fold<double>(0.0, (s, e) => s + ((e['progress'] as num?)?.toDouble() ?? 0.0));
    double avgProgress = totalStudents > 0 ? (totalProgress / totalStudents) : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('student_analytics'))),
      body: RefreshIndicator(
        onRefresh: _fetchAnalytics,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview cards
              Row(
                children: [
                  _overviewCard(context, 'Total Students', '$totalStudents',
                      Icons.people_rounded, AppTheme.accentBlue),
                  const SizedBox(width: 12),
                  _overviewCard(
                      context,
                      'Avg Hours',
                      '${avgHours.toStringAsFixed(1)}h',
                      Icons.timer_rounded,
                      AppTheme.accentPurple),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  _overviewCard(context, 'Active Streaks', '$activeStreaks',
                      Icons.local_fire_department_rounded, AppTheme.warningAmber),
                  SizedBox(width: 12),
                  _overviewCard(context, 'Avg Progress', '${(avgProgress * 100).toStringAsFixed(0)}%',
                      Icons.speed_rounded, AppTheme.successGreen),
                ],
              ),
              SizedBox(height: 24),

              // Student cards
              Text(context.tr('individual_progress'),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 12),
              
              if (_students.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.analytics_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        SizedBox(height: 16),
                        Text(context.tr('no_students_yet'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 16)),
                      ],
                    ),
                  ),
                )
              else
                ..._students.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      (s['name'] as String).isNotEmpty ? (s['name'] as String)[0].toUpperCase() : 'S',
                                      style: TextStyle(
                                          color: AppTheme.accentBlue,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s['name'] as String,
                                          style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700)),
                                      Text('${(s['hours'] as double).toStringAsFixed(1)}h studied • 🔥 ${s['streak']}d',
                                          style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Icon(
                                  s['trend'] == 'up'
                                      ? Icons.trending_up_rounded
                                      : s['trend'] == 'down'
                                          ? Icons.trending_down_rounded
                                          : Icons.trending_flat_rounded,
                                  color: s['trend'] == 'up'
                                      ? AppTheme.successGreen
                                      : s['trend'] == 'down'
                                          ? AppTheme.errorRed
                                          : AppTheme.warningAmber,
                                  size: 24,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: s['progress'] as double,
                                      minHeight: 8,
                                      backgroundColor: AppTheme.divider,
                                      valueColor: AlwaysStoppedAnimation(
                                        (s['progress'] as double) >= 0.7
                                            ? AppTheme.successGreen
                                            : (s['progress'] as double) >= 0.5
                                                ? AppTheme.warningAmber
                                                : AppTheme.errorRed,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${((s['progress'] as double) * 100).toInt()}%',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewCard(
      BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  Text(label,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
