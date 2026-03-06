import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';

class BrowseStudentsScreen extends StatefulWidget {
  const BrowseStudentsScreen({super.key});

  @override
  State<BrowseStudentsScreen> createState() => _BrowseStudentsScreenState();
}

class _BrowseStudentsScreenState extends State<BrowseStudentsScreen> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _filtered = [];
  Map<String, String> _connectionStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadConnectionStatuses();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final snapshot = await _firestore.searchStudents();
      final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
      setState(() {
        _students = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((s) => s['uid'] != uid) // exclude self
            .toList();
        _filtered = _students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading students: $e');
    }
  }

  void _loadConnectionStatuses() {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid ?? '';
    if (uid.isEmpty) return;
    _firestore.mentorSentConnectionsStream(uid).listen((snapshot) {
      if (!mounted) return;
      final statuses = <String, String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final studentId = data['studentId'] as String? ?? '';
        final status = data['status'] as String? ?? '';
        if (studentId.isNotEmpty) statuses[studentId] = status;
      }
      setState(() => _connectionStatus = statuses);
    });
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = _students;
      } else {
        _filtered = _students.where((s) {
          final name = (s['name'] as String? ?? '').toLowerCase();
          final course = (s['course'] as String? ?? '').toLowerCase();
          final institution = (s['institution'] as String? ?? '').toLowerCase();
          return name.contains(query.toLowerCase()) ||
              course.contains(query.toLowerCase()) ||
              institution.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _sendRequest(Map<String, dynamic> student) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final mentorId = auth.userModel?.uid ?? '';
    final mentorName = auth.userModel?.name ?? '';
    final studentId = student['uid'] as String? ?? '';

    if (mentorId.isEmpty || studentId.isEmpty) return;

    try {
      final reqId = FirebaseFirestore.instance.collection('_').doc().id;
      await _firestore.sendMentorRequest({
        'id': reqId,
        'mentorId': mentorId,
        'mentorName': mentorName,
        'studentId': studentId,
        'studentName': student['name'] ?? '',
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent to ${student['name']}!'),
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

  Future<void> _openChat(Map<String, dynamic> student) async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid ?? '';
    final studentId = student['uid'] as String? ?? '';
    if (uid.isEmpty || studentId.isEmpty) return;

    final roomId = await _firestore.getOrCreateChatRoom(uid, studentId);
    if (mounted) {
      Navigator.pushNamed(context, AppRoutes.chatConversation, arguments: {
        'roomId': roomId,
        'otherUserId': studentId,
        'otherUserName': student['name'] ?? 'Student',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Students'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filterStudents,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search by name, course or institution...',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filterStudents('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${_filtered.length} student${_filtered.length == 1 ? '' : 's'} found',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Student List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text('No students found', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) => _buildStudentCard(_filtered[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final name = student['name'] as String? ?? 'Student';
    final course = student['course'] as String? ?? '';
    final institution = student['institution'] as String? ?? '';
    final level = student['level'] as int? ?? 1;
    final streak = student['streak'] as int? ?? 0;
    final points = student['points'] as int? ?? 0;
    final status = _connectionStatus[student['uid']];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accentBlue, AppTheme.accentPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: student['profileImageUrl'] != null
                      ? ClipOval(child: Image.network(student['profileImageUrl'], fit: BoxFit.cover, width: 52, height: 52))
                      : Center(child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
                      if (course.isNotEmpty)
                        Text(course, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
                      if (institution.isNotEmpty)
                        Text(institution, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Stats row
            Row(
              children: [
                _miniStat(Icons.bolt_rounded, 'Lvl $level', AppTheme.warningAmber),
                const SizedBox(width: 16),
                _miniStat(Icons.local_fire_department_rounded, '$streak day streak', AppTheme.errorRed),
                const SizedBox(width: 16),
                _miniStat(Icons.star_rounded, '$points pts', AppTheme.accentBlue),
              ],
            ),
            const SizedBox(height: 14),
            // Action buttons
            _buildConnectionButton(student, status),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildConnectionButton(Map<String, dynamic> student, String? status) {
    if (status == 'approved') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _openChat(student),
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentBlue,
                side: const BorderSide(color: AppTheme.accentBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.successGreen),
                const SizedBox(width: 6),
                Text('Connected', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ],
      );
    } else if (status == 'pending') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.schedule_rounded, size: 18),
          label: const Text('Request Pending'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.warningAmber,
            side: const BorderSide(color: AppTheme.warningAmber),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            disabledForegroundColor: AppTheme.warningAmber.withOpacity(0.6),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _sendRequest(student),
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text('Connect'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0,
          ),
        ),
      );
    }
  }
}
