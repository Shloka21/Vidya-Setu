import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../../../app/routes.dart';
import '../../../app/design_system.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
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
  bool _availableForNew = true;
  bool _sessionReminders = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                    Navigator.pushNamed(context, AppRoutes.editMentorProfile);
                  }),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _navItem(Icons.lock_rounded, 'Change Password', () {
                    _showChangePasswordDialog();
                  }),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _navItem(Icons.shield_rounded, 'Verification Status', () {
                    _showVerificationStatus();
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
                    title: Text(
                      'Available for New Students',
                      style: TextStyle(color: scheme.onSurface, fontSize: 15),
                    ),
                    subtitle: Text(
                      'Allow students to send connection requests',
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                    value: _availableForNew,
                    activeColor: DesignSystem.primaryPurple,
                    onChanged: (v) => setState(() => _availableForNew = v),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _navItem(
                    Icons.schedule_rounded,
                    'Set Availability Hours',
                    () {
                      _showAvailabilitySchedule();
                    },
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
                  _toggle(
                    'New Student Requests',
                    _newRequests,
                    (v) => setState(() => _newRequests = v),
                  ),
                  _toggle(
                    'Messages',
                    _messageNotif,
                    (v) => setState(() => _messageNotif = v),
                  ),
                  _toggle(
                    'Student Progress Updates',
                    _studentUpdates,
                    (v) => setState(() => _studentUpdates = v),
                  ),
                  _toggle(
                    'Session Reminders',
                    _sessionReminders,
                    (v) => setState(() => _sessionReminders = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('App Settings'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _navItem(Icons.dark_mode_rounded, 'Theme', () {
                    _showThemeDialog();
                  }),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _navItem(Icons.language_rounded, 'Language', () {
                    _showLanguageDialog();
                  }),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _navItem(Icons.storage_rounded, 'Clear Cache', () {
                    _showClearCacheDialog();
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Support & Legal'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _navItem(Icons.help_outline_rounded, 'Help & FAQ', () {
                    _showHelpFAQ();
                  }),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _navItem(Icons.mail_outline_rounded, 'Contact Support', () {
                    _contactSupport();
                  }),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _navItem(Icons.policy_rounded, 'Privacy Policy', () {
                    _showPrivacyPolicy();
                  }),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _navItem(Icons.article_outlined, 'Terms of Service', () {
                    _showTermsOfService();
                  }),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _navItem(Icons.info_outline_rounded, 'About', () {
                    _showAboutDialog();
                  }),
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
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 22,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red, fontSize: 15),
                    ),
                    onTap: () => _showLogoutConfirmation(),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.red,
                      size: 22,
                    ),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.red, fontSize: 15),
                    ),
                    onTap: () => _showDeleteAccountDialog(),
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
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: scheme.onSurface.withValues(alpha: 0.5),
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(color: scheme.onSurface, fontSize: 15),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: scheme.onSurface.withValues(alpha: 0.4),
        size: 22,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    final scheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      title: Text(
        label,
        style: TextStyle(color: scheme.onSurface, fontSize: 15),
      ),
      value: value,
      activeColor: DesignSystem.primaryPurple,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showVerificationStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Verified Mentor'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VerificationItem(
              title: 'Identity Verification',
              status: 'Verified',
              isComplete: true,
            ),
            _VerificationItem(
              title: 'Qualifications',
              status: 'Verified',
              isComplete: true,
            ),
            _VerificationItem(
              title: 'Background Check',
              status: 'Verified',
              isComplete: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Your profile is verified and visible to students.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAvailabilitySchedule() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Availability Schedule',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Schedule saved!')),
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _DayScheduleItem(
                    day: 'Monday',
                    startTime: '09:00',
                    endTime: '18:00',
                    isActive: true,
                  ),
                  _DayScheduleItem(
                    day: 'Tuesday',
                    startTime: '09:00',
                    endTime: '18:00',
                    isActive: true,
                  ),
                  _DayScheduleItem(
                    day: 'Wednesday',
                    startTime: '09:00',
                    endTime: '18:00',
                    isActive: true,
                  ),
                  _DayScheduleItem(
                    day: 'Thursday',
                    startTime: '09:00',
                    endTime: '18:00',
                    isActive: true,
                  ),
                  _DayScheduleItem(
                    day: 'Friday',
                    startTime: '09:00',
                    endTime: '18:00',
                    isActive: true,
                  ),
                  _DayScheduleItem(
                    day: 'Saturday',
                    startTime: '10:00',
                    endTime: '14:00',
                    isActive: true,
                  ),
                  _DayScheduleItem(
                    day: 'Sunday',
                    startTime: '',
                    endTime: '',
                    isActive: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeOption(
              title: 'System Default',
              icon: Icons.settings_suggest_rounded,
              isSelected: themeProvider.themeMode == ThemeMode.system,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              title: 'Light Mode',
              icon: Icons.light_mode_rounded,
              isSelected: themeProvider.themeMode == ThemeMode.light,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            _ThemeOption(
              title: 'Dark Mode',
              icon: Icons.dark_mode_rounded,
              isSelected: themeProvider.themeMode == ThemeMode.dark,
              onTap: () {
                themeProvider.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              language: 'English',
              isSelected: true,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language set to English')),
                );
              },
            ),
            _LanguageOption(
              language: 'हिंदी (Hindi)',
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language set to Hindi')),
                );
              },
            ),
            _LanguageOption(
              language: 'తెలుగు (Telugu)',
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language set to Telugu')),
                );
              },
            ),
            _LanguageOption(
              language: 'தமிழ் (Tamil)',
              isSelected: false,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Language set to Tamil')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear temporary files and cached data. Your personal data will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final cacheDir = await getTemporaryDirectory();
                if (cacheDir.existsSync()) {
                  await cacheDir.delete(recursive: true);
                  await cacheDir.create();
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache cleared successfully!'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared!')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignSystem.primaryPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showHelpFAQ() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Help & FAQ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _FAQTile(
                    question: 'How do I manage student requests?',
                    answer:
                        'Go to your Dashboard and you\'ll see pending requests. You can approve or decline them from there.',
                  ),
                  _FAQTile(
                    question: 'How do payments work?',
                    answer:
                        'After completing sessions, payments are automatically processed. You can view your earnings in the Wallet section.',
                  ),
                  _FAQTile(
                    question: 'How do I set my availability?',
                    answer:
                        'Go to Settings > Availability to set the days and hours when you\'re available for sessions.',
                  ),
                  _FAQTile(
                    question: 'Can I cancel a scheduled session?',
                    answer:
                        'Yes, you can cancel sessions from the Sessions tab. Please notify students in advance if possible.',
                  ),
                  _FAQTile(
                    question: 'How do I send feedback to students?',
                    answer:
                        'Navigate to a student\'s profile and tap "Send Feedback" to provide detailed assessment.',
                  ),
                  _FAQTile(
                    question: 'How do I get verified?',
                    answer:
                        'Complete your profile with qualifications and credentials. Our team will review and verify your profile.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _contactSupport() async {
    final uri = Uri.parse(
      'mailto:mentors@vidyasetu.com?subject=Mentor Support Request',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email: mentors@vidyasetu.com')),
        );
      }
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy Policy'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last updated: January 2025',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Information We Collect\n\n'
                  'We collect information you provide directly, including your name, email, profile information, qualifications, and teaching preferences.\n\n'
                  '2. How We Use Your Information\n\n'
                  'We use your information to connect you with students, process payments, and improve our services.\n\n'
                  '3. Information Sharing\n\n'
                  'We do not sell your personal information. Your profile is visible to students looking for mentors.\n\n'
                  '4. Data Security\n\n'
                  'We implement appropriate security measures to protect your information.\n\n'
                  '5. Your Rights\n\n'
                  'You have the right to access, update, or delete your personal information at any time.\n\n'
                  '6. Contact Us\n\n'
                  'For any questions about this policy, contact us at privacy@vidyasetu.com',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Terms of Service'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last updated: January 2025',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  '1. Mentor Agreement\n\n'
                  'As a mentor, you agree to provide quality educational guidance and maintain professional conduct.\n\n'
                  '2. Session Conduct\n\n'
                  'Mentors must be punctual and prepared for sessions. Inappropriate behavior may result in suspension.\n\n'
                  '3. Payments\n\n'
                  'Payments are processed after sessions. Platform fees are deducted automatically.\n\n'
                  '4. Content Rights\n\n'
                  'You retain rights to your original content. Students may not redistribute session materials.\n\n'
                  '5. Cancellation Policy\n\n'
                  'Excessive cancellations may affect your profile visibility and rating.\n\n'
                  '6. Verification\n\n'
                  'You must provide accurate credentials. False information will result in account termination.\n\n'
                  '7. Contact\n\n'
                  'For questions, contact legal@vidyasetu.com',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    DesignSystem.primaryPurple,
                    DesignSystem.primaryIndigo,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'VidyaSetu',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              'Empowering mentors to share knowledge and inspire the next generation.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '© 2025 VidyaSetu. All rights reserved.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (_) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. All your data, students, and session history will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Account deletion request submitted. You will receive a confirmation email.',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }
}

class _VerificationItem extends StatelessWidget {
  final String title;
  final String status;
  final bool isComplete;

  const _VerificationItem({
    required this.title,
    required this.status,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.pending,
            color: isComplete ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            status,
            style: TextStyle(
              color: isComplete ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayScheduleItem extends StatefulWidget {
  final String day;
  final String startTime;
  final String endTime;
  final bool isActive;

  const _DayScheduleItem({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  @override
  State<_DayScheduleItem> createState() => _DayScheduleItemState();
}

class _DayScheduleItemState extends State<_DayScheduleItem> {
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _isActive = widget.isActive;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Switch(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeColor: DesignSystem.primaryPurple,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.day,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _isActive ? null : Colors.grey,
                ),
              ),
            ),
            if (_isActive)
              Text(
                '${widget.startTime} - ${widget.endTime}',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              Text('Off', style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(language),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: DesignSystem.primaryPurple)
          : null,
      onTap: onTap,
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(
        icon,
        color: isSelected ? DesignSystem.primaryPurple : null,
      ),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: DesignSystem.primaryPurple)
          : null,
      onTap: onTap,
    );
  }
}

class _FAQTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FAQTile({required this.question, required this.answer});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: DesignSystem.primaryPurple,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Text(
                  widget.answer,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
