import 'package:flutter/material.dart';

class AnimatedThemeToggle extends StatefulWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const AnimatedThemeToggle({
    super.key,
    required this.isDark,
    required this.onChanged,
  });

  @override
  State<AnimatedThemeToggle> createState() => _AnimatedThemeToggleState();
}

class _AnimatedThemeToggleState extends State<AnimatedThemeToggle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    );

    if (widget.isDark) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedThemeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDark != oldWidget.isDark) {
      if (widget.isDark) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.isDark),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isDark = _animation.value > 0.5;
          final backgroundColor = Color.lerp(
            const Color(0xFF87CEEB), // Day Sky
            const Color(0xFF1B2838), // Night Sky
            _animation.value.clamp(0.0, 1.0),
          );

          return Container(
            width: 70,
            height: 38,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.blue.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                // Inner shadow effect via border for depth
                Border.all(
                  color: Colors.black.withOpacity(0.1),
                  width: 1,
                ).paint,
              ].whereType<BoxShadow>().toList(),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
              children: [
                // Star/Cloud Background Elements
                if (isDark)
                  ..._buildStars()
                else
                  ..._buildClouds(),

                // Toggle Button (Sun/Moon)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.translate(
                    offset: Offset(_animation.value * (70 - 38), 0),
                    child: Transform.rotate(
                      angle: _animation.value * 3.14159,
                      child: Container(
                        width: 38,
                        height: 38,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFFF5F3CE) : const Color(0xFFFFD700),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.white24 : Colors.orange.withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            if (isDark)
                              ..._buildMoonCraters(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildStars() {
    return [
      _buildStar(top: 8, left: 15, size: 2),
      _buildStar(top: 18, left: 25, size: 3),
      _buildStar(top: 25, left: 10, size: 2),
      _buildStar(top: 12, left: 35, size: 1.5),
    ];
  }

  Widget _buildStar({required double top, required double left, required double size}) {
    return Positioned(
      top: top,
      left: left,
      child: Opacity(
        opacity: _animation.value.clamp(0.0, 1.0),
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildClouds() {
    return [
      Positioned(
        bottom: -5,
        right: 15,
        child: Opacity(
          opacity: (1.0 - _animation.value).clamp(0.0, 1.0),
          child: Icon(Icons.cloud, color: Colors.white.withOpacity(0.8), size: 18),
        ),
      ),
      Positioned(
        top: 2,
        right: 5,
        child: Opacity(
          opacity: (1.0 - _animation.value).clamp(0.0, 1.0),
          child: Icon(Icons.cloud, color: Colors.white.withOpacity(0.6), size: 14),
        ),
      ),
    ];
  }

  List<Widget> _buildMoonCraters() {
    return [
      Positioned(
        top: 4,
        left: 8,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        bottom: 6,
        right: 6,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
      ),
      Positioned(
        top: 12,
        right: 12,
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
        ),
      ),
    ];
  }
}
