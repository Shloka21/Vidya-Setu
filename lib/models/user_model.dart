import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'student' or 'mentor'
  final String? profileImageUrl;
  final String? institution;
  final String? course;
  final String? bio;
  final String? phone;
  final DateTime? dateOfBirth;
  final int points;
  final int level;
  final int streak;
  final double totalStudyHours;
  final int tasksCompleted;
  final List<String> subjectsTaught; // mentor only
  final int experienceYears; // mentor only
  final double rating; // mentor only
  final int studentCount; // mentor only
  final int maxStudents; // mentor only
  final bool isTimetableCreated; // student only
  final DateTime createdAt;
  final DateTime lastActive;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
    this.institution,
    this.course,
    this.bio,
    this.phone,
    this.dateOfBirth,
    this.points = 0,
    this.level = 1,
    this.streak = 0,
    this.totalStudyHours = 0,
    this.tasksCompleted = 0,
    this.subjectsTaught = const [],
    this.experienceYears = 0,
    this.rating = 0,
    this.studentCount = 0,
    this.maxStudents = 20,
    this.isTimetableCreated = false,
    DateTime? createdAt,
    DateTime? lastActive,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActive = lastActive ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      profileImageUrl: map['profileImageUrl'],
      institution: map['institution'],
      course: map['course'],
      bio: map['bio'],
      phone: map['phone'],
      dateOfBirth: map['dateOfBirth'] != null
          ? (map['dateOfBirth'] as Timestamp).toDate()
          : null,
      points: map['points'] ?? 0,
      level: map['level'] ?? 1,
      streak: map['streak'] ?? 0,
      totalStudyHours: (map['totalStudyHours'] ?? 0).toDouble(),
      tasksCompleted: map['tasksCompleted'] ?? 0,
      subjectsTaught: List<String>.from(map['subjectsTaught'] ?? []),
      experienceYears: map['experienceYears'] ?? 0,
      rating: (map['rating'] ?? 0).toDouble(),
      studentCount: map['studentCount'] ?? 0,
      maxStudents: map['maxStudents'] ?? 20,
      isTimetableCreated: map['isTimetableCreated'] ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastActive: map['lastActive'] != null
          ? (map['lastActive'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'institution': institution,
      'course': course,
      'bio': bio,
      'phone': phone,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'points': points,
      'level': level,
      'streak': streak,
      'totalStudyHours': totalStudyHours,
      'tasksCompleted': tasksCompleted,
      'subjectsTaught': subjectsTaught,
      'experienceYears': experienceYears,
      'rating': rating,
      'studentCount': studentCount,
      'maxStudents': maxStudents,
      'isTimetableCreated': isTimetableCreated,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': Timestamp.fromDate(lastActive),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    String? profileImageUrl,
    String? institution,
    String? course,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    int? points,
    int? level,
    int? streak,
    double? totalStudyHours,
    int? tasksCompleted,
    List<String>? subjectsTaught,
    int? experienceYears,
    double? rating,
    int? studentCount,
    int? maxStudents,
    bool? isTimetableCreated,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      institution: institution ?? this.institution,
      course: course ?? this.course,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      points: points ?? this.points,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      totalStudyHours: totalStudyHours ?? this.totalStudyHours,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      subjectsTaught: subjectsTaught ?? this.subjectsTaught,
      experienceYears: experienceYears ?? this.experienceYears,
      rating: rating ?? this.rating,
      studentCount: studentCount ?? this.studentCount,
      maxStudents: maxStudents ?? this.maxStudents,
      isTimetableCreated: isTimetableCreated ?? this.isTimetableCreated,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  bool get isStudent => role == 'student';
  bool get isMentor => role == 'mentor';
}
