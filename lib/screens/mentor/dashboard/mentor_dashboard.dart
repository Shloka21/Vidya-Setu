import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/stat_card.dart';
import 'package:vidyasetu/services/localization_service.dart';
import '../../../widgets/common/translated_text.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  final FirestoreService _firestore = FirestoreService();
  List<Map<String, dynamic>> _students = [];
  int _pendingRequests = 0;
  bool _loading = true;
  StreamSubscription? _chatSubscription;
  final Set<String> _processedIds = {};
  final DateTime _sessionStart = DateTime.now().subtract(const Duration(seconds: 10));
  Timer? _activeHeartbeatTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreamObservers();

    // Setup WhatsApp-style lastActive heartbeat
    _activeHeartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
      if (uid != null && mounted) {
        _firestore.updateUser(uid, {'lastActive': Timestamp.now()});
      }
    });

    // Set initial heartbeat immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
      if (uid != null && mounted) {
        _firestore.updateUser(uid, {'lastActive': Timestamp.now()});
      }
    });
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _activeHeartbeatTimer?.cancel();
    super.dispose();
  }

  void _setupStreamObservers() {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) return;

    final notifService = NotificationService();

    // Observer for Chat Messages
    _chatSubscription = _firestore.chatRoomsStream(uid).listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lastMessageSenderId = data['lastMessageSenderId'] as String?;
        final lastMessageTime = (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now();
        final roomId = doc.id;
        final lastMsgText = data['lastMessage'] as String? ?? '';

        // Only notify if the last message is from someone else and arrived after app start
        if (lastMessageSenderId != null && 
            lastMessageSenderId != uid && 
            lastMessageTime.isAfter(_sessionStart) &&
            !_processedIds.contains('$roomId-$lastMessageTime')) {
          
          _processedIds.add('$roomId-$lastMessageTime');
          
          notifService.showChatNotification(
            senderName: 'Vidyasetu',
            message: lastMsgText,
            roomId: roomId,
            senderId: lastMessageSenderId,
          );
        }
      }
    });
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userModel?.uid;
    if (uid == null) { setState(() => _loading = false); return; }
    try {
      final students = await _firestore.getConnectedStudents(uid);
      final pending = await _firestore.getPendingRequestsCount(uid);
      if (mounted) {
        setState(() {
          _students = students;
          _pendingRequests = pending;
          _loading = false;
        });
      }

      // Check if mentor has completed profile setup
      final user = auth.userModel;
      if (user != null && (user.bio == null || user.bio!.isEmpty)) {
        _showOnboardingDialog(uid);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showOnboardingDialog(String uid) {
    final bioCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final langCtrl = TextEditingController(text: 'English, Hindi');
    final availCtrl = TextEditingController(text: 'Mon-Fri, 4:00 PM - 8:00 PM');
    final specCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.waving_hand_rounded, color: AppTheme.warningAmber, size: 28),
              const SizedBox(width: 10),
              Expanded(child: Text(context.tr('welcome_mentor'), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('complete_profile_desc'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14)),
                const SizedBox(height: 16),
                _onboardField(bioCtrl, context.tr('bio'), 'Tell students about yourself...', maxLines: 3),
                const SizedBox(height: 12),
                _onboardField(expCtrl, context.tr('years_of_experience'), 'e.g. 5'),
                const SizedBox(height: 12),
                _onboardField(langCtrl, context.tr('languages'), 'e.g. English, Hindi, Marathi'),
                const SizedBox(height: 12),
                _onboardField(availCtrl, context.tr('availability'), 'e.g. Mon-Fri, 4-8 PM'),
                const SizedBox(height: 12),
                _onboardField(specCtrl, context.tr('specialization'), 'e.g. Mathematics, Physics'),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final bio = bioCtrl.text.trim();
                  final exp = int.tryParse(expCtrl.text.trim()) ?? 0;
                  final langs = langCtrl.text.trim();
                  final avail = availCtrl.text.trim();
                  final specs = specCtrl.text.trim().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

                  await _firestore.updateUser(uid, {
                    'bio': bio,
                    'experienceYears': exp,
                    'languages': langs,
                    'availability': avail,
                    if (specs.isNotEmpty) 'subjectsTaught': specs,
                    'profileCompleted': true,
                  });

                  // Refresh auth provider
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  await auth.refreshUser();

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.tr('profile_setup_complete')),
                        backgroundColor: AppTheme.successGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(context.tr('save_continue'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _onboardField(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  String _lastActiveLabel(Map<String, dynamic> student) {
    final lastActive = student['lastActive'];
    if (lastActive == null) return 'Unknown';
    DateTime dt;
    if (lastActive is Timestamp) {
      dt = lastActive.toDate();
    } else {
      return 'Unknown';
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 5) return context.tr('active_now');
    if (diff.inMinutes < 60) return context.tr('active_mins_ago').replaceFirst('{}', diff.inMinutes.toString());
    if (diff.inHours < 24) return context.tr('active_hours_ago').replaceFirst('{}', diff.inHours.toString());
    if (diff.inDays < 7) return context.tr('active_days_ago').replaceFirst('{}', diff.inDays.toString());
    return context.tr('inactive_days').replaceFirst('{}', diff.inDays.toString());
  }

  Color _activityColor(Map<String, dynamic> student) {
    final lastActive = student['lastActive'];
    if (lastActive == null) return Colors.grey;
    DateTime dt;
    if (lastActive is Timestamp) {
      dt = lastActive.toDate();
    } else {
      return Colors.grey;
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inHours < 1) return Colors.green;
    if (diff.inHours < 24) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildQuickStats(),
              const SizedBox(height: 24),
              _buildStudentActivity(),
              const SizedBox(height: 24),
              _buildPendingRequests(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final now = DateTime.now();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.school_rounded, size: 20, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('vidyasetu'), 
                           style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              letterSpacing: -0.5,
                            )),
                      Text(
                        DateFormat('EEEE, MMM d', Provider.of<LocalizationService>(context).locale).format(now).toUpperCase(),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '${context.tr('welcome_back')},\n${user?.name ?? "Mentor"}!',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.mentorProfileScreen),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.successGreen, width: 2.5),
                ),
                child: Center(
                  child: user?.profileImageUrl != null
                      ? ClipOval(child: Image.network(user!.profileImageUrl!, fit: BoxFit.cover, width: 52, height: 52))
                      : Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'M',
                          style: TextStyle(color: AppTheme.accentPurple, fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.chatList),
              child: StreamBuilder<int>(
                stream: _firestore.totalUnreadCountStream(
                    Provider.of<AuthProvider>(context, listen: false).userModel?.uid ?? ''),
                builder: (context, snapshot) {
                  final unread = snapshot.data ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle, boxShadow: AppTheme.cardBoxShadow),
                        child: Center(child: Icon(Icons.chat_bubble_outline_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 22)),
                      ),
                      if (unread > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppTheme.errorRed, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            child: Center(
                              child: Text(
                                unread > 99 ? '99+' : '$unread',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: context.tr('students'),
              value: '${_students.length}',
              icon: Icons.people_rounded,
              iconColor: AppTheme.accentBlue,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: StatCard(
              label: context.tr('pending_requests_1'),
              value: '$_pendingRequests',
              icon: Icons.person_add_rounded,
              iconColor: AppTheme.accentPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(context.tr('student_activity'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.myStudents),
              child: Text(context.tr('view_all'), style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        SizedBox(height: 12),
        if (_loading)
          Center(child: CircularProgressIndicator())
        else if (_students.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    context.tr('no_connected_students_yet_students_can_f'),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ...(_students.take(3).map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildStudentActivityItem(s),
          ))),
      ],
    );
  }

  Widget _buildStudentActivityItem(Map<String, dynamic> student) {
    final name = student['name'] ?? 'Student';
    final status = _lastActiveLabel(student);
    final statusColor = _activityColor(student);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: student['profileImageUrl'] != null
                ? ClipOval(child: Image.network(student['profileImageUrl'], fit: BoxFit.cover, width: 46, height: 46))
                : Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: TextStyle(color: AppTheme.accentBlue, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(status, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble_outline_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
            onPressed: () async {
              final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
              if (uid == null) return;
              final roomId = await _firestore.getOrCreateChatRoom(uid, student['uid']);
              if (mounted) {
                Navigator.pushNamed(context, AppRoutes.chatConversation, arguments: {
                  'roomId': roomId,
                  'otherUserName': name,
                  'otherUserId': student['uid'],
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequests() {
    final uid = Provider.of<AuthProvider>(context).userModel?.uid;
    if (uid == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('pending_requests'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
        SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.mentorRequestsStream(uid),
          builder: (context, snapshot) {
            final incomingDocs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['requestedBy'] != uid;
            }).toList();

            if (incomingDocs.isEmpty) {
              return AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: AppTheme.successGreen, size: 28),
                    SizedBox(width: 14),
                    Text(context.tr('no_pending_requests'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
                  ],
                ),
              );
            }

            return Column(
              children: incomingDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['studentName'] ?? 'Student';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.person_add_rounded, color: AppTheme.accentBlue, size: 22),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                              Text(context.tr('wants_to_connect'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: AppTheme.successGreen),
                              onPressed: () async {
                                await _firestore.updateConnectionStatus(doc.id, 'approved');
                                _loadData();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: AppTheme.errorRed),
                              onPressed: () async {
                                await _firestore.updateConnectionStatus(doc.id, 'rejected');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final cs = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('quick_actions'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(  
            children: [
              // 🔵 Main Button
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.studentAnalyticsMentor);
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.groups_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('student_analytics'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ⚪ Bottom Small Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMiniCard(
                      icon: Icons.rate_review_rounded,
                      label: context.tr('feedback'),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.feedbackHistory),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildMiniCard(
                      icon: Icons.notifications_active_rounded,
                      label: context.tr('reminders'),
                      onTap: () => Navigator.pushNamed(context, AppRoutes.mentorRemindersList),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

