import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../models/timetable_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_card.dart';
import 'package:vidyasetu/services/localization_service.dart';
import '../../../widgets/common/translated_text.dart';

class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  TimetableSession? _session;
  String? _planId;
  String? _generatedNotes;
  bool _loadingNotes = false;
  bool _loadingVideos = false;
  List<Map<String, String>> _videoLinks = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _session = args['session'] as TimetableSession?;
      _planId = args['planId'] as String?;
      if (_session != null) {
        _generatedNotes = _session!.notes;
        _videoLinks = _session!.youtubeLinks.map((l) => {'title': l, 'url': l}).toList();
        
        // Initial adaptive translation check
        _checkAdaptiveNotes();
      }
    }
  }

  Future<void> _checkAdaptiveNotes() async {
    if (_session == null || _generatedNotes == null) return;
    
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final currentLocale = loc.locale;
    final sourceLocale = _session!.notesLang;
    
    // If language mismatch detected, translate on-the-fly
    if (sourceLocale != null && sourceLocale != currentLocale && currentLocale != 'en') {
      final translated = await loc.translateDynamic(_generatedNotes!);
      if (mounted) {
        setState(() {
          _generatedNotes = translated;
        });
      }
    }
  }

  Future<void> _generateNotes() async {
    if (_session == null) return;
    setState(() => _loadingNotes = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );

      final loc = Provider.of<LocalizationService>(context, listen: false);
      final langName = loc.getLanguageName(loc.locale);

      final prompt = '''Generate concise study notes for:
Subject: ${_session!.subject}
Topic: ${_session!.topic}
${_session!.moduleName != null ? 'Module: ${_session!.moduleName}' : ''}

IMPORTANT: The user targets the $langName language. Generate ALL notes in $langName.

Format as markdown with:
# ${_session!.topic} (In $langName)

## Key Concepts
- bullet points of main ideas

## Important Definitions
- term: definition format

## Formulas / Key Points
- any formulas or critical facts

## Quick Summary
2-3 sentence summary

Keep it concise, student-friendly, and ENTIRELY in $langName.''';

      final response = await model.generateContent([Content.text(prompt)]);
      final notes = response.text ?? 'Could not generate notes.';

      final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
      if (uid != null && _planId != null) {
        await FirestoreService().updateSessionNotes(uid, _planId!, _session!.id, notes, lang: loc.locale);
      }

      if (mounted) setState(() { _generatedNotes = notes; _loadingNotes = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingNotes = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error_generating_notes')}: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<void> _searchVideos() async {
    if (_session == null) return;
    setState(() => _loadingVideos = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );

      final loc = Provider.of<LocalizationService>(context, listen: false);
      final langName = loc.getLanguageName(loc.locale);

      final prompt = '''For the topic "${_session!.topic}" in subject "${_session!.subject}", 
suggest 4 specific YouTube search queries that a student could use to find helpful tutorial videos.
IMPORTANT: Respond in $langName.
Return ONLY the search queries, one per line, no numbering or bullets.''';

      final response = await model.generateContent([Content.text(prompt)]);
      final queries = (response.text ?? '').split('\n').where((q) => q.trim().isNotEmpty).take(4).toList();

      if (mounted) {
        setState(() {
          _videoLinks = queries.map((q) => {
            'title': q.trim(),
            'url': 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(q.trim())}',
          }).toList();
          _loadingVideos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingVideos = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('could_not_open_link_error')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return Scaffold(appBar: AppBar(title: Text(context.tr('session'))), body: Center(child: Text(context.tr('no_session_data'))));
    }

    final session = _session!;
    final color = Color(int.parse(session.colorHex.replaceFirst('#', '0xFF')));
    final timeRange = '${DateFormat('h:mm a').format(session.startTime)} – ${DateFormat('h:mm a').format(session.endTime)}';
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('session_details'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Session Header ───
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.book_rounded, color: color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TranslatedText(session.subject, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
                          if (session.moduleName != null) TranslatedText(session.moduleName!, style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 13)),
                        ],
                      )),
                      if (session.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.successGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.check_circle, color: AppTheme.successGreen, size: 16),
                            SizedBox(width: 4),
                            Text(context.tr('done'), style: TextStyle(color: AppTheme.successGreen, fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TranslatedText(session.topic, style: TextStyle(color: cs.onSurface, fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Icon(Icons.schedule_rounded, color: cs.onSurface.withOpacity(0.4), size: 16),
                    SizedBox(width: 6),
                    Text(timeRange, style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 14)),
                    SizedBox(width: 16),
                    Icon(Icons.timer_outlined, color: cs.onSurface.withOpacity(0.4), size: 16),
                    SizedBox(width: 6),
                    Text('${session.durationMinutes} min', style: TextStyle(color: cs.onSurface.withOpacity(0.6), fontSize: 14)),
                  ]),
                ],
              ),
            ),
            SizedBox(height: 24),

            // ─── Notes Section ───
            _sectionHeader(context.tr('study_notes'), _generatedNotes == null
                ? TextButton.icon(
                    onPressed: _loadingNotes ? null : _generateNotes,
                    icon: Icon(_loadingNotes ? Icons.hourglass_top : Icons.auto_awesome, size: 16),
                    label: Text(_loadingNotes ? context.tr('generating_notes') : context.tr('generate_with_ai')),
                  )
                : null),
            SizedBox(height: 8),
            if (_loadingNotes)
              Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_generatedNotes != null)
              AppCard(padding: const EdgeInsets.all(16), child: MarkdownBody(data: _generatedNotes!, selectable: true))
            else
              _emptyCard(Icons.note_alt_outlined, context.tr('tap_generate_with_to_create_notes')),
            SizedBox(height: 24),

            // ─── Videos Section ───
            _sectionHeader(context.tr('video_resources'), _videoLinks.isEmpty
                ? TextButton.icon(onPressed: _loadingVideos ? null : _searchVideos, icon: Icon(Icons.play_circle_outline, size: 16), label: Text(context.tr('find_videos')))
                : null),
            const SizedBox(height: 8),
            if (_loadingVideos)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_videoLinks.isNotEmpty)
              ..._videoLinks.map((v) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: InkWell(
                    onTap: () => _openUrl(v['url']!),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.red, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(v['title']!, style: TextStyle(color: cs.onSurface, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis)),
                      Icon(Icons.open_in_new_rounded, color: cs.onSurface.withOpacity(0.4), size: 18),
                    ]),
                  ),
                ),
              ))
            else
              _emptyCard(Icons.video_library_outlined, context.tr('tap_to_find_videos_hint')),
            SizedBox(height: 32),

            // ─── Complete Button ───
            if (!session.isCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToQuiz(),
                  icon: Icon(Icons.quiz_rounded, size: 20),
                  label: Text(context.tr('mark_complete__take_quiz')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Widget? action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
        if (action != null) action,
      ],
    );
  }

  Widget _emptyCard(IconData icon, String text) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Center(child: Column(children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), size: 40),
        const SizedBox(height: 8),
        Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 13)),
      ])),
    );
  }

  void _navigateToQuiz() {
    if (_session == null) return;
    Navigator.pushNamed(context, AppRoutes.sessionQuiz, arguments: {'session': _session, 'planId': _planId});
  }
}
