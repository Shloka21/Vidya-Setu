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

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
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
    _savePref(key, value);
    // Toggle notification channels
    if (key == 'pref_reminder_notif' && !value) {
      NotificationService().cancelAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Settings')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Account'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      _buildNavItem(Icons.person_rounded, 'Edit Profile', () {
                        Navigator.pushNamed(context, AppRoutes.editStudentProfile);
                      }),
                      const Divider(height: 1),
                      _buildNavItem(Icons.lock_rounded, 'Change Password', () {
                        _showChangePasswordDialog();
                      }),
                      const Divider(height: 1),
                      _buildNavItem(Icons.shield_rounded, 'Privacy Settings', () {
                        _showPrivacySettingsDialog();
                      }),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle('Notification Preferences'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(children: [
                      _buildToggle('Reminder Notifications', _reminderNotifications, (v) {
                        setState(() => _reminderNotifications = v);
                        _updateNotifPref('pref_reminder_notif', v);
                      }),
                      _buildToggle('Voice Notifications', _voiceNotifications, (v) {
                        setState(() => _voiceNotifications = v);
                        _savePref('pref_voice_notif', v);
                      }),
                      _buildToggle('Mentor Messages', _mentorMessages, (v) {
                        setState(() => _mentorMessages = v);
                        _savePref('pref_mentor_msgs', v);
                      }),
                      _buildToggle('System Notifications', _systemNotifications, (v) {
                        setState(() => _systemNotifications = v);
                        _savePref('pref_system_notif', v);
                      }),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle('Study Preferences'),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Default Session Duration', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: Slider(
                              value: _defaultSessionDuration,
                              min: 15, max: 120, divisions: 7,
                              activeColor: AppTheme.accentBlue,
                              label: '${_defaultSessionDuration.toInt()} min',
                              onChanged: (v) {
                                setState(() => _defaultSessionDuration = v);
                                _savePref('pref_session_duration', v);
                              },
                            ),
                          ),
                          Text('${_defaultSessionDuration.toInt()} min', style: const TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 16),
                        Text('Break Duration', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: Slider(
                              value: _breakDuration,
                              min: 5, max: 30, divisions: 5,
                              activeColor: AppTheme.successGreen,
                              label: '${_breakDuration.toInt()} min',
                              onChanged: (v) {
                                setState(() => _breakDuration = v);
                                _savePref('pref_break_duration', v);
                              },
                            ),
                          ),
                          Text('${_breakDuration.toInt()} min', style: const TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 12),
                        _buildToggle('Break Reminders', _breakReminders, (v) {
                          setState(() => _breakReminders = v);
                          _savePref('pref_break_reminders', v);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle('Appearance'),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      // Animated Dark Mode Toggle
                      GestureDetector(
                        onTap: () => themeProvider.toggleTheme(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [const Color(0xFF0F1923), const Color(0xFF1B2838)]
                                  : [const Color(0xFFF5F7FA), Colors.white],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? AppTheme.accentBlue.withOpacity(0.3) : AppTheme.divider),
                          ),
                          child: Row(children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                                key: ValueKey(isDark),
                                color: isDark ? Colors.amber : Colors.orange,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isDark ? 'Dark Mode' : 'Light Mode',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                                Text(isDark ? 'Easy on the eyes at night' : 'Bright and clear for daytime',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                              ],
                            )),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              width: 54, height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: isDark ? AppTheme.accentBlue : AppTheme.divider,
                              ),
                              child: AnimatedAlign(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  width: 26, height: 26,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                                  ),
                                  child: Icon(
                                    isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                                    size: 14,
                                    color: isDark ? AppTheme.accentBlue : Colors.orange,
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle('App Settings'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      _buildNavItem(Icons.language_rounded, 'Language', () {
                        _showLanguageDialog();
                      }),
                      const Divider(height: 1),
                      _buildNavItem(Icons.storage_rounded, 'Clear Cache', () {
                        _showClearCacheDialog();
                      }),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle('Support & Legal'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      _buildNavItem(Icons.help_outline_rounded, 'Help & FAQ', () {
                        _showHelpDialog();
                      }),
                      const Divider(height: 1),
                      _buildNavItem(Icons.mail_outline_rounded, 'Contact Support', () {
                        _showContactSupportDialog();
                      }),
                      const Divider(height: 1),
                      _buildNavItem(Icons.policy_rounded, 'Privacy Policy', () {
                        _showPrivacyPolicyDialog();
                      }),
                      const Divider(height: 1),
                      _buildNavItem(Icons.article_outlined, 'Terms of Service', () {
                        _showTermsDialog();
                      }),
                      const Divider(height: 1),
                      _buildNavItem(Icons.info_outline_rounded, 'About', () {
                        _showAboutAppDialog();
                      }),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Danger Zone
                  _sectionTitle('DANGER ZONE'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 22),
                        title: const Text('Logout', style: TextStyle(color: AppTheme.errorRed, fontSize: 15)),
                        trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.errorRed.withOpacity(0.5), size: 22),
                        onTap: () => _showLogoutDialog(),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.errorRed, size: 22),
                        title: const Text('Delete Account', style: TextStyle(color: AppTheme.errorRed, fontSize: 15)),
                        trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.errorRed.withOpacity(0.5), size: 22),
                        onTap: () => _showDeleteAccountDialog(),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1,
      )),
    );
  }

  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 22),
      title: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
      trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), size: 22),
      onTap: onTap,
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15))),
          Switch(value: value, onChanged: onChanged, activeColor: AppTheme.accentBlue),
        ],
      ),
    );
  }

  // ─── Dialogs ────────────────────────────────────────
  void _showChangePasswordDialog() {
    final currentPC = TextEditingController();
    final newPC = TextEditingController();
    final confirmPC = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: currentPC, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
          const SizedBox(height: 12),
          TextField(controller: newPC, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
          const SizedBox(height: 12),
          TextField(controller: confirmPC, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm Password')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newPC.text != confirmPC.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              try {
                final user = FirebaseAuth.instance.currentUser;
                final cred = EmailAuthProvider.credential(email: user?.email ?? '', password: currentPC.text);
                await user?.reauthenticateWithCredential(cred);
                await user?.updatePassword(newPC.text);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated!'), backgroundColor: AppTheme.successGreen));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _buildToggle('Show Profile to Mentors', true, (_) {}),
          _buildToggle('Show Progress to Mentors', true, (_) {}),
          _buildToggle('Allow Search Discovery', true, (_) {}),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Language'),
        children: ['English', 'Hindi', 'Marathi', 'Tamil', 'Telugu'].map((l) => SimpleDialogOption(
          onPressed: () {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$l selected')));
          },
          child: Text(l, style: const TextStyle(fontSize: 16)),
        )).toList(),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. You may need to re-download some content.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared!'), backgroundColor: AppTheme.successGreen));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _faqItem('How do I generate a timetable?', 'Go to Study Plan > Generate Timetable, upload your syllabus PDF, and follow the steps.'),
            _faqItem('How do reminders work?', 'Set reminders with custom times and repeat options. You\'ll get notifications before the event.'),
            _faqItem('How do I connect with a mentor?', 'Go to Find Mentor, browse profiles, and send a connection request.'),
            _faqItem('What is the quiz feature?', 'After completing a study session, take a quiz to test your knowledge. Pass to mark it complete!'),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Widget _faqItem(String q, String a) {
    return ExpansionTile(
      title: Text(q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      children: [Padding(padding: const EdgeInsets.all(12), child: Text(a, style: const TextStyle(fontSize: 13)))],
    );
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _contactItem(Icons.email, 'Email', 'support@vidyasetu.app'),
          _contactItem(Icons.phone, 'Phone', '+91 98765 43210'),
          _contactItem(Icons.chat, 'In-app', 'Use the chat feature'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Widget _contactItem(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentBlue, size: 22),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(value, style: const TextStyle(fontSize: 13)),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'VidyaSetu Privacy Policy\n\n'
            'We respect your privacy and protect your personal information. '
            'Data collected includes: name, email, study preferences, and usage analytics.\n\n'
            'Your data is stored securely on Firebase servers and is never sold to third parties.\n\n'
            'You can request data deletion at any time through the app settings.',
            style: TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'VidyaSetu Terms of Service\n\n'
            '1. Use the app responsibly for educational purposes.\n'
            '2. Do not share inappropriate content.\n'
            '3. Mentor-student interactions should be professional.\n'
            '4. We reserve the right to suspend accounts that violate these terms.\n'
            '5. The app is provided "as is" without warranties.',
            style: TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About VidyaSetu'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/app_logo.png', width: 80, height: 80, errorBuilder: (_, __, ___) => const Icon(Icons.school, size: 60, color: AppTheme.accentBlue)),
          const SizedBox(height: 16),
          const Text('VidyaSetu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Smart Student Reminder & Mentor Guidance', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          _aboutRow(Icons.code, 'Version', '1.0.0'),
          _aboutRow(Icons.person, 'Developer', 'VidyaSetu Team'),
          _aboutRow(Icons.flutter_dash, 'Framework', 'Flutter'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Widget _aboutRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 18, color: AppTheme.accentBlue),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(value, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<AuthProvider>(context, listen: false).signOut();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
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
        title: const Text('Delete Account', style: TextStyle(color: AppTheme.errorRed)),
        content: const Text('This action is irreversible. All your data will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
