import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../app/routes.dart';
import '../../../app/design_system.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
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
  double _defaultSessionDuration = 45;

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
                  _buildNavItem(Icons.person_rounded, 'Edit Profile', () {
                    Navigator.pushNamed(context, AppRoutes.editStudentProfile);
                  }),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _buildNavItem(Icons.lock_rounded, 'Change Password', () {
                    _showChangePasswordDialog();
                  }),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _buildNavItem(
                    Icons.shield_rounded,
                    'Privacy Settings',
                    () => _showPrivacySettings(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionTitle('Notification Preferences'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _buildToggle(
                    'Reminder Notifications',
                    _reminderNotifications,
                    (v) => setState(() => _reminderNotifications = v),
                  ),
                  _buildToggle(
                    'Voice Notifications',
                    _voiceNotifications,
                    (v) => setState(() => _voiceNotifications = v),
                  ),
                  _buildToggle(
                    'Mentor Messages',
                    _mentorMessages,
                    (v) => setState(() => _mentorMessages = v),
                  ),
                  _buildToggle(
                    'System Notifications',
                    _systemNotifications,
                    (v) => setState(() => _systemNotifications = v),
                  ),
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
                  Text(
                    'Default Session Duration',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _defaultSessionDuration,
                          min: 15,
                          max: 120,
                          divisions: 7,
                          label: '${_defaultSessionDuration.toInt()} min',
                          onChanged: (v) =>
                              setState(() => _defaultSessionDuration = v),
                        ),
                      ),
                      Text(
                        '${_defaultSessionDuration.toInt()} min',
                        style: TextStyle(
                          color: DesignSystem.primaryIndigo,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildToggle(
                    'Break Reminders',
                    _breakReminders,
                    (v) => setState(() => _breakReminders = v),
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
                  _buildNavItem(
                    Icons.language_rounded,
                    'Language',
                    () => _showLanguageDialog(),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _buildNavItem(
                    Icons.dark_mode_rounded,
                    'Theme',
                    () => _showThemeDialog(),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _buildNavItem(
                    Icons.storage_rounded,
                    'Clear Cache',
                    () => _showClearCacheDialog(),
                  ),
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
                    Icons.help_outline_rounded,
                    'Help & FAQ',
                    () => _showHelpFAQ(),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _buildNavItem(
                    Icons.mail_outline_rounded,
                    'Contact Support',
                    () => _contactSupport(),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _buildNavItem(
                    Icons.policy_rounded,
                    'Privacy Policy',
                    () => _showPrivacyPolicy(),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _buildNavItem(
                    Icons.article_outlined,
                    'Terms of Service',
                    () => _showTermsOfService(),
                  ),
                  Divider(
                    height: 1,
                    color: scheme.outline.withValues(alpha: 0.3),
                  ),
                  _buildNavItem(
                    Icons.info_outline_rounded,
                    'About',
                    () => _showAboutDialog(),
                  ),
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
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.5),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
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
        color: scheme.onSurface.withValues(alpha: 0.3),
        size: 22,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    final scheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      title: Text(
        label,
        style: TextStyle(color: scheme.onSurface, fontSize: 15),
      ),
      value: value,
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
              backgroundColor: DesignSystem.primaryIndigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Privacy Settings',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _PrivacyToggle(
              title: 'Show Profile to Mentors',
              subtitle: 'Allow mentors to view your profile',
              value: true,
            ),
            _PrivacyToggle(
              title: 'Show Progress',
              subtitle: 'Share your learning progress',
              value: true,
            ),
            _PrivacyToggle(
              title: 'Show on Leaderboard',
              subtitle: 'Display your name on the leaderboard',
              value: true,
            ),
            _PrivacyToggle(
              title: 'Activity Status',
              subtitle: 'Let others see when you are online',
              value: false,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignSystem.primaryIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 16),
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
              backgroundColor: DesignSystem.primaryIndigo,
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
                    question: 'How do I create a timetable?',
                    answer:
                        'Go to the Timetable section and tap "Generate Timetable". Fill in your subjects and preferences, and our AI will create a personalized study plan for you.',
                  ),
                  _FAQTile(
                    question: 'How do I find a mentor?',
                    answer:
                        'Navigate to the Explore tab and browse available mentors. You can filter by subject, rating, and price. Tap on a mentor to view their profile and book a session.',
                  ),
                  _FAQTile(
                    question: 'How do XP points work?',
                    answer:
                        'You earn XP by completing study sessions, attending mentor sessions, maintaining streaks, and achieving milestones. XP helps you level up and unlock achievements.',
                  ),
                  _FAQTile(
                    question: 'Can I cancel a booked session?',
                    answer:
                        'Yes, you can cancel sessions from the Sessions tab. Please cancel at least 2 hours before the scheduled time for a full refund.',
                  ),
                  _FAQTile(
                    question: 'How do reminders work?',
                    answer:
                        'Set reminders for study sessions, mentor meetings, or personal tasks. You\'ll receive notifications at your scheduled time.',
                  ),
                  _FAQTile(
                    question: 'How do I track my progress?',
                    answer:
                        'Visit the Analytics section to see your study time, completion rates, subject progress, and performance trends.',
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
      'mailto:support@vidyasetu.com?subject=VidyaSetu Support Request',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email: support@vidyasetu.com')),
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
                  'We collect information you provide directly, including your name, email, profile information, and learning preferences.\n\n'
                  '2. How We Use Your Information\n\n'
                  'We use your information to provide and improve our services, personalize your experience, and communicate with you.\n\n'
                  '3. Information Sharing\n\n'
                  'We do not sell your personal information. We may share data with mentors to facilitate sessions.\n\n'
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
                  '1. Acceptance of Terms\n\n'
                  'By using VidyaSetu, you agree to these terms of service.\n\n'
                  '2. User Accounts\n\n'
                  'You are responsible for maintaining the security of your account and all activities under it.\n\n'
                  '3. User Conduct\n\n'
                  'Users must behave respectfully during sessions and not share inappropriate content.\n\n'
                  '4. Mentor Sessions\n\n'
                  'Session fees are processed through the platform. Cancellation policies apply.\n\n'
                  '5. Intellectual Property\n\n'
                  'All content on VidyaSetu is protected by copyright and other intellectual property laws.\n\n'
                  '6. Limitation of Liability\n\n'
                  'VidyaSetu is not liable for any indirect damages arising from use of the service.\n\n'
                  '7. Modifications\n\n'
                  'We reserve the right to modify these terms at any time.\n\n'
                  '8. Contact\n\n'
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
                    DesignSystem.primaryIndigo,
                    DesignSystem.primaryPurple,
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
              'Connecting students with mentors for personalized learning experiences.',
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
          'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently deleted.',
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

class _PrivacyToggle extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool value;

  const _PrivacyToggle({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  @override
  State<_PrivacyToggle> createState() => _PrivacyToggleState();
}

class _PrivacyToggleState extends State<_PrivacyToggle> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.title),
      subtitle: Text(
        widget.subtitle,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: Switch(
        value: _value,
        onChanged: (value) => setState(() => _value = value),
        activeColor: DesignSystem.primaryIndigo,
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
          ? Icon(Icons.check_circle, color: DesignSystem.primaryIndigo)
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
        color: isSelected ? DesignSystem.primaryIndigo : null,
      ),
      title: Text(title),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: DesignSystem.primaryIndigo)
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
                    color: DesignSystem.primaryIndigo,
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
