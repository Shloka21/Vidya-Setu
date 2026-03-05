import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/app_card.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;

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
                            ? ClipOval(
                                child: Image.network(user!.profileImageUrl!, fit: BoxFit.cover),
                              )
                            : Center(
                                child: Text(
                                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'S',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'Student',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
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
                icon: const Icon(Icons.settings_rounded, color: Colors.white),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.studentSettings),
              ),
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
                  // Stats row
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

                  // Bio section
                  if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                    _sectionTitle('ABOUT ME'),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        user.bio!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Achievements preview
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
                  const SizedBox(height: 24),

                  // Settings section
                  _sectionTitle('PREFERENCES'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          context,
                          Icons.notifications_outlined,
                          'Notifications',
                          Colors.blue,
                          () => Navigator.pushNamed(context, AppRoutes.studentSettings),
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildSettingsItem(
                          context,
                          Icons.language_rounded,
                          'Language',
                          Colors.teal,
                          () => _showLanguageDialog(context),
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildSettingsItem(
                          context,
                          Icons.palette_outlined,
                          'Theme',
                          AppTheme.accentPurple,
                          () => _showThemeDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle('SUPPORT'),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          context,
                          Icons.help_outline_rounded,
                          'Help & Support',
                          AppTheme.successGreen,
                          () => _showHelpDialog(context),
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildSettingsItem(
                          context,
                          Icons.privacy_tip_outlined,
                          'Privacy Policy',
                          AppTheme.warningAmber,
                          () => _showPrivacyDialog(context),
                        ),
                        const Divider(height: 1, indent: 56),
                        _buildSettingsItem(
                          context,
                          Icons.info_outline_rounded,
                          'About',
                          AppTheme.accentBlue,
                          () => _showAboutDialog(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.errorRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded, color: AppTheme.errorRed, size: 20),
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600),
                      ),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to log out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text('Logout', style: TextStyle(color: AppTheme.errorRed)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await Provider.of<AuthProvider>(context, listen: false).signOut();
                          if (context.mounted) {
                            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
                          }
                        }
                      },
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 12, fontWeight: FontWeight.w600),
            ),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: unlocked ? AppTheme.warningAmber.withOpacity(0.1) : AppTheme.divider,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: TextStyle(fontSize: 22, color: unlocked ? null : Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: unlocked ? AppTheme.textPrimary : AppTheme.textLight,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
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
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight, size: 22),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────

  void _showLanguageDialog(BuildContext context) {
    String selected = 'English';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Choose Language'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['English', 'Hindi', 'Marathi', 'Tamil', 'Telugu'].map((lang) {
              return RadioListTile<String>(
                title: Text(lang),
                value: lang,
                groupValue: selected,
                activeColor: AppTheme.accentBlue,
                onChanged: (v) => setDialogState(() => selected = v!),
              );
            }).toList(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Language set to $selected')),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        );
      }),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode_rounded, color: AppTheme.warningAmber),
              title: const Text('Light'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Light theme active')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded, color: AppTheme.primaryNavy),
              title: const Text('Dark'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dark theme coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('FAQ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            SizedBox(height: 8),
            Text('Q: How do I generate a timetable?\nA: Go to Timetable → Generate New → Upload your syllabus PDF.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            SizedBox(height: 12),
            Text('Q: How do I connect with a mentor?\nA: Go to Mentors → Browse and send a request.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            SizedBox(height: 16),
            Text('Contact Us', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            SizedBox(height: 4),
            Text('Email: support@vidyasetu.app',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'VidyaSetu respects your privacy.\n\n'
            '• We collect only the data necessary to provide our services.\n'
            '• Your study data and chat messages are stored securely on Firebase.\n'
            '• We do not share your personal information with third parties.\n'
            '• You can delete your account and all associated data at any time from Settings.\n\n'
            'For the full privacy policy, visit our website.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('VidyaSetu'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Version 1.0.0', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            SizedBox(height: 12),
            Text(
              'VidyaSetu is an AI-powered study companion that helps students '
              'create personalized study plans, track progress, and connect with mentors.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
            ),
            SizedBox(height: 12),
            Text('Made with ❤️ for students everywhere.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
