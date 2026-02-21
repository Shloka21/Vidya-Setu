import 'package:flutter/material.dart';
import '../../app/theme.dart';

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool useGradient;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.useGradient = true,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onPressed != null && !widget.isLoading) {
      widget.onPressed!();
    }
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (widget.isOutlined) {
      return _buildOutlinedButton(scheme);
    }

    if (widget.useGradient && widget.backgroundColor == null) {
      return _buildGradientButton();
    }

    return _buildSolidButton(scheme);
  }

  Widget _buildGradientButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: widget.onPressed != null && !widget.isLoading
            ? _onTapDown
            : null,
        onTapUp: widget.onPressed != null && !widget.isLoading
            ? _onTapUp
            : null,
        onTapCancel: _onTapCancel,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.isLoading || widget.onPressed == null
                ? LinearGradient(
                    colors: [
                      AppTheme.brandPrimary.withOpacity(0.5),
                      AppTheme.brandSecondary.withOpacity(0.5),
                    ],
                  )
                : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.onPressed != null && !widget.isLoading
                ? [
                    BoxShadow(
                      color: AppTheme.brandPrimary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Center(child: _buildChild(Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSolidButton(ColorScheme scheme) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: widget.onPressed != null && !widget.isLoading
            ? _onTapDown
            : null,
        onTapUp: widget.onPressed != null && !widget.isLoading
            ? _onTapUp
            : null,
        onTapCancel: _onTapCancel,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? scheme.primary,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.onPressed != null && !widget.isLoading
                ? [
                    BoxShadow(
                      color: (widget.backgroundColor ?? scheme.primary)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(child: _buildChild(widget.textColor ?? Colors.white)),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(ColorScheme scheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: widget.onPressed != null && !widget.isLoading
            ? _onTapDown
            : null,
        onTapUp: widget.onPressed != null && !widget.isLoading
            ? _onTapUp
            : null,
        onTapCancel: _onTapCancel,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: isDark
                ? scheme.surfaceContainerHighest.withOpacity(0.3)
                : scheme.surface,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.backgroundColor ?? scheme.outline.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: _buildChild(
              widget.textColor ?? widget.backgroundColor ?? scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (widget.isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (widget.icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 20, color: color),
          const SizedBox(width: 10),
          Text(
            widget.text,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Text(
      widget.text,
      style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}
