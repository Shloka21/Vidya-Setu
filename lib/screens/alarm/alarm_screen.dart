import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../app/theme.dart';
import '../../services/notification_service.dart';
import 'package:vidyasetu/services/localization_service.dart';

/// ──────────────────────────────────────────────────────────────────────
/// PREMIUM ALARM SCREEN
/// Background color adapts to priority (High=Red, Medium=Amber, Low=Green).
/// Features: Ripple effect, glassmorphism card, animated bell, particle dust.
/// ──────────────────────────────────────────────────────────────────────
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> with TickerProviderStateMixin {
  // ── Animation Controllers ──
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late AnimationController _rippleCtrl;
  late AnimationController _bellCtrl;

  late Animation<double> _pulseAnim;
  late Animation<Offset> _slideAnim;

  String _title = 'Reminder';
  String _description = '';
  String _timeStr = '';
  String _priority = 'high';
  int _notificationId = 0;
  bool _dismissed = false;
  bool _argsLoaded = false;
  final FlutterTts _tts = FlutterTts();
  Timer? _autoTimer;
  Timer? _vibTimer;
  Timer? _clockTimer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _bellCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));

    HapticFeedback.heavyImpact();
    _startVibrationLoop();

    // Real-time clock — ticks every second
    _updateClock();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_dismissed) _updateClock();
    });

    // Auto-dismiss after 2 minutes
    _autoTimer = Timer(const Duration(minutes: 2), () {
      if (mounted && !_dismissed) _dismiss();
    });
  }

  void _startVibrationLoop() {
    _vibTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!_dismissed) HapticFeedback.heavyImpact();
    });
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _argsLoaded = true;
      _title = args['title'] ?? 'Reminder';
      _description = args['description'] ?? '';
      _timeStr = args['time'] ?? '';
      _priority = args['priority'] ?? 'high';
      _notificationId = args['notificationId'] ?? 0;
      if (args['voice'] == true) _speakAlarm();
    }
  }

  Future<void> _speakAlarm() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.speak('Attention! $_title is starting now. $_description');
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    _rippleCtrl.dispose();
    _bellCtrl.dispose();
    _autoTimer?.cancel();
    _vibTimer?.cancel();
    _clockTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  void _snooze() {
    setState(() => _dismissed = true);
    _tts.stop();

    final notifService = NotificationService();
    notifService.scheduleReminderAlarm(
      reminderId: 'snooze_${DateTime.now().millisecondsSinceEpoch}',
      title: _title,
      body: _description.isNotEmpty ? _description : 'Snoozed reminder',
      eventTime: DateTime.now().add(const Duration(minutes: 5)),
      reminderMinutesBefore: [0],
      repeatType: 'once',
    );

    if (_notificationId > 0) notifService.cancelNotification(_notificationId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('snoozed_for_5_minutes')),
        backgroundColor: AppTheme.warningAmber,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    _exitOrPop();
  }

  void _dismiss() {
    setState(() => _dismissed = true);
    _tts.stop();
    if (_notificationId > 0) NotificationService().cancelNotification(_notificationId);
    _exitOrPop();
  }

  void _exitOrPop() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final killed = args?['launchedFromColdStart'] ?? false;
    if (killed) {
      SystemNavigator.pop();
    } else {
      Navigator.pop(context);
    }
  }

  // ── Priority-Based Colors ──
  Color get _accentColor {
    switch (_priority) {
      case 'high': return const Color(0xFFEF4444);
      case 'medium': return const Color(0xFFF59E0B);
      case 'low': return const Color(0xFF10B981);
      default: return const Color(0xFFEF4444);
    }
  }

  List<Color> get _bgGradient {
    switch (_priority) {
      case 'high': return [const Color(0xFF1A0505), const Color(0xFF450A0A), const Color(0xFF7F1D1D)];
      case 'medium': return [const Color(0xFF1A1005), const Color(0xFF451A03), const Color(0xFF78350F)];
      case 'low': return [const Color(0xFF051A0A), const Color(0xFF022C22), const Color(0xFF064E3B)];
      default: return [const Color(0xFF1A0505), const Color(0xFF450A0A), const Color(0xFF7F1D1D)];
    }
  }

  IconData get _priorityIcon {
    switch (_priority) {
      case 'high': return Icons.priority_high_rounded;
      case 'medium': return Icons.notifications_active_rounded;
      case 'low': return Icons.notifications_none_rounded;
      default: return Icons.alarm_rounded;
    }
  }

  String get _priorityLabel {
    switch (_priority) {
      case 'high': return 'URGENT';
      case 'medium': return 'IMPORTANT';
      case 'low': return 'REMINDER';
      default: return 'ALERT';
    }
  }

  @override
  Widget build(BuildContext context) {

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bgGradient[0],
        body: Stack(
          children: [
            // ── Layer 1: Animated gradient background ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: _pulseAnim.value * 1.8,
                      colors: [
                        _accentColor.withOpacity(0.35),
                        _bgGradient[1],
                        _bgGradient[0],
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // ── Layer 2: Ripple rings ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rippleCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _RipplePainter(
                    progress: _rippleCtrl.value,
                    color: _accentColor,
                  ),
                ),
              ),
            ),

            // ── Layer 3: Main content ──
            SafeArea(
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // Priority badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: _accentColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_priorityIcon, color: _accentColor, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _priorityLabel,
                              style: TextStyle(
                                color: _accentColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Animated Bell/Alarm icon
                      AnimatedBuilder(
                        animation: _bellCtrl,
                        builder: (_, __) {
                          return Transform.rotate(
                            angle: math.sin(_bellCtrl.value * math.pi * 2) * 0.15,
                            child: AnimatedBuilder(
                              animation: _pulseAnim,
                              builder: (_, __) => Transform.scale(
                                scale: _pulseAnim.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _accentColor.withOpacity(0.15),
                                    border: Border.all(color: _accentColor.withOpacity(0.6), width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _accentColor.withOpacity(0.4),
                                        blurRadius: 50,
                                        spreadRadius: 15,
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.alarm_rounded, color: _accentColor, size: 56),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 36),

                      // Glass Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 40, offset: const Offset(0, 16)),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Time display
                            Text(
                              _currentTime,
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 48,
                                fontWeight: FontWeight.w200,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              _title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_description.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                _description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(flex: 2),

                      // ── Action buttons ──
                      Row(
                        children: [
                          // Snooze button
                          Expanded(
                            child: GestureDetector(
                              onTap: _snooze,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.07),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.snooze_rounded, color: Colors.white.withOpacity(0.9), size: 26),
                                    const SizedBox(height: 6),
                                    Text(
                                      context.tr('snooze'),
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '5 min',
                                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Dismiss button
                          Expanded(
                            child: GestureDetector(
                              onTap: _dismiss,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [_accentColor, _accentColor.withOpacity(0.8)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _accentColor.withOpacity(0.5),
                                      blurRadius: 25,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                                    const SizedBox(height: 6),
                                    Text(
                                      context.tr('dismiss'),
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expanding ripple circles from center
class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.height * 0.5;

    for (int i = 0; i < 3; i++) {
      final individualProgress = (progress + i * 0.33) % 1.0;
      final radius = individualProgress * maxRadius;
      final opacity = (1.0 - individualProgress) * 0.12;

      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.progress != progress;
}
