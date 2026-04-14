import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class LocalizationService extends ChangeNotifier {
  String _locale = 'en';
  bool _isTranslating = false;
  bool _cancelRequested = false;
  Map<String, String> _activeDictionary = Map.from(_english);
  OnDeviceTranslator? _dynamicTranslator;

  String get locale => _locale;
  bool get isTranslating => _isTranslating;

  void cancelTranslation() {
    _cancelRequested = true;
    _isTranslating = false;
    notifyListeners();
  }

  LocalizationService() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('pref_language') ?? 'en';
    await setLocale(savedCode);
  }

  Future<void> setLocale(String localeCode) async {
    _cancelRequested = false;
    // If setting to English, shortcut — instant
    if (localeCode == 'en' || _getLanguageEnum(localeCode) == null) {
      _locale = 'en';
      _activeDictionary = Map.from(_english);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pref_language', 'en');
      notifyListeners();
      return;
    }

    _locale = localeCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_language', localeCode);

    // ── Step 1: Try loading from local JSON cache (instant!) ──
    final cachedJson = prefs.getString('lang_cache_$localeCode');
    if (cachedJson != null) {
      try {
        final cached = Map<String, String>.from(jsonDecode(cachedJson));
        if (cached.length >= _english.length * 0.8) {
          // Cache is valid and has enough keys — use it instantly
          _activeDictionary = cached;
          notifyListeners();
          return; // Done! No loading dialog needed
        }
      } catch (_) {}
    }

    // ── Step 2: No cache — translate with ML Kit (first time only) ──
    _isTranslating = true;
    notifyListeners();

    final targetLang = _getLanguageEnum(localeCode)!;

    // Download model if needed
    final modelManager = OnDeviceTranslatorModelManager();
    final bool isDownloaded = await modelManager.isModelDownloaded(targetLang.bcpCode);
    if (!isDownloaded) {
      await modelManager.downloadModel(targetLang.bcpCode);
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: targetLang,
    );

    // Build dictionary — translate all strings
    final newDict = <String, String>{};
    for (var entry in _english.entries) {
      if (_cancelRequested) {
        _isTranslating = false;
        notifyListeners();
        translator.close();
        return;
      }
      try {
        newDict[entry.key] = await translator.translateText(entry.value);
      } catch (e) {
        newDict[entry.key] = entry.value; // Fallback to English
      }
    }

    translator.close();

    // ── Step 3: Cache the translated dictionary as JSON ──
    _activeDictionary = newDict;
    await prefs.setString('lang_cache_$localeCode', jsonEncode(newDict));
    
    // Update dynamic translator for on-the-fly requests
    _dynamicTranslator?.close();
    _dynamicTranslator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: targetLang,
    );

    _isTranslating = false;
    notifyListeners();
  }

  String translate(String key) {
    // 1. Check Manual Overrides first (Hardcoded Transliterations)
    if (_manualOverrides.containsKey(_locale) && _manualOverrides[_locale]!.containsKey(key)) {
      return _manualOverrides[_locale]![key]!;
    }

    // 2. Return translated value, fall back to English value, NEVER return raw key
    return _activeDictionary[key] ?? _english[key] ?? key.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  Future<String> translateDynamic(String text) async {
    if (_locale == 'en' || text.isEmpty) return text;
    if (_activeDictionary.containsKey(text)) return _activeDictionary[text]!;
    
    try {
      if (_dynamicTranslator != null) {
        final res = await _dynamicTranslator!.translateText(text);
        // Cache it dynamically for performance
        _activeDictionary[text] = res;
        return res;
      }
    } catch (_) {}
    return text;
  }

  TranslateLanguage? _getLanguageEnum(String code) {
    switch (code) {
      case 'hi': return TranslateLanguage.hindi;
      case 'bn': return TranslateLanguage.bengali;
      case 'mr': return TranslateLanguage.marathi;
      case 'te': return TranslateLanguage.telugu;
      case 'ta': return TranslateLanguage.tamil;
      case 'gu': return TranslateLanguage.gujarati;
      case 'kn': return TranslateLanguage.kannada;
      case 'ur': return TranslateLanguage.urdu;
      default: return null;
    }
  }

  // --- MANUAL OVERRIDES (Hardcoded Transliterations for Brands/Specific Terms) ---
  static const Map<String, Map<String, String>> _manualOverrides = {
    'hi': {
      'vidyasetu': 'विद्यासेतु',
      'high': 'उच्च',
      'medium': 'मध्यम',
      'low': 'कम',
      'at_exact_time': 'सटीक समय पर',
      '5_min': '5 मिनट पहले',
      '15_min': '15 मिनट पहले',
      '30_min': '30 मिनट पहले',
      '1_hour': '1 घंटा पहले',
      '1_day': '1 दिन पहले',
      'one_time': 'एक बार',
      'daily': 'दैनिक',
      'weekly': 'साप्ताहिक',
      'save_reminder': 'रिमाइंडर सहेजें',
      'update_reminder': 'रिमाइंडर अपडेट करें',
      'exams': 'परीक्षा',
      'assignments': 'असाइनमेंट',
      'quizzes': 'प्रश्नोत्तरी',
      'quiz': 'प्रश्नोत्तरी',
      'study': 'अध्ययन',
      'custom': 'कस्टम',
      'unlocked': 'अनलॉक किया गया',
      'locked': 'लॉक किया गया',
      'view_all': 'सभी देखें',
      'week_warrior': 'सप्ताह का योद्धा',
      'getting_started': 'शुरुआत',
      'point_master': 'अंक मास्टर',
      'monthly_master': 'मासिक मास्टर',
      'task_master': 'कार्य मास्टर',
      'centurion': 'शतकीय योद्धा',
      'recent_mentor_feedback': 'मेंटर्स द्वारा हालिया फीडबैक',
      'no_recent_feedback_from_your_mentors': 'आपके मेंटर्स द्वारा कोई हालिया फीडबैक नहीं है।',
      'all': 'सभी',
      'today': 'आज',
      'upcoming': 'आगामी',
      'completed': 'पूरा हुआ',
      'add_reminder': 'रिमाइंडर जोड़ें',
      'edit_reminder': 'रिमाइंडर संपादित करें',
      'add_reminder_for_student': 'छात्र के लिए रिमाइंडर जोड़ें',
      'error_occurred': 'त्रुटि हुई',
      'date': 'दिनांक',
      'time': 'समय',
      'type': 'प्रकार',
      'priority': 'प्राथमिकता',
      'notifications': 'अधिसूचनाएं',
      'remind_before': 'पहले याद दिलाएं',
      'repeat': 'दोहराएं',
      'enter_reminder_title': 'रिमाइंडर शीर्षक दर्ज करें',
      'add_details_about_this_reminde': 'इस रिमाइंडर के बारे में विवरण जोड़ें',
      'popup_notification': 'पॉपअप अधिसूचना',
      'voice_notification': 'वॉयस अधिसूचना',
      'title': 'शीर्षक',
      'description': 'विवरण',
      'save': 'सहेजें',
      'confirm': 'पुष्टि करें',
      'about_me': 'मेरे बारे में',
      'level': 'स्तर',
      'points': 'अंक',
      'streak': 'चील',
    },
    'mr': {
      'vidyasetu': 'विद्यासेतु',
    },
    'bn': {
       'vidyasetu': 'বিদ্যাসেতু',
    },
    'ta': {
       'vidyasetu': 'வித்யாசேது',
    },
    'te': {
       'vidyasetu': 'విద్యాసేతు',
    },
    'gu': {
       'vidyasetu': 'વિદ્યાસેતુ',
    },
    'kn': {
       'vidyasetu': 'ವಿದ್ಯಾಸೇತು',
    },
    'ur': {
       'vidyasetu': 'ودیا سیتو',
    },
  };

  // --- VERY BASIC DICTIONARY (Base Layer) ---
  static const Map<String, String> _english = {
    '1': '🇺🇸  +1',
    '1240__1500_xp': '1,240 / 1,500 XP',
    '1240_xp': '1,240 XP',
    '300_xp_earned': '300 XP Earned!',
    '38_hours_studied__60_complete': '38 hours studied • 60% complete',
    '3_of_6_achievements_unlocked': '3 of 6 achievements unlocked',
    '44': '🇬🇧  +44',
    '61': '🇦🇺  +61',
    '91': '🇮🇳  +91',
    '971': '🇦🇪  +971',
    'about': 'About',
    'about_vidyasetu': 'About VidyaSetu',
    'active_chat_participation': 'Active chat participation',
    'active_now': 'Active now',
    'active_min_ago': 'Active 1m ago',
    'active_mins_ago': 'Active {}m ago',
    'activity_goal': 'Activity Goal',
    'active_hours_ago': 'Active {}h ago',
    'active_days_ago': 'Active {}d ago',
    'account': 'ACCOUNT',
    'account_restored_successfully': 'Account restored successfully!',
    'account_scheduled_for_deletion': 'Account Scheduled for Deletion',
    'achievements': 'Achievements',
    'achievements_unlocked': 'Achievements Unlocked',
    'achiever': 'Achiever',
    'add_reminder': 'Add Reminder',
    'add_reminder_for_student': 'Add Reminder for Student',
    'add_details_about_this_reminde': 'Add details about this reminder',
    'add_more': 'Add More',
    'after_last_pt__finals': 'After last PT → Finals',
    'aipowered_timetables': 'AI-Powered Timetables',
    'alarm_diagnostics': '🔔 Alarm Diagnostics',
    'alarm_scheduled_kill_the_app_a': 'Alarm scheduled! Kill the app and lock your phone now.',
    'all': 'All',
    'assignments': 'Assignments',
    'assignment': 'Assignment',
    'at_exact_time': 'At exact time',
    'all_time': 'All Time',
    'allow_students_to_send_connection_reques': 'Allow students to send connection requests',
    'already_have_an_account': 'Already have an account? ',
    'an_immediate_test_notification_was_just': 'An immediate test notification was just fired. Check your notification shade!',
    'analytics': 'Analytics',
    'analytics_snapshot': 'Analytics Snapshot',
    'analyzing_your_syllabus': 'Analyzing Your Syllabus',
    'ananya_kumar': 'Ananya Kumar',
    'beginner': 'Beginner',
    'app_theme': 'App Theme',
    'appearance': 'APPEARANCE',
    'are_you_sure_you_want_to_delet': 'Are you sure you want to delete this timetable slot?',
    'are_you_sure_you_want_to_logou': 'Are you sure you want to logout?',
    'are_you_sure_you_want_to_logout': 'Are you sure you want to logout?',
    'are_you_sure_you_want_to_make_these_chan': 'Are you sure you want to make these changes? ',
    'audio_only': 'Audio Only',
    'availability': 'AVAILABILITY',
    'available_for_new_students': 'Available for New Students',
    'back': 'Back',
    'back_to_chat': 'Back to Chat',
    'back_to_timetable': 'Back to Timetable',
    'before_pt1': 'Before PT1',
    'bio': 'Bio',
    'break_duration': 'Break Duration',
    'browse_students': 'Browse Students',
    'by_using_vidyasetu_as_a_mentor_you_agree': 'By using VidyaSetu as a mentor, you agree to:\n\n',
    'by_using_vidyasetu_you_agree_to_our_term': 'By using VidyaSetu, you agree to our Terms...\n\n(This is a placeholder for actual TS)',
    'cache_cleared': 'Cache cleared!',
    'call_in_progress': 'Call in progress',
    'camera_and_microphone_permissi': 'Camera and Microphone permissions are required for video calls',
    'cancel': 'Cancel',
    'change_password': 'Change Password',
    'change_profile_photo': 'Change Profile Photo',
    'check_your_internet_connection': 'Check your internet connection',
    'choose_a_student': 'Choose a student',
    'choose_from_gallery': 'Choose from Gallery',
    'choosenyour_role': 'Choose\nYour Role',
    'champion': 'Champion',
    'class_12__cbse': 'Class 12 • CBSE',
    'clear': 'Clear',
    'clear_cache': 'Clear Cache',
    'close': 'Close',
    'college_timetable': 'College Timetable',
    'color': 'Color',
    'complete_study_sessions_to_see_your_subj': 'Complete study sessions to see your subject distribution.',
    'completed': 'Completed',
    'completion_target': 'Completion Target',
    'confirm': 'Confirm',
    'confirm_password': 'Confirm Password',
    'confirm_your_password': 'Confirm your password',
    'connect': 'Connect',
    'connected': 'Connected',
    'contact_info': 'Contact Info',
    'contact_support': 'Contact Support',
    'complete_study_session': 'Complete study session',
    'connect_with_mentor': 'Connect with mentor',
    'continue': 'Continue',
    'continue_with_google': 'Continue with Google',
    'continue_with_phone': 'Continue with Phone',
    'could_not_load_resources': 'Could not load resources',
    'could_not_open_link': 'Could not open link',
    'course__grade': 'Course / Grade',
    'crafting_your_plan': 'Crafting Your Plan',
    'create': 'Create',
    'create_a_password': 'Create a password',
    'create_account': 'Create Account',
    'create_reminder': 'Create Reminder',
    'createnaccount': 'Create\nAccount',
    'current_password': 'Current Password',
    'daily_study_plan': 'Daily Study Plan',
    'danger_zone': 'Danger Zone',
    'date': 'Date',
    'day': 'Day',
    'default_session_duration': 'Default Session Duration',
    'delete': 'Delete',
    'delete_1': 'Delete ',
    'delete_account': 'Delete Account',
    'delete_forever': 'Delete Forever',
    'delete_reminder': 'Delete Reminder',
    'daily': 'Daily',
    'delete_slot': 'Delete Slot?',
    'description': 'Description',
    'detailed_feedback': 'Detailed Feedback',
    'details': 'Details',
    'dismiss': 'Dismiss',
    'done': 'Done',
    'dont_have_an_account': 'Don\'t have an account? ',
    'due_date': 'Due Date',
    'edit': 'Edit',
    'edit_reminder': 'Edit Reminder',
    'exam': 'Exam',
    'exams': 'Exams',
    'edit_profile': 'Edit Profile',
    'edit_slot': 'Edit Slot',
    'email': 'Email',
    'email_address': 'Email address',
    'english_is_currently_the_only': 'English is currently the only available language',
    'english_is_currently_the_only_available': 'English is currently the only available language',
    'explorer': 'Explorer',
    'expert': 'Expert',
    'enjoy_your_free_time': 'Enjoy your free time! 🎉',
    'enter_otp': 'Enter OTP',
    'enter_phone_number': 'Enter phone number',
    'enter_reminder_title': 'Enter reminder title',
    'enter_your_email': 'Enter your email',
    'enter_your_email_address_and_we': 'Enter your email address and we\'ll send you a recovery link.',
    'enter_your_full_name': 'Enter your full name',
    'enter_your_password': 'Enter your password',
    'error_loading_chats': 'Error loading chats',
    'exact_alarms_allowed': 'Exact Alarms Allowed',
    'exam_schedule': 'Exam Schedule',
    'extracted_text_preview': 'Extracted Text Preview:',
    'failed_to_upload_file': 'Failed to upload file',
    'feedback': 'Feedback',
    'feedback__reminders': 'Feedback & Reminders',
    'feedback_sent_successfully': 'Feedback sent successfully!',
    'finish_a_topic': 'Finish a topic',
    'feedback_type': 'Feedback Type',
    'final': 'Final',
    'final_exam': 'Final Exam',
    'find_a_mentor': 'Find a Mentor',
    'find_students': 'Find Students',
    'find_videos': 'Find Videos',
    'fires_a_test_alarm_in_5_seconds__try_loc': 'Fires a test alarm in 5 seconds — try locking your screen!',
    'forgot_password': 'Forgot Password?',
    'from': 'From',
    'full_name': 'Full Name',
    'generate_new': 'Generate New',
    'generate_timetable': 'Generate Timetable',
    'generate_with_ai': 'Generate with AI',
    'generating_quiz_questions': 'Generating quiz questions...',
    'get_expert_help_anytime': 'Get expert help anytime',
    'go_to_browse_students': 'Go to Browse Students (from Quick Actions) and tap Connect on their profile.',
    'go_to_my_students': 'Go to My Students -> tap a student -> Send Feedback.',
    'go_to_reminders_from_quick': 'Go to Reminders from Quick Actions -> Create Reminder.',
    'goal': 'Goal',
    'good_afternoon': 'Good Afternoon',
    'good_evening': 'Good Evening',
    'good_morning': 'Good Morning',
    'guidance': 'Guidance',
    'help__faq': 'Help & FAQ',
    'holidayweekend': '🎉 Holiday/Weekend',
    'hours': 'Hours',
    'how_do_i_connect_with_a_mentor': 'How do I connect with a mentor?',
    'how_do_i_connect_with_students': 'How do I connect with students?',
    'how_do_i_generate_a_timetable': 'How do I generate a timetable?',
    'how_do_i_provide_feedback': 'How do I provide feedback?',
    'how_do_i_schedule_meetings': 'How do I schedule meetings?',
    'how_do_i_send_reminders': 'How do I send reminders?',
    'how_do_i_take_a_quiz': 'How do I take a quiz?',
    'how_it_works': 'How it works',
    'how_to_earn_xp': 'How to Earn XP',
    'i_agree_to_the': 'I agree to the ',
    'i_am_a': 'I am a',
    'incoming_video_call': 'Incoming video call',
    'individual_progress': 'Individual Progress',
    'institution': 'Institution',
    'leaderboard': 'Leaderboard',
    'learning_milestones': 'Learning Milestones',
    'learner': 'Learner',
    'legend': 'Legend',
    'low': 'Low',
    'legal': 'LEGAL',
    'level': 'Level',
    'level_5__scholar': 'Level 5 — Scholar',
    'level_6': 'Level 6',
    'level_progression': 'Level Progression',
    'loading_resources__quiz': 'Loading resources & quiz...',
    'location_optional': 'Location (Optional)',
    'locked': 'Locked',
    'login': 'Login',
    'logout': 'Logout',
    'mark_as_studied': 'Mark as Studied',
    'mark_complete__take_quiz': 'Mark Complete & Take Quiz',
    'meeting_scheduled': 'Meeting scheduled!',
    'meeting_title': 'Meeting Title',
    'mentor': 'Mentor',
    'mentor_guidance': 'Mentor Guidance',
    'mentor_messages': 'Mentor Messages',
    'mentor_request_sent_successful': 'Mentor request sent successfully!',
    'mentornotifmessages': 'mentor_notif_messages',
    'mentornotifrequests': 'mentor_notif_requests',
    'mentornotifupdates': 'mentor_notif_updates',
    'mentors': 'Mentors',
    'message': 'Message',
    'messages': 'Messages',
    'medium': 'Medium',
    'missed': 'Missed',
    'month': 'Month',
    'monthly': 'Monthly',
    'my_rank': 'My Rank',
    'my_students': 'My Students',
    'my_timetable': 'My Timetable',
    'name': 'Name',
    'master': 'Master',
    'maintain_daily_streak': 'Maintain daily streak',
    'never_miss_deadlines': 'Never miss deadlines',
    'new_password': 'New Password',
    'new_student_requests': 'New Student Requests',
    'next_session': 'Next Session',
    'no_chat_room_selected': 'No chat room selected',
    'no_connected_students_yet_students_can_f': 'No connected students yet. Students can find and connect with you from the Mentors screen.',
    'no_conversations_yet': 'No conversations yet',
    'no_delete_it': 'No, Delete It',
    'no_feedback_yet': 'No feedback yet',
    'no_leaderboard_data_yet': 'No leaderboard data yet',
    'no_login_required__instant_joi': 'No login required • Instant join',
    'no_mentors_found': 'No mentors found',
    'no_messages_yet': 'No messages yet',
    'no_pending_requests': 'No pending requests',
    'no_quiz_available': 'No quiz available',
    'no_reminders_in_this_view': 'No reminders in this view',
    'no_reminders_sent_yet': 'No reminders sent yet',
    'no_reminders_sent_yet_1': 'No reminders sent yet.',
    'no_recent_feedback_from_your_mentors': 'No recent feedback from your mentors.',
    'no_resources_found': 'No resources found',
    'no_session_data': 'No session data',
    'no_sessions_generated': 'No sessions generated',
    'no_sessions_on_this_day': 'No sessions on this day',
    'no_sessions_today': 'No sessions today',
    'no_students_found': 'No students found',
    'no_students_yet': 'No students yet.',
    'no_students_yet_1': 'No students yet',
    'no_study_plan_yet': 'No Study Plan Yet',
    'no_subjects_found': 'No subjects found',
    'no_upcoming_reminders_tap__to_add_one': 'No upcoming reminders. Tap + to add one!',
    'no_upcoming_sessions_found': 'No upcoming sessions found',
    'no_videos_found': 'No videos found',
    'not_logged_in': 'Not logged in',
    'notes': 'Notes',
    'notifications': 'NOTIFICATIONS',
    'notifications_1': 'Notifications',
    'notifications_enabled': 'Notifications Enabled',
    'number_of_periodic_tests_pt': 'Number of Periodic Tests (PT)',
    'ok': 'OK',
    'on_college_days_sessions_are_scheduled_o': 'On college days, sessions are scheduled only in the evening after your last lecture',
    'open_a_chat': 'Open a chat -> tap the menu -> Schedule Meeting.',
    'or': 'OR',
    'overall_rating': 'Overall Rating',
    'password': 'Password',
    'password_reset_email_sent': 'Password reset email sent!',
    'password_updated': 'Password updated!',
    'pending': 'Pending',
    'pending_requests': 'Pending Requests',
    'pending_requests_1': 'Pending\nRequests',
    'percentage': 'Percentage',
    'phone': 'Phone',
    'phone_number': 'Phone Number',
    'phonenverification': 'Phone\nVerification',
    'pick_an_existing_photo': 'Pick an existing photo',
    'plan_ready': 'Plan Ready!',
    'plan_summary': 'Plan Summary',
    'please_accept_the_terms__condi': 'Please accept the Terms & Conditions',
    'please_enter_a_title': 'Please enter a title',
    'please_enter_a_valid_phone_num': 'Please enter a valid phone number',
    'please_enter_the_complete_otp': 'Please enter the complete OTP',
    'please_log_in': 'Please log in.',
    'please_log_in_to_view_messages': 'Please log in to view messages',
    'please_provide_title_and_messa': 'Please provide title and message',
    'please_select_a_student': 'Please select a student',
    'please_select_a_student_and_pr': 'Please select a student and provide a title',
    'please_upload_at_least_one_pdf': 'Please upload at least one PDF syllabus',
    'point_system': 'Point System',
    'points': 'Points',
    'popup_notification': 'Popup Notification',
    'powered_by_jitsi_meet': 'Powered by Jitsi Meet',
    'prefbreakduration': 'pref_break_duration',
    'prefmentormsgs': 'pref_mentor_msgs',
    'prefremindernotif': 'pref_reminder_notif',
    'prefringtone': 'pref_ringtone',
    'prefsessionduration': 'pref_session_duration',
    'prefsystemnotif': 'pref_system_notif',
    'prefvoicenotif': 'pref_voice_notif',
    'priority': 'Priority',
    'privacy_policy': 'Privacy Policy',
    'privacy_settings': 'Privacy Settings',
    'profile_updated_successfully': '✅ Profile updated successfully!',
    'pt1__pt2': 'PT1 → PT2',
    'pt2__pt3': 'PT2 → PT3',
    'quick_actions': 'Quick Actions',
    'scholar': 'Scholar',
    'score_80_plus_on_quiz': 'Score 80%+ on quiz',
    'quiz': 'Quiz',
    'quizzes': 'Quizzes',
    'quiz_completed_great_job': 'Quiz completed! Great job! 🎉',
    'rating': 'Rating',
    'recent_reviews': 'Recent Reviews',
    'recent_mentor_feedback': 'Recent Mentor Feedback',
    'rejoin_call': 'Rejoin Call',
    'remember_me': 'Remember me',
    'remind_before': 'Remind Before',
    'reminder_sent_successfully': 'Reminder sent successfully!',
    'reminders': 'Reminders',
    'remove': 'Remove',
    'remove_photo': 'Remove Photo',
    'repeat': 'Repeat',
    'request_pending': 'Request Pending',
    'request_sent': 'Request Sent',
    'reschedule': 'Reschedule',
    'resend_otp': 'Resend OTP',
    'reset_password': 'Reset Password',
    'restore_account': 'Restore Account',
    'retry': 'Retry',
    'retry_with_new_questions': 'Retry with New Questions',
    'review_answers': 'REVIEW ANSWERS',
    'review_before_generating': 'Review before generating',
    'review_notes__study_materials': 'Review Notes & Study Materials',
    'save': 'Save',
    'saving': 'Saving...',
    'save_reminder': 'Save Reminder',
    'save_changes': 'Save Changes',
    'say_hello': 'Say hello! 👋',
    'schedule': 'Schedule',
    'schedule_meeting': 'Schedule Meeting',
    'score': 'Score',
    'search_by_name_course_or_insti': 'Search by name, course or institution...',
    'search_by_name_or_subject': 'Search by name or subject...',
    'see_all': 'See All',
    'select_all': 'Select All',
    'select_at_least_one_subject': 'Select at least one subject',
    'select_how_you_want_to_use_vidyasetu': 'Select how you want to use VidyaSetu',
    'select_multiple_files_if_needed': 'Select multiple files if needed',
    'select_student': 'Select Student',
    'select_subjects': 'Select Subjects',
    'send_feedback': 'Send Feedback',
    'send_link': 'Send Link',
    'send_otp': 'Send OTP',
    'send_reminder': 'Send Reminder',
    'send_request': 'Send Request',
    'service_initialized': 'Service Initialized',
    'session': 'Session',
    'session_details': 'Session Details',
    'sessions': 'Sessions',
    'set_your_periodic_test_and_final_exam_da': 'Set your periodic test and final exam dates. Syllabus will be divided accordingly.',
    'settings': 'Settings',
    'share_progress_with_mentor': 'Share progress with Mentor',
    'show_activity_status': 'Show Activity Status',
    'sign_in_to_continue_your_learning_journe': 'Sign in to continue your learning journey',
    'sign_up': 'Sign Up',
    'skip': 'Skip',
    'slot_deleted': 'Slot Deleted',
    'slot_saved_successfully': 'Slot Saved Successfully',
    'smart_learning_companion': 'SMART LEARNING COMPANION',
    'smart_reminders': 'Smart Reminders',
    'smart_timetable': 'Smart Timetable',
    'smart_timetable_created_notifi': '🎉 Smart Timetable Created! Notifications scheduled.',
    'snooze': 'Snooze',
    'snoozed_for_5_minutes': '⏰ Snoozed for 5 minutes',
    'some_permissions_are_missing': '⚠️ Some permissions are missing!\n\n',
    'start_studying_to_earn_points': 'Start studying to earn points!',
    'start_your_learning_journey_today': 'Start your learning journey today',
    'status': 'Status',
    'streak': 'Streak',
    'student': 'Student',
    'student_activity': 'Student Activity',
    'student_analytics': 'Student Analytics',
    'student_progress_updates': 'Student Progress Updates',
    'student_reminders': 'Student Reminders',
    'students': 'Students',
    'students_can_send_you_connection_request': 'Students can send you connection requests from the Find Mentor screen.',
    'study_hours': 'Study Hours',
    'study_hours_by_topic': 'Study Hours by Topic',
    'study_notes': 'STUDY NOTES',
    'study_only_after_college': 'Study only after college',
    'study_preferences': 'Study Preferences',
    'study_preferences_updated': 'Study preferences updated.',
    'study_reminders': 'Study Reminders',
    'study_resources': '📚 Study Resources',
    'study_session': 'Study Session',
    'study': 'Study',
    'study_smarter_not_harder': 'Study smarter, not harder',
    'streak_records': 'Streak Records',
    'study_streak': 'Study Streak',
    'study_time': 'Study Time',
    'subject': 'Subject',
    'subject_analytics': 'Subject Analytics',
    'subject_distribution': 'Subject Distribution',
    'subject_name': 'Subject Name',
    'submit_answer': 'Submit Answer',
    'suggested_conversations': 'SUGGESTED CONVERSATIONS',
    'support': 'SUPPORT',
    'switch_to_the_call_window_to_c': 'Switch to the call window to continue',
    'system_notifications': 'System Notifications',
    'system_preferences': 'System Preferences',
    'take_a_break_or_review_previous_topics': 'Take a break or review previous topics!',
    'take_photo': 'Take Photo',
    'tap__to_create_a_reminder_for': 'Tap + to create a reminder for a student',
    'tap__to_send_feedback_to_a_stu': 'Tap + to send feedback to a student',
    'tap_for_info': 'Tap for info',
    'tap_for_resources__quiz': 'Tap for resources & quiz',
    'tap_generate_with_to_create_notes': 'Tap \'Generate with AI\' to create notes',
    'tap_the__button_to_add_a_reminder': 'Tap the + button to add a reminder.',
    'tap_time_slots_where_you_have_college_le': 'Tap time slots where you have college lectures',
    'tap_to_change_photo': 'Tap to change photo',
    'tap_to_find_videos': 'Tap to find relevant YouTube videos',
    'tap_to_return_to_today': 'Tap to return to today',
    'tap_to_upload_pdfs': 'Tap to Upload PDF(s)',
    'task_completion': 'Task Completion',
    'tasks_done': 'Tasks Done',
    'tell_us_about_your_schedule_so_we_plan_a': 'Tell us about your schedule so we plan around it',
    'terms__conditions': 'Terms & Conditions',
    'terms_of_service': 'Terms of Service',
    'test_alarm_15s': 'Test Alarm (15s)',
    'test_notification_alarm': 'Test Notification Alarm',
    'test_your_knowledge': '🧠 Test Your Knowledge',
    'this_action_is_irreversible_all_your_dat': 'This action is irreversible. All your data including students, feedback, and messages will be permanently deleted.',
    'this_preview_shows_the_raw_text_that_wil': 'This preview shows the raw text that will be used for AI analysis.',
    'this_will_clear_locally_cached': 'This will clear locally cached images and data. Your account data will not be affected.',
    'time': 'Time',
    'timetable_created_save_pending': 'Timetable created (save pending)',
    'title': 'Title',
    'to': 'To',
    'total_earned': 'Total Earned',
    'todays_progress': 'Today\'s Progress',
    'todays_study_plan': 'Today\'s Study Plan',
    'top_subject': 'Top Subject',
    'topic__chapter': 'Topic / Chapter',
    'topic_breakdown': 'Topic Breakdown',
    'topics_to_be_covered': 'Topics to be covered',
    'try_a_different_search_term': 'Try a different search term',
    'try_adjusting_your_constraints': 'Try adjusting your constraints',
    'try_uploading_a_different_pdf': 'Try uploading a different PDF',
    'type': 'Type',
    'type_a_message': 'Type a message...',
    'unavailable_college_days': 'Unavailable (college days)',
    'unavailable_holidaysweekends': 'Unavailable (holidays/weekends)',
    'unlocked': 'Unlocked',
    'upcoming_holidays': 'Upcoming Holidays',
    'upcoming_reminders': 'Upcoming Reminders',
    'update': 'Update',
    'update_reminder': 'Update Reminder',
    'update_study_plan': 'Update Study Plan?',
    'upload_one_or_more_university_syllabus_p': 'Upload one or more university syllabus PDFs',
    'upload_syllabus': 'Upload Syllabus',
    'upload_your_syllabus_pdf_and_generate_a': 'Upload your syllabus PDF and generate a smart study timetable.',
    'upload_your_syllabus_pdf_to_generate_a_p': 'Upload your syllabus PDF to generate a personalized study timetable.',
    'uploading_image': 'Uploading image...',
    'use_your_camera': 'Use your camera',
    'verification': 'Verification',
    'verification_status': 'Verification Status',
    'verified_mentor': 'Verified Mentor',
    'verify__sign_in': 'Verify & Sign In',
    'video_call': 'Video Call',
    'video_resources': 'VIDEO RESOURCES',
    'vidyasetu': 'VidyaSetu',
    'vidyasetu_respects_your_privacy': 'VidyaSetu respects your privacy.\n\n',
    'view': 'View',
    'view_all': 'View All',
    'view_pdf': 'View PDF',
    'voice_alerts_beta': 'Voice Alerts (Beta)',
    'voice_notification': 'Voice Notification',
    'wants_to_connect': 'Wants to connect',
    'we_ll_send_you_an_otp_to_verify_': 'We\'ll send you an OTP to verify your phone number',
    'we_sent_a_6digit_code_to': 'We sent a 6-digit code to ',
    'weekly': 'Weekly',
    'week': 'Week',
    'weekly_progress': 'Weekly Progress',
    'welcomenback': 'Welcome\nBack',
    'what_does_streak_mean': 'What does Streak mean?',
    'xp': 'XP',
    'you': 'You',
    'you_1': 'YOU',
    'your_account_was_previously_marked_for_d': 'Your account was previously marked for deletion. ',
    'your_account_will_be_scheduled_for_delet': 'Your account will be scheduled for deletion. ',
    'your_daily_routine': 'Your Daily Routine',
    'your_mentor_account_is_verifiednnverifie': 'Your mentor account is verified.\n\nVerified mentors appear with a badge and are prioritized in student searches.',
    'your_points': 'Your Points',
    'youtube_videos': '🎬 YouTube Videos',
    'how_do_i_generate_a_timetable_ans': 'Go to Timetable (Dashboard/Nav bar) -> Tap "+" in the timeline.',
    'how_do_i_connect_with_a_mentor_ans': 'Go to Mentors tab -> Find Mentor -> Send Request.',
    'how_do_i_take_a_quiz_ans': 'Click on a study session in your timetable -> Start Quiz.',
    'what_does_streak_mean_ans': 'It is the number of consecutive days you have completed at least one study session.',
    'how_do_i_connect_with_students_ans': 'Go to Browse Students (from Quick Actions) and tap Connect on their profile.',
    'how_do_i_schedule_meetings_ans': 'Open a chat -> tap the ⋮ menu -> Schedule Meeting.',
    'how_do_i_provide_feedback_ans': 'Go to My Students -> tap a student -> Send Feedback.',
    'how_do_i_send_reminders_ans': 'Go to Reminders from Quick Actions -> Create Reminder.',
    'extracting_text_from_pdf': 'Extracting text from PDF...',
    'fetching_holidays': 'Fetching holidays...',
    'generating_timetable': 'Generating timetable...',
    'generating_notes': 'Generating notes...',
    'analyzing_syllabus': 'Analyzing your syllabus...',
    'preparing_study_plan': 'Preparing your study plan...',
    'tap_to_find_videos_hint': 'Tap to find relevant YouTube videos',
    'quick_learner': 'Quick Learner',
    'consistency_king': 'Consistency King',
    'quiz_master': 'Quiz Master',
    'night_owl': 'Night Owl',
    'early_bird': 'Early Bird',
    'uploaded_files': 'Uploaded Files',
    'checking_calendar': 'Checking calendar',
    'scheduling_sessions': 'Scheduling sessions',
    'balancing_subjects': 'Balancing subjects',
    'finishing_up': 'Finishing up',
    'plan_adapts_to_college': 'Your plan adapts to your college schedule',
    'subjects_rotated_daily': 'Subjects are rotated daily for variety',
    'holidays_study_time': 'Holidays get 1.5× more study time',
    'session_includes_quiz': 'Each session includes quiz & resources',
    'equal_coverage_subject': 'Equal coverage ensures no subject falls behind',
    'building_exam_schedule': 'Building exam schedule...',
    'build': 'Build',
    'version': 'Version',
    'help_center': 'Help Center',
    'for': 'For',
    'using_dark_theme': 'Currently using dark theme',
    'using_light_theme': 'Currently using light theme',
    'h': 'h',
    'studied': 'studied',
    'complete': 'complete',
    'streak_master': 'Streak Master',
    'rising_star': 'Rising Star',
    'bookworm': 'Bookworm',
    'critical_actions': 'Critical Actions',
    'cancel_download_title': 'Cancel Download?',
    'cancel_download_msg': 'Switching languages requires downloading a small pack. Stopping now will keep your current language.',
    'continue_download': 'Continue Download',
    'cancel_download': 'Cancel Download',
    'today': 'Today',
    'yesterday': 'Yesterday',
    'todays_tasks': "Today's Tasks",
    'language_updated': 'Language updated:',
    'ringtone_set': 'Ringtone set:',
    'alarm_ringtone': 'Alarm Ringtone',

    'question_of': 'Question',
    'of': 'of',
    'your_answer': 'Your answer',
    'correct_answer': 'Correct',
    'take_quiz': 'Take Quiz',
    'questions': 'questions',
    'size': 'Size',
    'error_extracting_text': 'Error extracting text',
    'error': 'Error',
    'request_sent_to': 'Request sent to',
    'error_sending_reminder': 'Error sending reminder',
    'error_sending_feedback': 'Error sending feedback',
    'to_label': 'To',
    'rescheduled_to': 'Rescheduled to',
    'welcome_back': 'Welcome back',
    'error_generating_quiz': 'Error generating quiz',
    'error_generating_notes': 'Error generating notes',
    'could_not_open_link_error': 'Could not open link',
    'could_not_pick_image': 'Could not pick image',
    'alarm_error': 'Alarm error',
    'error_please_reauth': 'Error. Please re-authenticate first.',
    'focus_mode': 'Focus Mode',
    'high': 'High',
    'one_time': 'One-time',
    '5_min': '5 min',
    '15_min': '15 min',
    '30_min': '30 min',
    '1_hour': '1 hour',
    '1_day': '1 day',
    '7_day_streak_bonus': '7-day streak bonus',
    'guru': 'Guru',
    
    // Achievements
    'first_steps': 'First Steps',
    'earn_50_xp': 'Earn 50 XP',
    'week_warrior': 'Week Warrior',
    '7_day_streak': '7-day streak',
    'monthly_master': 'Monthly Master',
    '30_day_streak': '30-day streak',
    'bookworm_desc': 'Studied for 10 hours',
    'dedicated_learner': 'Dedicated Learner',
    '50_hours_study': 'Studied for 50 hours',
    'time_master': 'Time Master',
    '100_hours_study': 'Studied for 100 hours',
    'task_master': 'Task Master',
    'complete_5_tasks': 'Complete 5 tasks',
    'productivity_pro': 'Productivity Pro',
    'complete_25_tasks': 'Complete 25 tasks',
    'unstoppable': 'Unstoppable',
    'complete_100_tasks': 'Complete 100 tasks',
  };
}
// Global build context extension for easy translation: context.tr('key')
extension LocalizationExtension on BuildContext {
  String tr(String key) {
    // We don't listen here to avoid massive rebuilds if not needed,
    // or we CAN listen via Provider.of<LocalizationService>(this).
    final service = Provider.of<LocalizationService>(this, listen: true);
    return service.translate(key);
  }
}
