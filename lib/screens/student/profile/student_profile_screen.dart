import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/notification_service.dart';
import '../../../services/auth_service.dart';
import 'package:vidyasetu/services/localization_service.dart';
import 'package:vidyasetu/services/gamification_logic.dart';
import 'package:vidyasetu/widgets/common/app_card.dart';
import '../../../widgets/common/animated_theme_toggle.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;
import 'package:intl/intl.dart';
import '../../../services/firestore_service.dart';
import '../../../models/timetable_model.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _firestore = FirestoreService();
  // Notification prefs
  bool _reminderNotifications = true;
  bool _voiceNotifications = false;
  bool _mentorMessages = true;
  bool _systemNotifications = true;

  // Study prefs
  double _defaultSessionDuration = 45;
  double _breakDuration = 10;
  bool _breakReminders = true;

  // Base prefs
  String _selectedRingtone = 'nokia_classic';
  String _selectedLanguage = 'en';

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, String> _ringtoneFiles = {
    'nokia_classic': 'freesound_community-nokia-ringtone-with-vibration-100491.mp3',
    'classic_phone': 'soynoviembre-classic-phone-ringtone-439034.mp3',
    'gentle_chime': 'universfield-ringtone-023-376906.mp3',
    'morning_bell': 'universfield-ringtone-029-437512.mp3',
    'soft_melody': 'universfield-ringtone-030-437513.mp3',
    'bright_tone': 'universfield-ringtone-031-437514.mp3',
    'crystal_alert': 'universfield-ringtone-055-494939.mp3',
    'rising_pulse': 'universfield-ringtone-087-496415.mp3',
    'echo_ring': 'universfield-ringtone-088-496414.mp3',
  };

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _syncStats();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _syncStats() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid != null) {
      await FirestoreService().ensureUserInitialized(uid);
      // Trigger a local refresh if needed
      if (mounted) {
        Provider.of<AuthProvider>(context, listen: false).refreshUser();
      }
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _reminderNotifications = prefs.getBool('pref_reminder_notif') ?? true;
        _voiceNotifications = prefs.getBool('pref_voice_notif') ?? false;
        _mentorMessages = prefs.getBool('pref_mentor_msgs') ?? true;
        _systemNotifications = prefs.getBool('pref_system_notif') ?? true;
        _defaultSessionDuration = prefs.getDouble('pref_session_duration') ?? 45;
        _breakDuration = prefs.getDouble('pref_break_duration') ?? 10;
        _breakReminders = prefs.getBool('pref_break_reminders') ?? true;
        _selectedRingtone = prefs.getString('pref_ringtone') ?? 'nokia_classic';
        _selectedLanguage = prefs.getString('pref_language') ?? 'en';
        _loaded = true;
      });
    }
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  void _updateNotifPref(String key, bool value) {
    setState(() {
      if (key == 'pref_reminder_notif') _reminderNotifications = value;
      if (key == 'pref_voice_notif') _voiceNotifications = value;
      if (key == 'pref_mentor_msgs') _mentorMessages = value;
      if (key == 'pref_system_notif') _systemNotifications = value;
    });
    _savePref(key, value);
    if (key == 'pref_reminder_notif' && !value) {
      NotificationService().cancelAll();
    }
  }

  Future<void> _playRingtonePreview(String ringtoneKey) async {
    try {
      final fileName = _ringtoneFiles[ringtoneKey];
      if (fileName != null) {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource('ringtone/$fileName'));
      }
    } catch (e) {
      debugPrint('Error playing ringtone preview: $e');
    }
  }

  void _confirmStudyPrefChange(String prefKey, double newValue) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('update_study_plan')),
        content: Text(
          context.tr('are_you_sure_you_want_to_make_these_chan') +
          ' Your future generated study timetables will automatically adjust to this new duration.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _loadPreferences(); // Revert visual slider if canceled
            },
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              _savePref(prefKey, newValue);
              
              try {
                final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
                if (uid != null) {
                  final firestore = FirestoreService();
                  final currentPlan = await firestore.getStudyPlan(uid);
                  
                  if (currentPlan != null) {
                    final updatedSessions = currentPlan.sessions.map((s) {
                      if (s.startTime.isAfter(DateTime.now())) {
                        return TimetableSession(
                          id: s.id,
                          subject: s.subject,
                          topic: s.topic,
                          moduleName: s.moduleName,
                          date: s.date,
                          startTime: s.startTime,
                          durationMinutes: _defaultSessionDuration.toInt(),
                          colorHex: s.colorHex,
                          isCompleted: s.isCompleted,
                          location: s.location,
                          notes: s.notes,
                          isHolidaySession: s.isHolidaySession,
                          resourceLinks: s.resourceLinks,
                          youtubeLinks: s.youtubeLinks,
                          quizCompleted: s.quizCompleted,
                        );
                      }
                      return s;
                    }).toList();

                    final updatedPlan = StudyPlan(
                      id: currentPlan.id,
                      sessions: updatedSessions,
                      subjects: currentPlan.subjects,
                      constraints: currentPlan.constraints,
                      collegeSlots: currentPlan.collegeSlots,
                      createdAt: currentPlan.createdAt,
                      startDate: currentPlan.startDate,
                      endDate: currentPlan.endDate,
                      weeklyAvailableHours: currentPlan.weeklyAvailableHours,
                    );
                    
                    await firestore.saveStudyPlan(uid, updatedPlan);
                  }
                }
              } catch (e) {
                debugPrint('Failed to recalculate slots: $e');
              }
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr('study_preferences_updated'))),
                );
              }
            },
            child: Text(context.tr('confirm')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = Provider.of<AuthProvider>(context).userModel;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final isTranslating = Provider.of<LocalizationService>(context).isTranslating;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
                pinned: true,
                elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 52, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: user?.profileImageUrl != null
                            ? ClipOval(child: Image.network(user!.profileImageUrl!, fit: BoxFit.cover))
                            : Center(
                                child: Text(
                                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'S',
                                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 28, fontWeight: FontWeight.w700),
                                ),
                              ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'Student',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.onSurface),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.editStudentProfile),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats ──
                  // Stats
                  // Stats
                  Row(
                    children: [
                      _buildStatItem(context.tr('level'), '${user?.level ?? 1}', Icons.workspace_premium_rounded, AppTheme.warningAmber),
                      const SizedBox(width: 12),
                      _buildStatItem(context.tr('points'), '${user?.points ?? 0}', Icons.bolt_rounded, AppTheme.accentPurple),
                      const SizedBox(width: 12),
                      _buildStatItem(context.tr('streak'), '${user?.streak ?? 0}', Icons.local_fire_department_rounded, AppTheme.errorRed),
                    ],
                  ),
                  SizedBox(height: 28),

                  // ── Bio ──
                  if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                    _sectionTitle(context.tr('about_me')),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        user.bio!,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14, height: 1.5),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // ── Achievements ──
                  _sectionTitle(context.tr('achievements') ?? 'Achievements'),
                  _buildAchievementsSection(user),
                  SizedBox(height: 28),

                  // ── Recent Mentor Feedback ──
                  _sectionTitle(context.tr('recent_mentor_feedback')),
                  StreamBuilder<cloud_firestore.QuerySnapshot>(
                    stream: FirestoreService().getFeedbackStream(user?.uid ?? ''),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      final docs = (snapshot.data?.docs ?? [])
                          .where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final type = data['type'] as String? ?? '';
                            final title = data['title'] as String? ?? '';
                            
                            // Exclude all technical signaling types
                            if (type == 'mentor_reminder' || 
                                type.startsWith('reminder_') || 
                                type == 'acknowledgement' ||
                                type == 'connection_request') {
                              return false;
                            }
                            
                            // Also double check title as a fallback
                            if (title.startsWith('Reminder ')) {
                              return false;
                            }

                            return true;
                          })
                          .toList();
                      if (docs.isEmpty) {
                        return AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                               context.tr('no_recent_feedback_from_your_mentors'),
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: docs.take(3).map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final title = data['title'] ?? data['content'] ?? 'Feedback';
                          final message = data['message'] ?? '';
                          final isPositive = data['isPositive'] ?? true;
                          final rawMentorName = data['mentorName'];
                          final mentorId = data['mentorId'] ?? '';
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _showFeedbackDetailsDialog(data, doc.id),
                              borderRadius: BorderRadius.circular(16),
                              child: AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        color: isPositive ? AppTheme.successGreen.withOpacity(0.2) : AppTheme.warningAmber.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isPositive ? Icons.thumb_up_rounded : Icons.lightbulb_outline_rounded,
                                        color: isPositive ? AppTheme.successGreen : AppTheme.warningAmber,
                                        size: 18,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              FutureBuilder<Map<String, dynamic>?>(
                                                future: rawMentorName != null ? null : _firestore.getUser(mentorId),
                                                builder: (context, nameSnapshot) {
                                                  final mentorDisplayName = rawMentorName ?? nameSnapshot.data?['name'] ?? 'Your Mentor';
                                                  return Text(mentorDisplayName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700));
                                                },
                                              ),
                                              if (data['acknowledged'] == true)
                                                Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 16),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            message,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  SizedBox(height: 28),

                  // ── Account ──
                  _sectionTitle(context.tr('account')),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildNavItem(Icons.lock_rounded, context.tr('change_password'), _showChangePasswordDialog),
                        Divider(height: 1),
                        _buildNavItem(Icons.shield_rounded, context.tr('privacy_settings'), _showPrivacySettingsDialog),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // ── System Preferences (App Base) ──
                  _sectionTitle(context.tr('system_preferences')),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              AnimatedSwitcher(
                                duration: Duration(milliseconds: 350),
                                transitionBuilder: (child, anim) => RotationTransition(turns: Tween(begin: 0.75, end: 1.0).animate(anim), child: FadeTransition(opacity: anim, child: child)),
                                child: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, key: ValueKey(isDark), color: isDark ? AppTheme.warningAmber : AppTheme.accentBlue, size: 24),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(context.tr('app_theme'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
                                    Text(isDark ? context.tr('using_dark_theme') : context.tr('using_light_theme'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                                  ],
                                ),
                              ),
                              AnimatedThemeToggle(
                                isDark: isDark,
                                onChanged: (v) => themeProvider.toggleTheme(),
                              ),
                            ],
                          ),
                        ),
                        Divider(height:1),
                        ListTile(
                          leading: Icon(Icons.language_rounded, color: AppTheme.accentBlue),
                          title: Text(context.tr('language'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                          trailing: DropdownButton<String>(
                            value: _selectedLanguage,
                            alignment: AlignmentDirectional.centerEnd,
                            isDense: true,
                            menuMaxHeight: 300,
                            borderRadius: BorderRadius.circular(12),
                            underline: const SizedBox(),
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            items: const [
                              DropdownMenuItem(value: 'en', child: Text('English')),
                              DropdownMenuItem(value: 'hi', child: Text('Hindi (हिन्दी)')),
                              DropdownMenuItem(value: 'bn', child: Text('Bengali (বাংলা)')),
                              DropdownMenuItem(value: 'mr', child: Text('Marathi (मराठी)')),
                              DropdownMenuItem(value: 'te', child: Text('Telugu (తెలుగు)')),
                              DropdownMenuItem(value: 'ta', child: Text('Tamil (தமிழ்)')),
                              DropdownMenuItem(value: 'gu', child: Text('Gujarati (ગુજરાતી)')),
                              DropdownMenuItem(value: 'kn', child: Text('Kannada (ಕನ್ನಡ)')),
                              DropdownMenuItem(value: 'ur', child: Text('Urdu (اردو)')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedLanguage = val);
                                Provider.of<LocalizationService>(context, listen: false).setLocale(val);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.tr('language_updated')} $val')));
                              }
                            },
                          ),
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.music_note_rounded, color: AppTheme.accentPurple),
                          title: Text(context.tr('alarm_ringtone'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                          trailing: DropdownButton<String>(
                            value: _selectedRingtone,
                            alignment: AlignmentDirectional.centerEnd,
                            isDense: true,
                            menuMaxHeight: 300,
                            borderRadius: BorderRadius.circular(12),
                            underline: const SizedBox(),
                            dropdownColor: Theme.of(context).colorScheme.surface,
                            items: const [
                              DropdownMenuItem(value: 'nokia_classic', child: Text('Nokia Classic')),
                              DropdownMenuItem(value: 'classic_phone', child: Text('Classic Phone')),
                              DropdownMenuItem(value: 'gentle_chime', child: Text('Gentle Chime')),
                              DropdownMenuItem(value: 'morning_bell', child: Text('Morning Bell')),
                              DropdownMenuItem(value: 'soft_melody', child: Text('Soft Melody')),
                              DropdownMenuItem(value: 'bright_tone', child: Text('Bright Tone')),
                              DropdownMenuItem(value: 'crystal_alert', child: Text('Crystal Alert')),
                              DropdownMenuItem(value: 'rising_pulse', child: Text('Rising Pulse')),
                              DropdownMenuItem(value: 'echo_ring', child: Text('Echo Ring')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedRingtone = val);
                                _savePref('pref_ringtone', val);
                                _playRingtonePreview(val);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${context.tr('ringtone_set')} ${val.replaceAll('_', ' ').toUpperCase()}'),
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'STOP',
                                      textColor: Colors.white,
                                      onPressed: () => _audioPlayer.stop(),
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // ── Study Preferences ──
                  _sectionTitle(context.tr('study_preferences')),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(context.tr('default_session_duration'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
                            Text('${_defaultSessionDuration.toInt()} min', style: TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Slider(
                          value: _defaultSessionDuration,
                          min: 15, max: 120, divisions: 7,
                          activeColor: AppTheme.accentPurple,
                          onChanged: (v) {
                            setState(() => _defaultSessionDuration = v);
                          },
                          onChangeEnd: (v) => _confirmStudyPrefChange(context.tr('prefsessionduration'), v),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(context.tr('break_duration'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
                            Text('${_breakDuration.toInt()} min', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Slider(
                          value: _breakDuration,
                          min: 5, max: 30, divisions: 5,
                          activeColor: AppTheme.accentBlue,
                          onChanged: (v) {
                            setState(() => _breakDuration = v);
                          },
                          onChangeEnd: (v) => _confirmStudyPrefChange(context.tr('prefbreakduration'), v),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // ── Notifications ──
                  _sectionTitle(context.tr('notifications')),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        _buildSwitchItem(context.tr('study_reminders'), _reminderNotifications, (v) => _updateNotifPref(context.tr('prefremindernotif'), v)),
                        _buildSwitchItem(context.tr('voice_alerts_beta'), _voiceNotifications, (v) => _updateNotifPref(context.tr('prefvoicenotif'), v)),
                        _buildSwitchItem(context.tr('mentor_messages'), _mentorMessages, (v) => _updateNotifPref(context.tr('prefmentormsgs'), v)),
                        _buildSwitchItem(context.tr('system_notifications'), _systemNotifications, (v) => _updateNotifPref(context.tr('prefsystemnotif'), v)),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // ── Support ──
                  _sectionTitle(context.tr('support')),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildNavItem(Icons.help_outline_rounded, context.tr('help__faq'), _showHelpDialog),
                        Divider(height: 1),
                        _buildNavItem(Icons.headset_mic_rounded, context.tr('contact_support'), _showContactSupportDialog),
                        Divider(height: 1),
                        _buildNavItem(Icons.policy_rounded, context.tr('terms_of_service'), _showTermsDialog),
                        Divider(height: 1),
                        _buildNavItem(Icons.info_outline_rounded, context.tr('about_vidyasetu'), _showAboutAppDialog),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // ── Critical Actions ──
                  _sectionTitle(context.tr('account_actions')),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 20)),
                          title: Text(context.tr('logout'), style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
                          onTap: _showLogoutDialog,
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.delete_forever_rounded, color: AppTheme.errorRed, size: 20)),
                          title: Text(context.tr('delete_account'), style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
                          onTap: _showDeleteAccountDialog,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                top: -10,
                child: Icon(icon, size: 80, color: color.withOpacity(0.10)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      //child: Icon(icon, color: color, size: 20),
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(String emoji, String label, bool unlocked) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: unlocked ? AppTheme.warningAmber.withOpacity(0.1) : AppTheme.divider, shape: BoxShape.circle),
            child: Center(child: Text(emoji, style: TextStyle(fontSize: 22, color: unlocked ? null : Colors.grey))),
          ),
          const SizedBox(height: 6),
          Text(
            label, textAlign: TextAlign.center,
            style: TextStyle(color: unlocked ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    // Convert to Title Case with spaces handled properly
    final cleanTitle = title.replaceAll('_', ' ');
    final titleCase = cleanTitle.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}' : '').join(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        titleCase,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 22),
      title: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
      trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 22),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _buildSwitchItem(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
      value: value,
      activeColor: AppTheme.accentBlue,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  void _showFeedbackDetailsDialog(Map<String, dynamic> data, String docId) {
    final rawMentorName = data['mentorName'];
    final mentorId = data['mentorId'] ?? '';
    final title = data['title'] ?? data['content'] ?? 'Feedback';
    final message = data['message'] ?? '';
    final isPositive = data['isPositive'] ?? true;
    final isAcknowledged = data['acknowledged'] ?? false;
    final createdAt = (data['createdAt'] as cloud_firestore.Timestamp?)?.toDate() ?? DateTime.now();
    final studentName = Provider.of<AuthProvider>(context, listen: false).userModel?.name ?? 'Student';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isProcessing = false;
          bool success = false;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.only(left: 20, right: 8, top: 12),
            title: Row(
              children: [
                Icon(
                  isPositive ? Icons.school_rounded : Icons.record_voice_over_rounded,
                  color: isPositive ? AppTheme.accentBlue : AppTheme.warningAmber,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: rawMentorName != null ? null : _firestore.getUser(mentorId),
                    builder: (context, nameSnapshot) {
                      final mentorDisplayName = rawMentorName ?? nameSnapshot.data?['name'] ?? 'Your Mentor';
                      return Text(mentorDisplayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(fontSize: 15, height: 1.5, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85)),
                ),
                if (isAcknowledged) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.successGreen.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('acknowledged'),
                            style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 30),
                  StatefulBuilder(
                    builder: (context, innerSetState) {
                      return Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isProcessing ? null : () async {
                              innerSetState(() => isProcessing = true);
                              try {
                                await FirestoreService().acknowledgeFeedback(docId, mentorId, studentName);
                                innerSetState(() {
                                  isProcessing = false;
                                  success = true;
                                });
                                await Future.delayed(const Duration(milliseconds: 600));
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(context.tr('feedback_acknowledged_notified')), backgroundColor: AppTheme.successGreen),
                                  );
                                }
                              } catch (e) {
                                debugPrint('Acknowledgement error: $e');
                                innerSetState(() => isProcessing = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: success ? AppTheme.successGreen : AppTheme.accentBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            child: isProcessing 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  success ? context.tr('acknowledged') : context.tr('acknowledge'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                          ),
                        ),
                      );
                    }
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Dialogs ──
  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('change_password'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentPassCtrl, obscureText: true, decoration: InputDecoration(labelText: context.tr('current_password'), filled: true, fillColor: Theme.of(context).colorScheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            SizedBox(height: 12),
            TextField(controller: newPassCtrl, obscureText: true, decoration: InputDecoration(labelText: context.tr('new_password'), filled: true, fillColor: Theme.of(context).colorScheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && user.email != null) {
                  final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassCtrl.text);
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPassCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('password_updated')), backgroundColor: AppTheme.successGreen));
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.tr('error')}: $e'), backgroundColor: AppTheme.errorRed));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: Text(context.tr('update')),
          ),
        ],
      ),
    );
  }

  bool _shareProgress = true;
  bool _showActivityStatus = true;

  void _showPrivacySettingsDialog() {
    // Load current values
    SharedPreferences.getInstance().then((prefs) {
      _shareProgress = prefs.getBool('pref_share_progress') ?? true;
      _showActivityStatus = prefs.getBool('pref_activity_status') ?? true;

      showDialog(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(context.tr('privacy_settings')),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              SwitchListTile(
                title: Text(context.tr('share_progress_with_mentor')),
                value: _shareProgress,
                activeColor: AppTheme.accentBlue,
                onChanged: (v) async {
                  setDialogState(() => _shareProgress = v);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('pref_share_progress', v);
                  final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
                  if (uid != null) {
                    FirestoreService().updateUser(uid, {'shareProgress': v});
                  }
                },
              ),
              SwitchListTile(
                title: Text(context.tr('show_activity_status')),
                value: _showActivityStatus,
                activeColor: AppTheme.accentBlue,
                onChanged: (v) async {
                  setDialogState(() => _showActivityStatus = v);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('pref_activity_status', v);
                  final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
                  if (uid != null) {
                    FirestoreService().updateUser(uid, {'showActivityStatus': v});
                  }
                },
              ),
            ]),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('close')))],
          ),
        ),
      );
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('help__faq')),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _faq(context.tr('how_do_i_generate_a_timetable'), context.tr('how_do_i_generate_a_timetable_ans')),
              _faq(context.tr('how_do_i_connect_with_a_mentor'), context.tr('how_do_i_connect_with_a_mentor_ans')),
              _faq(context.tr('how_do_i_take_a_quiz'), context.tr('how_do_i_take_a_quiz_ans')),
              _faq(context.tr('what_does_streak_mean'), context.tr('what_does_streak_mean_ans')),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('close')))],
      ),
    );
  }

  Widget _faq(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q: $q', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
          SizedBox(height: 4),
          Text(a, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('contact_support')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _contactRow(Icons.email_rounded, context.tr('email'), 'support@vidyasetu.app'),
          _contactRow(Icons.language_rounded, context.tr('help_center'), 'vidyasetu.app/help'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('close')))],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 20, color: AppTheme.accentBlue),
        SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          Text(value, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500)),
        ]),
      ]),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('terms_of_service')),
        content: SingleChildScrollView(child: Text(context.tr('by_using_vidyasetu_you_agree_to_our_term'))),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('close')))],
      ),
    );
  }

  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('about_vidyasetu')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _aboutRow(Icons.apps_rounded, context.tr('version'), '1.0.0'),
          _aboutRow(Icons.build_rounded, context.tr('build'), '2026.03.07'),
          _aboutRow(Icons.school_rounded, context.tr('for'), context.tr('students')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('close')))],
      ),
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.accentBlue),
        SizedBox(width: 12),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
        Spacer(),
        Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('logout')),
        content: Text(context.tr('are_you_sure_you_want_to_logout')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.signOut();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('delete_account'), style: TextStyle(color: AppTheme.errorRed)),
        content: Text(
          context.tr('your_account_will_be_scheduled_for_delet') + 
          ' You have 30 days to restore it by logging back in. ' +
          'After 30 days, all your study data, notes, and connections will be permanently removed.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final uid = FirebaseAuth.instance.currentUser?.uid;
              try {
                if (uid != null) {
                  await AuthService().softDeleteAccount(uid);
                } else {
                  await auth.signOut();
                }
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${context.tr('error_please_reauth')} $e'), backgroundColor: AppTheme.errorRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text(context.tr('delete_account')),
          ),
        ],
      ),
    );
  }

  // --- Dynamic Achievements Block ---
  Widget _buildAchievementsSection(dynamic user) {
    if (user == null) return const SizedBox.shrink();
    
    // Use unified logic
    final achievements = GamificationLogic.getAchievements(
      context,
      xpPoints: user.points ?? 0,
      streak: user.streak ?? 0,
      totalHours: user.totalStudyHours ?? 0.0,
      tasksCompleted: user.tasksCompleted ?? 0,
      level: user.level ?? 1,
    );

    final unlocked = achievements.where((a) => a.unlocked).toList();
    final locked = achievements.where((a) => !a.unlocked).toList();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${unlocked.length} / ${achievements.length} ${context.tr('unlocked')}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.achievements),
                child: Text(context.tr('view_all'), style: TextStyle(color: AppTheme.accentBlue, fontSize: 13, fontWeight: FontWeight.w700)),
              )
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...unlocked.map((a) => _buildBadge(a, true)),
                ...locked.map((a) => _buildBadge(a, false)),
              ],
            ),
          )
        ],
      )
    );
  }

  Widget _buildBadge(dynamic a, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(right: 18),
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: isUnlocked ? a.color.withOpacity(0.12) : Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
              shape: BoxShape.circle,
              border: isUnlocked ? Border.all(color: a.color.withOpacity(0.4), width: 2) : Border.all(color: Colors.transparent),
              boxShadow: isUnlocked ? [
                BoxShadow(color: a.color.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
              ] : [],
            ),
            child: Icon(
              a.icon,
              color: isUnlocked ? a.color : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 75,
            child: Text(
              a.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isUnlocked ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 11,
                fontWeight: isUnlocked ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
