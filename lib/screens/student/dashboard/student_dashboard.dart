import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/stat_card.dart';
import '../../../widgets/common/bottom_nav_bar.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
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
              Navigator.pushNamed(context, AppRoutes.timetableOverview);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.remindersList);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.progressDashboard);
              break;
            case 4:
              Navigator.pushNamed(context, AppRoutes.studentProfile);
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
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month_rounded,
            label: 'Timetable',
          ),
          AppNavItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications_rounded,
            label: 'Reminders',
          ),
          AppNavItem(
            icon: Icons.bar_chart_outlined,
            activeIcon: Icons.bar_chart_rounded,
            label: 'Analytics',
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
            _buildUpcomingSection(),
            const SizedBox(height: 24),
            _buildTodaySchedule(),
            const SizedBox(height: 24),
            _buildQuickActions(),
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
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App branding
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
                '$greeting,\n${user?.name ?? "Student"}!',
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
            // Profile avatar
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.studentProfile),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.successGreen,
                    width: 2.5,
                  ),
                ),
                child: user?.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user!.profileImageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        user?.name.isNotEmpty == true
                            ? user!.name[0].toUpperCase()
                            : 'S',
                        style: TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            // Notification bell
            GestureDetector(
              onTap: () {},
              child: Container(
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
              label: "Today's Tasks",
              value: '${user?.tasksCompleted ?? 0}',
              icon: Icons.task_alt_rounded,
              iconColor: AppTheme.successGreen,
              iconBgColor: AppTheme.successGreen.withOpacity(0.1),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: StatCard(
              label: 'Study Streak',
              value: '${user?.streak ?? 0}',
              icon: Icons.local_fire_department_rounded,
              isDark: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming',
              style: TextStyle(
                color: AppTheme.primaryNavy,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.remindersList),
              child: Text(
                'See All',
                style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Placeholder upcoming items
        _buildUpcomingItem(
          'Mathematics Exam',
          'Tomorrow, 10:00 AM',
          Icons.quiz_rounded,
          AppTheme.errorRed,
        ),
        const SizedBox(height: 10),
        _buildUpcomingItem(
          'Physics Assignment',
          'Feb 16, 5:00 PM',
          Icons.assignment_rounded,
          AppTheme.warningAmber,
        ),
        const SizedBox(height: 10),
        _buildUpcomingItem(
          'Chemistry Study Session',
          'Today, 8:00 PM',
          Icons.menu_book_rounded,
          AppTheme.successGreen,
        ),
      ],
    );
  }

  Widget _buildUpcomingItem(
    String title,
    String time,
    IconData icon,
    Color priorityColor,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: priorityColor, size: 22),
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
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.check_circle_outline_rounded,
              color: AppTheme.textLight,
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
          "Today's Schedule",
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
              _buildScheduleItem('9:00 AM', 'Mathematics', true),
              const Divider(height: 24),
              _buildScheduleItem('10:30 AM', 'Physics', false),
              const Divider(height: 24),
              _buildScheduleItem('2:00 PM', 'Chemistry', false),
              const Divider(height: 24),
              _buildScheduleItem('4:00 PM', 'English', false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(String time, String subject, bool isCurrent) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            time,
            style: TextStyle(
              color: isCurrent ? AppTheme.accentBlue : AppTheme.textLight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: isCurrent ? AppTheme.accentBlue : AppTheme.divider,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppTheme.accentBlue.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              subject,
              style: TextStyle(
                color: isCurrent ? AppTheme.accentBlue : AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: AppTheme.primaryNavy,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Reminders',
                Icons.notifications_active_rounded,
                AppTheme.accentBlue,
                () => Navigator.pushNamed(context, AppRoutes.remindersList),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Timetable',
                Icons.calendar_month_rounded,
                AppTheme.accentPurple,
                () => Navigator.pushNamed(context, AppRoutes.timetableOverview),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Mentors',
                Icons.people_rounded,
                AppTheme.successGreen,
                () => Navigator.pushNamed(context, AppRoutes.findMentor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
