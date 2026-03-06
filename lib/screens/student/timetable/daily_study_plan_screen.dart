import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme.dart';
import '../../../models/timetable_model.dart';
import '../../../services/pdf_service.dart';
import '../../../widgets/common/app_card.dart';

class DailyStudyPlanScreen extends StatefulWidget {
  final StudyPlan? studyPlan;
  const DailyStudyPlanScreen({super.key, this.studyPlan});

  @override
  State<DailyStudyPlanScreen> createState() => _DailyStudyPlanScreenState();
}

class _DailyStudyPlanScreenState extends State<DailyStudyPlanScreen> {
  late DateTime _selectedDate;
  late List<TimetableSession> _allSessions;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _allSessions = widget.studyPlan?.sessions ?? _mockSessions();
  }

  List<TimetableSession> _mockSessions() {
    return [
      TimetableSession(
        id: '1',
        subject: 'Data Structures',
        topic: 'Binary Trees & Traversals',
        moduleName: 'Trees',
        date: DateTime.now(),
        startTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 17, 0),
        durationMinutes: 50,
        colorHex: '#4F46E5',
      ),
      TimetableSession(
        id: '2',
        subject: 'Operating Systems',
        topic: 'Process Scheduling Algorithms',
        moduleName: 'Process Management',
        date: DateTime.now(),
        startTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 18, 0),
        durationMinutes: 50,
        colorHex: '#0EA5E9',
      ),
      TimetableSession(
        id: '3',
        subject: 'Data Structures',
        topic: 'Graph BFS & DFS',
        moduleName: 'Graphs',
        date: DateTime.now(),
        startTime: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, 19, 0),
        durationMinutes: 50,
        colorHex: '#4F46E5',
      ),
    ];
  }

  List<TimetableSession> get _todaysSessions {
    return _allSessions.where((s) =>
        s.date.year == _selectedDate.year &&
        s.date.month == _selectedDate.month &&
        s.date.day == _selectedDate.day).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Color _getColorFromHex(String hexColor) {
    return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _todaysSessions;
    return Scaffold(
      
      appBar: AppBar(
        title: Text('Daily Study Plan',
            style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Column(
        children: [
          _buildDateHeader(sessions),
          _buildProgressBar(sessions),
          Expanded(child: _buildSessionsList(sessions)),
        ],
      ),
    );
  }

  Widget _buildDateHeader(List<TimetableSession> sessions) {
    final totalHours =
        sessions.fold(0, (sum, s) => sum + s.durationMinutes) / 60;
    final uniqueSubjects = sessions.map((s) => s.subject).toSet();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: AppTheme.cardBoxShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(_selectedDate),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDate),
                      style: Theme.of(context).textTheme.headlineMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryNavy.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Goal',
                        style: Theme.of(context).textTheme.labelSmall),
                    Text(
                      '${totalHours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        color: AppTheme.primaryNavy,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (uniqueSubjects.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 28,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: uniqueSubjects.map((subj) {
                  final session =
                      sessions.firstWhere((s) => s.subject == subj);
                  final color = _getColorFromHex(session.colorHex);
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(subj,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(List<TimetableSession> sessions) {
    int completed = sessions.where((s) => s.isCompleted).length;
    int total = sessions.length;
    double progress = total == 0 ? 0 : completed / total;

    int completedMinutes = sessions
        .where((s) => s.isCompleted)
        .fold(0, (sum, s) => sum + s.durationMinutes);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Progress",
                  style: Theme.of(context).textTheme.titleMedium),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  color: AppTheme.accentBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$completed / $total Sessions',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('${(completedMinutes / 60).toStringAsFixed(1)}h done',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(List<TimetableSession> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No sessions today',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Enjoy your free time! 🎉',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final color = _getColorFromHex(session.colorHex);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _openSessionDetail(session, index),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${DateFormat('h:mm a').format(session.startTime)} - ${DateFormat('h:mm a').format(session.endTime)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBadge(session),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              session.subject,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              session.topic,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (session.moduleName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                session.moduleName!,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.touch_app,
                                    size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                const SizedBox(width: 4),
                                Text('Tap for resources & quiz',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.accentBlue,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(TimetableSession session) {
    Color color;
    String text;
    if (session.isCompleted && session.quizCompleted) {
      color = AppTheme.successGreen;
      text = '✅ Done';
    } else if (session.isCompleted) {
      color = Colors.orange;
      text = '📖 Studied';
    } else {
      color = Colors.grey;
      text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Session Detail with Resources & Quiz
  // ═══════════════════════════════════════════════════════════════════════════
  void _openSessionDetail(TimetableSession session, int sessionIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _SessionDetailSheet(
        session: session,
        onMarkCompleted: () {
          setState(() => session.isCompleted = true);
          Navigator.pop(ctx);
        },
        onQuizCompleted: () {
          setState(() {
            session.isCompleted = true;
            session.quizCompleted = true;
          });
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Session Detail Bottom Sheet (Resources + Quiz)
// ═══════════════════════════════════════════════════════════════════════════════
class _SessionDetailSheet extends StatefulWidget {
  final TimetableSession session;
  final VoidCallback onMarkCompleted;
  final VoidCallback onQuizCompleted;

  const _SessionDetailSheet({
    required this.session,
    required this.onMarkCompleted,
    required this.onQuizCompleted,
  });

  @override
  State<_SessionDetailSheet> createState() => _SessionDetailSheetState();
}

class _SessionDetailSheetState extends State<_SessionDetailSheet> {
  bool _isLoadingResources = false;
  Map<String, dynamic>? _resources;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoadingResources = true;
      _error = null;
    });
    try {
      final result = await PdfService.getTopicResources(
        subject: widget.session.subject,
        topic: widget.session.topic,
        moduleName: widget.session.moduleName ?? '',
      );
      if (mounted) {
        setState(() {
          _resources = result;
          _isLoadingResources = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingResources = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final color = Color(
        int.parse(session.colorHex.replaceFirst('#', '0xFF')));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: ListView(
          controller: controller,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subject & Topic header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.subject,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(session.topic,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                  if (session.moduleName != null) ...[
                    const SizedBox(height: 4),
                    Text(session.moduleName!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: color),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${DateFormat('h:mm a').format(session.startTime)} - ${DateFormat('h:mm a').format(session.endTime)} (${session.durationMinutes} min)',
                          style: TextStyle(fontSize: 12, color: color),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ─── Resources Section ──────────────────────────────────
            if (_isLoadingResources)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(strokeWidth: 3),
                      const SizedBox(height: 12),
                      Text('Loading resources & quiz...',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                    ],
                  ),
                ),
              )
            else if (_error != null)
              _buildErrorCard()
            else if (_resources != null) ...[
              // Reference Links
              _buildSectionHeader('📚 Study Resources'),
              const SizedBox(height: 8),
              _buildResourceLinks(),

              const SizedBox(height: 20),

              // YouTube Videos
              _buildSectionHeader('🎬 YouTube Videos'),
              const SizedBox(height: 8),
              _buildYoutubeLinks(),

              const SizedBox(height: 20),

              // Mark as Studied
              if (!widget.session.isCompleted)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    onPressed: widget.onMarkCompleted,
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as Studied'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

              // Quiz
              _buildSectionHeader('🧠 Test Your Knowledge'),
              const SizedBox(height: 8),
              _buildQuizSection(),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
  }

  Widget _buildErrorCard() {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.wifi_off, size: 36, color: Colors.orange),
            const SizedBox(height: 8),
            const Text('Could not load resources',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Check your internet connection',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loadResources,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceLinks() {
    final links = (_resources?['resourceLinks'] as List<dynamic>?) ?? [];
    if (links.isEmpty) {
      return _buildEmptyState('No resources found');
    }

    return Column(
      children: links.map((link) {
        final title = link['title']?.toString() ?? 'Resource';
        final url = link['url']?.toString() ?? '';
        final source = link['source']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            child: ListTile(
              dense: true,
              leading: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0x1A4F46E5),
                child: Icon(Icons.article, size: 16, color: Color(0xFF4F46E5)),
              ),
              title: Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              subtitle: Text(source,
                  style: TextStyle(
                      fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () => _launchUrl(url),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildYoutubeLinks() {
    final videos = (_resources?['youtubeVideos'] as List<dynamic>?) ?? [];
    if (videos.isEmpty) {
      return _buildEmptyState('No videos found');
    }

    return Column(
      children: videos.map((video) {
        final title = video['title']?.toString() ?? 'Video';
        final videoId = video['videoId']?.toString() ?? '';
        final channel = video['channel']?.toString() ?? '';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            child: ListTile(
              dense: true,
              leading: const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0x1AEF4444),
                child: Icon(Icons.play_circle_fill,
                    size: 18, color: Color(0xFFEF4444)),
              ),
              title: Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              subtitle: Text(channel,
                  style: TextStyle(
                      fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () =>
                  _launchUrl('https://www.youtube.com/watch?v=$videoId'),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuizSection() {
    final quiz = (_resources?['quiz'] as List<dynamic>?) ?? [];
    if (quiz.isEmpty) {
      return _buildEmptyState('No quiz available');
    }

    if (widget.session.quizCompleted) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.successGreen),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Quiz completed! Great job! 🎉',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _startQuiz(quiz),
      icon: const Icon(Icons.quiz),
      label: Text('Take Quiz (${quiz.length} questions)'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13)),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    }
  }

  void _startQuiz(List<dynamic> quiz) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _QuizDialog(
        questions: quiz,
        onComplete: (score, total) {
          Navigator.pop(ctx);
          widget.onQuizCompleted();
          _showQuizResult(score, total);
        },
      ),
    );
  }

  void _showQuizResult(int score, int total) {
    final percentage = (score / total * 100).round();
    final passed = percentage >= 60;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          passed ? '🎉 Great Job!' : '📖 Keep Studying!',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$score / $total',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: passed ? AppTheme.successGreen : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage% correct',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 8),
            Text(
              passed
                  ? 'You have a solid understanding of this topic!'
                  : 'Review the resources and try again later.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Quiz Dialog
// ═══════════════════════════════════════════════════════════════════════════════
class _QuizDialog extends StatefulWidget {
  final List<dynamic> questions;
  final Function(int score, int total) onComplete;

  const _QuizDialog({required this.questions, required this.onComplete});

  @override
  State<_QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<_QuizDialog> {
  int _currentQuestion = 0;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;

  Map<String, dynamic> get _question =>
      widget.questions[_currentQuestion] as Map<String, dynamic>;

  @override
  Widget build(BuildContext context) {
    final q = _question;
    final options = (q['options'] as List<dynamic>?) ?? [];
    final correctIndex = q['correctIndex'] as int? ?? 0;
    final explanation = q['explanation']?.toString() ?? '';
    final total = widget.questions.length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Question ${_currentQuestion + 1} of $total',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accentBlue)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () =>
                          widget.onComplete(_score, total),
                    ),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentQuestion + 1) / total,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.accentBlue),
                  ),
                ),
                const SizedBox(height: 20),

                // Question
                Text(
                  q['question']?.toString() ?? '',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                // Options
                ...List.generate(options.length, (i) {
                  final isSelected = _selectedOption == i;
                  final isCorrect = i == correctIndex;
                  Color? bgColor;
                  Color? borderColor;

                  if (_answered) {
                    if (isCorrect) {
                      bgColor = AppTheme.successGreen.withValues(alpha: 0.12);
                      borderColor = AppTheme.successGreen;
                    } else if (isSelected && !isCorrect) {
                      bgColor = Colors.red.withValues(alpha: 0.12);
                      borderColor = Colors.red;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: _answered ? null : () => _selectOption(i),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: bgColor ??
                              (isSelected
                                  ? AppTheme.accentBlue
                                      .withValues(alpha: 0.08)
                                  : AppTheme.surface),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor ??
                                (isSelected
                                    ? AppTheme.accentBlue
                                    : AppTheme.divider),
                            width: isSelected || _answered ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppTheme.accentBlue
                                    : Colors.grey.shade200,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                String.fromCharCode(65 + i),
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                options[i].toString(),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            if (_answered && isCorrect)
                              const Icon(Icons.check_circle,
                                  color: AppTheme.successGreen, size: 20),
                            if (_answered && isSelected && !isCorrect)
                              const Icon(Icons.cancel,
                                  color: Colors.red, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Explanation (after answering)
                if (_answered && explanation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb,
                            size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(explanation,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Action button
                if (!_answered && _selectedOption != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Submit Answer'),
                    ),
                  ),
                if (_answered)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _currentQuestion < widget.questions.length - 1
                            ? 'Next Question'
                            : 'Finish Quiz',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectOption(int index) {
    setState(() => _selectedOption = index);
  }

  void _submitAnswer() {
    final correctIndex = _question['correctIndex'] as int? ?? 0;
    if (_selectedOption == correctIndex) {
      _score++;
    }
    setState(() => _answered = true);
  }

  void _nextQuestion() {
    if (_currentQuestion < widget.questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      widget.onComplete(_score, widget.questions.length);
    }
  }
}

