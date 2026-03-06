import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  Future<void> _continue() async {
    if (_selectedRole == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.setUserRole(_selectedRole!);

    if (mounted) {
      if (_selectedRole == 'student') {
        // Check if student has created a timetable
        final user = authProvider.userModel;
        if (user != null && !user.isTimetableCreated) {
           Navigator.pushReplacementNamed(context, AppRoutes.generateTimetable);
        } else {
           Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard);
        }
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.mentorDashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Text(
                'Choose\nYour Role',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryNavy,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select how you want to use VidyaSetu',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),

              // Student card
              _buildRoleCard(
                role: 'student',
                title: "I'm a Student",
                description:
                    'Set reminders, manage timetables, track progress, and connect with mentors for guidance.',
                icon: Icons.school_rounded,
                color: AppTheme.accentBlue,
              ),
              const SizedBox(height: 20),

              // Mentor card
              _buildRoleCard(
                role: 'mentor',
                title: "I'm a Mentor",
                description:
                    'Guide students, track their progress, send feedback, and conduct video sessions.',
                icon: Icons.psychology_rounded,
                color: AppTheme.accentPurple,
              ),

              const Spacer(),

              // Continue button
              AppButton(
                text: 'Continue',
                onPressed: _selectedRole != null ? _continue : null,
                icon: Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryNavy : AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isSelected ? AppTheme.primaryNavy : AppTheme.divider,
            width: 2,
          ),
          boxShadow: isSelected
              ? AppTheme.elevatedShadow
              : AppTheme.cardBoxShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.15)
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

