import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../widgets/common/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      icon: Icons.notifications_active_rounded,
      title: 'Smart Reminders',
      subtitle: 'Never miss deadlines',
      description:
          'Set intelligent reminders for exams, assignments, and study sessions with voice and push notifications.',
      color: AppTheme.accentBlue,
    ),
    OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'AI-Powered Timetables',
      subtitle: 'Study smarter, not harder',
      description:
          'Upload your syllabus and get an optimized study schedule generated automatically. Track your progress daily.',
      color: AppTheme.accentPurple,
    ),
    OnboardingSlide(
      icon: Icons.people_rounded,
      title: 'Mentor Guidance',
      subtitle: 'Get expert help anytime',
      description:
          'Connect with experienced mentors for personalized guidance, feedback, and video sessions.',
      color: AppTheme.successGreen,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.4),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index]);
                },
              ),
            ),

            // Page Indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? scheme.primary
                          : scheme.onSurface.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: AppButton(
                text: _currentPage == _slides.length - 1
                    ? 'Get Started'
                    : 'Next',
                onPressed: _nextPage,
                icon: _currentPage == _slides.length - 1
                    ? Icons.arrow_forward_rounded
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingSlide slide) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glow ring
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: slide.color.withOpacity(isDark ? 0.08 : 0.06),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: slide.color.withOpacity(isDark ? 0.15 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(slide.icon, size: 44, color: slide.color),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // Subtitle label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: slide.color.withOpacity(isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              slide.subtitle.toUpperCase(),
              style: TextStyle(
                color: slide.color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.5),
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingSlide {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final Color color;

  const OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.color,
  });
}
