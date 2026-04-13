import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/timetable_model.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/stat_card.dart';
import '../../../widgets/common/translated_text.dart';
import 'package:vidyasetu/services/localization_service.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() => _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  String _selectedPeriod = 'week';
  final FirestoreService _firestore = FirestoreService();
  StudyPlan? _studyPlan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final plan = await _firestore.getStudyPlan(uid);
      if (mounted) setState(() { _studyPlan = plan; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Computed Stats ─────────────────────────────────────────

  List<TimetableSession> get _sessionsInPeriod {
    if (_studyPlan == null) return [];
    final now = DateTime.now();
    DateTime startDate;
    if (_selectedPeriod == 'week') {
      startDate = now.subtract(const Duration(days: 7));
    } else if (_selectedPeriod == 'month') {
      startDate = now.subtract(const Duration(days: 30));
    } else {
      startDate = DateTime.fromMillisecondsSinceEpoch(0);
    }
    return _studyPlan!.sessions.where((s) => s.date.isAfter(startDate) || s.date.isAtSameMomentAs(startDate)).toList();
  }

  List<TimetableSession> get _completedSessions =>
      _sessionsInPeriod.where((s) => s.isCompleted).toList();

  int get _pendingSessions {
    final now = DateTime.now();
    return _sessionsInPeriod.where((s) => !s.isCompleted && s.endTime.isAfter(now)).length;
  }

  int get _missedSessions {
    final now = DateTime.now();
    return _sessionsInPeriod.where((s) => !s.isCompleted && s.endTime.isBefore(now)).length;
  }

  double get _totalStudyHours =>
      _completedSessions.fold<double>(0, (s, e) => s + e.durationMinutes / 60.0);

  double get _completionRate =>
      _sessionsInPeriod.isEmpty ? 0 : _completedSessions.length / _sessionsInPeriod.length;

  Map<String, double> get _subjectDistribution {
    final map = <String, double>{};
    for (var s in _completedSessions) {
      map[s.subject] = (map[s.subject] ?? 0) + s.durationMinutes;
    }
    return map;
  }

  List<double> get _chartData {
    final now = DateTime.now();
    if (_selectedPeriod == 'week') {
      final result = List<double>.filled(7, 0.0);
      for (var s in _completedSessions) {
        final diff = now.difference(s.date).inDays;
        if (diff >= 0 && diff < 7) {
          final dayIndex = s.date.weekday - 1; // 0=Mon
          result[dayIndex] += s.durationMinutes / 60.0;
        }
      }
      return result;
    } else if (_selectedPeriod == 'month') {
      // 4 weeks representation
      final result = List<double>.filled(4, 0.0);
      for (var s in _completedSessions) {
        final diff = now.difference(s.date).inDays;
        if (diff >= 0 && diff < 28) {
          final weekIndex = 3 - (diff ~/ 7); // 3=this week, 0=3 weeks ago
          result[weekIndex] += s.durationMinutes / 60.0;
        }
      }
      return result;
    } else {
      // All time - 6 months representation
      final result = List<double>.filled(6, 0.0);
      for (var s in _completedSessions) {
        final diff = now.difference(s.date).inDays;
        if (diff >= 0 && diff < 180) {
          final monthIndex = 5 - (diff ~/ 30); // 5=this month, 0=5 months ago
          result[monthIndex] += s.durationMinutes / 60.0;
        }
      }
      return result;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;

    return Scaffold(
      
      appBar: AppBar(title: Text(context.tr('analytics'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period selector
                    Row(
                      children: ['week', 'month', 'all'].map((p) {
                        final isSelected = _selectedPeriod == p;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(context.tr(p)),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedPeriod = p),
                            selectedColor: AppTheme.primaryNavy,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),

                    // Stats cards
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: context.tr('study_hours'),
                              value: _totalStudyHours.toStringAsFixed(1),
                              icon: Icons.timer_rounded,
                              iconColor: AppTheme.accentBlue,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              label: context.tr('tasks_done'),
                              value: '${_completedSessions.length}',
                              icon: Icons.task_alt_rounded,
                              iconColor: AppTheme.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: context.tr('streak'),
                              value: '${user?.streak ?? 0}',
                              icon: Icons.local_fire_department_rounded,
                              isDark: true,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: StatCard(
                              label: context.tr('score'),
                              value: '${(_completionRate * 100).toInt()}%',
                              icon: Icons.stars_rounded,
                              iconColor: AppTheme.warningAmber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    // Insights section
                    _buildInsightsSection(),
                    SizedBox(height: 24),

                    // Study time chart
                    Text(context.tr('study_time'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    AppCard(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: (_chartData.isEmpty ? 2.0 : _chartData.reduce((a, b) => a > b ? a : b) + 1).ceilToDouble().clamp(2, _selectedPeriod == 'week' ? 12.0 : 50.0),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, gIdx, rod, rIdx) {
                                  return BarTooltipItem(
                                    '${rod.toY.toStringAsFixed(1)}h',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, _) {
                                    if (_selectedPeriod == 'week') {
                                      const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                      if (value.toInt() >= 0 && value.toInt() < days.length) {
                                        return Text(days[value.toInt()], style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12));
                                      }
                                    } else if (_selectedPeriod == 'month') {
                                      return Text('W${value.toInt() + 1}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12));
                                    } else {
                                      return Text('M${value.toInt() + 1}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12));
                                    }
                                    return const Text('');
                                  },
                                  reservedSize: 24,
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, _) {
                                    return Text('${value.toInt()}h', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 11));
                                  },
                                  reservedSize: 28,
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.divider, strokeWidth: 1),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(_chartData.length, (i) => _makeBarGroup(i, _chartData[i])),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Subject distribution
                    Text(context.tr('subject_distribution'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
                    SizedBox(height: 12),
                    _buildSubjectDistribution(),
                    SizedBox(height: 24),

                    // Task completion
                    Text(context.tr('task_completion'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _buildTaskCompletion(),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSubjectDistribution() {
    final dist = _subjectDistribution;
    if (dist.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(context.tr('complete_study_sessions_to_see_your_subj'),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
        ),
      );
    }

    final total = dist.values.fold<double>(0, (s, e) => s + e);
    final colors = [
      const Color(0xFF4A7BF7), const Color(0xFF7C4DFF), const Color(0xFF10B981),
      const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFF06B6D4),
      const Color(0xFFF97316), const Color(0xFF8B5CF6),
    ];

    final entries = dist.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: entries.asMap().entries.map((e) {
                  final pct = e.value.value / total * 100;
                  return PieChartSectionData(
                    value: pct,
                    color: colors[e.key % colors.length],
                    radius: 25,
                    showTitle: false,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: entries.asMap().entries.map((e) {
                final pct = (e.value.value / total * 100).toInt();
                return _buildLegendItem(
                  e.value.key,
                  '$pct%',
                  colors[e.key % colors.length],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCompletion() {
    final completed = _completedSessions.length;
    final pending = _pendingSessions;
    final missed = _missedSessions;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _completionRate,
                    strokeWidth: 10,
                    backgroundColor: AppTheme.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successGreen),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${(_completionRate * 100).toInt()}%',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow(context.tr('completed'), '$completed', AppTheme.successGreen),
                SizedBox(height: 8),
                _buildStatRow(context.tr('pending'), '$pending', AppTheme.warningAmber),
                SizedBox(height: 8),
                _buildStatRow(context.tr('missed'), '$missed', AppTheme.errorRed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppTheme.accentBlue,
          width: 18,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildInsightsSection() {
    final trendValue = 12; // In a real app, calculate this from previous period
    final topSubject = _subjectDistribution.entries.isEmpty 
        ? 'None' 
        : (_subjectDistribution.entries.toList()..sort((a,b) => b.value.compareTo(a.value))).first.key;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.trending_up_rounded, color: AppTheme.successGreen, size: 24),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('weekly_progress'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    TranslatedText('You studied $trendValue% more than last week!', 
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.psychology_rounded, color: AppTheme.accentPurple, size: 24),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('top_subject'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    TranslatedText('Your most studied subject is $topSubject', 
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13), overflow: TextOverflow.ellipsis),
          ),
          Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
        const Spacer(),
        Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

