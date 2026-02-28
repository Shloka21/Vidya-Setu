import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/app_card.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  bool _reminderNotifications = true;
  bool _voiceNotifications = false;
  bool _mentorMessages = true;
  bool _systemNotifications = true;
  bool _breakReminders = true;
  bool _darkMode = false;
  double _defaultSessionDuration = 45;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Account'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildNavItem(Icons.person_rounded, 'Edit Profile', () {
                    Navigator.pushNamed(context, AppRoutes.editStudentProfile);
                  }),
                  const Divider(height: 1),
                  _buildNavItem(Icons.lock_rounded, 'Change Password', () {
                    _showChangePasswordDialog();
                  }),
                  const Divider(height: 1),
                  _buildNavItem(Icons.shield_rounded, 'Privacy Settings', () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Notification Preferences'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _buildToggle('Reminder Notifications', _reminderNotifications,
                      (v) => setState(() => _reminderNotifications = v)),
                  _buildToggle('Voice Notifications', _voiceNotifications,
                      (v) => setState(() => _voiceNotifications = v)),
                  _buildToggle('Mentor Messages', _mentorMessages,
                      (v) => setState(() => _mentorMessages = v)),
                  _buildToggle('System Notifications', _systemNotifications,
                      (v) => setState(() => _systemNotifications = v)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Study Preferences'),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Default Session Duration',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _defaultSessionDuration,
                          min: 15,
                          max: 120,
                          divisions: 7,
                          activeColor: AppTheme.accentBlue,
                          label: '${_defaultSessionDuration.toInt()} min',
                          onChanged: (v) =>
                              setState(() => _defaultSessionDuration = v),
                        ),
                      ),
                      Text('${_defaultSessionDuration.toInt()} min',
                          style: TextStyle(
                              color: AppTheme.accentBlue,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildToggle('Break Reminders', _breakReminders,
                      (v) => setState(() => _breakReminders = v)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('App Settings'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Dark Mode',
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 15)),
                    secondary: Icon(Icons.dark_mode_rounded,
                        color: AppTheme.textSecondary, size: 22),
                    value: _darkMode,
                    activeThumbColor: AppTheme.accentBlue,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                  const Divider(height: 1),
                  _buildNavItem(Icons.language_rounded, 'Language', () {}),
                  const Divider(height: 1),
                  _buildNavItem(
                      Icons.storage_rounded, 'Clear Cache', () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Support & Legal'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildNavItem(
                      Icons.help_outline_rounded, 'Help & FAQ', () {}),
                  const Divider(height: 1),
                  _buildNavItem(
                      Icons.mail_outline_rounded, 'Contact Support', () {}),
                  const Divider(height: 1),
                  _buildNavItem(
                      Icons.policy_rounded, 'Privacy Policy', () {}),
                  const Divider(height: 1),
                  _buildNavItem(
                      Icons.article_outlined, 'Terms of Service', () {}),
                  const Divider(height: 1),
                  _buildNavItem(Icons.info_outline_rounded, 'About', () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Danger Zone
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.logout_rounded,
                        color: AppTheme.errorRed, size: 22),
                    title: Text('Logout',
                        style: TextStyle(
                            color: AppTheme.errorRed, fontSize: 15)),
                    onTap: () async {
                      final auth =
                          Provider.of<AuthProvider>(context, listen: false);
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, AppRoutes.login, (_) => false);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.delete_forever_rounded,
                        color: AppTheme.errorRed, size: 22),
                    title: Text('Delete Account',
                        style: TextStyle(
                            color: AppTheme.errorRed, fontSize: 15)),
                    onTap: () {},
                  ),
                ],
              ),
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
      child: Text(title,
          style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );
  }

  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
      title: Text(label,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: AppTheme.textLight, size: 22),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
      value: value,
      activeThumbColor: AppTheme.accentBlue,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Update')),
        ],
      ),
    );
  }
}
