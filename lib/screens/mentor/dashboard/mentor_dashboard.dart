import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/stat_card.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
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
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
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
                    child: const Icon(Icons.school_rounded, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VidyaSetu', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(
                        DateFormat('EEEE, MMM d').format(now).toUpperCase(),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome back,\n${user?.name ?? "Mentor"}!',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5),
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
              label: 'Students',
              value: '${_students.length}',
              icon: Icons.people_rounded,
              isDark: true,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: StatCard(
              label: 'Pending\nRequests',
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
            Text('Student Activity', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.myStudents),
              child: Text('View All', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_students.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.people_outline_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'No connected students yet. Students can find and connect with you from the Mentors screen.',
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
        Text('Pending Requests', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.mentorRequestsStream(uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: AppTheme.successGreen, size: 28),
                    const SizedBox(width: 14),
                    Text('No pending requests', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
                  ],
                ),
              );
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
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
                          child: const Icon(Icons.person_add_rounded, color: AppTheme.accentBlue, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600)),
                              Text('Wants to connect', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
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
        Text('Quick Actions', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionCard('Guidance', Icons.rate_review_rounded, AppTheme.warningAmber, () => Navigator.pushNamed(context, AppRoutes.feedbackHistory)),
            const SizedBox(width: 12),         
            _actionCard('Analytics', Icons.analytics_rounded, AppTheme.accentPurple, () => Navigator.pushNamed(context, AppRoutes.studentAnalyticsMentor)),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: Column(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

