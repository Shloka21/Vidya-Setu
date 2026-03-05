import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
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
  final _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  void _loadAvailability() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) return;
    final userData = await _firestore.getUser(uid);
    if (userData != null && mounted) {
      setState(() {
        _availableForNew = userData['availableForNew'] ?? true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
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
                  _navItem(Icons.lock_rounded, 'Change Password', () {
                    _showChangePasswordDialog();
                  }),
                  const Divider(height: 1),
                  _navItem(Icons.shield_rounded, 'Verification Status', () {
                    _showVerificationDialog();
                  }),
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
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                    subtitle: Text('Allow students to send connection requests',
                        style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
                    value: _availableForNew,
                    activeColor: AppTheme.accentBlue,
                    onChanged: (v) async {
                      setState(() => _availableForNew = v);
                      final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
                      if (uid != null) {
                        await _firestore.updateUser(uid, {'availableForNew': v});
                      }
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
                    secondary: Icon(Icons.dark_mode_rounded, color: AppTheme.textSecondary, size: 22),
                    value: _darkMode,
                    activeColor: AppTheme.accentBlue,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                  const Divider(height: 1),
                  _navItem(Icons.language_rounded, 'Language', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('English is currently the only available language')),
                    );
                  }),
                  const Divider(height: 1),
                  _navItem(Icons.help_outline_rounded, 'Help & FAQ', () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Help & FAQ'),
                        content: const Text(
                          '• How do I connect with students?\n'
                          '  Students send you requests from the Find Mentor screen.\n\n'
                          '• How do I schedule meetings?\n'
                          '  Open a chat → tap the ⋮ menu → Schedule Meeting.\n\n'
                          '• How do I provide feedback?\n'
                          '  Go to My Students → tap a student → Send Feedback.\n\n'
                          'Email: support@vidyasetu.app',
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                      ),
                    );
                  }),
                  const Divider(height: 1),
                  _navItem(Icons.policy_rounded, 'Privacy Policy', () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Privacy Policy'),
                        content: const Text(
                          'VidyaSetu respects your privacy.\n\n'
                          '• Your data is stored securely in Firebase.\n'
                          '• We do not share your information with third parties.\n'
                          '• You can delete your account at any time.\n\n'
                          'For full policy: vidyasetu.app/privacy',
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                      ),
                    );
                  }),
                  const Divider(height: 1),
                  _navItem(Icons.info_outline_rounded, 'About', () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'VidyaSetu',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2026 VidyaSetu. All rights reserved.',
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 22),
                title: Text('Logout', style: TextStyle(color: AppTheme.errorRed, fontSize: 15)),
                onTap: () async {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
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

  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Change Password', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                filled: true, fillColor: AppTheme.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                filled: true, fillColor: AppTheme.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null && user.email != null) {
                  final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassCtrl.text);
                  await user.reauthenticateWithCredential(cred);
                  await user.updatePassword(newPassCtrl.text);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Password updated!'), backgroundColor: AppTheme.successGreen,
                          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    );
                  }
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.verified_rounded, color: AppTheme.successGreen, size: 24),
            const SizedBox(width: 8),
            const Text('Verification Status'),
          ],
        ),
        content: const Text(
          'Your mentor account is verified.\n\n'
          'Verified mentors appear with a badge and are prioritized in student searches.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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
      title: Text(label, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textLight, size: 22),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
      value: value,
      activeColor: AppTheme.accentBlue,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }
}
