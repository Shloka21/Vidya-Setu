import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../services/localization_service.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int requiredValue;
  final int xpReward;
  final String type; // 'xp', 'streak', 'hours', 'tasks', 'level'
  bool unlocked;
  int? currentValue;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredValue,
    required this.xpReward,
    required this.type,
    this.unlocked = false,
    this.currentValue,
  });
}

class GamificationLogic {
  static List<Achievement> getAchievements(BuildContext context, {
    required int xpPoints,
    required int streak,
    required double totalHours,
    required int tasksCompleted,
    required int level,
  }) {
    return [
      // XP-based achievements
      Achievement(
        id: 'first_xp',
        title: context.tr('first_steps') ?? 'First Steps',
        description: context.tr('earn_50_xp') ?? 'Earn 50 XP',
        icon: Icons.flag_rounded,
        color: AppTheme.accentBlue,
        type: 'xp',
        requiredValue: 50,
        xpReward: 50,
        currentValue: xpPoints,
        unlocked: xpPoints >= 50,
      ),
      Achievement(
        id: 'xp_100',
        title: context.tr('rising_star') ?? 'Rising Star',
        description: context.tr('earn_100_xp') ?? 'Earn 100 XP',
        icon: Icons.star_rounded,
        color: AppTheme.warningAmber,
        type: 'xp',
        requiredValue: 100,
        xpReward: 100,
        currentValue: xpPoints,
        unlocked: xpPoints >= 100,
      ),
      Achievement(
        id: 'xp_500',
        title: context.tr('scholar') ?? 'Scholar',
        description: context.tr('earn_500_xp') ?? 'Earn 500 XP',
        icon: Icons.school_rounded,
        color: AppTheme.accentPurple,
        type: 'xp',
        requiredValue: 500,
        xpReward: 250,
        currentValue: xpPoints,
        unlocked: xpPoints >= 500,
      ),
      Achievement(
        id: 'xp_1000',
        title: context.tr('legend') ?? 'Legend',
        description: context.tr('earn_1000_xp') ?? 'Earn 1000 XP',
        icon: Icons.stars_rounded,
        color: const Color(0xFFEF4444),
        type: 'xp',
        requiredValue: 1000,
        xpReward: 500,
        currentValue: xpPoints,
        unlocked: xpPoints >= 1000,
      ),

      // Streak achievements
      Achievement(
        id: 'streak_3',
        title: context.tr('consistent') ?? 'Consistent',
        description: context.tr('3_day_streak') ?? '3-day study streak',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFF97316),
        type: 'streak',
        requiredValue: 3,
        xpReward: 75,
        currentValue: streak,
        unlocked: streak >= 3,
      ),
      Achievement(
        id: 'streak_7',
        title: context.tr('week_warrior') ?? 'Week Warrior',
        description: context.tr('7_day_streak') ?? '7-day streak',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFEF4444),
        type: 'streak',
        requiredValue: 7,
        xpReward: 150,
        currentValue: streak,
        unlocked: streak >= 7,
      ),
      Achievement(
        id: 'streak_30',
        title: context.tr('monthly_master') ?? 'Monthly Master',
        description: context.tr('30_day_streak') ?? '30-day streak',
        icon: Icons.whatshot_rounded,
        color: const Color(0xFFDC2626),
        type: 'streak',
        requiredValue: 30,
        xpReward: 500,
        currentValue: streak,
        unlocked: streak >= 30,
      ),

      // Study hours achievements
      Achievement(
        id: 'hours_10',
        title: context.tr('bookworm') ?? 'Bookworm',
        description: context.tr('10_hours_study') ?? '10 hours of study',
        icon: Icons.menu_book_rounded,
        color: AppTheme.successGreen,
        type: 'hours',
        requiredValue: 10,
        xpReward: 100,
        currentValue: totalHours.toInt(),
        unlocked: totalHours >= 10,
      ),
      Achievement(
        id: 'hours_50',
        title: context.tr('dedicated_learner') ?? 'Dedicated Learner',
        description: context.tr('50_hours_study') ?? '50 hours of study',
        icon: Icons.library_books_rounded,
        color: const Color(0xFF06B6D4),
        type: 'hours',
        requiredValue: 50,
        xpReward: 300,
        currentValue: totalHours.toInt(),
        unlocked: totalHours >= 50,
      ),
      Achievement(
        id: 'hours_100',
        title: context.tr('time_master') ?? 'Time Master',
        description: context.tr('100_hours_study') ?? '100 hours of study',
        icon: Icons.watch_later_rounded,
        color: const Color(0xFF8B5CF6),
        type: 'hours',
        requiredValue: 100,
        xpReward: 500,
        currentValue: totalHours.toInt(),
        unlocked: totalHours >= 100,
      ),

      // Tasks achievements
      Achievement(
        id: 'tasks_5',
        title: context.tr('task_master') ?? 'Task Master',
        description: context.tr('complete_5_tasks') ?? 'Complete 5 tasks',
        icon: Icons.task_alt_rounded,
        color: AppTheme.successGreen,
        type: 'tasks',
        requiredValue: 5,
        xpReward: 75,
        currentValue: tasksCompleted,
        unlocked: tasksCompleted >= 5,
      ),
      Achievement(
        id: 'tasks_25',
        title: context.tr('productivity_pro') ?? 'Productivity Pro',
        description: context.tr('complete_25_tasks') ?? 'Complete 25 tasks',
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF10B981),
        type: 'tasks',
        requiredValue: 25,
        xpReward: 250,
        currentValue: tasksCompleted,
        unlocked: tasksCompleted >= 25,
      ),
      Achievement(
        id: 'tasks_100',
        title: context.tr('unstoppable') ?? 'Unstoppable',
        description: context.tr('complete_100_tasks') ?? 'Complete 100 tasks',
        icon: Icons.done_all_rounded,
        color: const Color(0xFF14B8A6),
        type: 'tasks',
        requiredValue: 100,
        xpReward: 500,
        currentValue: tasksCompleted,
        unlocked: tasksCompleted >= 100,
      ),

      // Level achievements
      Achievement(
        id: 'level_5',
        title: context.tr('level_up') ?? 'Level Up!',
        description: context.tr('reach_level_5') ?? 'Reach Level 5',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFFA78BFA),
        type: 'level',
        requiredValue: 5,
        xpReward: 200,
        currentValue: level,
        unlocked: level >= 5,
      ),
      Achievement(
        id: 'level_10',
        title: context.tr('elite_scholar') ?? 'Elite Scholar',
        description: context.tr('reach_level_10') ?? 'Reach Level 10',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFEC4899),
        type: 'level',
        requiredValue: 10,
        xpReward: 500,
        currentValue: level,
        unlocked: level >= 10,
      ),
    ];
  }
}
