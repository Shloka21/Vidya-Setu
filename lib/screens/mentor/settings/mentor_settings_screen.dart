import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/app_card.dart';

class MentorSettingsScreen extends StatefulWidget {
  const MentorSettingsScreen({super.key});

  @override
  State<MentorSettingsScreen> createState() => _MentorSettingsScreenState();
}

class _MentorSettingsScreenState extends State<MentorSettingsScreen> {
  bool _newRequests = true;
  bool _messageNotif = true;
  bool _studentUpdates = true;
  bool _darkMode = false;
  bool _availableForNew = true;

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
                  _navItem(Icons.person_rounded, 'Edit Profile', () {
                    Navigator.pushNamed(context, AppRoutes.mentorProfileScreen);
                  }),
                  const Divider(height: 1),
                  _navItem(Icons.lock_rounded, 'Change Password', () {}),
                  const Divider(height: 1),
                  _navItem(Icons.shield_rounded, 'Verification Status', () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Availability'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Available for New Students',
                        style: TextStyle(
                            color: AppTheme.textPrimary, fontSize: 15)),
                    subtitle: Text('Allow students to send connection requests',
                        style: TextStyle(
                            color: AppTheme.textLight, fontSize: 12)),
                    value: _availableForNew,
                    activeThumbColor: AppTheme.accentBlue,
                    onChanged: (v) =>
                        setState(() => _availableForNew = v),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Notifications'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _toggle('New Student Requests', _newRequests,
                      (v) => setState(() => _newRequests = v)),
                  _toggle('Messages', _messageNotif,
                      (v) => setState(() => _messageNotif = v)),
                  _toggle('Student Progress Updates', _studentUpdates,
                      (v) => setState(() => _studentUpdates = v)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('App'),
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
                  _navItem(Icons.language_rounded, 'Language', () {}),
                  const Divider(height: 1),
                  _navItem(Icons.help_outline_rounded, 'Help & FAQ', () {}),
                  const Divider(height: 1),
                  _navItem(Icons.policy_rounded, 'Privacy Policy', () {}),
                  const Divider(height: 1),
                  _navItem(Icons.info_outline_rounded, 'About', () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
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

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
      title: Text(label,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: AppTheme.textLight, size: 22),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label,
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
      value: value,
      activeThumbColor: AppTheme.accentBlue,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
