import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_card.dart';

class MentorProfileViewScreen extends StatelessWidget {
  const MentorProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock mentor data (would come via route args in production)
    const mentor = {
      'name': 'Dr. Sharma',
      'specialization': 'Mathematics, Statistics',
      'bio': 'PhD in Applied Mathematics with 15 years of teaching experience. Passionate about making complex concepts simple and accessible for every student.',
      'rating': 4.8,
      'students': 24,
      'sessions': 156,
      'yearsExp': 15,
      'languages': 'Hindi, English',
      'availability': 'Mon-Fri, 4:00 PM - 8:00 PM',
    };

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentBlue,
                      AppTheme.accentPurple,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Center(
                          child: Text('D',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(mentor['name'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(mentor['specialization'] as String,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14)),
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
                  // Stats row
                  Row(
                    children: [
                      _buildStat('⭐', '${mentor['rating']}', 'Rating'),
                      _buildStat('👨‍🎓', '${mentor['students']}', 'Students'),
                      _buildStat('📹', '${mentor['sessions']}', 'Sessions'),
                      _buildStat('🎓', '${mentor['yearsExp']}y', 'Experience'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // About
                  Text('About',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Text(mentor['bio'] as String,
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            height: 1.6)),
                  ),
                  const SizedBox(height: 20),

                  // Details
                  Text('Details',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _detailItem(Icons.language_rounded, 'Languages',
                            mentor['languages'] as String),
                        const Divider(height: 1),
                        _detailItem(Icons.schedule_rounded, 'Availability',
                            mentor['availability'] as String),
                        const Divider(height: 1),
                        _detailItem(Icons.star_rounded, 'Specialization',
                            mentor['specialization'] as String),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reviews
                  Text('Recent Reviews',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _buildReview('Ananya K.', 5,
                      'Amazing mentor! Explains concepts so clearly.'),
                  _buildReview('Raj P.', 4,
                      'Very helpful with calculus problems.'),
                  _buildReview('Priya S.', 5,
                      'Best statistics tutor I have ever had!'),
                  const SizedBox(height: 24),

                  // CTA buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Send Request',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Mentor request sent successfully!')),
                            );
                          },
                          icon: Icons.person_add_rounded,
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

  Widget _buildStat(String emoji, String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentBlue, size: 22),
      title: Text(label,
          style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
      subtitle: Text(value,
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildReview(String name, int stars, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: Text(name[0],
                          style: TextStyle(
                              color: AppTheme.accentPurple,
                              fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                      5,
                      (i) => Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppTheme.warningAmber,
                          size: 16)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(text,
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
