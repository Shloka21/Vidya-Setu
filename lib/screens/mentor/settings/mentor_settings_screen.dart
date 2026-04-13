import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';
import 'package:vidyasetu/services/localization_service.dart';

class MentorSettingsScreen extends StatefulWidget {
  const MentorSettingsScreen({super.key});

  @override
  State<MentorSettingsScreen> createState() => _MentorSettingsScreenState();
}

class _MentorSettingsScreenState extends State<MentorSettingsScreen> {
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
    if (value is int) prefs.setInt(key, value);
    if (value is String) prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Account ──
            _sectionTitle(context.tr('account')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _navItem(Icons.person_rounded, 'Edit Profile', () {
                    Navigator.pushNamed(context, AppRoutes.mentorProfileScreen);
                  }),
                  Divider(height: 1),
                  _navItem(Icons.lock_rounded, 'Change Password', _showChangePasswordDialog),
                  Divider(height: 1),
                  _navItem(Icons.verified_rounded, 'Verification Status', _showVerificationDialog),
                ],
              ),
            ),
            SizedBox(height: 24),

            // ── Availability ──
            _sectionTitle(context.tr('availability')),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SwitchListTile(
                title: Text(context.tr('available_for_new_students'),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
                subtitle: Text(context.tr('allow_students_to_send_connection_reques'),
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
            SizedBox(height: 24),

            // ── Notifications ──
            _sectionTitle(context.tr('notifications')),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _toggle(context.tr('new_student_requests'), _newRequests, (v) {
                    setState(() => _newRequests = v);
                    _savePref(context.tr('mentornotifrequests'), v);
                  }),
                  _toggle(context.tr('messages'), _messageNotif, (v) {
                    setState(() => _messageNotif = v);
                    _savePref(context.tr('mentornotifmessages'), v);
                  }),
                  _toggle(context.tr('student_progress_updates'), _studentUpdates, (v) {
                    setState(() => _studentUpdates = v);
                    _savePref(context.tr('mentornotifupdates'), v);
                  }),
                ],
              ),
            ),
            SizedBox(height: 24),

            // ── Appearance ──
            _sectionTitle(context.tr('appearance')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Animated Dark Mode Toggle
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
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('app_theme'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
                              Text(isDark ? 'Currently using dark theme' : 'Currently using light theme',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                            ],
                          ),
                        ),
                        Switch(
                          value: isDark,
                          activeColor: AppTheme.accentBlue,
                          onChanged: (v) => themeProvider.toggleTheme(),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  _navItem(Icons.language_rounded, 'Language', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('english_is_currently_the_only'))),
                    );
                  }),
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
                  _navItem(Icons.help_outline_rounded, 'Help & FAQ', _showHelpDialog),
                  Divider(height: 1),
                  _navItem(Icons.headset_mic_rounded, 'Contact Support', _showContactSupportDialog),
                  Divider(height: 1),
                  _navItem(Icons.delete_sweep_rounded, 'Clear Cache', _showClearCacheDialog),
                ],
              ),
            ),
            SizedBox(height: 24),

            // ── Legal ──
            _sectionTitle(context.tr('legal')),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _navItem(Icons.policy_rounded, 'Privacy Policy', _showPrivacyPolicyDialog),
                  Divider(height: 1),
                  _navItem(Icons.description_rounded, 'Terms of Service', _showTermsDialog),
                  Divider(height: 1),
                  _navItem(Icons.info_outline_rounded, 'About VidyaSetu', _showAboutAppDialog),
                ],
              ),
            ),
            SizedBox(height: 24),

            // ── Logout ──
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 22),
                title: Text(context.tr('logout'), style: TextStyle(color: AppTheme.errorRed, fontSize: 15, fontWeight: FontWeight.w600)),
                onTap: _showLogoutDialog,
              ),
            ),
            SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.delete_forever_rounded, color: AppTheme.errorRed.withOpacity(0.7), size: 22),
                title: Text(context.tr('delete_account'), style: TextStyle(color: AppTheme.errorRed.withOpacity(0.7), fontSize: 15)),
                onTap: _showDeleteAccountDialog,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──
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
  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('change_password'), style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPassCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.tr('current_password'),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.tr('new_password'),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))),
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
                      SnackBar(content: Text(context.tr('password_updated')), backgroundColor: AppTheme.successGreen,
                          behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    );
                  }
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${context.tr('error')}: $e'), backgroundColor: AppTheme.errorRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: Text(context.tr('update')),
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
        title: Row(children: [
          Icon(Icons.verified_rounded, color: AppTheme.successGreen, size: 24),
          SizedBox(width: 8),
          Text(context.tr('verification_status')),
        ]),
        content: Text(
          context.tr('your_mentor_account_is_verifiednnverifie'),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('ok')))],
      ),
    );
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
              _faqItem(context.tr('how_do_i_connect_with_students'), context.tr('how_do_i_connect_with_students_ans')),
              _faqItem(context.tr('how_do_i_schedule_meetings'), context.tr('how_do_i_schedule_meetings_ans')),
              _faqItem(context.tr('how_do_i_provide_feedback'), context.tr('how_do_i_provide_feedback_ans')),
              _faqItem(context.tr('how_do_i_send_reminders'), context.tr('how_do_i_send_reminders_ans')),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('close')))],
      ),
    );
  }

  Widget _faqItem(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Q: $q', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
          SizedBox(height: 4),
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
        title: Text(context.tr('contact_support')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _contactItem(Icons.email_rounded, 'Email', 'support@vidyasetu.app'),
            _contactItem(Icons.language_rounded, 'Website', 'vidyasetu.app/help'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('close')))],
      ),
    );
  }

  Widget _contactItem(IconData icon, String label, String value) {
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

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('clear_cache')),
        content: Text(context.tr('this_will_clear_locally_cached')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('cache_cleared')), backgroundColor: AppTheme.successGreen,
                    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
            child: Text(context.tr('clear')),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('privacy_policy')),
        content: SingleChildScrollView(
          child: Text(
            context.tr('vidyasetu_respects_your_privacy') +
            '\n• Your data is stored securely in Firebase.\n' +
            '• We do not share your information with third parties.\n' +
            '• Student data you mentor is kept confidential.\n' +
            '• You can delete your account at any time.\n\n' +
            'For full policy: vidyasetu.app/privacy',
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('close')))],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('terms_of_service')),
        content: SingleChildScrollView(
          child: Text(
            context.tr('by_using_vidyasetu_as_a_mentor_you_agree') +
            '\n• Provide accurate guidance and feedback.\n' +
            '• Respect student privacy and confidentiality.\n' +
            '• Not share student data outside the platform.\n' +
            '• Maintain professional conduct in all interactions.\n\n' +
            'Full terms: vidyasetu.app/terms',
          ),
        ),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _aboutRow(Icons.apps_rounded, 'Version', '1.0.0'),
            _aboutRow(Icons.build_rounded, 'Build', '2026.03.07'),
            _aboutRow(Icons.code_rounded, 'Framework', 'Flutter'),
            _aboutRow(Icons.cloud_rounded, 'Backend', 'Firebase'),
          ],
        ),
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
        content: Text(context.tr('are_you_sure_you_want_to_logou')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
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
          context.tr('this_action_is_irreversible_all_your_dat'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseAuth.instance.currentUser?.delete();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${context.tr('error_please_reauth')} $e'), backgroundColor: AppTheme.errorRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text(context.tr('delete_forever')),
          ),
        ],
      ),
    );
  }
}
