import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/stat_card.dart';
import '../../../widgets/common/bottom_nav_bar.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _buildBody(),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          switch (index) {
            case 1:
              Navigator.pushNamed(context, AppRoutes.myStudents);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.achievements);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.chatList);
              break;
            case 4:
              Navigator.pushNamed(context, AppRoutes.mentorProfileScreen);
              break;
          }
        },
        items: const [
          AppNavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'Home',
          ),
          AppNavItem(
            icon: Icons.people_outline_rounded,
            activeIcon: Icons.people_rounded,
            label: 'Students',
          ),
          AppNavItem(
            icon: Icons.emoji_events_outlined,
            activeIcon: Icons.emoji_events_rounded,
            label: 'Arena',
          ),
          AppNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
            label: 'Messages',
          ),
          AppNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildQuickStats(),
            const SizedBox(height: 24),
            _buildStudentActivity(),
            const SizedBox(height: 24),
            _buildTodaySchedule(),
            const SizedBox(height: 24),
            _buildRecentAlerts(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final now = DateTime.now();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VidyaSetu',
                        style: TextStyle(
                          color: AppTheme.primaryNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMM d').format(now).toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome back,\n${user?.name ?? "Mentor"}!',
                style: TextStyle(
                  color: AppTheme.primaryNavy,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.mentorProfileScreen),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.successGreen,
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : 'M',
                    style: TextStyle(
                      color: AppTheme.accentPurple,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardBoxShadow,
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.textSecondary,
                size: 22,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final user = Provider.of<AuthProvider>(context).userModel;

    return SizedBox(
      height: 160,
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Total Students',
              value: '${user?.studentCount ?? 0}',
              icon: Icons.people_rounded,
              iconColor: AppTheme.accentBlue,
              iconBgColor: AppTheme.accentBlue.withOpacity(0.1),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: StatCard(
              label: 'Pending\nRequests',
              value: '0',
              icon: Icons.person_add_rounded,
              isDark: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Student Activity',
              style: TextStyle(
                color: AppTheme.primaryNavy,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.myStudents),
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStudentActivityItem(
          'Emma Taylor',
          'Active now • Studying Physics',
          Colors.green,
        ),
        const SizedBox(height: 10),
        _buildStudentActivityItem(
          'Rushabh Shah',
          'Last active 2h ago',
          Colors.orange,
        ),
        const SizedBox(height: 10),
        _buildStudentActivityItem(
          'Riya Malhotra',
          'Inactive for 3 days',
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStudentActivityItem(
    String name,
    String status,
    Color statusColor,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name[0],
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        status,
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppTheme.primaryNavy,
              size: 20,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Sessions",
          style: TextStyle(
            color: AppTheme.primaryNavy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.videocam_rounded,
                      color: AppTheme.accentBlue, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Video Call with Emma Taylor',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '3:00 PM - Physics Doubt Session',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Join',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alerts',
          style: TextStyle(
            color: AppTheme.primaryNavy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildAlertItem(
          'Student missed 3 sessions',
          'Riya Malhotra needs attention',
          Icons.warning_rounded,
          AppTheme.errorRed,
        ),
        const SizedBox(height: 10),
        _buildAlertItem(
          'New connection request',
          'Arjun wants to connect',
          Icons.person_add_rounded,
          AppTheme.accentBlue,
        ),
      ],
    );
  }

  Widget _buildAlertItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
        ],
      ),
    );
  }
}
