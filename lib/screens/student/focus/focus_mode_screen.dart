import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:do_not_disturb/do_not_disturb.dart';
import 'package:device_apps/device_apps.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import 'package:vidyasetu/services/localization_service.dart';
import '../../../services/notification_service.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({Key? key}) : super(key: key);

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _dndPlugin = DoNotDisturbPlugin();
  static const _appBlockerChannel = MethodChannel('com.example.vidyasetu/app_blocker');
  bool _isActive = false;
  int _selectedMinutes = 25; // Default pomodoro
  int _remainingSeconds = 0;
  Timer? _timer;
  Timer? _clockTimer;
  String _currentTimeStr = '';
  String _currentQuote = '';
  int _quoteIndex = 0;

  final List<String> _quotes = [
    "Focus on being productive, not being busy.",
    "The pain of discipline is far less than the pain of regret.",
    "Study now, be proud later.",
    "Success is the sum of small efforts, repeated day in and day out.",
    "Your future self will thank you for the work you do today.",
    "Deep work is the superpower of the 21st century.",
    "Don't stop until you're proud.",
    "Action is the foundational key to all success."
  ];

  bool _hasUsage = false;
  bool _hasAccessibility = false;
  bool _hasOverlay = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;

  final List<int> _presets = [15, 25, 45, 60, 90, 120];
  
  List<Application> _installedApps = [];
  Set<String> _blockedAppPackages = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breatheAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _currentTimeStr = _getFormattedClock();
    _currentQuote = _quotes[0];
    
    _loadApps();
    _checkPermissions();
  }

  String _getFormattedClock() {
    final now = DateTime.now();
    final hour = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  Future<void> _checkPermissions() async {
    try {
      final usage = await _appBlockerChannel.invokeMethod('hasUsagePermission');
      final acc = await _appBlockerChannel.invokeMethod('hasAccessibilityPermission');
      final overlay = await _appBlockerChannel.invokeMethod('hasOverlayPermission');
      
      if (mounted) {
        setState(() {
          _hasUsage = usage ?? false;
          _hasAccessibility = acc ?? false;
          _hasOverlay = overlay ?? false;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadApps() async {
    try {
      final apps = await DeviceApps.getInstalledApplications(
        includeSystemApps: false,
        includeAppIcons: true,
        onlyAppsWithLaunchIntent: true,
      );
      if (mounted) {
        setState(() {
          // Sort apps alphabetically
          apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
          _installedApps = apps;
        });
      }
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isActive && _blockedAppPackages.isNotEmpty) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        // App went to background during strict focus session
        NotificationService().showInstantNotification(
          context.tr('focus_mode_enforced'),
          context.tr('return_to_vidyasetu_immediately'),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _clockTimer?.cancel();
    _pulseController.dispose();
    _breatheController.dispose();
    if (_isActive) _disableDND();
    super.dispose();
  }

  Future<void> _enableDND() async {
    try {
      final hasAccess = await _dndPlugin.isNotificationPolicyAccessGranted();
      if (hasAccess) {
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.priority);
      }
    } catch (e) {
      debugPrint('DND enable failed: $e');
    }
  }

  Future<void> _disableDND() async {
    try {
      final hasAccess = await _dndPlugin.isNotificationPolicyAccessGranted();
      if (hasAccess) {
        await _dndPlugin.setInterruptionFilter(InterruptionFilter.all);
      }
    } catch (e) {
      debugPrint('DND disable failed: $e');
    }
  }

  Future<void> _requestDNDPermission() async {
    try {
      final hasAccess = await _dndPlugin.isNotificationPolicyAccessGranted();
      if (!hasAccess) {
        await _dndPlugin.openNotificationPolicyAccessSettings();
      }
    } catch (e) {
      debugPrint('DND permission check failed: $e');
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.shield_rounded, color: Theme.of(context).colorScheme.onSurface, size: 28),
              const SizedBox(width: 12),
              Text(context.tr('setup_focus_enforcer'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('to_block_distracting_apps_desc'),
                style: const TextStyle(fontSize: 14, height: 1.4)),
              const SizedBox(height: 20),
              _permissionToggle(
                title: context.tr('accessibility_service'),
                desc: context.tr('accessibility_service_desc'),
                isGranted: _hasAccessibility,
                onTap: () async {
                  await _appBlockerChannel.invokeMethod('requestAccessibilityPermission');
                },
              ),
              const SizedBox(height: 12),
              _permissionToggle(
                title: context.tr('overlay_permission'),
                desc: context.tr('overlay_permission_desc'),
                isGranted: _hasOverlay,
                onTap: () async {
                  await _appBlockerChannel.invokeMethod('requestOverlayPermission');
                },
              ),
              const SizedBox(height: 12),
              _permissionToggle(
                title: context.tr('usage_access'),
                desc: context.tr('usage_access_desc'),
                isGranted: _hasUsage,
                onTap: () async {
                  await _appBlockerChannel.invokeMethod('requestUsagePermission');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('cancel') ?? 'Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
            ),
            ElevatedButton(
              onPressed: (_hasAccessibility && _hasOverlay && _hasUsage)
                ? () => Navigator.pop(ctx)
                : () async {
                    await _checkPermissions();
                    setDialogState(() {});
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: (_hasAccessibility && _hasOverlay && _hasUsage) ? AppTheme.successGreen : AppTheme.accentBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text((_hasAccessibility && _hasOverlay && _hasUsage) ? context.tr('all_set') : context.tr('check_status')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permissionToggle({required String title, required String desc, required bool isGranted, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isGranted ? AppTheme.successGreen.withOpacity(0.1) : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isGranted ? AppTheme.successGreen : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(isGranted ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
              color: isGranted ? AppTheme.successGreen : AppTheme.accentBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(desc, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          ],
        ),
      ),
    );
  }

  void _startFocus() async {
    // Check permissions first
    await _checkPermissions();
    if (_blockedAppPackages.isNotEmpty && (!_hasAccessibility || !_hasOverlay || !_hasUsage)) {
      _showPermissionDialog();
      return;
    }

    await _requestDNDPermission();
    await _enableDND();

    // Start native app blocking if apps are selected
    if (_blockedAppPackages.isNotEmpty) {
      try {
        await _appBlockerChannel.invokeMethod('startBlocking', {
          'packages': _blockedAppPackages.toList(),
        });
      } catch (e) {
        debugPrint('App blocker start failed: $e');
      }
    }

    setState(() {
      _isActive = true;
      _remainingSeconds = _selectedMinutes * 60;
      _currentTimeStr = _getFormattedClock();
      _currentQuote = _quotes[0];
      _quoteIndex = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _endFocus();
        return;
      }
      setState(() {
        _remainingSeconds--;
        // Update quote every 30 seconds
        if (_remainingSeconds % 30 == 0) {
          _quoteIndex = (_quoteIndex + 1) % _quotes.length;
          _currentQuote = _quotes[_quoteIndex];
        }
      });
    });

    // Clock timer (every minute)
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newTime = _getFormattedClock();
      if (newTime != _currentTimeStr) {
        setState(() => _currentTimeStr = newTime);
      }
    });
  }

  void _endFocus() async {
    _timer?.cancel();
    _clockTimer?.cancel();
    await _disableDND();

    // Stop native app blocking
    if (_blockedAppPackages.isNotEmpty) {
      try {
        await _appBlockerChannel.invokeMethod('stopBlocking');
      } catch (e) {
        debugPrint('App blocker stop failed: $e');
      }
    }

    // Persist study hours to Firestore
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userModel?.uid;
    if (uid != null) {
      final hours = _selectedMinutes / 60.0;
      await FirestoreService().incrementStudyHours(uid, hours);
      await FirestoreService().updateStreak(uid); // Also update streak/points for focus session
    }
    
    if (mounted) {
      setState(() {
        _isActive = false;
        _remainingSeconds = 0;
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Row(
            children: [
              const Text('🎉 ', style: TextStyle(fontSize: 28)),
              Text(context.tr('focus_complete') ?? 'Focus Complete!',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text(
            context.tr('great_work_focus_session') ??
                'Great work! You completed a $_selectedMinutes-minute focus session.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
              child: Text(context.tr('done') ?? 'Done'),
            ),
          ],
        ),
      );
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get _progress {
    if (!_isActive || _selectedMinutes == 0) return 0;
    final total = _selectedMinutes * 60;
    return 1.0 - (_remainingSeconds / total);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _isActive
          ? (isDark ? const Color(0xFF0A0E17) : const Color(0xFF0F1923))
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: _isActive
          ? null
          : AppBar(
              title: Text(context.tr('focus_mode') ?? 'Focus Mode'),
              backgroundColor: Colors.transparent,
            ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isActive ? _buildActiveView() : _buildSetupView(),
        ),
      ),
    );
  }

  Widget _buildSetupView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Hero illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                  AppTheme.accentBlue.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.self_improvement_rounded,
                size: 60, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('get_in_the_zone') ?? 'Get in the Zone',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('focus_mode_desc') ??
                'Silence notifications, minimize distractions,\nand study with full concentration.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),

          // Duration selector
          Text(
            context.tr('select_duration') ?? 'Select Duration',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _presets.map((min) {
              final isSelected = _selectedMinutes == min;
              return GestureDetector(
                onTap: () => setState(() => _selectedMinutes = min),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.1),
                      width: 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : AppTheme.cardBoxShadow,
                  ),
                  child: Text(
                    '${min}m',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 36),

          // Target Apps to Block Section
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr('apps_to_block') ?? 'Distracting Apps',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr('select_apps_to_restrict'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _installedApps.isEmpty
              ? const CircularProgressIndicator()
              : SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _installedApps.length,
                    itemBuilder: (context, index) {
                      final app = _installedApps[index] as ApplicationWithIcon;
                      final isBlocked = _blockedAppPackages.contains(app.packageName);
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isBlocked) {
                              _blockedAppPackages.remove(app.packageName);
                            } else {
                              _blockedAppPackages.add(app.packageName);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isBlocked ? AppTheme.errorRed.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isBlocked ? AppTheme.errorRed : Theme.of(context).colorScheme.surface,
                              width: 2,
                            ),
                            boxShadow: AppTheme.cardBoxShadow,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(app.icon, width: 44, height: 44),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      app.appName,
                                      style: TextStyle(
                                        color: isBlocked ? AppTheme.errorRed : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                        fontSize: 10,
                                        fontWeight: isBlocked ? FontWeight.w700 : FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              if (isBlocked)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(Icons.block_rounded, color: AppTheme.errorRed, size: 16),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
          const SizedBox(height: 36),

          // What happens section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.cardBoxShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('what_happens') ?? 'What happens?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _featureRow(Icons.notifications_off_rounded,
                    context.tr('dnd_enabled') ?? 'Do Not Disturb enabled',
                    Theme.of(context).colorScheme.onSurface),
                _featureRow(Icons.timer_rounded,
                    context.tr('countdown_timer') ?? 'Countdown timer on screen',
                    AppTheme.accentBlue),
                _featureRow(Icons.self_improvement_rounded,
                    context.tr('breathing_guide') ?? 'Calm breathing guide',
                    AppTheme.successGreen),
                _featureRow(Icons.emoji_events_rounded,
                    context.tr('focus_points') ?? 'Earn points on completion',
                    AppTheme.warningAmber),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Start button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _startFocus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.onSurface,
                foregroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('start_focus') ?? 'Start Focus',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(text,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActiveView() {
    return Column(
      children: [
        const SizedBox(height: 30),
        // Current Clock
        Text(
          _currentTimeStr,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        
        // Timer circle
        ScaleTransition(
          scale: _pulseAnimation,
          child: SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 6,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                // Progress ring
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 6,
                    color: Theme.of(context).colorScheme.onSurface,
                    backgroundColor: Colors.transparent,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Time display
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w200,
                        letterSpacing: 4,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('stay_focused') ?? 'Stay Focused',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),

        // Breathing guide
        AnimatedBuilder(
          animation: _breatheAnimation,
          builder: (context, _) {
            final phase = _breatheAnimation.value;
            final label = phase < 0.5
                ? (context.tr('breathe_in') ?? 'Breathe in...')
                : (context.tr('breathe_out') ?? 'Breathe out...');
            return Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 12 + (phase * 20),
                  height: 12 + (phase * 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3 + phase * 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
        const Spacer(),

        // Motivational Quote
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _currentQuote,
              key: ValueKey(_currentQuote),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 40),

        // End button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _endFocus,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                side: BorderSide(color: AppTheme.errorRed.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                context.tr('end_session') ?? 'End Session',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
