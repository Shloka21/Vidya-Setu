import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'routes.dart';
import '../main.dart' show navigatorKey;
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
import '../screens/student/timetable/session_detail_screen.dart';
import '../screens/student/timetable/session_quiz_screen.dart';
import '../screens/student/analytics/progress_dashboard_screen.dart';
import '../screens/student/analytics/subject_analytics_screen.dart';
import '../screens/student/mentor/find_mentor_screen.dart';
import '../screens/student/mentor/mentor_profile_view_screen.dart';
import '../screens/student/profile/student_profile_screen.dart';
import '../screens/student/profile/edit_profile_screen.dart';
import '../screens/mentor/dashboard/mentor_dashboard.dart';
import '../screens/mentor/students/my_students_screen.dart';
import '../screens/mentor/students/student_profile_mentor_view.dart';
import '../screens/mentor/students/student_analytics_mentor_screen.dart';
import '../screens/mentor/feedback/send_feedback_screen.dart';
import '../screens/mentor/feedback/feedback_history_screen.dart';
import '../screens/mentor/reminders/mentor_reminders_screen.dart';
import '../screens/mentor/reminders/create_reminder_screen.dart';
import '../screens/mentor/profile/mentor_profile_screen.dart';
import '../screens/mentor/settings/mentor_settings_screen.dart';
import '../screens/mentor/students/browse_students_screen.dart';
import '../screens/mentor/students/schedule_group_meeting_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_room_screen.dart';
import '../screens/chat/video_call_screen.dart';
import '../screens/gamification/achievements_screen.dart';
import '../screens/gamification/leaderboard_screen.dart';
import '../screens/gamification/point_system_screen.dart';
import '../screens/alarm/alarm_screen.dart';
import '../screens/student/focus/focus_mode_screen.dart';
import '../screens/student/focus/focus_blocked_screen.dart';

import '../services/notification_service.dart';
import '../services/localization_service.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/translation_loader.dart';

class VidyaSetuApp extends StatefulWidget {
  const VidyaSetuApp({super.key});

  @override
  State<VidyaSetuApp> createState() => _VidyaSetuAppState();
}

class _VidyaSetuAppState extends State<VidyaSetuApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<LocalizationService>(
          create: (_) => LocalizationService(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
        navigatorKey: navigatorKey,
        onGenerateTitle: (context) => context.tr('vidyasetu'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        builder: (context, child) {
          final isTranslating = Provider.of<LocalizationService>(context).isTranslating;
          return Stack(
            children: [
              if (child != null) child,
              if (isTranslating) const PremiumTranslationLoader(),
            ],
          );
        },
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (_) => const SplashScreen(),
          AppRoutes.onboarding: (_) => OnboardingScreen(),
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.signup: (_) => const SignupScreen(),
          AppRoutes.phoneAuth: (_) => const PhoneAuthScreen(),
          AppRoutes.roleSelection: (_) => const RoleSelectionScreen(),

          // Student
          AppRoutes.studentDashboard: (_) => const StudentDashboard(),
          AppRoutes.remindersList: (_) => const RemindersListScreen(),
          AppRoutes.addReminder: (_) => const AddEditReminderScreen(),
          AppRoutes.editReminder: (_) => const AddEditReminderScreen(),
          AppRoutes.timetableOverview: (_) => const TimetableOverviewScreen(),
          AppRoutes.generateTimetable: (_) => const GenerateTimetableScreen(),
          AppRoutes.editTimetableSlot: (_) => const EditTimetableSlotScreen(),
          AppRoutes.dailyStudyPlan: (_) => const DailyStudyPlanScreen(),
          AppRoutes.progressDashboard: (_) => const ProgressDashboardScreen(),
          AppRoutes.subjectAnalytics: (_) => const SubjectAnalyticsScreen(),
          AppRoutes.findMentor: (_) => const FindMentorScreen(),
          AppRoutes.mentorProfile: (_) => const MentorProfileViewScreen(),
          AppRoutes.studentProfile: (_) => const StudentProfileScreen(),
          AppRoutes.editStudentProfile: (_) => const EditProfileScreen(),


          // Mentor
          AppRoutes.mentorDashboard: (_) => const MentorDashboard(),
          AppRoutes.myStudents: (_) => MyStudentsScreen(),
          AppRoutes.studentProfileMentorView: (_) => const StudentProfileMentorView(),
          AppRoutes.studentAnalyticsMentor: (_) => const StudentAnalyticsMentorScreen(),
          AppRoutes.sendFeedback: (_) => const SendFeedbackScreen(),
          AppRoutes.feedbackHistory: (_) => FeedbackHistoryScreen(),
          AppRoutes.mentorRemindersList: (_) => MentorRemindersScreen(),
          AppRoutes.createReminder: (_) => const CreateReminderScreen(),
          AppRoutes.mentorProfileScreen: (_) => const MentorProfileScreen(),
          AppRoutes.mentorSettings: (_) => const MentorSettingsScreen(),
          AppRoutes.browseStudents: (_) => const BrowseStudentsScreen(),
          AppRoutes.scheduleGroupMeeting: (_) => const ScheduleGroupMeetingScreen(),

          // Chat
          AppRoutes.chatList: (_) => ChatListScreen(),
          AppRoutes.chatConversation: (_) => const ChatRoomScreen(),
          AppRoutes.videoCall: (_) => const VideoCallScreen(),

          // Timetable extras
          AppRoutes.sessionDetail: (_) => const SessionDetailScreen(),
          AppRoutes.sessionQuiz: (_) => const SessionQuizScreen(),

          // Gamification
          AppRoutes.achievements: (_) => const AchievementsScreen(),
          AppRoutes.leaderboard: (_) => const LeaderboardScreen(),
          AppRoutes.pointSystem: (_) => const PointSystemScreen(),

          // Alarm
          AppRoutes.alarmScreen: (_) => const AlarmScreen(),

          // Focus
          AppRoutes.focusMode: (_) => const FocusModeScreen(),
          AppRoutes.focusBlocked: (_) => const FocusBlockedScreen(),
        },
      )),
    );
  }
}
