import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/app_card.dart';
import 'package:vidyasetu/services/localization_service.dart';

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

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final FirestoreService _firestore = FirestoreService();
  List<Achievement> _achievements = [];
  int _totalXPEarned = 0;
  int _userLevel = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  int _xpPoints = 0;
  int _streak = 0;
  double _totalHours = 0;
  int _tasksCompleted = 0;

  Future<void> _loadAchievements() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      setState(() {
        _xpPoints = (userData['points'] as num?)?.toInt() ?? 0;
        _streak = (userData['streak'] as num?)?.toInt() ?? 0;
        _totalHours = (userData['totalStudyHours'] as num?)?.toDouble() ?? 0;
        _tasksCompleted = (userData['tasksCompleted'] as num?)?.toInt() ?? 0;
        _userLevel = (userData['level'] as num?)?.toInt() ?? 1;
        _totalXPEarned = _xpPoints;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      setState(() => _loading = false);
    }
  }

  List<Achievement> _buildAchievements({
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
        color: Color(0xFFEF4444),
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
        color: Color(0xFFF97316),
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
        color: Color(0xFFEF4444),
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
        color: Color(0xFFDC2626),
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
        color: Color(0xFF06B6D4),
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
        color: Color(0xFF8B5CF6),
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
        color: Color(0xFF10B981),
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
        color: Color(0xFF14B8A6),
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
        color: Color(0xFFA78BFA),
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
        color: Color(0xFFEC4899),
        type: 'level',
        requiredValue: 10,
        xpReward: 500,
        currentValue: level,
        unlocked: level >= 10,
      ),
    ];
  }

  int _getTotalUnlockedXP() {
    return _achievements
        .where((a) => a.unlocked)
        .fold<int>(0, (sum, a) => sum + a.xpReward);
  }

  @override
  Widget build(BuildContext context) {
    // Build achievements list in build() so context.tr() works properly
    _achievements = _buildAchievements(
      xpPoints: _xpPoints,
      streak: _streak,
      totalHours: _totalHours,
      tasksCompleted: _tasksCompleted,
      level: _userLevel,
    );
    final unlockedCount =
        _achievements.where((a) => a.unlocked).length;
    final totalCount = _achievements.length;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          context.tr('achievements') ?? 'Achievements',
          style: const TextStyle(
            color: AppTheme.primaryNavy,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // XP Summary Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentPurple.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.amber,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$_totalXPEarned XP',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -1,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            context.tr('total_earned') ??
                                                'Total Earned',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Lvl $_userLevel',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Progress bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.tr('achievements_unlocked') ??
                                      'Achievements Unlocked',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$unlockedCount/$totalCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: totalCount > 0 ? unlockedCount / totalCount : 0.0,
                                backgroundColor: Colors.white.withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.amber,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Unlocked Section
                  if (_achievements.any((a) => a.unlocked)) ...[
                    _buildSectionHeader(
                      context,
                      context.tr('unlocked') ?? 'Unlocked',
                      _achievements.where((a) => a.unlocked).length,
                    ),
                    const SizedBox(height: 12),
                    ..._achievements
                        .where((a) => a.unlocked)
                        .map((a) => _buildAchievementCard(context, a, true))
                        .toList(),
                    const SizedBox(height: 32),
                  ],

                  // Locked Section
                  if (_achievements.any((a) => !a.unlocked)) ...[
                    _buildSectionHeader(
                      context,
                      context.tr('locked') ?? 'Locked',
                      _achievements.where((a) => !a.unlocked).length,
                    ),
                    const SizedBox(height: 12),
                    ..._achievements
                        .where((a) => !a.unlocked)
                        .map((a) => _buildAchievementCard(context, a, false))
                        .toList(),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.primaryNavy,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: AppTheme.accentBlue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    Achievement achievement,
    bool unlocked,
  ) {
    final progressPercent =
        (achievement.currentValue ?? 0) / achievement.requiredValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Opacity(
          opacity: unlocked ? 1.0 : 0.6,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: unlocked
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: achievement.color.withOpacity(0.2),
                      width: 1,
                    ),
                  )
                : null,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: achievement.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        achievement.icon,
                        color: achievement.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: const TextStyle(
                              color: AppTheme.primaryNavy,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            achievement.description,
                            style: TextStyle(
                              color: AppTheme.primaryNavy.withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? AppTheme.successGreen.withOpacity(0.12)
                            : AppTheme.divider,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '+${achievement.xpReward}',
                            style: TextStyle(
                              color: unlocked
                                  ? AppTheme.successGreen
                                  : AppTheme.primaryNavy.withOpacity(0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '⭐',
                            style: TextStyle(
                              fontSize: 11,
                              color: unlocked ? Colors.amber : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (unlocked) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.successGreen,
                        size: 24,
                      ),
                    ],
                  ],
                ),
                if (!unlocked) ...[
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${achievement.currentValue ?? 0}/${achievement.requiredValue}',
                            style: TextStyle(
                              color: AppTheme.primaryNavy.withOpacity(0.5),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(progressPercent * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: achievement.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progressPercent.clamp(0.0, 1.0),
                          backgroundColor:
                              AppTheme.divider.withOpacity(0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            achievement.color.withOpacity(0.6),
                          ),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
