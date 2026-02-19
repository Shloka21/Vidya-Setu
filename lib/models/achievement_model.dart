import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementModel {
  final String id;
  final String name;
  final String description;
  final String category; // 'consistency', 'completion', 'excellence', 'social'
  final String iconName;
  final int requiredValue;
  final int pointsReward;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.iconName = 'emoji_events',
    required this.requiredValue,
    this.pointsReward = 50,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'completion',
      iconName: map['iconName'] ?? 'emoji_events',
      requiredValue: map['requiredValue'] ?? 1,
      pointsReward: map['pointsReward'] ?? 50,
      isUnlocked: map['isUnlocked'] ?? false,
      unlockedAt: map['unlockedAt'] != null
          ? (map['unlockedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'iconName': iconName,
      'requiredValue': requiredValue,
      'pointsReward': pointsReward,
      'isUnlocked': isUnlocked,
      'unlockedAt':
          unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    };
  }
}

// Default achievements
class DefaultAchievements {
  static List<AchievementModel> get all => [
        AchievementModel(
          id: 'streak_7',
          name: 'Week Warrior',
          description: 'Maintain a 7-day study streak',
          category: 'consistency',
          iconName: 'local_fire_department',
          requiredValue: 7,
          pointsReward: 50,
        ),
        AchievementModel(
          id: 'streak_30',
          name: 'Monthly Master',
          description: 'Maintain a 30-day study streak',
          category: 'consistency',
          iconName: 'whatshot',
          requiredValue: 30,
          pointsReward: 200,
        ),
        AchievementModel(
          id: 'tasks_10',
          name: 'Getting Started',
          description: 'Complete 10 tasks',
          category: 'completion',
          iconName: 'check_circle',
          requiredValue: 10,
          pointsReward: 25,
        ),
        AchievementModel(
          id: 'tasks_50',
          name: 'Task Master',
          description: 'Complete 50 tasks',
          category: 'completion',
          iconName: 'verified',
          requiredValue: 50,
          pointsReward: 100,
        ),
        AchievementModel(
          id: 'tasks_100',
          name: 'Centurion',
          description: 'Complete 100 tasks',
          category: 'completion',
          iconName: 'military_tech',
          requiredValue: 100,
          pointsReward: 250,
        ),
        AchievementModel(
          id: 'perfect_week',
          name: 'Perfect Week',
          description: 'Complete all tasks in a week',
          category: 'excellence',
          iconName: 'star',
          requiredValue: 1,
          pointsReward: 75,
        ),
        AchievementModel(
          id: 'early_bird',
          name: 'Early Bird',
          description: 'Complete 5 tasks before 8 AM',
          category: 'excellence',
          iconName: 'wb_sunny',
          requiredValue: 5,
          pointsReward: 50,
        ),
        AchievementModel(
          id: 'mentor_connected',
          name: 'Guided Path',
          description: 'Connect with a mentor',
          category: 'social',
          iconName: 'people',
          requiredValue: 1,
          pointsReward: 30,
        ),
        AchievementModel(
          id: 'first_chat',
          name: 'Conversation Starter',
          description: 'Send your first message to a mentor',
          category: 'social',
          iconName: 'chat',
          requiredValue: 1,
          pointsReward: 20,
        ),
      ];
}
