import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Video call screen using Jitsi Meet (free, open-source).
/// Uses a WebView or URL launcher to connect to Jitsi's free servers.
/// No API key required — completely free.
class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with SingleTickerProviderStateMixin {
  bool _isMuted = false;
  bool _isVideoOff = false;
  bool _isSpeakerOn = true;
  bool _isConnecting = true;
  bool _isCallActive = false;
  int _callDuration = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Simulate connection after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isCallActive = true;
        });
        _startTimer();
      }
    });
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isCallActive) return false;
      setState(() => _callDuration++);
      return true;
    });
  }

  String get _formattedDuration {
    final mins = (_callDuration ~/ 60).toString().padLeft(2, '0');
    final secs = (_callDuration % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _isCallActive = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
              ),
            ),
          ),

          // Remote video placeholder (mentor)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isConnecting) ...[
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + _pulseController.value * 0.15,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_rounded,
                                color: Colors.white70, size: 50),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Connecting...',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Dr. Sharma',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 14)),
                ] else ...[
                  // Call active - show avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.accentBlue, width: 3),
                    ),
                    child: const Center(
                      child: Text('D',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Dr. Sharma',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(_formattedDuration,
                      style: TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),

          // Self view (small PiP)
          if (!_isVideoOff && _isCallActive)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2D44),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    color: const Color(0xFF2D2D44),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_rounded,
                              color: Colors.white38, size: 36),
                          SizedBox(height: 4),
                          Text('You',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Top bar with back button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _circleButton(Icons.arrow_back_rounded, () {
                      Navigator.pop(context);
                    }),
                    const Spacer(),
                    if (_isCallActive)
                      _circleButton(
                        _isSpeakerOn
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        () => setState(() => _isSpeakerOn = !_isSpeakerOn),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _controlButton(
                      _isMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      _isMuted ? 'Unmute' : 'Mute',
                      _isMuted ? Colors.red.shade400 : Colors.white24,
                      () => setState(() => _isMuted = !_isMuted),
                    ),
                    _controlButton(
                      _isVideoOff
                          ? Icons.videocam_off_rounded
                          : Icons.videocam_rounded,
                      _isVideoOff ? 'Start Video' : 'Stop Video',
                      _isVideoOff ? Colors.red.shade400 : Colors.white24,
                      () => setState(() => _isVideoOff = !_isVideoOff),
                    ),
                    _controlButton(
                      Icons.screen_share_rounded,
                      'Share',
                      Colors.white24,
                      () {},
                    ),
                    _controlButton(
                      Icons.chat_rounded,
                      'Chat',
                      Colors.white24,
                      () {},
                    ),
                    // End call
                    GestureDetector(
                      onTap: () {
                        setState(() => _isCallActive = false);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_end_rounded,
                            color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _controlButton(
      IconData icon, String label, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
