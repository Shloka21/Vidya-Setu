import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/animated_theme_toggle.dart';

class MentorProfileScreen extends StatefulWidget {
  const MentorProfileScreen({super.key});

  @override
  State<MentorProfileScreen> createState() => _MentorProfileScreenState();
}

class _MentorProfileScreenState extends State<MentorProfileScreen> {
  bool _newRequests = true;
  bool _messageNotif = true;
  bool _studentUpdates = true;
  bool _availableForNew = true;
  final _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid != null) {
      final userData = await _firestore.getUser(uid);
      if (userData != null && mounted) {
        setState(() {
          _availableForNew = userData['availableForNew'] ?? true;
        });
      }
    }
    if (mounted) {
      setState(() {
        _newRequests = prefs.getBool('mentor_notif_requests') ?? true;
        _messageNotif = prefs.getBool('mentor_notif_messages') ?? true;
        _studentUpdates = prefs.getBool('mentor_notif_updates') ?? true;
      });
    }
  }

  Future<void> _savePref(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _showEditProfileDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile Header ──
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.accentPurple, AppTheme.accentBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: user?.profileImageUrl != null
                        ? ClipOval(child: Image.network(user!.profileImageUrl!, fit: BoxFit.cover, width: 90, height: 90))
                        : Center(
                            child: Text(
                              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'M',
                              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),
                  Text(user?.name ?? 'Mentor',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14)),
                  const SizedBox(height: 6),
                  if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                    Text(user.bio!, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13), textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, size: 14, color: AppTheme.accentPurple),
                        const SizedBox(width: 4),
                        Text('Mentor', style: TextStyle(color: AppTheme.accentPurple, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Stats ──
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _firestore.getConnectedStudents(user?.uid ?? ''),
              builder: (context, snap) {
                final studentCount = snap.data?.length ?? 0;
                return Row(
                  children: [
                    _buildStat('Students', '$studentCount', AppTheme.accentBlue),
                    _buildStat('Rating', '${(user?.rating ?? 4.9).toStringAsFixed(1)}', AppTheme.warningAmber),
                    _buildStat('Sessions', '${user?.sessionsCompleted ?? 0}', AppTheme.successGreen),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),

            // ── Account ──
            _sectionTitle('ACCOUNT'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _navItem(Icons.people_outline_rounded, 'My Students', () => Navigator.pushNamed(context, AppRoutes.myStudents)),
                  const Divider(height: 1),
                  _navItem(Icons.lock_rounded, 'Change Password', _showChangePasswordDialog),
                  const Divider(height: 1),
                  _navItem(Icons.verified_rounded, 'Verification Status', _showVerificationDialog),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Availability ──
            _sectionTitle('AVAILABILITY'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SwitchListTile(
                title: Text('Available for New Students',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
                subtitle: Text('Allow students to send connection requests',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
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
            ),
            const SizedBox(height: 24),

            // ── Notifications ──
            _sectionTitle('NOTIFICATIONS'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _toggle('New Student Requests', _newRequests, (v) {
                    setState(() => _newRequests = v);
                    _savePref('mentor_notif_requests', v);
                  }),
                  _toggle('Messages', _messageNotif, (v) {
                    setState(() => _messageNotif = v);
                    _savePref('mentor_notif_messages', v);
                  }),
                  _toggle('Student Progress Updates', _studentUpdates, (v) {
                    setState(() => _studentUpdates = v);
                    _savePref('mentor_notif_updates', v);
                  }),
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
                          transitionBuilder: (child, anim) =>
                              RotationTransition(turns: Tween(begin: 0.75, end: 1.0).animate(anim), child: FadeTransition(opacity: anim, child: child)),
                          child: Icon(
                            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            key: ValueKey(isDark),
                            color: isDark ? AppTheme.warningAmber : AppTheme.accentBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('App Theme', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
                              Text(isDark ? 'Currently using dark theme' : 'Currently using light theme',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
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
                  _navItem(Icons.language_rounded, 'Language', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('English is currently the only available language')),
                    );
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
                  _navItem(Icons.help_outline_rounded, 'Help & FAQ', _showHelpDialog),
                  const Divider(height: 1),
                  _navItem(Icons.headset_mic_rounded, 'Contact Support', _showContactSupportDialog),
                  const Divider(height: 1),
                  _navItem(Icons.policy_rounded, 'Privacy Policy', _showPrivacyPolicyDialog),
                  const Divider(height: 1),
                  _navItem(Icons.info_outline_rounded, 'About VidyaSetu', _showAboutAppDialog),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Logout ──
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 22),
                title: Text('Logout', style: TextStyle(color: AppTheme.errorRed, fontSize: 15, fontWeight: FontWeight.w600)),
                onTap: _showLogoutDialog,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──
  Widget _buildStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w700)),
            Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
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
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 22),
      title: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
      trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 22),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
      value: value,
      activeColor: AppTheme.accentBlue,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  // ── Dialogs ──
  void _showEditProfileDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.userModel;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final bioCtrl = TextEditingController(text: user?.bio ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Profile', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))),
          ElevatedButton(
            onPressed: () async {
              final uid = user?.uid;
              if (uid == null) return;
              await _firestore.updateUser(uid, {
                'name': nameCtrl.text.trim(),
                'bio': bioCtrl.text.trim(),
              });
              await auth.reloadUser();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: const Text('Save'),
          ),
        ],
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

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(Icons.verified_rounded, color: AppTheme.successGreen, size: 24), const SizedBox(width: 8), const Text('Verification')]),
        content: const Text('Your mentor account is verified.\n\nVerified mentors appear with a badge and are prioritized in student searches.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
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
              _faq('How do I connect with students?', 'Go to Browse Students (Find Students button on Dashboard) and tap Connect.'),
              _faq('How do I schedule meetings?', 'Open a chat → tap the ⋮ menu → Schedule Meeting.'),
              _faq('How do I provide feedback?', 'Go to My Students → tap a student → Send Feedback.'),
              _faq('How do I send reminders?', 'Go to Reminders from Quick Actions → Create Reminder.'),
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
          Text('Q: $q', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
          const SizedBox(height: 4),
          Text(a, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
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
          _contactRow(Icons.language_rounded, 'Website', 'vidyasetu.app/help'),
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

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(child: Text(
          'VidyaSetu respects your privacy.\n\n'
          '• Your data is stored securely in Firebase.\n'
          '• We do not share your information with third parties.\n'
          '• Student data you mentor is kept confidential.\n'
          '• You can delete your account at any time.\n\n'
          'For full policy: vidyasetu.app/privacy',
        )),
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
          _aboutRow(Icons.code_rounded, 'Framework', 'Flutter'),
          _aboutRow(Icons.cloud_rounded, 'Backend', 'Firebase'),
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
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
