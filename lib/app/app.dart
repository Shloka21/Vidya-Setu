import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'routes.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/phone_auth_screen.dart';
import '../screens/student/dashboard/student_dashboard.dart';
import '../screens/student/reminders/reminders_list_screen.dart';
import '../screens/student/reminders/add_edit_reminder_screen.dart';
import '../screens/student/timetable/timetable_overview_screen.dart';
import '../screens/student/timetable/generate_timetable_screen.dart';
import '../screens/student/timetable/edit_timetable_slot_screen.dart';
import '../screens/student/timetable/daily_study_plan_screen.dart';
import '../screens/student/analytics/progress_dashboard_screen.dart';
import '../screens/student/analytics/subject_analytics_screen.dart';
import '../screens/student/mentor/find_mentor_screen.dart';
import '../screens/student/mentor/mentor_profile_view_screen.dart';
import '../screens/student/profile/student_profile_screen.dart';
import '../screens/student/profile/edit_profile_screen.dart';
import '../screens/student/settings/student_settings_screen.dart';
import '../screens/mentor/dashboard/mentor_dashboard.dart';
import '../screens/mentor/students/my_students_screen.dart';
import '../screens/mentor/students/student_profile_mentor_view.dart';
import '../screens/mentor/students/student_analytics_mentor_screen.dart';
import '../screens/mentor/feedback/send_feedback_screen.dart';
import '../screens/mentor/feedback/feedback_history_screen.dart';
import '../screens/mentor/reminders/mentor_reminders_screen.dart';
import '../screens/mentor/reminders/create_reminder_screen.dart';
import '../screens/mentor/profile/mentor_profile_screen.dart';
import '../screens/mentor/profile/edit_mentor_profile_screen.dart';
import '../screens/mentor/settings/mentor_settings_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_room_screen.dart';
import '../screens/chat/video_call_screen.dart';
import '../screens/gamification/achievements_screen.dart';
import '../screens/gamification/leaderboard_screen.dart';
import '../screens/gamification/point_system_screen.dart';

class VidyaSetuApp extends StatelessWidget {
  const VidyaSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'VidyaSetu',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: AppRoutes.splash,
            routes: {
              AppRoutes.splash: (_) => const SplashScreen(),
              AppRoutes.onboarding: (_) => const OnboardingScreen(),
              AppRoutes.login: (_) => const LoginScreen(),
              AppRoutes.signup: (_) => const SignupScreen(),
              AppRoutes.phoneAuth: (_) => const PhoneAuthScreen(),
              AppRoutes.roleSelection: (_) => const RoleSelectionScreen(),

              // Student
              AppRoutes.studentDashboard: (_) => const StudentDashboard(),
              AppRoutes.remindersList: (_) => const RemindersListScreen(),
              AppRoutes.addReminder: (_) => const AddEditReminderScreen(),
              AppRoutes.editReminder: (_) => const AddEditReminderScreen(),
              AppRoutes.timetableOverview: (_) =>
                  const TimetableOverviewScreen(),
              AppRoutes.generateTimetable: (_) =>
                  const GenerateTimetableScreen(),
              AppRoutes.editTimetableSlot: (_) =>
                  const EditTimetableSlotScreen(),
              AppRoutes.dailyStudyPlan: (_) => const DailyStudyPlanScreen(),
              AppRoutes.progressDashboard: (_) =>
                  const ProgressDashboardScreen(),
              AppRoutes.subjectAnalytics: (_) => const SubjectAnalyticsScreen(),
              AppRoutes.findMentor: (_) => const FindMentorScreen(),
              AppRoutes.mentorProfile: (_) => const MentorProfileViewScreen(),
              AppRoutes.studentProfile: (_) => const StudentProfileScreen(),
              AppRoutes.editStudentProfile: (_) => const EditProfileScreen(),
              AppRoutes.studentSettings: (_) => const StudentSettingsScreen(),

              // Mentor
              AppRoutes.mentorDashboard: (_) => const MentorDashboard(),
              AppRoutes.myStudents: (_) => MyStudentsScreen(),
              AppRoutes.studentProfileMentorView: (_) =>
                  const StudentProfileMentorView(),
              AppRoutes.studentAnalyticsMentor: (_) =>
                  const StudentAnalyticsMentorScreen(),
              AppRoutes.sendFeedback: (_) => const SendFeedbackScreen(),
              AppRoutes.feedbackHistory: (_) => const FeedbackHistoryScreen(),
              AppRoutes.mentorRemindersList: (_) =>
                  const MentorRemindersScreen(),
              AppRoutes.createReminder: (_) => const CreateReminderScreen(),
              AppRoutes.mentorProfileScreen: (_) => const MentorProfileScreen(),
              AppRoutes.editMentorProfile: (_) =>
                  const EditMentorProfileScreen(),
              AppRoutes.mentorSettings: (_) => const MentorSettingsScreen(),

              // Chat
              AppRoutes.chatList: (_) => ChatListScreen(),
              AppRoutes.chatConversation: (_) => const ChatRoomScreen(),
              AppRoutes.videoCall: (_) => const VideoCallScreen(),

              // Gamification
              AppRoutes.achievements: (_) => const AchievementsScreen(),
              AppRoutes.leaderboard: (_) => const LeaderboardScreen(),
              AppRoutes.pointSystem: (_) => const PointSystemScreen(),
            },
          );
        },
      ),
    );
  }
}
