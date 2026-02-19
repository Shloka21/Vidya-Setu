import 'package:flutter/material.dart';

// ─── Subject Info (from PDF extraction) ─────────────────────────────────────
class SubjectInfo {
  final String code;
  final String name;
  final List<ModuleInfo> modules;
  final int totalHours;
  final int credits;
  bool isSelected;

  SubjectInfo({
    required this.code,
    required this.name,
    required this.modules,
    this.totalHours = 0,
    this.credits = 0,
    this.isSelected = true,
  });

  int get topicCount => modules.fold(0, (sum, m) => sum + m.topics.length);
  int get moduleCount => modules.length;

  /// Estimated study hours based on module hours with a multiplier for self-study
  double get estimatedStudyHours => totalHours > 0
      ? totalHours * 1.5
      : modules.fold(0.0, (sum, m) => sum + m.hours * 1.5);

  Map<String, dynamic> toMap() => {
        'code': code,
        'name': name,
        'modules': modules.map((m) => m.toMap()).toList(),
        'totalHours': totalHours,
        'credits': credits,
        'isSelected': isSelected,
      };

  factory SubjectInfo.fromMap(Map<String, dynamic> map) => SubjectInfo(
        code: map['code'] ?? '',
        name: map['name'] ?? '',
        modules: (map['modules'] as List?)
                ?.map((m) => ModuleInfo.fromMap(m))
                .toList() ??
            [],
        totalHours: map['totalHours'] ?? 0,
        credits: map['credits'] ?? 0,
        isSelected: map['isSelected'] ?? true,
      );
}

class ModuleInfo {
  final int number;
  final String name;
  final List<String> topics;
  final int hours;

  ModuleInfo({
    required this.number,
    required this.name,
    required this.topics,
    this.hours = 0,
  });

  Map<String, dynamic> toMap() => {
        'number': number,
        'name': name,
        'topics': topics,
        'hours': hours,
      };

  factory ModuleInfo.fromMap(Map<String, dynamic> map) => ModuleInfo(
        number: map['number'] ?? 0,
        name: map['name'] ?? '',
        topics: List<String>.from(map['topics'] ?? []),
        hours: map['hours'] ?? 0,
      );
}

// ─── College Timetable Slot ─────────────────────────────────────────────────
class CollegeSlot {
  final int weekday; // 1=Mon, 7=Sun
  final int startHour; // 8-18
  final int endHour;
  final String? label;

  CollegeSlot({
    required this.weekday,
    required this.startHour,
    required this.endHour,
    this.label,
  });

  Map<String, dynamic> toMap() => {
        'weekday': weekday,
        'startHour': startHour,
        'endHour': endHour,
        'label': label,
      };

  factory CollegeSlot.fromMap(Map<String, dynamic> map) => CollegeSlot(
        weekday: map['weekday'] ?? 1,
        startHour: map['startHour'] ?? 9,
        endHour: map['endHour'] ?? 10,
        label: map['label'],
      );
}

// ─── Lifestyle Constraints ──────────────────────────────────────────────────
class LifestyleConstraints {
  double sleepHours;
  double travelMinutes;
  double personalMinutes;
  double breakMinutes;
  List<CustomCommitment> customCommitments;

  LifestyleConstraints({
    this.sleepHours = 7.0,
    this.travelMinutes = 60,
    this.personalMinutes = 60,
    this.breakMinutes = 30,
    this.customCommitments = const [],
  });

  double get totalUnavailableHours =>
      sleepHours +
      (travelMinutes / 60) +
      (personalMinutes / 60) +
      (breakMinutes / 60);

  Map<String, dynamic> toMap() => {
        'sleepHours': sleepHours,
        'travelMinutes': travelMinutes,
        'personalMinutes': personalMinutes,
        'breakMinutes': breakMinutes,
        'customCommitments': customCommitments.map((c) => c.toMap()).toList(),
      };

  factory LifestyleConstraints.fromMap(Map<String, dynamic> map) =>
      LifestyleConstraints(
        sleepHours: (map['sleepHours'] ?? 7).toDouble(),
        travelMinutes: (map['travelMinutes'] ?? 60).toDouble(),
        personalMinutes: (map['personalMinutes'] ?? 60).toDouble(),
        breakMinutes: (map['breakMinutes'] ?? 30).toDouble(),
        customCommitments: (map['customCommitments'] as List?)
                ?.map((c) => CustomCommitment.fromMap(c))
                .toList() ??
            [],
      );
}

class CustomCommitment {
  final String name;
  final double durationMinutes;

  CustomCommitment({required this.name, required this.durationMinutes});

  Map<String, dynamic> toMap() =>
      {'name': name, 'durationMinutes': durationMinutes};

  factory CustomCommitment.fromMap(Map<String, dynamic> map) =>
      CustomCommitment(
        name: map['name'] ?? '',
        durationMinutes: (map['durationMinutes'] ?? 0).toDouble(),
      );
}

// ─── Exam Schedule ──────────────────────────────────────────────────────────
class ExamDate {
  final String label; // 'PT1', 'PT2', 'PT3', 'Final'
  final DateTime startDate;
  final DateTime endDate;

  ExamDate({required this.label, required this.startDate, required this.endDate});

  /// Convenience: single-day exam
  factory ExamDate.singleDay({required String label, required DateTime date}) =>
      ExamDate(label: label, startDate: date, endDate: date);

  Map<String, dynamic> toMap() => {
        'label': label,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

  factory ExamDate.fromMap(Map<String, dynamic> map) => ExamDate(
        label: map['label'] ?? '',
        startDate: DateTime.parse(map['startDate'] ?? map['date'] ?? DateTime.now().toIso8601String()),
        endDate: DateTime.parse(map['endDate'] ?? map['date'] ?? DateTime.now().toIso8601String()),
      );
}

class ExamSchedule {
  final int ptCount; // 1-3 periodic tests
  final List<ExamDate> ptDates;
  final ExamDate? finalExamDate;

  ExamSchedule({
    this.ptCount = 1,
    this.ptDates = const [],
    this.finalExamDate,
  });

  Map<String, dynamic> toMap() => {
        'ptCount': ptCount,
        'ptDates': ptDates.map((e) => e.toMap()).toList(),
        'finalExamDate': finalExamDate?.toMap(),
      };

  factory ExamSchedule.fromMap(Map<String, dynamic> map) => ExamSchedule(
        ptCount: map['ptCount'] ?? 1,
        ptDates: (map['ptDates'] as List?)
                ?.map((e) => ExamDate.fromMap(e))
                .toList() ??
            [],
        finalExamDate: map['finalExamDate'] != null
            ? ExamDate.fromMap(map['finalExamDate'])
            : null,
      );
}

// ─── Holiday Info ───────────────────────────────────────────────────────────
class HolidayInfo {
  final DateTime date;
  final String name;
  final String type; // national, regional, festival

  HolidayInfo({
    required this.date,
    required this.name,
    this.type = 'national',
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'name': name,
        'type': type,
      };

  factory HolidayInfo.fromMap(Map<String, dynamic> map) => HolidayInfo(
        date: DateTime.parse(map['date']),
        name: map['name'] ?? '',
        type: map['type'] ?? 'national',
      );
}

// ─── Study Day (enhanced) ───────────────────────────────────────────────────
class StudyDay {
  final String dayName;
  bool isEnabled;
  String preferredSlot;
  int sessions;
  double availableHours;
  bool isHoliday;
  String? holidayName;

  StudyDay({
    required this.dayName,
    this.isEnabled = true,
    this.preferredSlot = 'Morning',
    this.sessions = 0,
    this.availableHours = 0,
    this.isHoliday = false,
    this.holidayName,
  });
}

// ─── Timetable Session ──────────────────────────────────────────────────────
enum TimetableSessionStatus { notStarted, inProgress, completed, skipped }

class TimetableSession {
  final String id;
  final String subject;
  final String topic;
  final String? moduleName;
  final DateTime date;
  final DateTime startTime;
  final int durationMinutes;
  final String colorHex;
  bool isCompleted;
  final String? location;
  final String? notes;
  final bool isHolidaySession;

  TimetableSession({
    required this.id,
    required this.subject,
    required this.topic,
    this.moduleName,
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    required this.colorHex,
    this.isCompleted = false,
    this.location,
    this.notes,
    this.isHolidaySession = false,
  });

  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject': subject,
        'topic': topic,
        'moduleName': moduleName,
        'date': date.toIso8601String(),
        'startTime': startTime.toIso8601String(),
        'durationMinutes': durationMinutes,
        'colorHex': colorHex,
        'isCompleted': isCompleted,
        'location': location,
        'notes': notes,
        'isHolidaySession': isHolidaySession,
      };

  factory TimetableSession.fromMap(Map<String, dynamic> map) =>
      TimetableSession(
        id: map['id'] ?? '',
        subject: map['subject'] ?? '',
        topic: map['topic'] ?? '',
        moduleName: map['moduleName'],
        date: DateTime.parse(map['date']),
        startTime: DateTime.parse(map['startTime']),
        durationMinutes: map['durationMinutes'] ?? 60,
        colorHex: map['colorHex'] ?? '#4F46E5',
        isCompleted: map['isCompleted'] ?? false,
        location: map['location'],
        notes: map['notes'],
        isHolidaySession: map['isHolidaySession'] ?? false,
      );
}

// ─── Study Plan (full plan) ─────────────────────────────────────────────────
class StudyPlan {
  final String id;
  final List<TimetableSession> sessions;
  final List<SubjectInfo> subjects;
  final LifestyleConstraints constraints;
  final List<CollegeSlot> collegeSlots;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime endDate;
  final double weeklyAvailableHours;

  StudyPlan({
    required this.id,
    required this.sessions,
    required this.subjects,
    required this.constraints,
    required this.collegeSlots,
    required this.createdAt,
    required this.startDate,
    required this.endDate,
    this.weeklyAvailableHours = 0,
  });

  int get totalSessions => sessions.length;
  int get completedSessions => sessions.where((s) => s.isCompleted).count;
  double get progressPercent =>
      totalSessions > 0 ? completedSessions / totalSessions : 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'sessions': sessions.map((s) => s.toMap()).toList(),
        'subjects': subjects.map((s) => s.toMap()).toList(),
        'constraints': constraints.toMap(),
        'collegeSlots': collegeSlots.map((c) => c.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'weeklyAvailableHours': weeklyAvailableHours,
      };

  factory StudyPlan.fromMap(Map<String, dynamic> map) => StudyPlan(
        id: map['id'] ?? '',
        sessions: (map['sessions'] as List?)
                ?.map((s) => TimetableSession.fromMap(s))
                .toList() ??
            [],
        subjects: (map['subjects'] as List?)
                ?.map((s) => SubjectInfo.fromMap(s))
                .toList() ??
            [],
        constraints: map['constraints'] != null
            ? LifestyleConstraints.fromMap(map['constraints'])
            : LifestyleConstraints(),
        collegeSlots: (map['collegeSlots'] as List?)
                ?.map((c) => CollegeSlot.fromMap(c))
                .toList() ??
            [],
        createdAt: DateTime.parse(
            map['createdAt'] ?? DateTime.now().toIso8601String()),
        startDate: DateTime.parse(
            map['startDate'] ?? DateTime.now().toIso8601String()),
        endDate: DateTime.parse(
            map['endDate'] ?? DateTime.now().toIso8601String()),
        weeklyAvailableHours: (map['weeklyAvailableHours'] ?? 0).toDouble(),
      );
}

// Extension for count
extension IterableCount<T> on Iterable<T> {
  int get count => length;
}
