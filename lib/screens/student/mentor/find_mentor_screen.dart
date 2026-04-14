import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';
import 'package:vidyasetu/services/localization_service.dart';

class FindMentorScreen extends StatefulWidget {
  const FindMentorScreen({super.key});

  @override
  State<FindMentorScreen> createState() => _FindMentorScreenState();
}

class _FindMentorScreenState extends State<FindMentorScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _mentors = [];
  List<Map<String, dynamic>> _filteredMentors = [];
  Map<String, String> _connectionStatus = {}; // mentorId -> status
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMentors();
    _loadConnectionStatuses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMentors() async {
    try {
      // Load all mentors. Filtering by availability/connection 
      // is handled dynamically in _getDisplayMentors()
      final snapshot = await _firestoreService.searchMentors(onlyAvailable: false);
      setState(() {
        _mentors = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading mentors: $e');
    }
  }

  Future<void> _loadConnectionStatuses() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final studentId = auth.userModel?.uid ?? '';
    if (studentId.isEmpty) return;

    _firestoreService.studentConnectionsStream(studentId).listen((snapshot) {
      if (!mounted) return;
      final statuses = <String, String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final mentorId = data['mentorId'] as String? ?? '';
        final status = data['status'] as String? ?? '';
        if (mentorId.isNotEmpty) statuses[mentorId] = status;
      }
      setState(() => _connectionStatus = statuses);
    });
  }

  void _filterMentors(String query) {
    setState(() {
      // _filterMentors now just triggers a rebuild; the actual filtering happens in _getDisplayMentors
    });
  }

  List<Map<String, dynamic>> _getDisplayMentors() {
    final query = _searchController.text.toLowerCase();
    
    // First, filter by availability and connection status
    final baseMentors = _mentors.where((mentor) {
      final isAvailable = mentor['availableForNew'] ?? true;
      final mentorId = mentor['uid'] as String? ?? '';
      final hasConnection = _connectionStatus.containsKey(mentorId);
      return isAvailable || hasConnection;
    }).toList();

    // Then, filter by search query
    if (query.isEmpty) return baseMentors;

    return baseMentors.where((m) {
      final name = (m['name'] as String? ?? '').toLowerCase();
      final subjects =
          (List<String>.from(m['subjectsTaught'] ?? [])).join(' ').toLowerCase();
      return name.contains(query) || subjects.contains(query);
    }).toList();
  }

  Future<void> _sendRequest(Map<String, dynamic> mentor) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final studentId = auth.userModel?.uid ?? '';
    final studentName = auth.userModel?.name ?? '';
    final mentorId = mentor['uid'] as String? ?? '';

    if (studentId.isEmpty || mentorId.isEmpty) return;

    try {
      final reqId = FirebaseFirestore.instance.collection('_').doc().id;
      await _firestoreService.sendMentorRequest({
        'id': reqId,
        'studentId': studentId,
        'studentName': studentName,
        'mentorId': mentorId,
        'mentorName': mentor['name'] ?? '',
        'status': 'pending',
        'requestedBy': studentId, // Explicitly identify sender
        'createdAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr('request_sent_to')} ${mentor['name']}!'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<void> _openChat(Map<String, dynamic> mentor) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userModel?.uid ?? '';
    final mentorId = mentor['uid'] as String? ?? '';
    if (uid.isEmpty || mentorId.isEmpty) return;

    final roomId = await _firestoreService.getOrCreateChatRoom(uid, mentorId);
    if (mounted) {
      Navigator.pushNamed(context, AppRoutes.chatConversation, arguments: {
        'roomId': roomId,
        'otherUserId': mentorId,
        'otherUserName': mentor['name'] ?? 'Mentor',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayMentors = _getDisplayMentors();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('find_a_mentor'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMentors,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: context.tr('search_by_name_or_subject'),
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : displayMentors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 64),
                            SizedBox(height: 16),
                            Text(context.tr('no_mentors_found'),
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 18, fontWeight: FontWeight.w600)),
                            SizedBox(height: 8),
                            Text(context.tr('try_a_different_search_term'),
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: displayMentors.length,
                        itemBuilder: (context, index) {
                          final mentor = displayMentors[index];
                          return _buildMentorCard(mentor);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorCard(Map<String, dynamic> mentor) {
    final name = mentor['name'] as String? ?? 'Mentor';
    final subjects = List<String>.from(mentor['subjectsTaught'] ?? []);
    final rating = (mentor['rating'] ?? 0).toDouble();
    final yearsExp = mentor['experienceYears'] ?? 0;
    final bio = mentor['bio'] as String? ?? '';
    final mentorId = mentor['uid'] as String? ?? '';
    final status = _connectionStatus[mentorId];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => Navigator.pushNamed(context, AppRoutes.mentorProfile, arguments: mentor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0] : 'M',
                      style: TextStyle(color: AppTheme.accentBlue, fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 17, fontWeight: FontWeight.w700)),
                      if (subjects.isNotEmpty)
                        Text(subjects.join(', '),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (status == 'approved') ...[
                  IconButton(
                    onPressed: () => _openChat(mentor),
                    icon: Icon(Icons.chat_rounded, color: AppTheme.accentBlue, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: AppTheme.warningAmber, size: 18),
                        Text(' ${rating.toStringAsFixed(1)}',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Text('$yearsExp yrs', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 11)),
                  ],
                ),
              ],
            ),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(bio,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 16),
            // Full-width Connect button
            _buildConnectionButton(mentor, status),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionButton(Map<String, dynamic> mentor, String? status) {
    String labelText = context.tr('connect');
    IconData iconData = Icons.person_add_rounded;
    Color btnColor = AppTheme.accentBlue;
    VoidCallback? onPressed = () => _sendRequest(mentor);

    if (status == 'approved') {
      labelText = context.tr('connected');
      iconData = Icons.check_circle_rounded;
      btnColor = AppTheme.successGreen;
      onPressed = null; // Already connected
    } else if (status == 'pending') {
      labelText = context.tr('request_sent') ?? 'Connection Sent';
      iconData = Icons.hourglass_top_rounded;
      btnColor = AppTheme.warningAmber;
      onPressed = null; // Wait for response
    }

    return SizedBox(
      width: double.infinity,
      height: 40, // Increased height to accommodate larger font
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(iconData, size: 22),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            labelText,
            style: const TextStyle(
              fontSize: 15, 
              fontWeight: FontWeight.w600, 
              letterSpacing: 0.5,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: btnColor.withOpacity(0.8),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16), // Explicit horizontal padding
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}
