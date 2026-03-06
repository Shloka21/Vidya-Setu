import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/timetable_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Users ────────────────────────────────────────────────
  CollectionReference get usersCollection => _firestore.collection('users');

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await usersCollection.doc(uid).update(data);
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
    await remindersCollection(userId).doc(reminderId).delete();
  }

  Stream<QuerySnapshot> remindersStream(String userId) {
    return remindersCollection(userId)
        .orderBy('dateTime', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> mentorRemindersStream(String mentorId) {
    return _firestore.collectionGroup('reminders')
        .where('mentorId', isEqualTo: mentorId)
        .snapshots(); 
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
  Future<QuerySnapshot> searchMentors({String? query}) async {
    Query mentorQuery = usersCollection
        .where('role', isEqualTo: 'mentor');

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
    for (var session in sessions) {
      if (session['id'] == sessionId) {
        session['isCompleted'] = completed;
        break;
      }
    }
    await studyPlansCollection(userId).doc(planId).update({'sessions': sessions});
  }

  Future<void> updateSessionNotes(
      String userId, String planId, String sessionId, String notes) async {
    final doc = await studyPlansCollection(userId).doc(planId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
    for (var session in sessions) {
      if (session['id'] == sessionId) {
        session['notes'] = notes;
        break;
      }
    }
    await studyPlansCollection(userId).doc(planId).update({'sessions': sessions});
  }

  Future<void> updateSessionQuizCompleted(
      String userId, String planId, String sessionId, bool completed) async {
    final doc = await studyPlansCollection(userId).doc(planId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
    for (var session in sessions) {
      if (session['id'] == sessionId) {
        session['quizCompleted'] = completed;
        session['isCompleted'] = completed;
        break;
      }
    }
    await studyPlansCollection(userId).doc(planId).update({'sessions': sessions});
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
  Stream<QuerySnapshot> upcomingRemindersStream(String userId, {int limit = 3}) {
    return remindersCollection(userId)
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.now())
        .where('status', isEqualTo: 'pending')
        .orderBy('dateTime', descending: false)
        .limit(limit)
        .snapshots();
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
}

