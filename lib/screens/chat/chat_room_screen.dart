import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestoreService = FirestoreService();

  String? _roomId;
  String? _otherUserName;
  String? _otherUserId;
  Stream<QuerySnapshot>? _messagesStream;
  bool _isUploading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _roomId = args['roomId'] as String?;
      _otherUserId = args['otherUserId'] as String?;
      _otherUserName = args['otherUserName'] as String? ?? 'User';

      // Mark messages as read
      final currentUid =
          Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
      if (_roomId != null && currentUid != null) {
        _firestoreService.markMessagesRead(_roomId!, currentUid);
        _messagesStream ??= _firestoreService.messagesStream(_roomId!);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _roomId == null) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUid = authProvider.userModel?.uid ?? '';

    final msgId = FirebaseFirestore.instance.collection('_').doc().id;
    _firestoreService.sendMessage(_roomId!, {
      'id': msgId,
      'content': _messageController.text.trim(),
      'senderId': currentUid,
      'receiverId': _otherUserId ?? '',
      'timestamp': Timestamp.now(),
      'type': 'text',
    });
    _messageController.clear();
  }

  Future<void> _uploadFile() async {
    if (_roomId == null) return;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media, // Allows picking images & videos
    );
    if (result == null || result.files.single.path == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUid = authProvider.userModel?.uid ?? '';
    final msgId = FirebaseFirestore.instance.collection('_').doc().id;
    
    setState(() => _isUploading = true);
    try {
      final File file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      
      final url = await _firestoreService.uploadChatFile(_roomId!, msgId, file);

      final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].any((ext) => fileName.toLowerCase().endsWith(ext));
      final type = isImage ? 'image' : 'file'; // Treating video as a downloadable file for simplicity here

      _firestoreService.sendMessage(_roomId!, {
        'id': msgId,
        'content': url,
        'fileName': fileName,
        'senderId': currentUid,
        'receiverId': _otherUserId ?? '',
        'timestamp': Timestamp.now(),
        'type': type,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload file')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showScheduleMeetingDialog() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    final titleController = TextEditingController(text: 'Study Session');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Schedule Meeting', style: TextStyle(color: AppTheme.primaryNavy, fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Meeting Title',
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today_rounded, color: AppTheme.accentBlue),
                title: Text(DateFormat('EEE, MMM d, yyyy').format(selectedDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) setDialogState(() => selectedDate = picked);
                },
              ),
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.access_time_rounded, color: AppTheme.accentPurple),
                title: Text(selectedTime.format(ctx)),
                onTap: () async {
                  final picked = await showTimePicker(context: ctx, initialTime: selectedTime);
                  if (picked != null) setDialogState(() => selectedTime = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)))),
            ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(ctx, listen: false);
                final uid = auth.userModel?.uid ?? '';
                final scheduledAt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                final meetingId = FirebaseFirestore.instance.collection('_').doc().id;
                await _firestoreService.scheduleMeeting({
                  'id': meetingId,
                  'title': titleController.text.trim(),
                  'scheduledAt': Timestamp.fromDate(scheduledAt),
                  'createdBy': uid,
                  'participants': [uid, _otherUserId ?? ''],
                  'roomId': _roomId ?? '',
                  'status': 'scheduled',
                });
                // Send system message
                final msgId = FirebaseFirestore.instance.collection('_').doc().id;
                await _firestoreService.sendMessage(_roomId!, {
                  'id': msgId,
                  'content': '📅 Meeting scheduled: ${titleController.text.trim()} on ${DateFormat('MMM d').format(scheduledAt)} at ${selectedTime.format(ctx)}',
                  'senderId': uid,
                  'receiverId': _otherUserId ?? '',
                  'timestamp': Timestamp.now(),
                  'type': 'meeting',
                  'scheduledAt': Timestamp.fromDate(scheduledAt),
                  'meetingTitle': titleController.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Meeting scheduled!'),
                      backgroundColor: AppTheme.successGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
    titleController.dispose;
  }

  @override
  Widget build(BuildContext context) {
    final currentUid =
        Provider.of<AuthProvider>(context, listen: false).userModel?.uid ?? '';
    final displayName = _otherUserName ?? 'Chat';

    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0] : 'U',
                      style: TextStyle(
                          color: AppTheme.accentBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                Text('Tap for info',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ],
        ),
        actions: [
          if ((Provider.of<AuthProvider>(context, listen: false).userModel?.role ?? 'student') == 'mentor')
            IconButton(
              icon:
                  const Icon(Icons.videocam_rounded, color: AppTheme.accentBlue),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.videoCall, arguments: {
                  'roomId': _roomId ?? 'default',
                  'otherUserName': _otherUserName ?? 'User',
                });
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'schedule') _showScheduleMeetingDialog();
            },
            itemBuilder: (context) {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final role = auth.userModel?.role ?? 'student';
              return [
                if (role == 'mentor')
                  const PopupMenuItem(value: 'schedule', child: Text('Schedule Meeting')),
                const PopupMenuItem(value: 'info', child: Text('Contact Info')),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages from Firestore
          Expanded(
            child: _roomId == null || _messagesStream == null
                ? const Center(child: Text('No chat room selected'))
                : StreamBuilder<QuerySnapshot>(
                    stream: _messagesStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 48),
                              const SizedBox(height: 12),
                              Text('No messages yet',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Say hello! 👋',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                      fontSize: 14)),
                            ],
                          ),
                        );
                      }

                      // Auto-scroll to bottom
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            _scrollController.position.maxScrollExtent,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          );
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final msg =
                              docs[index].data() as Map<String, dynamic>;
                          final isMe = msg['senderId'] == currentUid;
                          final time = msg['timestamp'] as Timestamp?;
                          final timeStr = time != null
                              ? '${time.toDate().hour}:${time.toDate().minute.toString().padLeft(2, '0')}'
                              : '';
                          return _buildMessageBubble(
                            msg,
                            isMe,
                            timeStr,
                          );
                        },
                      );
                    },
                  ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: _isUploading 
                        ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            icon: Icon(Icons.attach_file_rounded,
                                color: AppTheme.accentBlue, size: 20),
                            onPressed: _uploadFile,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryNavy,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, String time) {
    final type = msg['type'] as String? ?? 'text';
    final content = msg['content'] as String? ?? '';
    final fileName = msg['fileName'] as String?;

    Widget messageContent;

    if (type == 'image') {
      messageContent = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: content,
          width: 200,
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(width: 50, height: 50, child: Center(child: CircularProgressIndicator())),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        ),
      );
    } else if (type == 'file') {
      messageContent = InkWell(
        onTap: () => launchUrl(Uri.parse(content), mode: LaunchMode.externalApplication),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: isMe ? Colors.white : AppTheme.primaryNavy),
            const SizedBox(width: 8),
            Flexible(child: Text(fileName ?? 'File', style: TextStyle(color: isMe ? Colors.white : AppTheme.primaryNavy, decoration: TextDecoration.underline))),
          ],
        ),
      );
    } else if (type == 'meeting' || type == 'system') {
      final scheduledAt = (msg['scheduledAt'] as Timestamp?)?.toDate();
      final isNow = scheduledAt != null && DateTime.now().isAfter(scheduledAt);
      
      messageContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content, style: TextStyle(color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface, fontSize: 15)),
          if (scheduledAt != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isNow ? () {
                  Navigator.pushNamed(context, AppRoutes.videoCall, arguments: {
                    'roomId': _roomId ?? 'default',
                    'otherUserName': _otherUserName ?? 'User',
                  });
                } : null,
                icon: const Icon(Icons.videocam_rounded, size: 20),
                label: Text(isNow ? 'Join Meeting' : 'Scheduled', style: const TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.5),
                  disabledForegroundColor: Colors.white70,
                ),
              ),
            ),
          ],
        ],
      );
    } else {
      messageContent = Text(
        content,
        style: TextStyle(
          color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
          fontSize: 15,
          height: 1.4,
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryNavy : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
          boxShadow: isMe ? [] : AppTheme.cardBoxShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            messageContent,
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color:
                    isMe ? Colors.white.withOpacity(0.6) : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

