import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/animated_theme_toggle.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  // Notification prefs
  bool _reminderNotifications = true;
  bool _voiceNotifications = false;
  bool _mentorMessages = true;
  bool _systemNotifications = true;

  // Study prefs
  double _defaultSessionDuration = 45;
  double _breakDuration = 10;
  bool _breakReminders = true;

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
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

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = Provider.of<AuthProvider>(context).userModel;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryNavy, Color(0xFF6C4DE6), Color(0xFF4A7BF7)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          color: Colors.white24,
                        ),
                        child: user?.profileImageUrl != null
                            ? ClipOval(child: Image.network(user!.profileImageUrl!, fit: BoxFit.cover))
                            : Center(
                                child: Text(
                                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'S',
                                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'Student',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
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
                  Row(
                    children: [
                      _buildStatItem('Level', '${user?.level ?? 1}', Icons.star_rounded, AppTheme.warningAmber),
                      const SizedBox(width: 12),
                      _buildStatItem('Points', '${user?.points ?? 0}', Icons.bolt_rounded, AppTheme.accentPurple),
                      const SizedBox(width: 12),
                      _buildStatItem('Streak', '${user?.streak ?? 0}', Icons.local_fire_department, AppTheme.errorRed),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Bio ──
                  if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                    _sectionTitle('ABOUT ME'),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        user.bio!,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── Achievements ──
                  _sectionTitle('ACHIEVEMENTS'),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _buildAchievementBadge('🔥', 'Streak Master', user?.streak != null && user!.streak >= 7),
                        const SizedBox(width: 12),
                        _buildAchievementBadge('⭐', 'Rising Star', user?.level != null && user!.level >= 3),
                        const SizedBox(width: 12),
                        _buildAchievementBadge('📚', 'Bookworm', user?.points != null && user!.points >= 100),
                        const SizedBox(width: 12),
                        _buildAchievementBadge('🏆', 'Champion', user?.points != null && user!.points >= 500),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Account ──
                  _sectionTitle('ACCOUNT'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildNavItem(Icons.lock_rounded, 'Change Password', _showChangePasswordDialog),
                        const Divider(height: 1),
                        _buildNavItem(Icons.shield_rounded, 'Privacy Settings', _showPrivacySettingsDialog),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Study Preferences ──
                  _sectionTitle('STUDY PREFERENCES'),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Default Session Duration', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
                            Text('${_defaultSessionDuration.toInt()} min', style: TextStyle(color: AppTheme.accentPurple, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Slider(
                          value: _defaultSessionDuration,
                          min: 15, max: 120, divisions: 7,
                          activeColor: AppTheme.accentPurple,
                          onChanged: (v) { setState(() => _defaultSessionDuration = v); _savePref('pref_session_duration', v); },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Break Duration', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
                            Text('${_breakDuration.toInt()} min', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Slider(
                          value: _breakDuration,
                          min: 5, max: 30, divisions: 5,
                          activeColor: AppTheme.accentBlue,
                          onChanged: (v) { setState(() => _breakDuration = v); _savePref('pref_break_duration', v); },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Notifications ──
                  _sectionTitle('NOTIFICATIONS'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        _buildSwitchItem('Study Reminders', _reminderNotifications, (v) => _updateNotifPref('pref_reminder_notif', v)),
                        _buildSwitchItem('Voice Alerts (Beta)', _voiceNotifications, (v) => _updateNotifPref('pref_voice_notif', v)),
                        _buildSwitchItem('Mentor Messages', _mentorMessages, (v) => _updateNotifPref('pref_mentor_msgs', v)),
                        _buildSwitchItem('System Notifications', _systemNotifications, (v) => _updateNotifPref('pref_system_notif', v)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Appearance ──
                  _sectionTitle('APPEARANCE'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, anim) => RotationTransition(turns: Tween(begin: 0.75, end: 1.0).animate(anim), child: FadeTransition(opacity: anim, child: child)),
                                child: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, key: ValueKey(isDark), color: isDark ? AppTheme.warningAmber : AppTheme.accentBlue, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('App Theme', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
                                    Text(isDark ? 'Currently using dark theme' : 'Currently using light theme', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
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
                        const Divider(height: 1),
                        _buildNavItem(Icons.language_rounded, 'Language', () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('English is currently the only available language')));
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Support ──
                  _sectionTitle('SUPPORT'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildNavItem(Icons.help_outline_rounded, 'Help & FAQ', _showHelpDialog),
                        const Divider(height: 1),
                        _buildNavItem(Icons.headset_mic_rounded, 'Contact Support', _showContactSupportDialog),
                        const Divider(height: 1),
                        _buildNavItem(Icons.policy_rounded, 'Terms of Service', _showTermsDialog),
                        const Divider(height: 1),
                        _buildNavItem(Icons.info_outline_rounded, 'About VidyaSetu', _showAboutAppDialog),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Danger Zone ──
                  _sectionTitle('DANGER ZONE'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppTheme.errorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 20)),
                          title: const Text('Logout', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
                          onTap: _showLogoutDialog,
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.errorRed),
                          title: const Text('Delete Account', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.08), color.withOpacity(0.03)]),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(icon, color: color, size: 22)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
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

  // ── Dialogs ──
  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change Password', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: currentPassCtrl, obscureText: true, decoration: InputDecoration(labelText: 'Current Password', filled: true, fillColor: Theme.of(context).colorScheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 12),
            TextField(controller: newPassCtrl, obscureText: true, decoration: InputDecoration(labelText: 'New Password', filled: true, fillColor: Theme.of(context).colorScheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && user.email != null) {
                  final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassCtrl.text);
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPassCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Password updated!'), backgroundColor: AppTheme.successGreen));
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettingsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Privacy Settings'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          SwitchListTile(title: const Text('Share progress with Mentor'), value: true, onChanged: (v) {}),
          SwitchListTile(title: const Text('Show Activity Status'), value: true, onChanged: (v) {}),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Help & FAQ'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _faq('How do I generate a timetable?', 'Go to Timetable (Dashboard/Nav bar) → Tap "+" in the timeline.'),
              _faq('How do I connect with a mentor?', 'Go to Mentors tab → Find Mentor → Send Request.'),
              _faq('How do I take a quiz?', 'Click on a study session in your timetable → Start Quiz.'),
              _faq('What does Streak mean?', 'It is the number of consecutive days you have completed at least one study session.'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
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
          const SizedBox(height: 4),
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
        title: const Text('Contact Support'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _contactRow(Icons.email_rounded, 'Email', 'support@vidyasetu.app'),
          _contactRow(Icons.language_rounded, 'Help Center', 'vidyasetu.app/help'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _contactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 20, color: AppTheme.accentBlue),
        const SizedBox(width: 12),
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
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(child: Text('By using VidyaSetu, you agree to our Terms...\n\n(This is a placeholder for actual TS)')),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('About VidyaSetu'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _aboutRow(Icons.apps_rounded, 'Version', '1.0.0'),
          _aboutRow(Icons.build_rounded, 'Build', '2026.03.07'),
          _aboutRow(Icons.school_rounded, 'For', 'Students'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.accentBlue),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
        const Spacer(),
        Text(value, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.signOut();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Logout'),
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
        title: const Text('Delete Account', style: TextStyle(color: AppTheme.errorRed)),
        content: const Text('This action is irreversible. All your study data, notes, and connections will be lost permanently. Are you absolutely sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                await auth.signOut();
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }
}
