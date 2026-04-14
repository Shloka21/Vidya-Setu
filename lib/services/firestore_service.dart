import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:async';
import '../models/timetable_model.dart';
import '../models/reminder_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Users ────────────────────────────────────────────────
  CollectionReference get usersCollection => _firestore.collection('users');

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await usersCollection.doc(uid).update(data);
  }

  /// Ensures a user dot has all necessary gamification fields
  Future<void> ensureUserInitialized(String uid) async {
    final doc = await usersCollection.doc(uid).get();
    if (!doc.exists) return;
    
    final data = doc.data() as Map<String, dynamic>;
    final updates = <String, dynamic>{};

    // Role healing: crucial for leaderboard which filters by role='student'
    if (data['role'] == null || data['role'] == '') updates['role'] = 'student';
    
    // Gamification fields: crucial for orderBy which ignores docs with missing fields
    if (data['points'] == null) updates['points'] = 0;
    if (data['level'] == null) updates['level'] = 1;
    if (data['streak'] == null) updates['streak'] = 0;
    if (data['tasksCompleted'] == null) updates['tasksCompleted'] = 0;
    if (data['totalStudyHours'] == null) updates['totalStudyHours'] = 0.0;
    if (data['lastStudyDate'] == null) updates['lastStudyDate'] = FieldValue.serverTimestamp();
    
    if (updates.isNotEmpty) {
      debugPrint('--- Sync Debug ---');
      debugPrint('Syncing user $uid with updates: $updates');
      await usersCollection.doc(uid).update(updates);
      debugPrint('Sync complete.');
      debugPrint('-------------------');
    }
  }

  Future<void> updateStreak(String uid) async {
    final doc = await usersCollection.doc(uid).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final lastStudyDateTs = data['lastStudyDate'] as Timestamp?;
    final lastStudyDate = lastStudyDateTs != null 
        ? DateTime(lastStudyDateTs.toDate().year, lastStudyDateTs.toDate().month, lastStudyDateTs.toDate().day)
        : null;

    int currentStreak = data['streak'] ?? 0;

    if (lastStudyDate == null || today.difference(lastStudyDate).inDays > 1) {
      // First time or missed a day
      currentStreak = 1;
    } else if (today.difference(lastStudyDate).inDays == 1) {
      // Consecutive day
      currentStreak++;
    }
    // If today.difference(lastStudyDate).inDays == 0, already tracked today

    await usersCollection.doc(uid).update({
      'streak': currentStreak,
      'lastStudyDate': Timestamp.fromDate(now),
      'points': FieldValue.increment(10), // Give 10 XP per session tracked
      'tasksCompleted': FieldValue.increment(1),
    });
  }

  Future<void> incrementStudyHours(String uid, double hours) async {
    await usersCollection.doc(uid).update({
      'totalStudyHours': FieldValue.increment(hours),
    });
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await usersCollection.doc(uid).get();
    return doc.data() as Map<String, dynamic>?;
  }

  Stream<DocumentSnapshot> userStream(String uid) {
    return usersCollection.doc(uid).snapshots();
  }

  // ─── Reminders ────────────────────────────────────────────
  CollectionReference remindersCollection(String userId) =>
      usersCollection.doc(userId).collection('reminders');

  Future<void> addReminder(String userId, Map<String, dynamic> data) async {
    await remindersCollection(userId).doc(data['id']).set(data);
  }

  Future<void> updateReminder(
      String userId, String reminderId, Map<String, dynamic> data) async {
    await remindersCollection(userId).doc(reminderId).update(data);
  }

  Future<void> deleteReminder(String userId, String reminderId) async {
    // Try deleting from personal subcollection first
    await remindersCollection(userId).doc(reminderId).delete();
    
    // Also try deleting from feedback collection (no-op if not there)
    // Mentors/Students can delete their own feedback/reminders depending on rules
    await feedbackCollection.doc(reminderId).delete();
  }

  Stream<QuerySnapshot> remindersStream(String userId) {
    return remindersCollection(userId)
        .orderBy('dateTime', descending: false)
        .snapshots();
  }

  Stream<List<Map<String, dynamic>>> mentorRemindersStream(String mentorId) {
    final controller = StreamController<List<Map<String, dynamic>>>();
    final Map<String, StreamSubscription> subscriptions = {};
    final Map<String, List<Map<String, dynamic>>> studentReminders = {};
    StreamSubscription? sentRemindersSub;
    List<Map<String, dynamic>> sentList = [];

    void updateEmit() {
      if (controller.isClosed) return;
      final all = [...studentReminders.values.expand((element) => element), ...sentList];
      // Sort by dateTime descending
      all.sort((a, b) {
        final aTime = (a['dateTime'] is Timestamp) ? (a['dateTime'] as Timestamp).toDate() : DateTime.tryParse(a['dateTime']?.toString() ?? '') ?? DateTime.now();
        final bTime = (b['dateTime'] is Timestamp) ? (b['dateTime'] as Timestamp).toDate() : DateTime.tryParse(b['dateTime']?.toString() ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      controller.add(all);
    }

    // Listen to reminders assigned via feedback collection (new model)
    sentRemindersSub = feedbackCollection
        .where('mentorId', isEqualTo: mentorId)
        .where('type', isEqualTo: 'mentor_reminder')
        .snapshots()
        .listen((snapshot) {
      sentList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {...data, 'id': doc.id};
      }).toList();
      updateEmit();
    });

    // First listen to connections to know which students to track for personal reminders
    final connectionsSub = mentorConnectionsStream(mentorId).listen((connSnapshot) {
      final studentIds = connSnapshot.docs.map((doc) => doc['studentId'] as String).toSet();
      
      // Remove subscriptions for students no longer connected
      final currentKeys = subscriptions.keys.toList();
      for (final id in currentKeys) {
        if (!studentIds.contains(id)) {
          subscriptions[id]?.cancel();
          subscriptions.remove(id);
          studentReminders.remove(id);
        }
      }

      // Add subscriptions for new students
      for (final id in studentIds) {
        if (!subscriptions.containsKey(id)) {
          subscriptions[id] = remindersStream(id).listen((reminderSnapshot) {
            studentReminders[id] = reminderSnapshot.docs
                .map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return {...data, 'id': d.id};
                })
                .toList();
            updateEmit();
          });
        }
      }
      
      if (studentIds.isEmpty && sentList.isEmpty) {
        studentReminders.clear();
        updateEmit();
      }
    });

    controller.onCancel = () {
      connectionsSub.cancel();
      sentRemindersSub?.cancel();
      for (final sub in subscriptions.values) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  /// Merges personal reminders and mentor-assigned reminders (from feedback collection)
  Stream<List<ReminderModel>> allRemindersStream(String userId) {
    final controller = StreamController<List<ReminderModel>>();
    
    StreamSubscription? personalSub;
    StreamSubscription? mentorSub;
    
    List<ReminderModel> personalList = [];
    List<ReminderModel> mentorList = [];

    void emit() {
      if (controller.isClosed) return;
      final combined = [...personalList, ...mentorList];
      combined.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      controller.add(combined);
    }

    personalSub = remindersStream(userId).listen((snapshot) {
      personalList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return ReminderModel.fromMap({...data, 'id': doc.id});
      }).toList();
      emit();
    }, onError: (e) => controller.addError(e));

    mentorSub = feedbackForStudentStream(userId).listen((snapshot) {
      mentorList = snapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'mentor_reminder')
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ReminderModel.fromMap({
              ...data,
              'id': doc.id,
              'userId': userId,
              'type': ReminderType.custom.name, // Will be displayed as mentor assigned
              'createdByMentorId': data['mentorId'],
            });
          }).toList();
      emit();
    }, onError: (e) => controller.addError(e));

    controller.onCancel = () {
      personalSub?.cancel();
      mentorSub?.cancel();
    };

    return controller.stream;
  }

  /// Recalculates and updates the totalStudyHours for a student based on all completed sessions
  Future<void> syncTotalStudyHours(String userId) async {
    final snapshots = await studyPlansCollection(userId).get();
    double totalHours = 0.0;
    
    for (var doc in snapshots.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
      for (var s in sessions) {
        if (s['isCompleted'] == true) {
          final duration = (s['durationMinutes'] as num? ?? 0).toDouble();
          totalHours += duration / 60.0;
        }
      }
    }
    
    await usersCollection.doc(userId).update({
      'totalStudyHours': totalHours,
    });
  }

  // ─── Timetables ───────────────────────────────────────────
  CollectionReference timetablesCollection(String userId) =>
      usersCollection.doc(userId).collection('timetables');

  Future<void> saveTimetable(String userId, Map<String, dynamic> data) async {
    await timetablesCollection(userId).doc(data['id']).set(data);
  }

  Future<void> updateTimetable(
      String userId, String timetableId, Map<String, dynamic> data) async {
    await timetablesCollection(userId).doc(timetableId).update(data);
  }

  Stream<QuerySnapshot> timetablesStream(String userId) {
    return timetablesCollection(userId).snapshots();
  }

  // ─── Chat Rooms ───────────────────────────────────────────
  CollectionReference get chatRoomsCollection =>
      _firestore.collection('chatRooms');

  Future<String> getOrCreateChatRoom(
      String userId1, String userId2) async {
    // Check if chat room already exists
    final query = await chatRoomsCollection
        .where('participants', arrayContains: userId1)
        .get();

    for (var doc in query.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(data['participants'] ?? []);
      if (participants.contains(userId2)) {
        return doc.id;
      }
    }

    // Create new chat room
    final roomRef = chatRoomsCollection.doc();
    await roomRef.set({
      'id': roomRef.id,
      'participants': [userId1, userId2],
      'lastMessage': 'Chat room created',
      'lastMessageTime': Timestamp.now(),
      'lastMessageSenderId': null,
      'unreadCount': {userId1: 0, userId2: 0},
    });
    return roomRef.id;
  }

  Stream<QuerySnapshot> chatRoomsStream(String userId) {
    return chatRoomsCollection
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // ─── Messages ─────────────────────────────────────────────
  CollectionReference messagesCollection(String roomId) =>
      chatRoomsCollection.doc(roomId).collection('messages');

  Future<void> sendMessage(String roomId, Map<String, dynamic> data) async {
    final batch = _firestore.batch();

    // Add message
    final msgRef = messagesCollection(roomId).doc(data['id']);
    batch.set(msgRef, data);

    // Update chat room
    batch.update(chatRoomsCollection.doc(roomId), {
      'lastMessage': data['content'],
      'lastMessageTime': data['timestamp'],
      'lastMessageSenderId': data['senderId'],
      'unreadCount.${data['receiverId']}': FieldValue.increment(1),
    });

    await batch.commit();
  }

  Stream<QuerySnapshot> messagesStream(String roomId) {
    return messagesCollection(roomId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  Future<void> markMessagesRead(String roomId, String userId) async {
    await chatRoomsCollection.doc(roomId).update({
      'unreadCount.$userId': 0,
    });
  }

  Future<String> uploadChatFile(String roomId, String messageId, File file) async {
    final ext = file.path.split('.').last;
    final path = 'chats/$roomId/$messageId.$ext';
    final ref = FirebaseStorage.instance.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // ─── Mentor Connections ───────────────────────────────────
  CollectionReference get connectionsCollection =>
      _firestore.collection('connections');

  Future<void> sendMentorRequest(Map<String, dynamic> data) async {
    await connectionsCollection.doc(data['id']).set(data);
  }

  Future<void> updateConnectionStatus(String id, String status) async {
    await connectionsCollection.doc(id).update({'status': status});
  }

  Stream<QuerySnapshot> mentorRequestsStream(String mentorId) {
    return connectionsCollection
        .where('mentorId', isEqualTo: mentorId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> studentConnectionsStream(String studentId) {
    return connectionsCollection
        .where('studentId', isEqualTo: studentId)
        .snapshots();
  }

  Stream<QuerySnapshot> mentorConnectionsStream(String mentorId) {
    return connectionsCollection
        .where('mentorId', isEqualTo: mentorId)
        .where('status', isEqualTo: 'approved')
        .snapshots();
  }

  // ─── Feedback ─────────────────────────────────────────────
  CollectionReference get feedbackCollection =>
      _firestore.collection('feedback');

  Future<void> sendFeedback(Map<String, dynamic> data) async {
    await feedbackCollection.doc(data['id']).set(data);
  }

  /// Specialized method for mentors to assign reminders to students
  /// (Stays in feedback collection to avoid permission errors on users/{uid}/reminders)
  Future<void> assignReminderByMentor(String studentId, Map<String, dynamic> data) async {
    data['type'] = 'mentor_reminder';
    data['studentId'] = studentId;
    data['createdAt'] = data['createdAt'] ?? Timestamp.now();
    await sendFeedback(data);
  }

  Stream<QuerySnapshot> feedbackForStudentStream(String studentId) {
    return feedbackCollection
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> feedbackByMentorStream(String mentorId) {
    return feedbackCollection
        .where('mentorId', isEqualTo: mentorId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> saveFeedback(Map<String, dynamic> data) async {
    await feedbackCollection.doc(data['id']).set(data);
  }

  Stream<QuerySnapshot> getFeedbackStream(String userId, {bool isMentor = false}) {
    if (isMentor) {
      return feedbackCollection
          .where('mentorId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      return feedbackCollection
          .where('studentId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

  // ─── Search Mentors ───────────────────────────────────────
  Future<QuerySnapshot> searchMentors({bool onlyAvailable = false}) async {
    Query mentorQuery = usersCollection.where('role', isEqualTo: 'mentor');
    
    if (onlyAvailable) {
      mentorQuery = mentorQuery.where('availableForNew', isEqualTo: true);
    }

    return await mentorQuery.get();
  }

  // ─── Search Students ──────────────────────────────────────
  Future<QuerySnapshot> searchStudents({String? query}) async {
    Query studentQuery = usersCollection
        .where('role', isEqualTo: 'student');
    return await studentQuery.get();
  }

  Stream<QuerySnapshot> mentorSentConnectionsStream(String mentorId) {
    return connectionsCollection
        .where('mentorId', isEqualTo: mentorId)
        .snapshots();
  }

  // ─── Leaderboard ──────────────────────────────────────────
  Future<QuerySnapshot> getLeaderboard({int limit = 20}) async {
    return await usersCollection
        .where('role', isEqualTo: 'student')
        .orderBy('points', descending: true)
        .limit(limit)
        .get();
  }

  Stream<QuerySnapshot> leaderboardStream() {
    return usersCollection.snapshots();
  }

  // ─── Study Plans (Smart Timetable) ────────────────────────
  CollectionReference studyPlansCollection(String userId) =>
      usersCollection.doc(userId).collection('studyPlans');

  Future<void> saveStudyPlan(String userId, StudyPlan plan) async {
    await studyPlansCollection(userId).doc(plan.id).set(plan.toMap());
  }

  Future<StudyPlan?> getStudyPlan(String userId) async {
    final snapshot = await studyPlansCollection(userId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return StudyPlan.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
  }

  Stream<QuerySnapshot> studyPlansStream(String userId) {
    return studyPlansCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> updateSessionStatus(
      String userId, String planId, String sessionId, bool completed) async {
    final doc = await studyPlansCollection(userId).doc(planId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
    
    double hoursToAdd = 0.0;
    bool alreadyCompleted = false;

    for (var session in sessions) {
      if (session['id'] == sessionId) {
        alreadyCompleted = session['isCompleted'] == true;
        session['isCompleted'] = completed;
        
        if (completed && !alreadyCompleted) {
          // Marking as done for the first time
          hoursToAdd = (session['durationMinutes'] as num? ?? 0).toDouble() / 60.0;
        } else if (!completed && alreadyCompleted) {
          // Unmarking as done
          hoursToAdd = -((session['durationMinutes'] as num? ?? 0).toDouble() / 60.0);
        }
        break;
      }
    }
    
    await studyPlansCollection(userId).doc(planId).update({'sessions': sessions});
    
    if (hoursToAdd != 0) {
      await incrementStudyHours(userId, hoursToAdd);
    }
  }

  Future<void> updateSessionNotes(
      String userId, String planId, String sessionId, String notes, {String? lang}) async {
    final doc = await studyPlansCollection(userId).doc(planId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
    for (var session in sessions) {
      if (session['id'] == sessionId) {
        session['notes'] = notes;
        if (lang != null) session['notesLang'] = lang;
        break;
      }
    }
    await studyPlansCollection(userId).doc(planId).update({'sessions': sessions});
  }

  Future<void> updateSessionQuizCompleted(
      String userId, String planId, String sessionId, bool completed, {String? lang}) async {
    final doc = await studyPlansCollection(userId).doc(planId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
    
    double hoursToAdd = 0.0;
    bool alreadyCompleted = false;

    for (var session in sessions) {
      if (session['id'] == sessionId) {
        alreadyCompleted = session['isCompleted'] == true;
        session['quizCompleted'] = completed;
        session['isCompleted'] = completed;
        if (lang != null) session['quizLang'] = lang;
        
        if (completed && !alreadyCompleted) {
          hoursToAdd = (session['durationMinutes'] as num? ?? 0).toDouble() / 60.0;
        } else if (!completed && alreadyCompleted) {
          hoursToAdd = -((session['durationMinutes'] as num? ?? 0).toDouble() / 60.0);
        }
        break;
      }
    }
    
    await studyPlansCollection(userId).doc(planId).update({'sessions': sessions});
    
    if (hoursToAdd != 0) {
      await incrementStudyHours(userId, hoursToAdd);
    }
  }

  Future<void> rescheduleSession(
      String userId, String planId, String sessionId, DateTime newDate) async {
    final doc = await studyPlansCollection(userId).doc(planId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
    for (var session in sessions) {
      if (session['id'] == sessionId) {
        final oldStartTime = DateTime.parse(session['startTime']);
        final newStartTime = DateTime(
          newDate.year, newDate.month, newDate.day,
          oldStartTime.hour, oldStartTime.minute,
        );
        session['date'] = newDate.toIso8601String();
        session['startTime'] = newStartTime.toIso8601String();
        break;
      }
    }
    await studyPlansCollection(userId).doc(planId).update({'sessions': sessions});
  }

  // ─── Dashboard Helpers ─────────────────────────────────────
  Stream<List<ReminderModel>> upcomingRemindersStream(String userId, {int limit = 3}) {
    final controller = StreamController<List<ReminderModel>>();
    
    StreamSubscription? sub;
    sub = allRemindersStream(userId).listen((list) {
      final now = DateTime.now();
      final upcoming = list
          .where((r) => r.dateTime.isAfter(now) && r.status == ReminderStatus.pending)
          .take(limit)
          .toList();
      controller.add(upcoming);
    }, onError: (e) => controller.addError(e));

    controller.onCancel = () => sub?.cancel();
    return controller.stream;
  }

  Future<List<Map<String, dynamic>>> getConnectedStudents(String mentorId) async {
    final connections = await connectionsCollection
        .where('mentorId', isEqualTo: mentorId)
        .where('status', isEqualTo: 'approved')
        .get();

    final students = <Map<String, dynamic>>[];
    for (var doc in connections.docs) {
      final conn = doc.data() as Map<String, dynamic>;
      final studentDoc = await usersCollection.doc(conn['studentId']).get();
      if (studentDoc.exists) {
        final data = studentDoc.data() as Map<String, dynamic>;
        data['connectionId'] = doc.id;
        students.add(data);
      }
    }
    return students;
  }

  Future<int> getPendingRequestsCount(String mentorId) async {
    final snapshot = await connectionsCollection
        .where('mentorId', isEqualTo: mentorId)
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.length;
  }

  // ─── Connected Mentors (for student chat suggestions) ─────
  Future<List<Map<String, dynamic>>> getConnectedMentors(String studentId) async {
    final connections = await connectionsCollection
        .where('studentId', isEqualTo: studentId)
        .where('status', isEqualTo: 'approved')
        .get();

    final mentors = <Map<String, dynamic>>[];
    for (var doc in connections.docs) {
      final conn = doc.data() as Map<String, dynamic>;
      final mentorDoc = await usersCollection.doc(conn['mentorId']).get();
      if (mentorDoc.exists) {
        final data = mentorDoc.data() as Map<String, dynamic>;
        data['connectionId'] = doc.id;
        mentors.add(data);
      }
    }
    return mentors;
  }

  // ─── Meetings (mentor scheduling) ─────────────────────────
  CollectionReference get meetingsCollection =>
      _firestore.collection('meetings');

  Future<void> scheduleMeeting(Map<String, dynamic> data) async {
    await meetingsCollection.doc(data['id']).set(data);
  }

  Stream<QuerySnapshot> meetingsStream(String userId) {
    return meetingsCollection
        .where('participants', arrayContains: userId)
        .orderBy('scheduledAt', descending: false)
        .snapshots();
  }

  // ─── Unread Count Helper ──────────────────────────────────
  Stream<int> totalUnreadCountStream(String userId) {
    return chatRoomsStream(userId).map((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final unread = (data['unreadCount'] as Map<String, dynamic>?)?[userId] ?? 0;
        total += (unread as num).toInt();
      }
      return total;
    });
  }

  // ─── Active Call Signaling (incoming call UI) ─────────────
  CollectionReference get activeCallsCollection =>
      _firestore.collection('activeCalls');

  Future<void> startCall({
    required String roomId,
    required String callerId,
    required String callerName,
    required String receiverId,
  }) async {
    await activeCallsCollection.doc(roomId).set({
      'roomId': roomId,
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'status': 'ringing', // ringing, accepted, declined, ended
      'startedAt': Timestamp.now(),
    });
  }

  Future<void> updateCallStatus(String roomId, String status) async {
    await activeCallsCollection.doc(roomId).update({'status': status});
  }

  Future<void> endCall(String roomId) async {
    await activeCallsCollection.doc(roomId).delete();
  }

  Stream<DocumentSnapshot> activeCallStream(String roomId) {
    return activeCallsCollection.doc(roomId).snapshots();
  }

  /// Stream for a user to know if they are being called
  Stream<QuerySnapshot> incomingCallsStream(String userId) {
    return activeCallsCollection
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'ringing')
        .snapshots();
  }

  // ─── In-App Notifications (No-op Placeholder) ───────────
  // These are now handled via stream observation in the dashboards.
  Future<void> writeNotification(String userId, Map<String, dynamic> data) async {}

  /// Acknowledge mentor feedback and notify mentor
  Future<void> acknowledgeFeedback(String feedbackId, String mentorId, String studentName) async {
    try {
      await feedbackCollection.doc(feedbackId).update({
        'acknowledged': true,
        'acknowledgedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Warning: Could not update feedback doc status: $e');
      // If update fails (permission), we still proceed to notify the mentor via a new doc
    }

    // Notify mentor - creating a document in their requests/notifs area
    // Since mentors have a dedicated connection area, we'll put it there or a shared notifs collection
    // For now, satisfy the "notify mentor" requirement by adding to a shared notifications system
    // or updating the connection status. We'll add a 'feedback_acknowledged' document to the 
    // root 'feedback' collection specifically formatted for the mentor to see.
    
    await feedbackCollection.add({
      'mentorId': mentorId,
      'type': 'acknowledgement',
      'title': 'Feedback Acknowledged',
      'content': '$studentName has acknowledged your feedback.',
      'studentName': studentName,
      'createdAt': Timestamp.now(),
      'isPositive': true,
    });
  }

  // ─── Leaderboard (extended) ───────────────────────────────
  /// Get user's rank even if they're not in the top N
  Future<Map<String, dynamic>?> getUserRankData(String userId) async {
    try {
      final userDoc = await usersCollection.doc(userId).get();
      if (!userDoc.exists) return null;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      userData['uid'] = userDoc.id; // Ensure consistency
      
      final userPoints = (userData['points'] ?? 0) as int;

      // Count how many users have more points
      final higherRankedQuery = usersCollection
          .where('points', isGreaterThan: userPoints);
      
      final countSnapshot = await higherRankedQuery.count().get();
      final higherCount = countSnapshot.count ?? 0;

      userData['rank'] = higherCount + 1;
      return userData;
    } catch (e) {
      debugPrint('Error fetching rank data: $e');
      return null;
    }
  }
}

