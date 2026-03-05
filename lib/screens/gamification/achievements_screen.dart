import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/common/app_card.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final achievements = [
      {'title': 'First Steps', 'desc': 'Complete your first task', 'icon': Icons.flag_rounded, 'color': AppTheme.accentBlue, 'unlocked': true, 'xp': 50},
      {'title': 'Week Warrior', 'desc': '7-day study streak', 'icon': Icons.local_fire_department_rounded, 'color': AppTheme.warningAmber, 'unlocked': true, 'xp': 100},
      {'title': 'Quiz Master', 'desc': 'Score 100% on 5 quizzes', 'icon': Icons.quiz_rounded, 'color': AppTheme.accentPurple, 'unlocked': true, 'xp': 150},
      {'title': 'Bookworm', 'desc': '50 hours of study time', 'icon': Icons.menu_book_rounded, 'color': AppTheme.successGreen, 'unlocked': false, 'xp': 200},
      {'title': 'Social Star', 'desc': 'Connect with 5 mentors', 'icon': Icons.people_rounded, 'color': const Color(0xFFEC4899), 'unlocked': false, 'xp': 250},
      {'title': 'Legend', 'desc': 'Reach Level 10', 'icon': Icons.stars_rounded, 'color': const Color(0xFFEF4444), 'unlocked': false, 'xp': 500},
    ];

    return Scaffold(
      
      appBar: AppBar(title: const Text('Achievements')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // XP Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.navyGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '300 XP Earned!',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '3 of 6 achievements unlocked',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 3 / 6,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Unlocked', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...achievements.where((a) => a['unlocked'] == true).map((a) => _buildAchievementCard(a, true)),

            const SizedBox(height: 24),
            Text('Locked', style: TextStyle(color: AppTheme.primaryNavy, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...achievements.where((a) => a['unlocked'] == false).map((a) => _buildAchievementCard(a, false)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> data, bool unlocked) {
    final color = data['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Opacity(
          opacity: unlocked ? 1.0 : 0.5,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(data['icon'] as IconData, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] as String,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['desc'] as String,
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: unlocked ? AppTheme.successGreen.withOpacity(0.1) : AppTheme.divider,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '+${data['xp']} XP',
                  style: TextStyle(
                    color: unlocked ? AppTheme.successGreen : AppTheme.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (unlocked) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
