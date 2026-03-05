import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/app_card.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userModel?.uid ?? '';
    final userRole = authProvider.userModel?.role ?? 'student';

    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded), onPressed: () {}),
        ],
      ),
      body: currentUserId.isEmpty
          ? const Center(child: Text('Please log in to view messages'))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.chatRoomsStream(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 48),
                        const SizedBox(height: 12),
                        Text('Error loading chats', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _buildEmptyState(currentUserId, userRole);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final participants = List<String>.from(data['participants'] ?? []);
                    final otherUserId = participants.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => '');
                    final unreadCount =
                        (data['unreadCount'] as Map<String, dynamic>?)?[currentUserId] ?? 0;
                    final lastMessage = data['lastMessage'] as String? ?? 'No messages yet';
                    final lastTime = data['lastMessageTime'] as Timestamp?;
                    final timeStr = lastTime != null ? _formatTime(lastTime.toDate()) : '';

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _firestoreService.getUser(otherUserId),
                      builder: (context, userSnap) {
                        final userName = userSnap.data?['name'] as String? ?? 'User';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            padding: const EdgeInsets.all(16),
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.chatConversation,
                                arguments: {
                                  'roomId': docs[index].id,
                                  'otherUserId': otherUserId,
                                  'otherUserName': userName,
                                }),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentBlue.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      userName.isNotEmpty ? userName[0] : 'U',
                                      style: TextStyle(
                                        color: AppTheme.accentBlue,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              userName,
                                              style: TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 16,
                                                fontWeight: unreadCount > 0
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            timeStr,
                                            style: TextStyle(
                                              color: unreadCount > 0
                                                  ? AppTheme.accentBlue
                                                  : AppTheme.textLight,
                                              fontSize: 12,
                                              fontWeight: unreadCount > 0
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              lastMessage,
                                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (unreadCount > 0) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: const BoxDecoration(
                                                color: AppTheme.accentBlue,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '$unreadCount',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(String currentUserId, String userRole) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: userRole == 'student'
          ? _firestoreService.getConnectedMentors(currentUserId)
          : _firestoreService.getConnectedStudents(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final connectedUsers = snapshot.data ?? [];

        if (connectedUsers.isEmpty) {
          // No connections at all
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.people_outline_rounded, color: AppTheme.accentBlue, size: 40),
                  ),
                  const SizedBox(height: 20),
                  Text('No conversations yet',
                      style: TextStyle(color: AppTheme.primaryNavy, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    userRole == 'student'
                        ? 'Connect with a mentor to start chatting!'
                        : 'Accept student requests to start chatting!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                  ),
                  if (userRole == 'student') ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.findMentor),
                      icon: const Icon(Icons.person_search_rounded, size: 18),
                      label: const Text('Find a Mentor'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        // Has connections but no messages — show suggestions
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.textLight, size: 48),
                    const SizedBox(height: 12),
                    Text('No messages yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'SUGGESTED CONVERSATIONS',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              ...connectedUsers.map((user) {
                final name = user['name'] as String? ?? 'User';
                final role = user['role'] as String? ?? '';
                final subjects = List<String>.from(user['subjectsTaught'] ?? []);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    onTap: () async {
                      final uid = user['uid'] as String? ?? '';
                      if (uid.isEmpty) return;
                      final roomId = await _firestoreService.getOrCreateChatRoom(currentUserId, uid);
                      if (mounted) {
                        Navigator.pushNamed(context, AppRoutes.chatConversation, arguments: {
                          'roomId': roomId,
                          'otherUserId': uid,
                          'otherUserName': name,
                        });
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.accentPurple.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0] : 'U',
                              style: TextStyle(color: AppTheme.accentPurple, fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                              Text(
                                role == 'mentor'
                                    ? (subjects.isNotEmpty ? subjects.join(', ') : 'Mentor')
                                    : 'Student',
                                style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryNavy.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_rounded, color: AppTheme.primaryNavy, size: 20),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}';
  }
}
