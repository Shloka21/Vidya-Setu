import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ReminderType { exam, assignment, quiz, studySession, custom }

enum ReminderPriority { high, medium, low }

enum ReminderStatus { pending, completed, missed }

class ReminderModel {
  final String id;
  final String userId;
  final String title;
  final ReminderType type;
  final String? subject;
  final String? description;
  final DateTime dateTime;
  final ReminderPriority priority;
  final ReminderStatus status;
  final bool popupNotification;
  final bool voiceNotification;
  final List<int> reminderMinutesBefore; // e.g. [1440, 60, 15] = 1day, 1hr, 15min
  final String repeatType; // 'once', 'daily', 'weekly'
  final String? createdByMentorId; // if mentor created it
  final String? mentorMessage;
  final DateTime createdAt;

  ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    this.subject,
    this.description,
    required this.dateTime,
    this.priority = ReminderPriority.medium,
    this.status = ReminderStatus.pending,
    this.popupNotification = true,
    this.voiceNotification = false,
    this.reminderMinutesBefore = const [60],
    this.repeatType = 'once',
    this.createdByMentorId,
    this.mentorMessage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      type: ReminderType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReminderType.custom,
      ),
      subject: map['subject'],
      description: map['description'],
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      priority: ReminderPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => ReminderPriority.medium,
      ),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReminderStatus.pending,
      ),
      popupNotification: map['popupNotification'] ?? true,
      voiceNotification: map['voiceNotification'] ?? false,
      reminderMinutesBefore:
          List<int>.from(map['reminderMinutesBefore'] ?? [60]),
      repeatType: map['repeatType'] ?? 'once',
      createdByMentorId: map['createdByMentorId'],
      mentorMessage: map['mentorMessage'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'type': type.name,
      'subject': subject,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'priority': priority.name,
      'status': status.name,
      'popupNotification': popupNotification,
      'voiceNotification': voiceNotification,
      'reminderMinutesBefore': reminderMinutesBefore,
      'repeatType': repeatType,
      'createdByMentorId': createdByMentorId,
      'mentorMessage': mentorMessage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ReminderModel copyWith({
    String? id,
    String? userId,
    String? title,
    ReminderType? type,
    String? subject,
    String? description,
    DateTime? dateTime,
    ReminderPriority? priority,
    ReminderStatus? status,
    bool? popupNotification,
    bool? voiceNotification,
    List<int>? reminderMinutesBefore,
    String? repeatType,
    String? createdByMentorId,
    String? mentorMessage,
    DateTime? createdAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      popupNotification: popupNotification ?? this.popupNotification,
      voiceNotification: voiceNotification ?? this.voiceNotification,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      repeatType: repeatType ?? this.repeatType,
      createdByMentorId: createdByMentorId ?? this.createdByMentorId,
      mentorMessage: mentorMessage ?? this.mentorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Color get priorityColor {
    switch (priority) {
      case ReminderPriority.high:
        return const Color(0xFFEF4444);
      case ReminderPriority.medium:
        return const Color(0xFFF59E0B);
      case ReminderPriority.low:
        return const Color(0xFF10B981);
    }
  }

  String get typeLabel {
    switch (type) {
      case ReminderType.exam:
        return 'Exam';
      case ReminderType.assignment:
        return 'Assignment';
      case ReminderType.quiz:
        return 'Quiz';
      case ReminderType.studySession:
        return 'Study Session';
      case ReminderType.custom:
        return 'Custom';
    }
  }
}
