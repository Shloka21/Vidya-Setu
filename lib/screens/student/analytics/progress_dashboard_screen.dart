import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/stat_card.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  String _selectedPeriod = 'Week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            Row(
              children: ['Week', 'Month', 'Year'].map((p) {
                final isSelected = _selectedPeriod == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(p),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedPeriod = p),
                    selectedColor: Theme.of(context).colorScheme.onSurface,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Stats cards
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 140,
                    child: StatCard(
                      label: 'Study Hours',
                      value: '24.5',
                      icon: Icons.timer_rounded,
                      iconColor: AppTheme.accentBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 140,
                    child: StatCard(
                      label: 'Tasks Done',
                      value: '18',
                      icon: Icons.task_alt_rounded,
                      iconColor: AppTheme.successGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 140,
                    child: StatCard(
                      label: 'Streak',
                      value: '12',
                      icon: Icons.local_fire_department_rounded,
                      isDark: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 140,
                    child: StatCard(
                      label: 'Score',
                      value: '87%',
                      icon: Icons.stars_rounded,
                      iconColor: AppTheme.warningAmber,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Study time chart
            Text(
              'Study Time',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 6,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            return Text(
                              days[value.toInt()],
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                                fontSize: 12,
                              ),
                            );
                          },
                          reservedSize: 24,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, _) {
                            return Text(
                              '${value.toInt()}h',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                                fontSize: 11,
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withOpacity(0.3),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: [
                      _makeBarGroup(0, 3.5),
                      _makeBarGroup(1, 4.2),
                      _makeBarGroup(2, 2.8),
                      _makeBarGroup(3, 5.0),
                      _makeBarGroup(4, 3.8),
                      _makeBarGroup(5, 4.5),
                      _makeBarGroup(6, 2.0),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Subject distribution
            Text(
              'Subject Distribution',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
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
                        sections: [
                          PieChartSectionData(
                            value: 30,
                            color: const Color(0xFF4A7BF7),
                            radius: 25,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: 25,
                            color: const Color(0xFF7C4DFF),
                            radius: 25,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: 20,
                            color: const Color(0xFF10B981),
                            radius: 25,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: 15,
                            color: const Color(0xFFF59E0B),
                            radius: 25,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            value: 10,
                            color: const Color(0xFFEF4444),
                            radius: 25,
                            showTitle: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildLegendItem(
                          'Mathematics',
                          '30%',
                          const Color(0xFF4A7BF7),
                        ),
                        _buildLegendItem(
                          'Physics',
                          '25%',
                          const Color(0xFF7C4DFF),
                        ),
                        _buildLegendItem(
                          'Chemistry',
                          '20%',
                          const Color(0xFF10B981),
                        ),
                        _buildLegendItem(
                          'English',
                          '15%',
                          const Color(0xFFF59E0B),
                        ),
                        _buildLegendItem(
                          'Biology',
                          '10%',
                          const Color(0xFFEF4444),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Task completion
            Text(
              'Task Completion',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
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
                            value: 0.75,
                            strokeWidth: 10,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.successGreen,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '75%',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatRow('Completed', '18', AppTheme.successGreen),
                        const SizedBox(height: 8),
                        _buildStatRow('Pending', '4', AppTheme.warningAmber),
                        const SizedBox(height: 8),
                        _buildStatRow('Missed', '2', AppTheme.errorRed),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
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
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
