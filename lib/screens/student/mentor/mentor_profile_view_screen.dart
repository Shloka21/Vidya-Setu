import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../../../app/routes.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_button.dart';
import '../../../widgets/common/app_card.dart';
import 'package:vidyasetu/services/localization_service.dart';

class MentorProfileViewScreen extends StatefulWidget {
  const MentorProfileViewScreen({super.key});

  @override
  State<MentorProfileViewScreen> createState() => _MentorProfileViewScreenState();
}

class _MentorProfileViewScreenState extends State<MentorProfileViewScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _connectionStatus; // null, 'pending', 'approved', 'rejected'
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;
  int _totalRatings = 0;
  bool _loadingReviews = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _loadConnectionStatus(args);
      _loadReviews(args);
    }
  }

  Future<void> _loadConnectionStatus(Map<String, dynamic> mentor) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final studentId = auth.userModel?.uid ?? '';
    final mentorId = mentor['uid'] as String? ?? '';
    if (studentId.isEmpty || mentorId.isEmpty) return;

    _firestoreService.studentConnectionsStream(studentId).listen((snapshot) {
      if (!mounted) return;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['mentorId'] == mentorId) {
          setState(() => _connectionStatus = data['status'] as String?);
          return;
        }
      }
    });
  }

  Future<void> _loadReviews(Map<String, dynamic> mentor) async {
    final mentorId = mentor['uid'] as String? ?? '';
    if (mentorId.isEmpty) {
      setState(() => _loadingReviews = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(mentorId)
          .collection('ratings')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      double totalRating = 0;
      final reviews = <Map<String, dynamic>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        reviews.add(data);
        totalRating += (data['rating'] as num?)?.toDouble() ?? 0;
      }

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _totalRatings = reviews.length;
          _averageRating = reviews.isNotEmpty ? totalRating / reviews.length : (mentor['rating'] as num?)?.toDouble() ?? 0;
          _loadingReviews = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      if (mounted) setState(() => _loadingReviews = false);
    }
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
        'requestedBy': studentId,
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

  void _showAddReviewDialog(String mentorId) {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Write a Review', style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppTheme.warningAmber,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => selectedRating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (commentController.text.trim().isEmpty) return;
                
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final student = auth.userModel;
                
                final reviewDoc = FirebaseFirestore.instance
                    .collection('users')
                    .doc(mentorId)
                    .collection('ratings')
                    .doc(student?.uid);

                await reviewDoc.set({
                  'studentId': student?.uid,
                  'studentName': student?.name,
                  'rating': selectedRating,
                  'comment': commentController.text.trim(),
                  'createdAt': Timestamp.now(),
                });
                
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  _loadReviews({'uid': mentorId}); // Refresh reviews
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentBlue),
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mentor Profile')),
        body: const Center(child: Text('No mentor data available')),
      );
    }

    final mentor = args;
    final mentorName = mentor['name']?.toString() ?? 'Mentor';
    final subjects = List<String>.from(mentor['subjectsTaught'] ?? []);
    final specialization = subjects.isNotEmpty ? subjects.join(', ') : (mentor['specialization']?.toString() ?? 'General');
    final bio = mentor['bio']?.toString() ?? 'No bio provided.';
    final displayRating = _averageRating > 0 ? _averageRating : (mentor['rating'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            actions: [
              if (_connectionStatus == 'approved')
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.chat_rounded, color: Colors.white),
                    onPressed: () {
                      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                      if (args != null) _openChat(args);
                    },
                    tooltip: context.tr('message'),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentBlue,
                      AppTheme.accentPurple,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 30),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Center(
                          child: Text(mentorName.isNotEmpty ? mentorName[0].toUpperCase() : 'M',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(mentorName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(specialization,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(width: 90, child: _buildStat(context, '⭐', displayRating.toStringAsFixed(1), 'Rating')),
                        SizedBox(width: 90, child: _buildStat(context, '👨‍🎓', '${mentor['studentCount'] ?? 0}', 'Students')),
                        SizedBox(width: 90, child: _buildStat(context, '📹', '${mentor['sessionsCompleted'] ?? mentor['sessions'] ?? 0}', 'Sessions')),
                        SizedBox(width: 90, child: _buildStat(context, '🎓', '${mentor['experienceYears'] ?? 0}y', 'Exp.')),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // About
                  Text(context.tr('about'),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  AppCard(
                    child: Text(bio,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 14,
                            height: 1.6)),
                  ),
                  SizedBox(height: 20),

                  // Details
                  Text(context.tr('details'),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _detailItem(context, Icons.language_rounded, 'Languages',
                            mentor['languages']?.toString() ?? 'English'),
                        Divider(height: 1),
                        _detailItem(context, Icons.schedule_rounded, 'Availability',
                            mentor['availability']?.toString() ?? 'Flexible'),
                        Divider(height: 1),
                        _detailItem(context, Icons.star_rounded, 'Specialization',
                            specialization),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Reviews
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.tr('recent_reviews'),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 17,
                              fontWeight: FontWeight.w700)),
                      if (_connectionStatus == 'approved')
                        TextButton(
                          onPressed: () => _showAddReviewDialog(mentor['uid']),
                          child: Text('Write Review', style: TextStyle(color: AppTheme.accentBlue, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (_loadingReviews)
                    const Center(child: CircularProgressIndicator())
                  else if (_reviews.isEmpty)
                    AppCard(
                      child: Center(
                        child: Text('No reviews yet.',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
                      ),
                    )
                  else
                    ..._reviews.map((review) => _buildReview(
                      context,
                      review['studentName']?.toString() ?? 'Student',
                      (review['rating'] as num?)?.toInt() ?? 5,
                      review['comment']?.toString() ?? '',
                    )),
                  SizedBox(height: 24),

                  // CTA button — single Send Request with state
                  _buildActionButton(mentor),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> mentor) {
    String labelText = context.tr('send_request');
    IconData iconData = Icons.person_add_rounded;
    Color? btnColor;
    VoidCallback? onPressed = () => _sendRequest(mentor);

    if (_connectionStatus == 'approved') {
      labelText = context.tr('connected') ?? 'Connected';
      iconData = Icons.check_circle_rounded;
      btnColor = AppTheme.successGreen;
      onPressed = null;
    } else if (_connectionStatus == 'pending') {
      labelText = context.tr('request_sent') ?? 'Request Sent';
      iconData = Icons.hourglass_top_rounded;
      btnColor = AppTheme.warningAmber;
      onPressed = null;
    }

    return SizedBox(
      width: double.infinity,
      child: AppButton(
        text: labelText,
        onPressed: onPressed,
        icon: iconData,
        backgroundColor: btnColor,
      ),
    );
  }

  Widget _buildStat(BuildContext context, String emoji, String value, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _detailItem(BuildContext context, IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentBlue, size: 22),
      title: Text(label,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600)),
      subtitle: Text(value,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildReview(BuildContext context, String name, int stars, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: Text(name.isNotEmpty ? name[0] : 'S',
                          style: TextStyle(
                              color: AppTheme.accentPurple,
                              fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(name,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                      5,
                      (i) => Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppTheme.warningAmber,
                          size: 16)),
                ),
              ],
            ),
            if (text.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(text,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}
