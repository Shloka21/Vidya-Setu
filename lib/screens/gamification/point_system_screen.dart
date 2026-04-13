import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../widgets/common/app_card.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import 'package:vidyasetu/services/localization_service.dart';

class PointSystemScreen extends StatelessWidget {
  const PointSystemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Fetch real user data
    final authProvider = Provider.of<AuthProvider>(context);
    final points = authProvider.userModel?.points ?? 0;
    final levelData = UserModel.calculateLevel(points);
    final level = levelData['level'] as int;
    final levelTitle = levelData['title'] as String;
    final nextXp = levelData['nextXp'] as int;
    final prevXp = levelData['prevXp'] as int;
    final progress = ((points - prevXp) / (nextXp - prevXp)).clamp(0.0, 1.0);

    final activities = [

      {'icon': Icons.timer_rounded, 'label': 'Complete study session', 'xp': 20, 'color': AppTheme.accentBlue},
      {'icon': Icons.check_circle_rounded, 'label': 'Finish a topic', 'xp': 50, 'color': AppTheme.successGreen},
      {'icon': Icons.local_fire_department_rounded, 'label': 'Maintain daily streak', 'xp': 10, 'color': AppTheme.warningAmber},
      {'icon': Icons.quiz_rounded, 'label': 'Score 80%+ on quiz', 'xp': 30, 'color': AppTheme.accentPurple},
      {'icon': Icons.emoji_events_rounded, 'label': 'Earn an achievement', 'xp': 100, 'color': Color(0xFFFFD700)},
      {'icon': Icons.people_rounded, 'label': 'Connect with mentor', 'xp': 40, 'color': AppTheme.accentBlue},
      {'icon': Icons.chat_rounded, 'label': 'Active chat participation', 'xp': 15, 'color': AppTheme.successGreen},
      {'icon': Icons.calendar_month_rounded, 'label': '7-day streak bonus', 'xp': 75, 'color': AppTheme.errorRed},
    ];

    final levels = [
      {'level': 1, 'xp': 0, 'title': 'Beginner'},
      {'level': 2, 'xp': 100, 'title': 'Learner'},
      {'level': 3, 'xp': 300, 'title': 'Explorer'},
      {'level': 4, 'xp': 600, 'title': 'Achiever'},
      {'level': 5, 'xp': 1000, 'title': 'Scholar'},
      {'level': 6, 'xp': 1500, 'title': 'Expert'},
      {'level': 7, 'xp': 2200, 'title': 'Master'},
      {'level': 8, 'xp': 3000, 'title': 'Champion'},
      {'level': 9, 'xp': 4000, 'title': 'Legend'},
      {'level': 10, 'xp': 5500, 'title': 'Guru'},
    ];

    return Scaffold(
      
      appBar: AppBar(title: Text(context.tr('point_system'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accentBlue, AppTheme.accentPurple],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                    Text(context.tr('your_points'),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('$points XP',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Level $level: $levelTitle',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 16),
                  // Progress to next level
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$points / $nextXp XP',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12)),
                          Text('Level ${level + 1}',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation(
                              Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            // How to earn XP
            Text(context.tr('how_to_earn_xp'),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...activities.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: (a['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(a['icon'] as IconData,
                              color: a['color'] as Color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(a['label'] as String,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('+${a['xp']} XP',
                              style: TextStyle(
                                  color: AppTheme.accentBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                )),
            SizedBox(height: 24),

            // Level chart
            Text(context.tr('level_progression'),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: levels.map((l) {
                  final lLevel = l['level'] as int;
                  final isCurrent = lLevel == level;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppTheme.accentBlue.withOpacity(0.05)
                          : null,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.divider, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text('$lLevel',
                              style: TextStyle(
                                  color: isCurrent
                                      ? AppTheme.accentBlue
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Expanded(
                          child: Text(l['title'] as String,
                              style: TextStyle(
                                  color: isCurrent
                                      ? AppTheme.accentBlue
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w500)),
                        ),
                        Text('${l['xp']} XP',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('YOU',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

