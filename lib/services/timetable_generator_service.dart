import '../models/timetable_model.dart';

class TimetableGeneratorService {
  /// Generates a complete StudyPlan with exam-aware scheduling.
  ///
  /// Key rules:
  /// - College days: study ONLY in evenings (after last college slot → 22:00)
  /// - Holidays/weekends: no travel time, full day study (9:00 → 22:00)
  /// - College hours are always blocked (never schedule study during them)
  /// - Portion divided by PT exam dates (before PT1 = first chunk, etc.)
  /// - After last PT → before finals = revision of all topics
  /// - During revision period: no college hours (treated as holiday)
  static StudyPlan generateStudyPlan({
    required List<SubjectInfo> subjects,
    required List<CollegeSlot> collegeSlots,
    required LifestyleConstraints constraints,
    required List<HolidayInfo> holidays,
    required DateTime startDate,
    ExamSchedule? examSchedule,
    int planDurationDays = 90,
  }) {
    final selectedSubjects = subjects.where((s) => s.isSelected).toList();
    final endDate = examSchedule?.finalExamDate?.startDate ??
        startDate.add(Duration(days: planDurationDays));

    if (selectedSubjects.isEmpty) {
      return _emptyPlan(selectedSubjects, constraints, collegeSlots,
          startDate, endDate);
    }

    // Flatten all topics
    final allTopics = <_TopicEntry>[];
    for (var subject in selectedSubjects) {
      for (var module in subject.modules) {
        for (var topic in module.topics) {
          allTopics.add(_TopicEntry(
            subject: subject.name,
            moduleName: module.name,
            topic: topic,
            estimatedMinutes: _estimateTopicMinutes(module, topic),
            color: _getColorForSubject(subject.name),
          ));
        }
      }
    }

    if (allTopics.isEmpty) {
      return _emptyPlan(selectedSubjects, constraints, collegeSlots,
          startDate, endDate);
    }

    // ── Build schedule based on exam dates ──────────────────────────
    final sessions = <TimetableSession>[];
    double totalWeeklyHours = 0;

    if (examSchedule != null && examSchedule.ptDates.isNotEmpty) {
      // Divide topics into chunks by PT exam count
      final chunks = _divideTopicsByExams(allTopics, examSchedule);
      DateTime chunkStart = startDate;

      for (int i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        DateTime chunkEnd;

        if (i < examSchedule.ptDates.length) {
          // Before PT: end 1 day before exam
          chunkEnd = examSchedule.ptDates[i].startDate
              .subtract(const Duration(days: 1));
        } else if (examSchedule.finalExamDate != null) {
          // Revision period: after last PT → before finals
          chunkEnd = examSchedule.finalExamDate!.startDate
              .subtract(const Duration(days: 1));
        } else {
          chunkEnd = startDate.add(Duration(days: planDurationDays));
        }

        final isRevisionPeriod = i >= examSchedule.ptDates.length;
        final chunkSessions = _scheduleSessions(
          topics: chunk,
          startDate: chunkStart,
          endDate: chunkEnd,
          collegeSlots: collegeSlots,
          constraints: constraints,
          holidays: holidays,
          isRevisionPeriod: isRevisionPeriod,
        );
        sessions.addAll(chunkSessions);

        // Next chunk starts after exam (skip exam day)
        if (i < examSchedule.ptDates.length) {
          chunkStart = examSchedule.ptDates[i].endDate
              .add(const Duration(days: 1));
        }
      }

      // Calculate weekly hours from first week
      for (int d = 0; d < 7 && d < sessions.length; d++) {
        final date = startDate.add(Duration(days: d));
        final dayInfo = _getDayInfo(date, collegeSlots, constraints,
            holidays, false);
        totalWeeklyHours += dayInfo.availableMinutes / 60;
      }
    } else {
      // No exam schedule: simple sequential scheduling
      final scheduled = _scheduleSessions(
        topics: allTopics,
        startDate: startDate,
        endDate: endDate,
        collegeSlots: collegeSlots,
        constraints: constraints,
        holidays: holidays,
        isRevisionPeriod: false,
      );
      sessions.addAll(scheduled);

      for (int d = 0; d < 7; d++) {
        final date = startDate.add(Duration(days: d));
        final dayInfo = _getDayInfo(date, collegeSlots, constraints,
            holidays, false);
        totalWeeklyHours += dayInfo.availableMinutes / 60;
      }
    }

    return StudyPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessions: sessions,
      subjects: selectedSubjects,
      constraints: constraints,
      collegeSlots: collegeSlots,
      createdAt: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
      weeklyAvailableHours: totalWeeklyHours,
    );
  }

  /// Divide topics into chunks for each exam period + revision.
  static List<List<_TopicEntry>> _divideTopicsByExams(
      List<_TopicEntry> allTopics, ExamSchedule examSchedule) {
    final ptCount = examSchedule.ptDates.length;
    final chunks = <List<_TopicEntry>>[];

    // Each PT gets an equal portion of new topics
    final topicsPerChunk = (allTopics.length / ptCount).ceil();

    for (int i = 0; i < ptCount; i++) {
      final start = i * topicsPerChunk;
      final end = (start + topicsPerChunk).clamp(0, allTopics.length);
      if (start < allTopics.length) {
        chunks.add(allTopics.sublist(start, end));
      }
    }

    // Revision chunk: ALL topics again (for revision after last PT)
    if (examSchedule.finalExamDate != null) {
      final revisionTopics = allTopics.map((t) => _TopicEntry(
            subject: t.subject,
            moduleName: t.moduleName,
            topic: '📝 Revise: ${t.topic}',
            estimatedMinutes: (t.estimatedMinutes * 0.5).round(), // Faster
            color: t.color,
          )).toList();
      chunks.add(revisionTopics);
    }

    return chunks;
  }

  /// Schedule study sessions between startDate and endDate.
  static List<TimetableSession> _scheduleSessions({
    required List<_TopicEntry> topics,
    required DateTime startDate,
    required DateTime endDate,
    required List<CollegeSlot> collegeSlots,
    required LifestyleConstraints constraints,
    required List<HolidayInfo> holidays,
    required bool isRevisionPeriod,
  }) {
    final sessions = <TimetableSession>[];
    int topicIndex = 0;
    final totalDays = endDate.difference(startDate).inDays;

    for (int day = 0; day <= totalDays && topicIndex < topics.length; day++) {
      final currentDate = startDate.add(Duration(days: day));
      final dayInfo = _getDayInfo(
          currentDate, collegeSlots, constraints, holidays, isRevisionPeriod);

      if (dayInfo.availableMinutes < 30) continue;

      final slots = _generateStudySlots(currentDate, dayInfo, collegeSlots);

      for (var slot in slots) {
        if (topicIndex >= topics.length) break;
        final topic = topics[topicIndex];
        sessions.add(TimetableSession(
          id: '${currentDate.millisecondsSinceEpoch}_$topicIndex',
          subject: topic.subject,
          topic: topic.topic,
          moduleName: topic.moduleName,
          date: currentDate,
          startTime: slot.startTime,
          durationMinutes: slot.durationMinutes,
          colorHex: topic.color,
          isCompleted: false,
          isHolidaySession: dayInfo.isHoliday || dayInfo.isWeekend,
        ));
        topicIndex++;
      }
    }

    return sessions;
  }

  /// Calculate available study info for a specific day.
  ///
  /// Key rules:
  /// - College days: only evening hours (after college → 22:00)
  /// - Holidays/weekends: no travel time, full day (9:00 → 22:00)
  /// - Revision period: treated like holiday (no college)
  static _DayInfo _getDayInfo(
    DateTime date,
    List<CollegeSlot> collegeSlots,
    LifestyleConstraints constraints,
    List<HolidayInfo> holidays,
    bool isRevisionPeriod,
  ) {
    final weekday = date.weekday;
    final isWeekend = weekday == 6 || weekday == 7;
    final isHoliday = HolidayService.isHoliday(date, holidays);
    final isFreeDay = isWeekend || isHoliday || isRevisionPeriod;

    // Calculate unavailable hours
    double unavailableHrs = constraints.sleepHours +
        (constraints.personalMinutes / 60) +
        (constraints.breakMinutes / 60);

    // Travel time ONLY on college days (not holidays/weekends/revision)
    if (!isFreeDay) {
      unavailableHrs += (constraints.travelMinutes / 60);
    }

    double totalAvailable = 24 - unavailableHrs;

    if (!isFreeDay) {
      // College day: subtract college hours
      final daySlots = collegeSlots.where((s) => s.weekday == weekday);
      for (var slot in daySlots) {
        totalAvailable -= (slot.endHour - slot.startHour);
      }
    }

    // Cap: no more than 10hrs on free days, 5hrs on college days
    double maxStudy = isFreeDay ? 10.0 : 5.0;
    double effectiveHours = totalAvailable.clamp(0, maxStudy);

    return _DayInfo(
      availableMinutes: (effectiveHours * 60).round(),
      isWeekend: isWeekend,
      isHoliday: isHoliday || isRevisionPeriod,
      holidayName: isHoliday ? _getHolidayName(date, holidays) : null,
      isFreeDay: isFreeDay,
    );
  }

  static String? _getHolidayName(DateTime date, List<HolidayInfo> holidays) {
    try {
      return holidays.firstWhere((h) =>
          h.date.year == date.year &&
          h.date.month == date.month &&
          h.date.day == date.day).name;
    } catch (e) {
      return null;
    }
  }

  /// Generate study slots for a day.
  ///
  /// College days: schedule ONLY in evenings (after last college slot)
  /// Free days: schedule from 9:00 with lunch break at 13:00
  static List<_StudySlot> _generateStudySlots(
    DateTime date,
    _DayInfo dayInfo,
    List<CollegeSlot> collegeSlots,
  ) {
    final slots = <_StudySlot>[];
    int remainingMinutes = dayInfo.availableMinutes;
    const sessionMinutes = 50;
    const breakMinutes = 10;

    int startHour;
    if (dayInfo.isFreeDay) {
      startHour = 9; // Full day from 9AM
    } else {
      // Find last college slot for this day, start after it
      final daySlots = collegeSlots
          .where((s) => s.weekday == date.weekday)
          .toList();
      if (daySlots.isNotEmpty) {
        startHour = daySlots
            .map((s) => s.endHour)
            .reduce((a, b) => a > b ? a : b);
        // Add 30min buffer after college
        startHour = startHour; // Start right after college ends
      } else {
        startHour = 17; // Default evening
      }
    }

    int currentHour = startHour;
    int currentMinute = 0;

    while (remainingMinutes >= sessionMinutes) {
      if (currentHour >= 22) break; // Don't study past 10 PM

      // Lunch break at 13:00 on free days
      if (dayInfo.isFreeDay && currentHour == 13 && currentMinute == 0) {
        currentHour = 14;
        continue;
      }

      // Skip college hours on college days (shouldn't happen but safety)
      if (!dayInfo.isFreeDay) {
        bool inCollege = collegeSlots.any((s) =>
            s.weekday == date.weekday &&
            currentHour >= s.startHour &&
            currentHour < s.endHour);
        if (inCollege) {
          currentHour++;
          currentMinute = 0;
          continue;
        }
      }

      slots.add(_StudySlot(
        startTime: DateTime(
            date.year, date.month, date.day, currentHour, currentMinute),
        durationMinutes: sessionMinutes,
      ));

      remainingMinutes -= (sessionMinutes + breakMinutes);
      currentMinute += (sessionMinutes + breakMinutes);
      while (currentMinute >= 60) {
        currentHour++;
        currentMinute -= 60;
      }
    }

    return slots;
  }

  /// Estimate minutes for a topic
  static int _estimateTopicMinutes(ModuleInfo module, String topic) {
    if (module.hours > 0 && module.topics.isNotEmpty) {
      return ((module.hours * 60) / module.topics.length).round().clamp(30, 90);
    }
    return 50;
  }

  /// Get a consistent color for a subject
  static String _getColorForSubject(String subject) {
    final colors = [
      '#4F46E5', '#0EA5E9', '#8B5CF6', '#10B981', '#F59E0B',
      '#EC4899', '#EF4444', '#06B6D4', '#84CC16', '#F97316',
    ];
    int hash = 0;
    for (int i = 0; i < subject.length; i++) {
      hash = (hash + subject.codeUnitAt(i)) * 31;
    }
    return colors[hash.abs() % colors.length];
  }

  /// Calculate summary statistics
  static Map<String, dynamic> calculateSummary({
    required List<SubjectInfo> subjects,
    required List<CollegeSlot> collegeSlots,
    required LifestyleConstraints constraints,
    required List<HolidayInfo> holidays,
    required DateTime startDate,
    ExamSchedule? examSchedule,
  }) {
    final selected = subjects.where((s) => s.isSelected).toList();
    final totalTopics = selected.fold(0, (sum, s) => sum + s.topicCount);
    final totalEstimatedHours =
        selected.fold(0.0, (sum, s) => sum + s.estimatedStudyHours);

    double weeklyHours = 0;
    for (int d = 0; d < 7; d++) {
      final date = startDate.add(Duration(days: d));
      final dayInfo =
          _getDayInfo(date, collegeSlots, constraints, holidays, false);
      weeklyHours += dayInfo.availableMinutes / 60;
    }

    final daysNeeded = weeklyHours > 0
        ? ((totalEstimatedHours / weeklyHours) * 7).ceil()
        : 90;

    DateTime predictedEndDate;
    if (examSchedule?.finalExamDate != null) {
      predictedEndDate = examSchedule!.finalExamDate!.startDate;
    } else {
      predictedEndDate = startDate.add(Duration(days: daysNeeded));
    }

    return {
      'selectedSubjects': selected.length,
      'totalTopics': totalTopics,
      'totalEstimatedHours': totalEstimatedHours,
      'weeklyAvailableHours': weeklyHours,
      'predictedDays': daysNeeded,
      'predictedEndDate': predictedEndDate,
    };
  }

  static StudyPlan _emptyPlan(
    List<SubjectInfo> subjects,
    LifestyleConstraints constraints,
    List<CollegeSlot> collegeSlots,
    DateTime startDate,
    DateTime endDate,
  ) {
    return StudyPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessions: [],
      subjects: subjects,
      constraints: constraints,
      collegeSlots: collegeSlots,
      createdAt: DateTime.now(),
      startDate: startDate,
      endDate: endDate,
    );
  }
}

// Internal helper
class HolidayService {
  static bool isHoliday(DateTime date, List<HolidayInfo> holidays) {
    return holidays.any((h) =>
        h.date.year == date.year &&
        h.date.month == date.month &&
        h.date.day == date.day);
  }
}

class _TopicEntry {
  final String subject;
  final String moduleName;
  final String topic;
  final int estimatedMinutes;
  final String color;
  _TopicEntry({
    required this.subject,
    required this.moduleName,
    required this.topic,
    required this.estimatedMinutes,
    required this.color,
  });
}

class _DayInfo {
  final int availableMinutes;
  final bool isWeekend;
  final bool isHoliday;
  final String? holidayName;
  final bool isFreeDay;
  _DayInfo({
    required this.availableMinutes,
    required this.isWeekend,
    required this.isHoliday,
    this.holidayName,
    required this.isFreeDay,
  });
}

class _StudySlot {
  final DateTime startTime;
  final int durationMinutes;
  _StudySlot({required this.startTime, required this.durationMinutes});
}
