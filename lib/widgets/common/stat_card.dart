import 'package:flutter/material.dart';
import '../../app/theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final bool isDark;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.iconBgColor,
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.primaryNavy : AppTheme.surface,
          gradient: isDark ? AppTheme.navyGradient : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.cardBoxShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.15)
                    : (iconBgColor ?? AppTheme.accentBlue.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                color: isDark
                    ? Colors.white
                    : (iconColor ?? AppTheme.accentBlue),
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : AppTheme.textLight,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.white : AppTheme.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
