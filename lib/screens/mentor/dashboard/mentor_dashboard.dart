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
  StreamSubscription? _notifSubscription;
  final Set<String> _processedNotifIds = {};
  Timer? _activeHeartbeatTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupNotificationListener();

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
    _notifSubscription?.cancel();
    _activeHeartbeatTimer?.cancel();
    super.dispose();
  }

  void _setupNotificationListener() {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null) return;

    _notifSubscription = _firestore.unreadNotificationsStream(uid).listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final id = data['id'] as String? ?? doc.id;
        if (_processedNotifIds.contains(id)) continue;
        _processedNotifIds.add(id);

        final type = data['type'] as String? ?? '';
        final notifService = NotificationService();

        if (type == 'chat') {
          notifService.showChatNotification(
            senderName: data['senderName'] ?? 'Student',
            message: data['message'] ?? 'New message',
            roomId: data['roomId'] ?? '',
            senderId: data['senderId'] ?? '',
          );
        }

        _firestore.markNotificationRead(uid, id);
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
              Expanded(child: Text('Welcome, Mentor!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Complete your profile so students can find you.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14)),
                const SizedBox(height: 16),
                _onboardField(bioCtrl, 'Bio', 'Tell students about yourself...', maxLines: 3),
                const SizedBox(height: 12),
                _onboardField(expCtrl, 'Years of Experience', 'e.g. 5'),
                const SizedBox(height: 12),
                _onboardField(langCtrl, 'Languages', 'e.g. English, Hindi, Marathi'),
                const SizedBox(height: 12),
                _onboardField(availCtrl, 'Availability', 'e.g. Mon-Fri, 4-8 PM'),
                const SizedBox(height: 12),
                _onboardField(specCtrl, 'Specialization', 'e.g. Mathematics, Physics'),
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
                        content: Text('Profile setup complete! 🎉'),
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
                child: const Text('Save & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
    if (diff.inMinutes < 5) return 'Active now';
    if (diff.inMinutes < 60) return 'Active ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Active ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Active ${diff.inDays}d ago';
    return 'Inactive ${diff.inDays}d';
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
              isDark: true,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: StatCard(
              label: context.tr('pending_requests_1'),
              value: '$_pendingRequests',
              icon: Icons.person_add_rounded,
              isDark: true,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('quick_actions'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 20)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildPremiumCard(
                title: context.tr('guidance'),
                subtitle: context.tr('send_feedback') ?? 'Send feedback',
                icon: Icons.rate_review_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, AppRoutes.feedbackHistory),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPremiumCard(
                title: context.tr('analytics'),
                subtitle: context.tr('student_progress') ?? 'Student progress',
                icon: Icons.analytics_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, AppRoutes.studentAnalyticsMentor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPremiumCard(
                title: context.tr('my_students'),
                subtitle: context.tr('manage_students') ?? 'Manage students',
                icon: Icons.groups_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0acffe), Color(0xFF495aff)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, AppRoutes.myStudents),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPremiumCard(
                title: context.tr('settings'),
                subtitle: context.tr('preferences') ?? 'Preferences',
                icon: Icons.settings_rounded,
                gradient: const LinearGradient(
                  colors: [Color(0xFFfa709a), Color(0xFFfee140)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, AppRoutes.mentorSettings),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPremiumCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (gradient as LinearGradient).colors.first.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -12,
              top: -12,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: -8,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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

