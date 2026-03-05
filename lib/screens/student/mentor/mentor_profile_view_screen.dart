import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_card.dart';

class MentorProfileViewScreen extends StatelessWidget {
  const MentorProfileViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    // Fallback to mock data if no args (development)
    final mentor = args ?? {
      'name': 'Dr. Sharma',
      'subjectsTaught': ['Mathematics', 'Statistics'],
      'bio': 'PhD in Applied Mathematics with 15 years of teaching experience. Passionate about making complex concepts simple and accessible for every student.',
      'rating': 4.8,
      'studentCount': 24,
      'sessions': 156,
      'experienceYears': 15,
      'languages': 'Hindi, English',
      'availability': 'Mon-Fri, 4:00 PM - 8:00 PM',
    };

    final mentorName = mentor['name']?.toString() ?? 'Mentor';
    final subjects = List<String>.from(mentor['subjectsTaught'] ?? []);
    final specialization = subjects.isNotEmpty ? subjects.join(', ') : (mentor['specialization']?.toString() ?? 'General');
    final bio = mentor['bio']?.toString() ?? 'No bio provided.';

    return Scaffold(
      
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
                        child: Center(
                          child: Text(mentorName.isNotEmpty ? mentorName[0].toUpperCase() : 'M',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(mentorName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(specialization,
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
                      _buildStat('👨‍🎓', '${mentor['studentCount'] ?? 0}', 'Students'),
                      _buildStat('📹', '${mentor['sessions'] ?? 0}', 'Sessions'),
                      _buildStat('🎓', '${mentor['experienceYears'] ?? 0}y', 'Experience'),
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
                    child: Text(bio,
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
                            mentor['languages']?.toString() ?? 'English'),
                        const Divider(height: 1),
                        _detailItem(Icons.schedule_rounded, 'Availability',
                            mentor['availability']?.toString() ?? 'Flexible'),
                        const Divider(height: 1),
                        _detailItem(Icons.star_rounded, 'Specialization',
                            specialization),
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
