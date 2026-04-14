import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart' show navigatorKey;
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import 'package:vidyasetu/services/localization_service.dart';

class GlobalCallListener extends StatefulWidget {
  final Widget child;
  const GlobalCallListener({super.key, required this.child});

  @override
  State<GlobalCallListener> createState() => _GlobalCallListenerState();
}

class _GlobalCallListenerState extends State<GlobalCallListener> {
  String? _lastNotifiedCallId;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final uid = auth.userModel?.uid;

    if (uid == null) return widget.child;

    return Stack(
      children: [
        widget.child,
        StreamBuilder<QuerySnapshot>(
          stream: FirestoreService().incomingCallsStream(uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }

            final callDoc = snapshot.data!.docs.first;
            final callData = callDoc.data() as Map<String, dynamic>;
            final roomId = callData['roomId'] as String;
            final callerName = callData['callerName'] as String? ?? 'Someone';

            // Show UI Overlay
            return _IncomingCallOverlay(
              callerName: callerName,
              onAccept: () {
                final args = {
                  'roomId': roomId,
                  'otherUserName': callerName,
                  'otherUserId': callData['callerId'],
                  'receiverId': uid,
                  'autoStart': true,
                };

                // 1. Trigger navigation immediately using the Global Navigator Key
                // This works even if the current context doesn't have a Navigator
                navigatorKey.currentState?.pushNamed(
                  AppRoutes.videoCall,
                  arguments: args,
                );

                // 2. Update status in background to hide the popup
                FirestoreService().updateCallStatus(roomId, uid, 'accepted');
              },
              onDecline: () {
                FirestoreService().updateCallStatus(roomId, uid, 'declined');
              },
            );
          },
        ),
      ],
    );
  }
}

class _IncomingCallOverlay extends StatelessWidget {
  final String callerName;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingCallOverlay({
    required this.callerName,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: AppTheme.accentBlue.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_received_rounded, color: AppTheme.accentBlue),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('incoming_call') ?? 'Incoming Call',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          callerName,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CallButton(
                        icon: Icons.close_rounded,
                        color: AppTheme.errorRed,
                        onPressed: onDecline,
                      ),
                      const SizedBox(width: 12),
                      _CallButton(
                        icon: Icons.check_rounded,
                        color: AppTheme.successGreen,
                        onPressed: onAccept,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CallButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
