import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? _receiverId;

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
      _receiverId = args['receiverId'] as String?;
      
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
      _firestoreService.endCall(_roomId, userId: _receiverId);
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
          FeatureFlags.addPeopleEnabled: isMentor,
          FeatureFlags.welcomePageEnabled: false,
          FeatureFlags.preJoinPageEnabled: false,
          FeatureFlags.unsafeRoomWarningEnabled: false,
          FeatureFlags.lobbyModeEnabled: isMentor,
          FeatureFlags.meetingPasswordEnabled: isMentor,
          FeatureFlags.resolution: 360,
          FeatureFlags.chatEnabled: true,
          FeatureFlags.inviteEnabled: false, // Disabling native invite as requested
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

            // Redirect students back to dashboard upon leaving
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (auth.userModel?.role == 'student') {
              Navigator.of(context).popUntil((route) => route.isFirst);
              return;
            }
          }
          // Clean up call signal
          _firestoreService.endCall(_roomId, userId: _receiverId);
        },
        conferenceJoined: (url) {
          if (mounted) {
            setState(() {
              _launching = false;
              _inCall = true;
            });
          }
          // Update call status
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final uid = auth.userModel?.uid;
          if (uid != null) {
            _firestoreService.updateCallStatus(_roomId, uid, 'accepted');
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
      _firestoreService.endCall(_roomId, userId: _receiverId);
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
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final isStudent = auth.userModel?.role == 'student';
                    
                    if (isStudent) {
                      return Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('joining_meeting___') ?? 'Joining meeting...',
                            style: TextStyle(
                              color: AppTheme.accentBlue,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
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
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _launching ? null : () => _startCall(audioOnly: true),
                            icon: const Icon(Icons.phone_rounded, size: 20),
                            label: Text(context.tr('audio_only')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
                if (Provider.of<AuthProvider>(context, listen: false).userModel?.role == 'mentor' && _otherUserId != null)
                   StreamBuilder<DocumentSnapshot>(
                     stream: _firestoreService.activeCallsCollection.doc('${_roomId}_$_otherUserId').snapshots(),
                     builder: (context, snapshot) {
                       final data = snapshot.data?.data() as Map<String, dynamic>?;
                       final status = data?['status'] as String? ?? '';
                       
                       // Hide button if student has already joined (accepted)
                       if (status == 'accepted') return const SizedBox.shrink();
                       
                       return Padding(
                         padding: const EdgeInsets.only(top: 20),
                         child: ElevatedButton.icon(
                           onPressed: () => _firestoreService.updateCallStatus(_roomId, _otherUserId!, 'ringing'),
                           icon: Icon(Icons.ring_volume_rounded, size: 20),
                           label: Text("Call $_otherUserName", style: TextStyle(fontWeight: FontWeight.w700)),
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppTheme.accentPurple,
                             foregroundColor: Colors.white,
                             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           ),
                         ),
                       );
                     },
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
                  _firestoreService.endCall(_roomId, userId: _receiverId);
                  Navigator.pop(context);
                },
                child: Text(context.tr('back_to_chat'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Provider.of<AuthProvider>(context, listen: false).userModel?.role == 'mentor'
          ? FloatingActionButton.extended(
              onPressed: () => _showParticipantManager(context),
              icon: Icon(Icons.people_rounded),
              label: Text("Participants"),
              backgroundColor: AppTheme.accentBlue,
            )
          : null,
    );
  }

  void _showParticipantManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ParticipantManagerPanel(
        roomId: _roomId,
        firestoreService: _firestoreService,
      ),
    );
  }
}

class _ParticipantManagerPanel extends StatelessWidget {
  final String roomId;
  final FirestoreService firestoreService;

  const _ParticipantManagerPanel({
    required this.roomId,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Invite Participants", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: () => _inviteMore(context),
                  icon: Icon(Icons.add_circle_outline_rounded, color: AppTheme.accentBlue),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.roomParticipantsStream(roomId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final participants = snapshot.data!.docs;
                if (participants.isEmpty) return Center(child: Text("No one invited yet."));
                
                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: participants.length,
                  itemBuilder: (context, index) {
                    final data = participants[index].data() as Map<String, dynamic>;
                    final status = data['status'] as String? ?? 'ringing';
                    final studentName = data['receiverId'] == data['callerId'] ? "Me" : (data['receiverId'] ?? "Student"); // Simplified
                    final receiverId = data['receiverId'] as String;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.accentBlue.withOpacity(0.1),
                        child: Icon(Icons.person, color: AppTheme.accentBlue),
                      ),
                      title: Text(receiverId, style: TextStyle(fontWeight: FontWeight.w600)), // Ideally name
                      subtitle: Text(status.toUpperCase(), style: TextStyle(color: _statusColor(status), fontSize: 12)),
                      trailing: status == 'declined'
                          ? TextButton(
                              onPressed: () => firestoreService.updateCallStatus(roomId, receiverId, 'ringing'),
                              child: Text("Ring Again", style: TextStyle(color: AppTheme.accentBlue)),
                            )
                          : (status == 'ringing' ? Icon(Icons.vibration_rounded, color: Colors.grey) : Icon(Icons.check_circle_rounded, color: AppTheme.successGreen)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted': return AppTheme.successGreen;
      case 'declined': return AppTheme.errorRed;
      default: return Colors.orange;
    }
  }

  void _inviteMore(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userModel?.uid ?? '';
    final students = await firestoreService.getConnectedStudents(uid);
    
    // Get currently invited student IDs to pre-check or disable
    final snapshot = await firestoreService.activeCallsCollection.where('roomId', isEqualTo: roomId).get();
    final invitedIds = snapshot.docs.map((doc) => (doc.data() as Map<String, dynamic>)['receiverId'] as String).toSet();

    final selectedUids = <String>{};

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Invite Participants"),
              content: Container(
                width: double.maxFinite,
                constraints: BoxConstraints(maxHeight: 400),
                child: students.isEmpty 
                  ? Center(child: Text("No connected students found."))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final sid = student['uid'] as String;
                        final alreadyInvited = invitedIds.contains(sid);
                        
                        return CheckboxListTile(
                          title: Text(student['name'] ?? 'User'),
                          subtitle: alreadyInvited ? Text("Already in list", style: TextStyle(fontSize: 11, color: Colors.grey)) : null,
                          value: selectedUids.contains(sid) || alreadyInvited,
                          onChanged: alreadyInvited ? null : (val) {
                            setDialogState(() {
                              if (val == true) selectedUids.add(sid);
                              else selectedUids.remove(sid);
                            });
                          },
                          secondary: CircleAvatar(
                            backgroundColor: AppTheme.accentBlue.withOpacity(0.1),
                            child: Text(student['name']?[0].toUpperCase() ?? 'S', style: TextStyle(color: AppTheme.accentBlue)),
                          ),
                          activeColor: AppTheme.accentBlue,
                        );
                      },
                    ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
                ElevatedButton(
                  onPressed: selectedUids.isEmpty ? null : () {
                    for (var sid in selectedUids) {
                      firestoreService.startCall(
                        roomId: roomId,
                        callerId: uid,
                        callerName: auth.userModel?.name ?? 'Mentor',
                        receiverId: sid,
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text("Invite Selected (${selectedUids.length})"),
                ),
              ],
            );
          }
        ),
      );
    }
  }
}
