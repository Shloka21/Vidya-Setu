class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String phoneAuth = '/phone-auth';
  static const String roleSelection = '/role-selection';

  // Student
  static const String studentDashboard = '/student/dashboard';
  static const String remindersList = '/student/reminders';
  static const String addReminder = '/student/reminders/add';
  static const String editReminder = '/student/reminders/edit';
  static const String timetableOverview = '/student/timetable';
  static const String generateTimetable = '/student/timetable/generate';
  static const String editTimetableSlot = '/student/timetable/edit-slot';
  static const String dailyStudyPlan = '/student/timetable/daily';
  static const String progressDashboard = '/student/analytics';
  static const String subjectAnalytics = '/student/analytics/subject';
  static const String findMentor = '/student/mentor/find';
  static const String mentorRequest = '/student/mentor/request';
  static const String mentorProfile = '/student/mentor/profile';
  static const String studentProfile = '/student/profile';
  static const String editStudentProfile = '/student/profile/edit';
  static const String studentSettings = '/student/settings';

  // Mentor
  static const String mentorDashboard = '/mentor/dashboard';
  static const String myStudents = '/mentor/students';
  static const String studentProfileMentorView = '/mentor/students/profile';
  static const String studentAnalyticsMentor = '/mentor/students/analytics';
  static const String sendFeedback = '/mentor/feedback/send';
  static const String feedbackHistory = '/mentor/feedback/history';
  static const String createReminder = '/mentor/reminders/create';
  static const String mentorRemindersList = '/mentor/reminders';
  static const String mentorProfileScreen = '/mentor/profile';
  static const String mentorSettings = '/mentor/settings';

  // Chat
  static const String chatList = '/chat';
  static const String chatConversation = '/chat/conversation';
  static const String videoCall = '/chat/video-call';

  // Timetable extras
  static const String sessionDetail = '/student/timetable/session';
  static const String sessionQuiz = '/student/timetable/quiz';

  // Gamification
  static const String achievements = '/gamification/achievements';
  static const String leaderboard = '/gamification/leaderboard';
  static const String pointSystem = '/gamification/points';
}
