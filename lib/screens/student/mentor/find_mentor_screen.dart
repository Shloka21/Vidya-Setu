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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMentors();
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

  void _filterMentors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMentors = _mentors;
      } else {
        _filteredMentors = _mentors.where((m) {
          final name = (m['name'] as String? ?? '').toLowerCase();
          final subjects = (List<String>.from(
            m['subjectsTaught'] ?? [],
          )).join(' ').toLowerCase();
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find a Mentor')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMentors,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Search by name or subject...',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Mentor list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMentors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No mentors found',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search term',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.mentorProfile,
          arguments: mentor,
        ),
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
                      style: TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 22,
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
                      Text(
                        name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subjects.isNotEmpty)
                        Text(
                          subjects.join(', '),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppTheme.warningAmber,
                          size: 18,
                        ),
                        Text(
                          ' ${rating.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$yearsExp yrs',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                bio,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: students < maxStudents
                        ? AppTheme.successGreen.withOpacity(0.1)
                        : AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    students < maxStudents
                        ? '${maxStudents - students} spots available'
                        : 'Full',
                    style: TextStyle(
                      color: students < maxStudents
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: students < maxStudents
                        ? () => _sendRequest(mentor)
                        : null,
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text(
                      'Connect',
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
