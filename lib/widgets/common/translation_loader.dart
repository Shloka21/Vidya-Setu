import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../services/localization_service.dart';
import '../../app/theme.dart';

/// ──────────────────────────────────────────────────────────────────────
/// GOD-LEVEL PREMIUM TRANSLATION LOADER
/// Featuring: Particle system, aurora wavefield, morphing script glyphs,
///            orbital rings, and intelligent cancel/continue dialog.
/// ──────────────────────────────────────────────────────────────────────
class PremiumTranslationLoader extends StatefulWidget {
  const PremiumTranslationLoader({super.key});

  @override
  State<PremiumTranslationLoader> createState() => _PremiumTranslationLoaderState();
}

class _PremiumTranslationLoaderState extends State<PremiumTranslationLoader>
    with TickerProviderStateMixin {
  // ── Animation Controllers ──
  late AnimationController _orbitalCtrl;   // Outer orbital rings
  late AnimationController _pulseCtrl;     // Inner pulse
  late AnimationController _auroraCtrl;    // Background aurora
  late AnimationController _particleCtrl;  // Particle system

  int _glyphIndex = 0;
  double _progressValue = 0.0;
  Timer? _glyphTimer;
  Timer? _progressTimer;

  // Sacred glyphs from world's major scripts — cycle through them
  static const _glyphs = [
    'अ', // Devanagari
    'あ', // Hiragana
    'ア', // Katakana
    '가', // Korean
    '字', // Chinese
    'ع', // Arabic
    'א', // Hebrew
    'ก', // Thai
    'Ω', // Greek
    'Ж', // Cyrillic
    'ꦄ', // Javanese  
    'অ', // Bengali
    'த', // Tamil
    'అ', // Telugu
    'ا', // Urdu
  ];

  // Greeting strings that morph across the screen
  static const _greetings = [
    'Initializing Neural Translation…',
    'नमस्ते — Downloading Hindi',
    'Syncing Language Cortex…',
    'নমস্কার — Bengali Models Loading',
    'வணக்கம் — Tamil Synapses Active',
    'Morphing Linguistic DNA…',
    'నమస్కారం — Telugu Pathways Open',
    'Calibrating Script Engines…',
    'Almost there — Finalizing Pack…',
  ];

  // Particle system state
  final List<_Particle> _particles = [];
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();

    // Orbital controller — slow, continuous rotation
    _orbitalCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    // Pulse controller — heartbeat
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    // Aurora controller — background wavefield
    _auroraCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    // Particle controller — drives particle physics
    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat()
      ..addListener(_tickParticles);

    // Generate initial particles
    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle.random(_rng));
    }

    // Cycle glyphs slowly to feel premium
    _glyphTimer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (mounted) setState(() => _glyphIndex = (_glyphIndex + 1) % _glyphs.length);
    });

    // Simulate progress (visual only — the real progress is indeterminate)
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) {
        setState(() {
          _progressValue += 0.003 + _rng.nextDouble() * 0.008;
          if (_progressValue > 0.95) _progressValue = 0.95; // Never quite finish (real completion ends the overlay)
        });
      }
    });
  }

  void _tickParticles() {
    for (var p in _particles) {
      p.y -= p.speed * 0.003;
      p.x += math.sin(p.y * 4 + p.phase) * 0.001;
      p.opacity = (math.sin(p.y * math.pi) * 0.6 + 0.4).clamp(0.0, 1.0);
      if (p.y < -0.1) {
        p.y = 1.1;
        p.x = _rng.nextDouble();
        p.phase = _rng.nextDouble() * math.pi * 2;
      }
    }
  }

  @override
  void dispose() {
    _orbitalCtrl.dispose();
    _pulseCtrl.dispose();
    _auroraCtrl.dispose();
    _particleCtrl.dispose();
    _glyphTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _CancelDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A1A) : const Color(0xFFF0F2FF);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final shouldCancel = await _onWillPop();
        if (shouldCancel && context.mounted) {
          Provider.of<LocalizationService>(context, listen: false).cancelTranslation();
        }
      },
      child: Material(
        color: bgColor,
        child: Stack(
          children: [
            // ── Layer 1: Aurora Wavefield ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _auroraCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _AuroraPainter(
                    progress: _auroraCtrl.value,
                    isDark: isDark,
                  ),
                ),
              ),
            ),

            // ── Layer 2: Particle System ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    color: isDark ? Colors.white : AppTheme.accentBlue,
                  ),
                ),
              ),
            ),

            // ── Layer 3: Main Content ──
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Orbital Ring + Morphing Glyph ──
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer orbital ring
                        AnimatedBuilder(
                          animation: _orbitalCtrl,
                          builder: (_, __) => CustomPaint(
                            size: const Size(220, 220),
                            painter: _OrbitalRingPainter(
                              rotation: _orbitalCtrl.value * 2 * math.pi,
                              color1: AppTheme.accentBlue,
                              color2: AppTheme.accentPurple,
                            ),
                          ),
                        ),

                        // Inner pulsing glow circle
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) {
                            final scale = 0.85 + _pulseCtrl.value * 0.15;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppTheme.accentBlue.withOpacity(0.15),
                                      AppTheme.accentPurple.withOpacity(0.05),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentBlue.withOpacity(0.3 * _pulseCtrl.value),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        // Morphing glyph at center
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 1400),
                          reverseDuration: const Duration(milliseconds: 900),
                          switchInCurve: Curves.easeOutExpo,
                          switchOutCurve: Curves.easeInQuart,
                          transitionBuilder: (child, anim) {
                            return ScaleTransition(
                              scale: Tween<double>(begin: 0.4, end: 1.0).animate(anim),
                              child: FadeTransition(opacity: anim, child: child),
                            );
                          },
                          child: Text(
                            _glyphs[_glyphIndex],
                            key: ValueKey(_glyphIndex),
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w300,
                              color: isDark 
                                  ? Colors.white.withOpacity(0.9)
                                  : AppTheme.accentBlue.withOpacity(0.8),
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // ── Greeting text (slide + fade) ──
                  SizedBox(
                    height: 56,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1200),
                      reverseDuration: const Duration(milliseconds: 800),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) {
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.4),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _greetings[_glyphIndex % _greetings.length],
                        key: ValueKey(_glyphIndex ~/ 1), // changes with glyph
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark 
                              ? Colors.white.withOpacity(0.85)
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.3,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Progress bar ──
                  SizedBox(
                    width: 260,
                    child: Column(
                      children: [
                        // Animated progress
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 6,
                            child: Stack(
                              children: [
                                // Track
                                Container(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : AppTheme.accentBlue.withOpacity(0.08),
                                ),
                                // Fill
                                FractionallySizedBox(
                                  widthFactor: _progressValue,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      gradient: const LinearGradient(
                                        colors: [AppTheme.accentBlue, AppTheme.accentPurple],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${(_progressValue * 100).toInt()}%  •  VidyaSetu Neural Engine',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withOpacity(0.25)
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// CANCEL DIALOG (glassmorphism style)
// ═══════════════════════════════════════════════════════════════════════
class _CancelDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.warningAmber.withOpacity(0.1),
                  ),
                  child: const Icon(Icons.translate_rounded, color: AppTheme.warningAmber, size: 28),
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('cancel_download_title'),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('cancel_download_msg'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: AppTheme.errorRed.withOpacity(0.4)),
                          foregroundColor: AppTheme.errorRed,
                        ),
                        child: Text(context.tr('cancel_download'), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: AppTheme.accentBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: Text(context.tr('continue_download'), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ORBITAL RING PAINTER — Two counter-rotating gradient arcs + orbiting dots
// ═══════════════════════════════════════════════════════════════════════
class _OrbitalRingPainter extends CustomPainter {
  final double rotation;
  final Color color1, color2;

  _OrbitalRingPainter({required this.rotation, required this.color1, required this.color2});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2;
    final innerR = outerR - 16;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Faint track
    paint.strokeWidth = 1.5;
    paint.color = color1.withOpacity(0.06);
    canvas.drawCircle(center, outerR, paint);
    canvas.drawCircle(center, innerR, paint);

    // Arc 1 — clockwise
    paint.strokeWidth = 4;
    paint.shader = SweepGradient(
      startAngle: rotation,
      endAngle: rotation + math.pi,
      colors: [color1, color1.withOpacity(0)],
      transform: GradientRotation(rotation),
    ).createShader(Rect.fromCircle(center: center, radius: outerR));
    canvas.drawArc(Rect.fromCircle(center: center, radius: outerR), rotation, math.pi * 0.8, false, paint);

    // Arc 2 — counter-clockwise
    paint.shader = SweepGradient(
      startAngle: -rotation * 0.6,
      endAngle: -rotation * 0.6 + math.pi,
      colors: [color2, color2.withOpacity(0)],
      transform: GradientRotation(-rotation * 0.6),
    ).createShader(Rect.fromCircle(center: center, radius: innerR));
    canvas.drawArc(Rect.fromCircle(center: center, radius: innerR), -rotation * 0.6, math.pi * 0.6, false, paint);

    // Arc 3 — third ring, subtle
    paint.strokeWidth = 2;
    final midR = (outerR + innerR) / 2;
    paint.shader = SweepGradient(
      startAngle: rotation * 1.3,
      endAngle: rotation * 1.3 + math.pi,
      colors: [color1.withOpacity(0.3), Colors.transparent],
      transform: GradientRotation(rotation * 1.3),
    ).createShader(Rect.fromCircle(center: center, radius: midR));
    canvas.drawArc(Rect.fromCircle(center: center, radius: midR), rotation * 1.3, math.pi * 0.5, false, paint);

    // Orbiting dots
    final dotPaint = Paint();
    for (int i = 0; i < 3; i++) {
      final angle = rotation * (1 + i * 0.3) + i * math.pi * 2 / 3;
      final r = i == 0 ? outerR : (i == 1 ? innerR : midR);
      final dx = center.dx + r * math.cos(angle);
      final dy = center.dy + r * math.sin(angle);
      dotPaint.color = (i == 0 ? color1 : color2).withOpacity(0.8);
      canvas.drawCircle(Offset(dx, dy), 3.5 - i * 0.5, dotPaint);
      
      // Glow
      dotPaint.color = (i == 0 ? color1 : color2).withOpacity(0.15);
      canvas.drawCircle(Offset(dx, dy), 8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_OrbitalRingPainter old) => old.rotation != rotation;
}

// ═══════════════════════════════════════════════════════════════════════
// AURORA WAVEFIELD PAINTER — Layered sine-wave gradient fields
// ═══════════════════════════════════════════════════════════════════════
class _AuroraPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _AuroraPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    for (int i = 0; i < 3; i++) {
      final phase = progress * 2 * math.pi + i * math.pi * 0.7;
      final amplitude = h * (0.06 + i * 0.03);
      final baseY = h * (0.3 + i * 0.15);
      
      final path = Path();
      path.moveTo(0, baseY);

      for (double x = 0; x <= w; x += 4) {
        final y = baseY + math.sin(x / w * math.pi * 2 + phase) * amplitude
            + math.sin(x / w * math.pi * 3 + phase * 1.5) * amplitude * 0.3;
        path.lineTo(x, y);
      }
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.close();

      final colors = [
        [AppTheme.accentBlue, AppTheme.accentPurple],
        [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
        [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
      ];

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors[i][0].withOpacity(isDark ? 0.04 : 0.03),
            colors[i][1].withOpacity(isDark ? 0.01 : 0.005),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════════════════
// PARTICLE PAINTER — Floating luminous particles
// ═══════════════════════════════════════════════════════════════════════
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;

  _ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = color.withOpacity(p.opacity * p.size * 0.15);
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════
// PARTICLE DATA CLASS
// ═══════════════════════════════════════════════════════════════════════
class _Particle {
  double x, y, speed, size, opacity, phase;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
    required this.phase,
  });

  factory _Particle.random(math.Random rng) {
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      speed: 0.3 + rng.nextDouble() * 0.7,
      size: 1.5 + rng.nextDouble() * 3,
      opacity: 0.3 + rng.nextDouble() * 0.7,
      phase: rng.nextDouble() * math.pi * 2,
    );
  }
}
