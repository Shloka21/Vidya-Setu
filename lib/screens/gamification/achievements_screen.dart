import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'package:vidyasetu/services/gamification_logic.dart';
import 'package:vidyasetu/services/localization_service.dart';
import 'package:vidyasetu/widgets/common/app_card.dart';

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
    return GamificationLogic.getAchievements(
      context,
      xpPoints: xpPoints,
      streak: streak,
      totalHours: totalHours,
      tasksCompleted: tasksCompleted,
      level: level,
    );
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
                                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                                  color: Colors.white,
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
