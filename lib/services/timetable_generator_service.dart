import '../models/timetable_model.dart';

class TimetableGeneratorService {
  /// Generates a complete StudyPlan with exam-aware, round-robin scheduling.
  ///
  /// Key rules:
  /// - College days: study ONLY in evenings after college, realistic 3-4 hrs
  /// - Holidays/weekends: 1.5x college-day study hours, ~5-6 hrs
  /// - 2-3 subjects per day in round-robin rotation
  /// - Equal weekly coverage across all subjects
  /// - Exam-based topic division (PT portions + revision)
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

    // Build per-subject topic queues
    final subjectQueues = <_SubjectQueue>[];
    for (var subject in selectedSubjects) {
      final topics = <_TopicEntry>[];
      for (var module in subject.modules) {
        for (var topic in module.topics) {
          topics.add(_TopicEntry(
            subject: subject.name,
            moduleName: module.name,
            topic: topic,
            estimatedMinutes: _estimateTopicMinutes(module, topic),
            color: _getColorForSubject(subject.name),
          ));
        }
      }
      if (topics.isNotEmpty) {
        subjectQueues.add(_SubjectQueue(
          subjectName: subject.name,
          topics: topics,
          color: _getColorForSubject(subject.name),
        ));
      }
    }

    if (subjectQueues.isEmpty) {
      return _emptyPlan(selectedSubjects, constraints, collegeSlots,
          startDate, endDate);
    }

    // ── Build schedule based on exam dates ──────────────────────────
    final sessions = <TimetableSession>[];
    double totalWeeklyHours = 0;

    if (examSchedule != null && examSchedule.ptDates.isNotEmpty) {
      // Divide topics into chunks by PT exam count
      final ptCount = examSchedule.ptDates.length;
      
      // Create per-PT topic queues (divide each subject's topics equally)
      final chunkQueues = <List<_SubjectQueue>>[];
      for (int i = 0; i < ptCount; i++) {
        final chunk = <_SubjectQueue>[];
        for (var sq in subjectQueues) {
          final topicsPerChunk = (sq.topics.length / ptCount).ceil();
          final start = i * topicsPerChunk;
          final end = (start + topicsPerChunk).clamp(0, sq.topics.length);
          if (start < sq.topics.length) {
            chunk.add(_SubjectQueue(
              subjectName: sq.subjectName,
              topics: sq.topics.sublist(start, end),
              color: sq.color,
            ));
          }
        }
        chunkQueues.add(chunk);
      }

      // Add revision chunk
      if (examSchedule.finalExamDate != null) {
        final revisionChunk = <_SubjectQueue>[];
        for (var sq in subjectQueues) {
          revisionChunk.add(_SubjectQueue(
            subjectName: sq.subjectName,
            topics: sq.topics.map((t) => _TopicEntry(
              subject: t.subject,
              moduleName: t.moduleName,
              topic: '📝 Revise: ${t.topic}',
              estimatedMinutes: (t.estimatedMinutes * 0.5).round(),
              color: t.color,
            )).toList(),
            color: sq.color,
          ));
        }
        chunkQueues.add(revisionChunk);
      }

      DateTime chunkStart = startDate;
      for (int i = 0; i < chunkQueues.length; i++) {
        DateTime chunkEnd;
        bool isRevision = i >= ptCount;

        if (i < examSchedule.ptDates.length) {
          chunkEnd = examSchedule.ptDates[i].startDate
              .subtract(const Duration(days: 1));
        } else if (examSchedule.finalExamDate != null) {
          chunkEnd = examSchedule.finalExamDate!.startDate
              .subtract(const Duration(days: 1));
        } else {
          chunkEnd = startDate.add(Duration(days: planDurationDays));
        }

        final chunkSessions = _scheduleRoundRobin(
          subjectQueues: chunkQueues[i],
          startDate: chunkStart,
          endDate: chunkEnd,
          collegeSlots: collegeSlots,
          constraints: constraints,
          holidays: holidays,
          isRevisionPeriod: isRevision,
        );
        sessions.addAll(chunkSessions);

        if (i < examSchedule.ptDates.length) {
          chunkStart = examSchedule.ptDates[i].endDate
              .add(const Duration(days: 1));
        }
      }

      // Calculate weekly hours
      for (int d = 0; d < 7; d++) {
        final date = startDate.add(Duration(days: d));
        final dayInfo = _getDayInfo(date, collegeSlots, constraints,
            holidays, false);
        totalWeeklyHours += dayInfo.availableMinutes / 60;
      }
    } else {
      // No exam schedule: round-robin across full duration
      final scheduled = _scheduleRoundRobin(
        subjectQueues: subjectQueues,
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

  // ─── Round-Robin Scheduler ────────────────────────────────────────────────
  /// Schedules study sessions using round-robin across subjects.
  /// Ensures 2-3 subjects per day and equal weekly coverage.
  static List<TimetableSession> _scheduleRoundRobin({
    required List<_SubjectQueue> subjectQueues,
    required DateTime startDate,
    required DateTime endDate,
    required List<CollegeSlot> collegeSlots,
    required LifestyleConstraints constraints,
    required List<HolidayInfo> holidays,
    required bool isRevisionPeriod,
  }) {
    final sessions = <TimetableSession>[];
    final totalDays = endDate.difference(startDate).inDays;

    // Pre-calculate total available slots
    int totalSlots = 0;
    for (int day = 0; day <= totalDays; day++) {
      final currentDate = startDate.add(Duration(days: day));
      final dayInfo = _getDayInfo(
          currentDate, collegeSlots, constraints, holidays, isRevisionPeriod);
      if (dayInfo.availableMinutes >= 30) {
        final slots = _generateStudySlots(currentDate, dayInfo, collegeSlots);
        totalSlots += slots.length;
      }
    }

    int totalTopics = 0;
    for (var q in subjectQueues) {
      totalTopics += q.topics.length;
    }

    // Expand topics by splitting them if we have more slots than topics (to stretch across all days)
    final expandedQueues = <_SubjectQueue>[];
    if (totalSlots > totalTopics && totalTopics > 0) {
      final partsPerTopic = (totalSlots / totalTopics).ceil();
      for (var q in subjectQueues) {
        final newTopics = <_TopicEntry>[];
        for (var t in q.topics) {
          if (partsPerTopic == 1) {
            newTopics.add(t);
          } else {
            for (int i = 1; i <= partsPerTopic; i++) {
              newTopics.add(_TopicEntry(
                subject: t.subject,
                moduleName: t.moduleName,
                topic: '${t.topic} (Part $i of $partsPerTopic)',
                estimatedMinutes: (t.estimatedMinutes / partsPerTopic).round(),
                color: t.color,
              ));
            }
          }
        }
        expandedQueues.add(_SubjectQueue(
          subjectName: q.subjectName,
          topics: newTopics,
          color: q.color,
        ));
      }
    } else {
      expandedQueues.addAll(subjectQueues);
    }

    // Track current position in each subject's topic queue
    final positions = List<int>.filled(expandedQueues.length, 0);
    int subjectRotation = 0; // Which subject to start with each day

    for (int day = 0; day <= totalDays; day++) {
      final currentDate = startDate.add(Duration(days: day));
      final dayInfo = _getDayInfo(
          currentDate, collegeSlots, constraints, holidays, isRevisionPeriod);

      if (dayInfo.availableMinutes < 30) continue;

      final slots = _generateStudySlots(currentDate, dayInfo, collegeSlots);
      if (slots.isEmpty) continue;

      // Determine how many subjects today (2-3)
      final activeQueues = <int>[];
      for (int i = 0; i < expandedQueues.length; i++) {
        if (positions[i] < expandedQueues[i].topics.length) {
          activeQueues.add(i);
        }
      }
      if (activeQueues.isEmpty) break;

      // Pick 2-3 subjects for today in round-robin order
      final subjectsPerDay = dayInfo.isFreeDay
          ? (activeQueues.length >= 3 ? 3 : activeQueues.length)
          : (activeQueues.length >= 2 ? 2 : activeQueues.length);

      final todaysSubjects = <int>[];
      for (int i = 0; i < subjectsPerDay; i++) {
        final idx = (subjectRotation + i) % activeQueues.length;
        todaysSubjects.add(activeQueues[idx]);
      }

      // Distribute slots across today's subjects
      int slotIndex = 0;
      int subjectCycleIdx = 0;

      while (slotIndex < slots.length) {
        final queueIdx = todaysSubjects[subjectCycleIdx % todaysSubjects.length];
        final queue = expandedQueues[queueIdx];

        if (positions[queueIdx] >= queue.topics.length) {
          // This subject is done, skip it
          subjectCycleIdx++;
          // Check if all today's subjects are done
          bool allDone = todaysSubjects.every(
              (idx) => positions[idx] >= expandedQueues[idx].topics.length);
          if (allDone) break;
          continue;
        }

        final topic = queue.topics[positions[queueIdx]];
        final slot = slots[slotIndex];

        sessions.add(TimetableSession(
          id: '${currentDate.millisecondsSinceEpoch}_${slotIndex}',
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

        positions[queueIdx]++;
        slotIndex++;
        subjectCycleIdx++;
      }

      // Rotate starting subject for next day
      subjectRotation = (subjectRotation + 1) % activeQueues.length;
    }

    return sessions;
  }

  // ─── Day Info Calculator ──────────────────────────────────────────────────
  /// Calculate available study info for a specific day.
  ///
  /// College days: 24 - sleep - travel - personal - break - college = study time
  /// Capped at 3-4 hrs realistically on college days.
  /// Free days: 1.5x of college-day study time, capped at 5-6 hrs.
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

    if (isFreeDay) {
      // Free day: no college, no travel
      // Calculate base college-day study time first
      double collegeDayUnavailable = constraints.sleepHours +
          (constraints.travelMinutes / 60) +
          (constraints.personalMinutes / 60) +
          (constraints.breakMinutes / 60);

      // Estimate average college hours (use 6 as typical)
      final avgCollegeHrs = _averageCollegeHours(collegeSlots);
      double collegeDayStudy = (24 - collegeDayUnavailable - avgCollegeHrs)
          .clamp(1.0, 4.0);

      // Free day = 1.5x college day study, capped at 6 hrs
      double freeDayStudy = (collegeDayStudy * 1.5).clamp(2.0, 6.0);

      return _DayInfo(
        availableMinutes: (freeDayStudy * 60).round(),
        isWeekend: isWeekend,
        isHoliday: isHoliday || isRevisionPeriod,
        holidayName: isHoliday ? _getHolidayName(date, holidays) : null,
        isFreeDay: true,
      );
    } else {
      // College day
      double unavailableHrs = constraints.sleepHours +
          (constraints.travelMinutes / 60) +
          (constraints.personalMinutes / 60) +
          (constraints.breakMinutes / 60);

      // Subtract college hours for this specific day
      final daySlots = collegeSlots.where((s) => s.weekday == weekday);
      double collegeHrs = 0;
      for (var slot in daySlots) {
        collegeHrs += (slot.endHour - slot.startHour);
      }

      double totalAvailable = 24 - unavailableHrs - collegeHrs;
      // Realistic cap: students won't study more than 3-4 hrs after college
      double effectiveHours = totalAvailable.clamp(0.5, 4.0);

      return _DayInfo(
        availableMinutes: (effectiveHours * 60).round(),
        isWeekend: false,
        isHoliday: false,
        holidayName: null,
        isFreeDay: false,
      );
    }
  }

  /// Calculate average daily college hours across weekdays
  static double _averageCollegeHours(List<CollegeSlot> collegeSlots) {
    if (collegeSlots.isEmpty) return 6.0; // Default assumption
    double total = 0;
    final days = <int>{};
    for (var slot in collegeSlots) {
      total += (slot.endHour - slot.startHour);
      days.add(slot.weekday);
    }
    return days.isNotEmpty ? total / days.length : 6.0;
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

  // ─── Study Slot Generator ────────────────────────────────────────────────
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

      // Skip college hours on college days (safety check)
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

class _SubjectQueue {
  final String subjectName;
  final List<_TopicEntry> topics;
  final String color;
  _SubjectQueue({
    required this.subjectName,
    required this.topics,
    required this.color,
  });
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
