import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_card.dart';

class SubjectAnalyticsScreen extends StatelessWidget {
  const SubjectAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    const subjectName = 'Mathematics';
    final topics = [
      {'name': 'Algebra', 'hours': 8.5, 'completed': true, 'difficulty': 3},
      {'name': 'Calculus', 'hours': 12.0, 'completed': false, 'difficulty': 5},
      {'name': 'Statistics', 'hours': 6.0, 'completed': true, 'difficulty': 2},
      {'name': 'Trigonometry', 'hours': 4.5, 'completed': false, 'difficulty': 4},
      {'name': 'Geometry', 'hours': 7.0, 'completed': true, 'difficulty': 3},
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Subject Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject header
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.calculate_rounded,
                        color: AppTheme.accentBlue, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subjectName,
                            style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('38 hours studied • 60% complete',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Study hours chart
            Text('Study Hours by Topic',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            AppCard(
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 15,
                    barGroups: topics.asMap().entries.map((e) {
                      return BarChartGroupData(x: e.key, barRods: [
                        BarChartRodData(
                          toY: (e.value['hours'] as num).toDouble(),
                          color: (e.value['completed'] as bool)
                              ? AppTheme.successGreen
                              : AppTheme.accentBlue,
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ]);
                    }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true, reservedSize: 30,
                              getTitlesWidget: (v, _) => Text('${v.toInt()}h',
                                  style: TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: 10)))),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final names = topics.map((t) => (t['name'] as String).substring(0, 3)).toList();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(names[v.toInt()],
                                      style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 10)),
                                );
                              })),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                            color: AppTheme.divider, strokeWidth: 1)),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Topics breakdown
            Text('Topic Breakdown',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...topics.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (t['completed'] as bool)
                                ? AppTheme.successGreen.withOpacity(0.1)
                                : AppTheme.warningAmber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            (t['completed'] as bool)
                                ? Icons.check_circle_rounded
                                : Icons.timer_rounded,
                            color: (t['completed'] as bool)
                                ? AppTheme.successGreen
                                : AppTheme.warningAmber,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['name'] as String,
                                  style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('${t['hours']}h studied',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        // Difficulty stars
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < (t['difficulty'] as int)
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: AppTheme.warningAmber,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
