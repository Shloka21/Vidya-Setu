import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../app/theme.dart';
import '../../../models/timetable_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import 'package:vidyasetu/services/localization_service.dart';

class SessionQuizScreen extends StatefulWidget {
  const SessionQuizScreen({super.key});

  @override
  State<SessionQuizScreen> createState() => _SessionQuizScreenState();
}

class _SessionQuizScreenState extends State<SessionQuizScreen> {
  TimetableSession? _session;
  String? _planId;
  List<Map<String, dynamic>> _questions = [];
  Map<int, int> _selectedAnswers = {};
  bool _loading = true;
  bool _submitted = false;
  int _score = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _questions.isEmpty) {
      _session = args['session'] as TimetableSession?;
      _planId = args['planId'] as String?;
      
      if (_session != null) {
        // If session already has a quiz but in a different language, we later translate it.
        // For now, if _questions is empty, generate. 
        // Note: _questions is currently not stored as a separate list in sessions, 
        // it's generated on-fly unless we change the architecture to store them.
        _generateQuiz();
      }
    }
  }

  Future<void> _generateQuiz() async {
    setState(() { _loading = true; _submitted = false; _selectedAnswers = {}; });

    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );

      final loc = Provider.of<LocalizationService>(context, listen: false);
      final langName = loc.getLanguageName(loc.locale);

      final prompt = '''Generate exactly 6 multiple choice questions for:
Subject: ${_session!.subject}
Topic: ${_session!.topic}
${_session!.moduleName != null ? 'Module: ${_session!.moduleName}' : ''}

IMPORTANT: The user targets the $langName language. Generate ALL questions, options, and explanations in $langName.

Return a valid JSON array with exactly 6 objects. Each object must have:
- "question": the question text
- "options": array of exactly 4 answer options
- "correctIndex": the index (0-3) of the correct answer
- "explanation": brief explanation of why

Return ONLY the JSON array, no extra text or markdown.''';

      final response = await model.generateContent([Content.text(prompt)]);
      var text = response.text?.trim() ?? '[]';

      // Strip markdown code fences if present
      if (text.startsWith('```')) {
        text = text.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '').trim();
      }

      final parsed = jsonDecode(text) as List;
      if (mounted) {
        setState(() {
          _questions = parsed.map((q) => Map<String, dynamic>.from(q)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error_generating_quiz')}: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  void _submitQuiz() {
    int correct = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_selectedAnswers[i] == _questions[i]['correctIndex']) correct++;
    }
    setState(() { _score = correct; _submitted = true; });

    // If passed, mark session complete
    if (_hasPassed) _markComplete();
  }

  bool get _hasPassed => _score >= (_questions.length * 0.6).ceil();

  Future<void> _markComplete() async {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (uid == null || _planId == null || _session == null) return;
    try {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      await FirestoreService().updateSessionStatus(uid, _planId!, _session!.id, true);
      await FirestoreService().updateSessionQuizCompleted(uid, _planId!, _session!.id, true, lang: loc.locale);
      await FirestoreService().updateStreak(uid);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text(_submitted ? 'Quiz Results' : 'Topic Quiz'),
        automaticallyImplyLeading: !_submitted,
      ),
      body: _loading
          ? _buildLoadingState()
          : _submitted
              ? _buildResultScreen()
              : _buildQuizBody(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(context.tr('generating_quiz_questions'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 15)),
          const SizedBox(height: 8),
          Text('${_session?.topic}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildQuizBody() {
    final allAnswered = _selectedAnswers.length == _questions.length;

    return Column(
      children: [
        // Progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Text('${_selectedAnswers.length}/${_questions.length} answered',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              //Text(_session?.topic ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: _questions.isEmpty ? 0 : _selectedAnswers.length / _questions.length,
          minHeight: 4,
          backgroundColor: AppTheme.divider,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
        ),

        // Questions
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _questions.length,
            itemBuilder: (context, qIndex) {
              final q = _questions[qIndex];
              final options = List<String>.from(q['options'] ?? []);

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardBoxShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: AppTheme.accentBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text('${qIndex + 1}', style: TextStyle(color: AppTheme.accentBlue, fontSize: 14, fontWeight: FontWeight.w700))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(q['question'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...options.asMap().entries.map((entry) {
                      final optIndex = entry.key;
                      final optText = entry.value;
                      final isSelected = _selectedAnswers[qIndex] == optIndex;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedAnswers[qIndex] = optIndex),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.accentBlue.withOpacity(0.1) : AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.accentBlue : AppTheme.divider,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppTheme.accentBlue : Colors.transparent,
                                  border: Border.all(color: isSelected ? AppTheme.accentBlue : Theme.of(context).colorScheme.onSurface.withOpacity(0.5), width: 2),
                                ),
                                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(optText, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14))),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),

        // Submit Button
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: allAnswered ? _submitQuiz : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.divider,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: Text(allAnswered ? context.tr('submit_quiz') : context.tr('answer_all_questions_to_submit')),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultScreen() {
    final passed = _hasPassed;
    final percentage = (_questions.isEmpty ? 0 : (_score / _questions.length * 100)).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Result Icon
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: (passed ? AppTheme.successGreen : AppTheme.warningAmber).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                passed ? Icons.celebration_rounded : Icons.psychology_rounded,
                color: passed ? AppTheme.successGreen : AppTheme.warningAmber,
                size: 60,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Result Title
          Text(
            passed ? context.tr('yayyy_you_did_it') : context.tr('keep_going'),
            style: TextStyle(color: AppTheme.primaryNavy, fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            passed
                ? 'You\'ve successfully completed this topic! Great job!'
                : 'Don\'t worry, every attempt makes you stronger. Review the material and try again!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 15, height: 1.5),
          ),
          SizedBox(height: 24),

          // Score Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.cardBoxShadow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _scoreItem(context.tr('score'), '$_score/${_questions.length}', passed ? AppTheme.successGreen : AppTheme.warningAmber),
                Container(width: 1, height: 50, color: AppTheme.divider),
                _scoreItem(context.tr('percentage'), '$percentage%', passed ? AppTheme.successGreen : AppTheme.warningAmber),
                Container(width: 1, height: 50, color: AppTheme.divider),
                _scoreItem(context.tr('status'), passed ? context.tr('passed') : context.tr('retry'), passed ? AppTheme.successGreen : AppTheme.errorRed),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Review answers
          Text(context.tr('review_answers'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 12),
          ..._questions.asMap().entries.map((entry) {
            final i = entry.key;
            final q = entry.value;
            final correct = q['correctIndex'] as int;
            final selected = _selectedAnswers[i] ?? -1;
            final isCorrect = selected == correct;
            final options = List<String>.from(q['options'] ?? []);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isCorrect ? AppTheme.successGreen.withOpacity(0.3) : AppTheme.errorRed.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(q['question'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!isCorrect && selected >= 0 && selected < options.length)
                    Text('${context.tr('your_answer')}: ${options[selected]}', style: TextStyle(color: AppTheme.errorRed, fontSize: 13)),
                  Text('${context.tr('correct_answer')}: ${options[correct]}', style: TextStyle(color: AppTheme.successGreen, fontSize: 13, fontWeight: FontWeight.w600)),
                  if (q['explanation'] != null) ...[
                    const SizedBox(height: 6),
                    Text(q['explanation'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            );
          }),
          SizedBox(height: 24),

          // Action Buttons
          if (passed) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back_rounded),
                label: Text(context.tr('back_to_timetable')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _generateQuiz(),
                icon: Icon(Icons.refresh_rounded),
                label: Text(context.tr('retry_with_new_questions')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Go back to session detail for notes
                },
                icon: Icon(Icons.book_rounded),
                label: Text(context.tr('review_notes__study_materials')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _scoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }
}

