import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/app_button.dart';

class StudentProfileMentorView extends StatelessWidget {
  const StudentProfileMentorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.accentPurple, AppTheme.accentBlue],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Center(
                          child: Text('A',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text('Ananya Kumar',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      Text('Class 12 • CBSE',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13)),
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
                  // Stats
                  Row(
                    children: [
                      _stat('Level', '5', AppTheme.accentBlue),
                      _stat('XP', '1240', AppTheme.accentPurple),
                      _stat('Streak', '12d', AppTheme.warningAmber),
                      _stat('Hours', '86', AppTheme.successGreen),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Progress overview
                  _section('Study Progress'),
                  AppCard(
                    child: Column(
                      children: [
                        _progressRow('Mathematics', 0.75, AppTheme.accentBlue),
                        const SizedBox(height: 12),
                        _progressRow('Physics', 0.60, AppTheme.accentPurple),
                        const SizedBox(height: 12),
                        _progressRow('Chemistry', 0.45, AppTheme.warningAmber),
                        const SizedBox(height: 12),
                        _progressRow('English', 0.85, AppTheme.successGreen),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent activity
                  _section('Recent Activity'),
                  _activityItem(Icons.timer_rounded, 'Completed 2h Math session',
                      '2 hours ago', AppTheme.accentBlue),
                  _activityItem(Icons.emoji_events_rounded, 'Earned "Math Wizard" badge',
                      'Yesterday', AppTheme.warningAmber),
                  _activityItem(Icons.check_circle_rounded, 'Finished Algebra chapter',
                      '2 days ago', AppTheme.successGreen),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Send Feedback',
                          onPressed: () {},
                          icon: Icons.feedback_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: 'Message',
                          onPressed: () {},
                          icon: Icons.chat_rounded,
                          isOutlined: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700)),
    );
  }

  Widget _progressRow(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppTheme.divider,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('${(value * 100).toInt()}%',
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _activityItem(
      IconData icon, String text, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text,
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(time,
                      style: TextStyle(
                          color: AppTheme.textLight, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
