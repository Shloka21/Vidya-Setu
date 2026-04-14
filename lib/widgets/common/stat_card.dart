import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final Color accentColor = iconColor ?? (isDark ? AppTheme.warningAmber : AppTheme.accentBlue);
    final Color cardBg = currentThemeDark ? AppTheme.darkSurface : AppTheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120, // Consistent height with profile stat items
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: accentColor.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Large Ghost Icon in Background
              Positioned(
                right: -2,
                top: -2,
                child: Icon(
                  icon,
                  size: 80,
                  color: accentColor.withOpacity(0.10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Small Icon Container
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // child: Icon(
                      //   icon,
                      //   color: accentColor,
                      //   size: 20,
                      // ),
                    ),
                    const Spacer(),
                    // Value
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    // Label
                    Text(
                      label.toUpperCase(),
                      style: GoogleFonts.inter(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
