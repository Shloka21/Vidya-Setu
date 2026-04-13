import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../app/routes.dart';
import 'package:vidyasetu/services/localization_service.dart';
import 'package:flutter/services.dart';

class FocusBlockedScreen extends StatelessWidget {
  const FocusBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Blocking Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.errorRed.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.block_rounded, color: AppTheme.errorRed, size: 60),
              ),
              const SizedBox(height: 40),

              // Warning Title
              Text(
                context.tr('focus_mode_active') ?? 'Focus Mode Active 🚫',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                context.tr('app_blocked_desc') ?? 'This app is blocked during your study session.\nStay focused on your goals! 💪',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Just return to VidyaSetu (which we are already in)
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.focusMode, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    context.tr('resume_study') ?? 'Resume Study',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    // Send stop signal to native if needed and pop
                    const MethodChannel('com.example.vidyasetu/app_blocker').invokeMethod('stopBlocking');
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.studentDashboard, (route) => false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.7),
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    context.tr('exit_focus_mode') ?? 'Exit Focus Mode',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
