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
import '../../../services/localization_service.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/stat_card.dart';
import '../../../widgets/common/translated_text.dart';
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
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid != null) {
      final userData = await _firestore.getUser(uid);
      if (userData != null && mounted) {
        setState(() {
          _availableForNew = userData['availableForNew'] ?? true;
          _newRequests = userData['newRequestsNotif'] ?? true;
          _messageNotif = userData['messageNotif'] ?? true;
          _studentUpdates = userData['studentUpdatesNotif'] ?? true;
        });
      }
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
    final loc = Provider.of<LocalizationService>(context);
    final isTranslating = loc.isTranslating;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
                pinned: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16), // Increased top padding for gap
                      child: Row(
                        children: [
                          Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: [AppTheme.accentPurple, AppTheme.accentBlue]),
                              border: Border.all(color: Theme.of(context).colorScheme.surface, width: 3),
                              boxShadow: [BoxShadow(color: AppTheme.accentPurple.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: user?.profileImageUrl != null
                                ? ClipOval(child: Image.network(user!.profileImageUrl!, fit: BoxFit.cover))
                                : Center(child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'M', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user?.name ?? 'Mentor', 
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                )),
                                SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppTheme.accentPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, size: 12, color: AppTheme.accentPurple),
                                      SizedBox(width: 4),
                                      Text(context.tr('verified_mentor'), style: TextStyle(color: AppTheme.accentPurple, fontSize: 10, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.onSurface),
                            onPressed: () => _showEditProfileDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                        _sectionTitle(context.tr('about_me')),
                        AppCard(
                          padding: const EdgeInsets.all(16),
                          child: TranslatedText(user.bio!, 
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13), 
                            textAlign: TextAlign.center),
                        ),
                        SizedBox(height: 24),
                      ],

            // ── Stats ──
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _firestore.getConnectedStudents(user?.uid ?? ''),
              builder: (context, snap) {
                final studentCount = snap.data?.length ?? 0;
                return Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: context.tr('students'),
                        value: '$studentCount',
                        icon: Icons.people_rounded,
                        iconColor: AppTheme.accentBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        label: context.tr('rating'),
                        value: '${(user?.rating ?? 4.9).toStringAsFixed(1)}',
                        icon: Icons.star_rounded,
                        iconColor: AppTheme.warningAmber,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatCard(
                        label: context.tr('sessions'),
                        value: '${user?.sessionsCompleted ?? 0}',
                        icon: Icons.history_rounded,
                        iconColor: AppTheme.successGreen,
                      ),
                    ),
                  ],
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
                  _navItem(Icons.people_outline_rounded, context.tr('my_students'), () => Navigator.pushNamed(context, AppRoutes.myStudents)),
                  Divider(height: 1),
                  _navItem(Icons.lock_rounded, context.tr('change_password'), _showChangePasswordDialog),
                  Divider(height: 1),
                  _navItem(Icons.verified_rounded, context.tr('verification_status'), _showVerificationDialog),
                ],
              ),
            ),
            SizedBox(height: 24),

            // ── Availability ──
            _sectionTitle(context.tr('availability')),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: SwitchListTile(
                title: Text(context.tr('available_for_new'),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15)),
                subtitle: Text(context.tr('allow_students_requests'),
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
                  _toggle(context.tr('new_requests'), _newRequests, (v) async {
                    setState(() => _newRequests = v);
                    final uid = user?.uid;
                    if (uid != null) await _firestore.updateUser(uid, {'newRequestsNotif': v});
                  }),
                  _toggle(context.tr('messages'), _messageNotif, (v) async {
                    setState(() => _messageNotif = v);
                    final uid = user?.uid;
                    if (uid != null) await _firestore.updateUser(uid, {'messageNotif': v});
                  }),
                  _toggle(context.tr('student_updates'), _studentUpdates, (v) async {
                    setState(() => _studentUpdates = v);
                    final uid = user?.uid;
                    if (uid != null) await _firestore.updateUser(uid, {'studentUpdatesNotif': v});
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
                              Text(context.tr('theme'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w500)),
                              Text(isDark ? context.tr('using_dark_theme') : context.tr('using_light_theme'),
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
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.language_rounded, color: AppTheme.accentBlue),
                    title: Text(context.tr('language'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                    trailing: DropdownButton<String>(
                      value: loc.locale,
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
                          Provider.of<LocalizationService>(context, listen: false).setLocale(val);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.tr('language_updated')} $val')));
                        }
                      },
                    ),
                  ),
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
                  _navItem(Icons.help_outline_rounded, context.tr('help_faq'), _showHelpDialog),
                  Divider(height: 1),
                  _navItem(Icons.headset_mic_rounded, context.tr('contact_support'), _showContactSupportDialog),
                  Divider(height: 1),
                  _navItem(Icons.policy_rounded, context.tr('privacy_policy'), _showPrivacyPolicyDialog),
                  Divider(height: 1),
                  _navItem(Icons.info_outline_rounded, context.tr('about_app'), _showAboutAppDialog),
                ],
              ),
            ),
            SizedBox(height: 24),

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
                  Divider(height: 1, indent: 20, endIndent: 20),
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
        title: Text(context.tr('edit_profile'), style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: context.tr('name'),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: bioCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.tr('bio'),
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
            child: Text(context.tr('save')),
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
        title: Text(context.tr('change_password'), style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w700)),
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
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed));
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
        title: Row(children: [Icon(Icons.verified_rounded, color: AppTheme.successGreen, size: 24), SizedBox(width: 8), Text(context.tr('verification'))]),
        content: Text(context.tr('verified_mentor_desc')),
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
              _faq(context.tr('how_do_i_connect_with_students'), context.tr('how_do_i_connect_with_students_ans')),
              _faq(context.tr('how_do_i_schedule_meetings'), context.tr('how_do_i_schedule_meetings_ans')),
              _faq(context.tr('how_do_i_provide_feedback'), context.tr('how_do_i_provide_feedback_ans')),
              _faq(context.tr('how_do_i_send_reminders'), context.tr('how_do_i_send_reminders_ans')),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('ok')))],
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
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _contactRow(Icons.email_rounded, context.tr('email'), 'support@vidyasetu.app'),
          _contactRow(Icons.language_rounded, context.tr('website'), 'vidyasetu.app/help'),
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

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('privacy_policy')),
        content: SingleChildScrollView(child: Text(
          context.tr('vidyasetu_respects_your_privacy') +
          '\n• Your data is stored securely in Firebase.\n' +
          '• We do not share your information with third parties.\n' +
          '• Student data you mentor is kept confidential.\n' +
          '• You can delete your account at any time.\n\n' +
          'For full policy: vidyasetu.app/privacy',
        )),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('close')))],
      ),
    );
  }

  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('about_app')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _aboutRow(Icons.apps_rounded, context.tr('version'), '1.0.0'),
          _aboutRow(Icons.build_rounded, context.tr('build'), '2026.03.07'),
          _aboutRow(Icons.code_rounded, context.tr('framework'), 'Flutter'),
          _aboutRow(Icons.cloud_rounded, context.tr('backend'), 'Firebase'),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('ok')))],
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
        title: Text(context.tr('delete_account'), style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('are_you_sure_you_want_to_delete_account'), style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 12),
            Text(context.tr('delete_account_desc'), style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.warningAmber.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.warningAmber, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text(context.tr('scheduled_deletion_msg'), style: TextStyle(fontSize: 12, color: AppTheme.warningAmber, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('cancel'))),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final uid = auth.userModel?.uid;
              if (uid != null) {
                Navigator.pop(ctx);
                await auth.softDeleteAccount(uid);
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, elevation: 0),
            child: Text(context.tr('delete_forever'), style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
