import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  String _roomId = 'default';
  String _otherUserName = 'User';
  bool _launching = false;
  bool _inCall = false;
  final _jitsiMeet = JitsiMeet();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _roomId = args['roomId'] as String? ?? 'default';
      _otherUserName = args['otherUserName'] as String? ?? 'User';
    }
  }

  Future<void> _startCall({bool audioOnly = false}) async {
    setState(() => _launching = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userName = auth.userModel?.name ?? 'User';
    final userEmail = auth.userModel?.email ?? '';
    final isMentor = auth.userModel?.role == 'mentor';

    try {
      // Request hardware permissions explicitly to avoid Jitsi's internal Android clash
      await [
        Permission.camera,
        Permission.microphone,
        Permission.bluetoothConnect,
      ].request();

      var options = JitsiMeetConferenceOptions(
        room: 'vidyasetu-${_roomId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
        serverURL: 'https://jitsi.riot.im/',
        userInfo: JitsiMeetUserInfo(
          displayName: userName,
          email: userEmail,
        ),
        featureFlags: {
          FeatureFlags.addPeopleEnabled: false,
          FeatureFlags.welcomePageEnabled: false,
          FeatureFlags.preJoinPageEnabled: false,
          FeatureFlags.unsafeRoomWarningEnabled: false,
          FeatureFlags.lobbyModeEnabled: false,
          FeatureFlags.meetingPasswordEnabled: false,
          FeatureFlags.resolution: 360,
          FeatureFlags.chatEnabled: true,
          FeatureFlags.inviteEnabled: false,
          FeatureFlags.kickOutEnabled: isMentor,
          FeatureFlags.recordingEnabled: isMentor,
          FeatureFlags.liveStreamingEnabled: false,
          FeatureFlags.meetingNameEnabled: true,
          FeatureFlags.raiseHandEnabled: true,
          FeatureFlags.tileViewEnabled: true,
          FeatureFlags.toolboxAlwaysVisible: false,
          FeatureFlags.filmstripEnabled: true,
        },
        configOverrides: {
          'startWithAudioMuted': false,
          'startWithVideoMuted': audioOnly,
          'subject': 'VidyaSetu: ${audioOnly ? "Audio" : "Video"} call with $_otherUserName',
          'requireDisplayName': false,
          'disableDeepLinking': true,
          'prejoinConfig.enabled': false,
        },
      );

      await _jitsiMeet.join(options);
      if (mounted) {
        setState(() {
          _launching = false;
          _inCall = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _launching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start call: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(title: const Text('Video Call')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.accentBlue.withOpacity(0.2), AppTheme.accentPurple.withOpacity(0.2)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _otherUserName.isNotEmpty ? _otherUserName[0].toUpperCase() : 'U',
                    style: TextStyle(color: AppTheme.accentBlue, fontSize: 42, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(_otherUserName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Powered by Jitsi Meet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
              const SizedBox(height: 12),
              Text('No login required • Instant join', style: TextStyle(color: AppTheme.successGreen, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 36),

              if (!_inCall) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _launching ? null : () => _startCall(audioOnly: false),
                    icon: _launching
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.videocam_rounded, size: 24),
                    label: Text(_launching ? 'Connecting...' : 'Start Video Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _launching ? null : () => _startCall(audioOnly: true),
                    icon: const Icon(Icons.phone_rounded, size: 20),
                    label: const Text('Audio Only'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 48),
                      const SizedBox(height: 12),
                      Text('Call started!', style: TextStyle(color: AppTheme.successGreen, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Switch to the call window to continue', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _startCall(audioOnly: false),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Rejoin Call'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              const SizedBox(height: 32),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Back to Chat', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

