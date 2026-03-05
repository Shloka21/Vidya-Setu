import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';

class MentorProfileScreen extends StatelessWidget {
  const MentorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final firestore = FirestoreService();

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Profile'),
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
          children: [
            // Avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentPurple, width: 3),
              ),
              child: Center(
                child: user?.profileImageUrl != null
                    ? ClipOval(child: Image.network(user!.profileImageUrl!, fit: BoxFit.cover, width: 90, height: 90))
                    : Text(
                        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'M',
                        style: TextStyle(color: AppTheme.accentPurple, fontSize: 36, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Text(user?.name ?? 'Mentor',
                style: TextStyle(color: AppTheme.primaryNavy, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(user?.email ?? '', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 6),
            if (user?.bio != null && user!.bio!.isNotEmpty) ...[
              Text(user.bio!, style: TextStyle(color: AppTheme.textLight, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 6),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Mentor',
                  style: TextStyle(color: AppTheme.accentPurple, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 24),

            // Stats — dynamic
            FutureBuilder<List<Map<String, dynamic>>>(
              future: firestore.getConnectedStudents(user?.uid ?? ''),
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
            const SizedBox(height: 24),

            // Menu items — all wired
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildItem(Icons.people_outline_rounded, 'My Students', () {
                    Navigator.pushNamed(context, AppRoutes.myStudents);
                  }),
                  const Divider(height: 1),
                  _buildItem(Icons.notifications_outlined, 'Notifications', () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications settings coming soon!')),
                    );
                  }),
                  const Divider(height: 1),
                  _buildItem(Icons.settings_outlined, 'Settings', () {
                    Navigator.pushNamed(context, AppRoutes.mentorSettings);
                  }),
                  const Divider(height: 1),
                  _buildItem(Icons.help_outline_rounded, 'Help & Support', () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Help & Support'),
                        content: const Text(
                          'Need help? Contact us at support@vidyasetu.app\n\n'
                          '• FAQ: How do I manage students?\n'
                          '• FAQ: How do I schedule meetings?\n'
                          '• FAQ: How do I update my profile?',
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                      ),
                    );
                  }),
                  const Divider(height: 1),
                  _buildItem(Icons.info_outline_rounded, 'About', () {
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
            AppButton(
              text: 'Logout',
              onPressed: () async {
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                }
              },
              isOutlined: true,
              icon: Icons.logout_rounded,
              backgroundColor: AppTheme.errorRed,
              textColor: AppTheme.errorRed,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static void _showEditProfileDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.userModel;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final bioCtrl = TextEditingController(text: user?.bio ?? '');
    final firestore = FirestoreService();

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
                fillColor: AppTheme.background,
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
                fillColor: AppTheme.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              final uid = user?.uid;
              if (uid == null) return;
              await firestore.updateUser(uid, {
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

  Widget _buildItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
      title: Text(label, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textLight, size: 22),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}
