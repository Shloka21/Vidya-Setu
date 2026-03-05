import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';

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
      final snapshot = await _firestoreService.searchMentors();
      setState(() {
        _mentors = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        _filteredMentors = _mentors;
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
      if (query.isEmpty) {
        _filteredMentors = _mentors;
      } else {
        _filteredMentors = _mentors.where((m) {
          final name = (m['name'] as String? ?? '').toLowerCase();
          final subjects =
              (List<String>.from(m['subjectsTaught'] ?? [])).join(' ').toLowerCase();
          return name.contains(query.toLowerCase()) ||
              subjects.contains(query.toLowerCase());
        }).toList();
      }
    });
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
        'createdAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent to ${mentor['name']}!'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
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
    return Scaffold(
      
      appBar: AppBar(title: const Text('Find a Mentor')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMentors,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name or subject...',
                hintStyle: TextStyle(color: AppTheme.textLight),
                prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary),
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
                ? const Center(child: CircularProgressIndicator())
                : _filteredMentors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded, color: AppTheme.textLight, size: 64),
                            const SizedBox(height: 16),
                            Text('No mentors found',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 18, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text('Try a different search term',
                                style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filteredMentors.length,
                        itemBuilder: (context, index) {
                          final mentor = _filteredMentors[index];
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
    final students = mentor['studentCount'] ?? 0;
    final maxStudents = mentor['maxStudents'] ?? 20;
    final yearsExp = mentor['experienceYears'] ?? 0;
    final bio = mentor['bio'] as String? ?? '';
    final mentorId = mentor['uid'] as String? ?? '';
    final status = _connectionStatus[mentorId]; // null, 'pending', 'approved', 'rejected'

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
                      Text(name, style: TextStyle(color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                      if (subjects.isNotEmpty)
                        Text(subjects.join(', '),
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: AppTheme.warningAmber, size: 18),
                        Text(' ${rating.toStringAsFixed(1)}',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    Text('$yearsExp yrs', style: TextStyle(color: AppTheme.textLight, fontSize: 11)),
                  ],
                ),
              ],
            ),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(bio,
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: students < maxStudents
                        ? AppTheme.successGreen.withOpacity(0.1)
                        : AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    students < maxStudents ? '${maxStudents - students} spots available' : 'Full',
                    style: TextStyle(
                      color: students < maxStudents ? AppTheme.successGreen : AppTheme.errorRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                _buildConnectionButton(mentor, status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionButton(Map<String, dynamic> mentor, String? status) {
    final students = mentor['studentCount'] ?? 0;
    final maxStudents = mentor['maxStudents'] ?? 20;

    if (status == 'approved') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 16),
                const SizedBox(width: 4),
                Text('Connected', style: TextStyle(color: AppTheme.successGreen, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => _openChat(mentor),
              icon: const Icon(Icons.chat_rounded, size: 16),
              label: const Text('Message', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      );
    }

    if (status == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.warningAmber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, color: AppTheme.warningAmber, size: 16),
            const SizedBox(width: 4),
            Text('Request Sent', style: TextStyle(color: AppTheme.warningAmber, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    // No connection or rejected — show Connect button
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: students < maxStudents ? () => _sendRequest(mentor) : null,
        icon: const Icon(Icons.person_add_rounded, size: 16),
        label: const Text('Connect', style: TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}
