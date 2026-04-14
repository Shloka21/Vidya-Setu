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
  final int sessionsCompleted; // mentor only
  final bool isTimetableCreated; // student only
  final bool availableForNew; // mentor only
  final bool newRequestsNotif;
  final bool messageNotif;
  final bool studentUpdatesNotif;
  final String? languages; // mentor only
  final String? availability; // mentor only
  final bool profileCompleted; // mentor only
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
    this.sessionsCompleted = 0,
    this.isTimetableCreated = false,
    this.availableForNew = true,
    this.newRequestsNotif = true,
    this.messageNotif = true,
    this.studentUpdatesNotif = true,
    this.languages,
    this.availability,
    this.profileCompleted = false,
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
      sessionsCompleted: map['sessionsCompleted'] ?? 0,
      isTimetableCreated: map['isTimetableCreated'] ?? false,
      availableForNew: map['availableForNew'] ?? true,
      newRequestsNotif: map['newRequestsNotif'] ?? true,
      messageNotif: map['messageNotif'] ?? true,
      studentUpdatesNotif: map['studentUpdatesNotif'] ?? true,
      languages: map['languages'],
      availability: map['availability'],
      profileCompleted: map['profileCompleted'] ?? false,
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
      'sessionsCompleted': sessionsCompleted,
      'isTimetableCreated': isTimetableCreated,
      'availableForNew': availableForNew,
      'newRequestsNotif': newRequestsNotif,
      'messageNotif': messageNotif,
      'studentUpdatesNotif': studentUpdatesNotif,
      'languages': languages,
      'availability': availability,
      'profileCompleted': profileCompleted,
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
    int? sessionsCompleted,
    bool? isTimetableCreated,
    bool? availableForNew,
    bool? newRequestsNotif,
    bool? messageNotif,
    bool? studentUpdatesNotif,
    String? languages,
    String? availability,
    bool? profileCompleted,
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
      sessionsCompleted: sessionsCompleted ?? this.sessionsCompleted,
      isTimetableCreated: isTimetableCreated ?? this.isTimetableCreated,
      availableForNew: availableForNew ?? this.availableForNew,
      newRequestsNotif: newRequestsNotif ?? this.newRequestsNotif,
      messageNotif: messageNotif ?? this.messageNotif,
      studentUpdatesNotif: studentUpdatesNotif ?? this.studentUpdatesNotif,
      languages: languages ?? this.languages,
      availability: availability ?? this.availability,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  bool get isStudent => role == 'student';
  bool get isMentor => role == 'mentor';

  static Map<String, dynamic> calculateLevel(int points) {
    if (points < 100) return {'level': 1, 'title': 'Beginner', 'nextXp': 100, 'prevXp': 0};
    if (points < 300) return {'level': 2, 'title': 'Learner', 'nextXp': 300, 'prevXp': 100};
    if (points < 600) return {'level': 3, 'title': 'Explorer', 'nextXp': 600, 'prevXp': 300};
    if (points < 1000) return {'level': 4, 'title': 'Achiever', 'nextXp': 1000, 'prevXp': 600};
    if (points < 1500) return {'level': 5, 'title': 'Scholar', 'nextXp': 1500, 'prevXp': 1000};
    if (points < 2200) return {'level': 6, 'title': 'Expert', 'nextXp': 2200, 'prevXp': 1500};
    if (points < 3000) return {'level': 7, 'title': 'Master', 'nextXp': 3000, 'prevXp': 2200};
    if (points < 4000) return {'level': 8, 'title': 'Champion', 'nextXp': 4000, 'prevXp': 3000};
    if (points < 5500) return {'level': 9, 'title': 'Legend', 'nextXp': 5500, 'prevXp': 4000};
    return {'level': 10, 'title': 'Guru', 'nextXp': 10000, 'prevXp': 5500};
  }
}
