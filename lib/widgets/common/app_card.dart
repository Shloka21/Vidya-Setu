import 'package:flutter/material.dart';
import '../../app/theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final double? borderRadius;
  final VoidCallback? onTap;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.borderRadius,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = color ?? Theme.of(context).colorScheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? EdgeInsets.zero,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: gradient == null ? surfaceColor : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppTheme.radiusLarge,
          ),
          boxShadow: isDark ? [] : AppTheme.cardBoxShadow,
          border: border ?? (isDark ? Border.all(color: AppTheme.darkDivider) : null),
        ),
        child: child,
      ),
    );
  }
}
