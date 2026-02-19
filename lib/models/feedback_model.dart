import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String mentorId;
  final String studentId;
  final String title;
  final String feedbackType; // 'general', 'subject', 'motivation'
  final String? subject;
  final String content;
  final String? suggestions;
  final String priority; // 'normal', 'important'
  final bool sendAsNotification;
  final bool isRead;
  final List<String> attachmentUrls;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.mentorId,
    required this.studentId,
    required this.title,
    this.feedbackType = 'general',
    this.subject,
    required this.content,
    this.suggestions,
    this.priority = 'normal',
    this.sendAsNotification = true,
    this.isRead = false,
    this.attachmentUrls = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'] ?? '',
      mentorId: map['mentorId'] ?? '',
      studentId: map['studentId'] ?? '',
      title: map['title'] ?? '',
      feedbackType: map['feedbackType'] ?? 'general',
      subject: map['subject'],
      content: map['content'] ?? '',
      suggestions: map['suggestions'],
      priority: map['priority'] ?? 'normal',
      sendAsNotification: map['sendAsNotification'] ?? true,
      isRead: map['isRead'] ?? false,
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mentorId': mentorId,
      'studentId': studentId,
      'title': title,
      'feedbackType': feedbackType,
      'subject': subject,
      'content': content,
      'suggestions': suggestions,
      'priority': priority,
      'sendAsNotification': sendAsNotification,
      'isRead': isRead,
      'attachmentUrls': attachmentUrls,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
