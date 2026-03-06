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
    final bool currentThemeDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: currentThemeDark ? AppTheme.primaryNavy : Theme.of(context).colorScheme.surface,
          gradient: currentThemeDark ? AppTheme.navyGradient : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: currentThemeDark ? [] : AppTheme.cardBoxShadow,
          border: currentThemeDark ? Border.all(color: Colors.white12) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: currentThemeDark
                    ? Colors.white.withOpacity(0.15)
                    : (iconBgColor ?? AppTheme.accentBlue.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                color: currentThemeDark
                    ? Colors.white
                    : (iconColor ?? AppTheme.accentBlue),
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
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

