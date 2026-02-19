import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';

class MentorProfileScreen extends StatelessWidget {
  const MentorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_rounded), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentPurple, width: 3),
              ),
              child: Center(
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'M',
                  style: TextStyle(
                    color: AppTheme.accentPurple,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              user?.name ?? 'Mentor',
              style: TextStyle(color: AppTheme.primaryNavy, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(user?.email ?? '', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Mentor',
                style: TextStyle(
                  color: AppTheme.accentPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                _buildStat('Students', '${user?.studentCount ?? 0}', AppTheme.accentBlue),
                _buildStat('Rating', '4.9', AppTheme.warningAmber),
                _buildStat('Sessions', '0', AppTheme.successGreen),
              ],
            ),
            const SizedBox(height: 24),

            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildItem(Icons.people_outline_rounded, 'My Students', () {
                    Navigator.pushNamed(context, AppRoutes.myStudents);
                  }),
                  const Divider(height: 1),
                  _buildItem(Icons.notifications_outlined, 'Notifications', () {}),
                  const Divider(height: 1),
                  _buildItem(Icons.settings_outlined, 'Settings', () {}),
                  const Divider(height: 1),
                  _buildItem(Icons.help_outline_rounded, 'Help & Support', () {}),
                  const Divider(height: 1),
                  _buildItem(Icons.info_outline_rounded, 'About', () {}),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
