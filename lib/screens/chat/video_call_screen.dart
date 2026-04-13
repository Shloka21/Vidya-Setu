import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'package:vidyasetu/services/localization_service.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  String _roomId = 'default';
  String _otherUserName = 'User';
  String? _otherUserId;
  bool _launching = false;
  bool _inCall = false;
  final _jitsiMeet = JitsiMeet();
  final _firestoreService = FirestoreService();

  bool _hasAutoStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasAutoStarted) return;
    _hasAutoStarted = true;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _roomId = args['roomId'] as String? ?? 'default';
      _otherUserName = args['otherUserName'] as String? ?? 'User';
      _otherUserId = args['otherUserId'] as String?;
      
      final autoStart = args['autoStart'] as bool? ?? false;
      final audioOnly = args['audioOnly'] as bool? ?? false;
      
      if (autoStart) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startCall(audioOnly: audioOnly);
        });
      }
    }
  }

  @override
  void dispose() {
    // Clean up call signal when leaving
    if (_inCall) {
      _firestoreService.endCall(_roomId);
    }
    super.dispose();
  }

  Future<void> _startCall({bool audioOnly = false}) async {
    setState(() => _launching = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userName = auth.userModel?.name ?? 'User';
    final userEmail = auth.userModel?.email ?? '';
    final uid = auth.userModel?.uid ?? '';
    final isMentor = auth.userModel?.role == 'mentor';

    try {
      // Request hardware permissions explicitly
      final statuses = await [
        Permission.camera,
        Permission.microphone,
        Permission.bluetoothConnect,
      ].request();

      // Check if critical permissions are denied
      if (statuses[Permission.camera]?.isDenied == true ||
          statuses[Permission.microphone]?.isDenied == true) {
        if (mounted) {
          setState(() => _launching = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('camera_and_microphone_permissi')),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Signal incoming call to the other user (mentor → student)
      if (isMentor && _otherUserId != null) {
        await _firestoreService.startCall(
          roomId: _roomId,
          callerId: uid,
          callerName: userName,
          receiverId: _otherUserId!,
        );
      }

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

      // Add event listeners for call lifecycle
      var listener = JitsiMeetEventListener(
        conferenceTerminated: (url, error) {
          if (mounted) {
            setState(() {
              _inCall = false;
              _launching = false;
            });
          }
          // Clean up call signal
          _firestoreService.endCall(_roomId);
        },
        conferenceJoined: (url) {
          if (mounted) {
            setState(() {
              _launching = false;
              _inCall = true;
            });
          }
          // Update call status
          if (_otherUserId != null) {
            _firestoreService.updateCallStatus(_roomId, 'accepted');
          }
        },
      );

      await _jitsiMeet.join(options, listener);
    } catch (e) {
      if (mounted) {
        setState(() => _launching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start call: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
      // Clean up call signal on failure
      _firestoreService.endCall(_roomId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('video_call'))),
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
              SizedBox(height: 20),
              Text(_otherUserName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text(context.tr('powered_by_jitsi_meet'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
              SizedBox(height: 12),
              Text(context.tr('no_login_required__instant_joi'), style: TextStyle(color: AppTheme.successGreen, fontSize: 13, fontWeight: FontWeight.w500)),
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
                      textStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _launching ? null : () => _startCall(audioOnly: true),
                    icon: Icon(Icons.phone_rounded, size: 20),
                    label: Text(context.tr('audio_only')),
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
                      Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 48),
                      SizedBox(height: 12),
                      Text(context.tr('call_in_progress'), style: TextStyle(color: AppTheme.successGreen, fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text(context.tr('switch_to_the_call_window_to_c'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _startCall(audioOnly: false),
                  icon: Icon(Icons.refresh_rounded),
                  label: Text(context.tr('rejoin_call')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
              SizedBox(height: 32),
              TextButton(
                onPressed: () {
                  _firestoreService.endCall(_roomId);
                  Navigator.pop(context);
                },
                child: Text(context.tr('back_to_chat'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
