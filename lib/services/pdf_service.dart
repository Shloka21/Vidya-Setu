import 'dart:convert';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/timetable_model.dart';

class PdfService {
  // ── Gemini API key ──────────────────────────────────────────────────────────
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // ─── Text Extraction ──────────────────────────────────────────────────────
  static Future<String> extractText(Uint8List fileBytes) async {
    try {
      final PdfDocument document = PdfDocument(inputBytes: fileBytes);
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  // ─── AI-Powered Parser ────────────────────────────────────────────────────
  /// Extracts subjects, modules, hours, and topics from syllabus PDF text
  /// using Gemini AI. Falls back to regex parser on failure.
  static Future<List<SubjectInfo>> parseUniversitySyllabus(String text) async {
    try {
      // Step 1: Clean text to reduce token usage
      final cleaned = _cleanText(text);

      // Step 2: Send to Gemini AI
      final jsonResult = await _extractWithGemini(cleaned);

      // Step 3: Parse JSON into SubjectInfo
      final subjects = _parseJsonToSubjects(jsonResult);
      if (subjects.isNotEmpty) return subjects;

      // If AI returned empty, try regex fallback
      return _regexFallback(text, debugError: 'AI returned empty or invalid JSON:\n$jsonResult');
    } catch (e) {
      // Fallback to regex parser on any error
      return _regexFallback(text, debugError: e.toString());
    }
  }

  // ─── Gemini API Call ──────────────────────────────────────────────────────
  static Future<String> _extractWithGemini(String syllabusText) async {
    final model = GenerativeModel(
      model: 'gemini-3-flash-preview',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        responseMimeType: 'application/json',
      ),
    );

    final prompt = '''
You are an expert academic syllabus parser for Mumbai University (MU) engineering syllabi.

Your task: extract ALL subjects with their COMPLETE data from the text below.

CRITICAL RULES:
1. Extract EVERY subject — from ALL semesters present (Sem 3, 4, 5, 6, etc.).
2. Include ALL types: Theory, Practical/Lab, Mini-projects, Audit courses.
3. Use the FULL COMPLETE subject name as written in the PDF (e.g., "Data Structures and Analysis" NOT just "Data").
4. Each subject MUST have ALL its modules (typically 4-6 modules per subject).
5. Each module MUST have ALL its topics listed — not just the first one.
6. Topics are the bullet points, numbered items, or comma-separated syllabus items under each module heading.
7. Module numbers may use Roman numerals (I, II, III, IV, V, VI) or Arabic (1, 2, 3, 4, 5, 6).
8. Hours per module: look for patterns like "06 Hrs", "6 Hours", "06" next to module titles or in tables.
   If HOURS ARE NOT EXPLICITLY FOUND, ESTIMATE THEM (usually 4 to 12 hours) based on topic depth.
   The "hours" field MUST ALWAYS BE AN INTEGER. NEVER return null or empty strings for hours.
9. IGNORE: Course Objectives, Course Outcomes, Teaching Scheme, Examination Scheme, References, Text Books.
10. For practical/lab subjects without modules, create one module with experiments as topics.
11. Self-learning topics: include with a "📖" prefix.
12. Subject codes are typically 7-digit numbers like "4324301".

DO NOT:
- Truncate subject names to single words
- Return only 1 module when there are multiple
- Return only 1 topic when there are multiple
- Skip any subject found in the text
- Merge topics from different modules

Return ONLY valid JSON:
{
  "subs": [
    {
      "code": "4324301",
      "name": "Full Complete Subject Name",
      "sem": 3,
      "cred": 4,
      "type": "theory",
      "mods": [
        {
          "num": 1,
          "title": "Full Module Title",
          "hrs": 6,
          "top": ["Topic 1 as written in syllabus", "Topic 2", "Topic 3", "...all topics"]
        },
        {
          "num": 2,
          "title": "Second Module Title",
          "hrs": 8,
          "top": ["Topic A", "Topic B", "Topic C"]
        }
      ]
    }
  ]
}

The "type" field should be: "theory", "practical", "lab", "mini-project", or "audit".

SYLLABUS TEXT:
$syllabusText
''';

    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? '{}';
  }

  // ─── Clean Text ───────────────────────────────────────────────────────────
  /// Minimal cleaning — remove only obvious noise, keep all syllabus content.
  /// Gemini 2.5 Flash handles 1M tokens so aggressive cleaning is unnecessary.
  static String _cleanText(String text) {
    final lines = text.split('\n');
    final cleaned = <String>[];

    for (var line in lines) {
      final trimmed = line.trim();

      // Skip truly empty lines
      if (trimmed.isEmpty) continue;

      // Skip very short noise (single chars, page numbers)
      if (trimmed.length <= 2 && RegExp(r'^\d+$').hasMatch(trimmed)) continue;

      // Skip page headers / footers
      final lower = trimmed.toLowerCase();
      if (lower.contains('page ') && trimmed.length < 20) continue;
      if (lower == 'mumbai university') continue;
      if (lower.contains('all rights reserved')) continue;

      cleaned.add(trimmed);
    }

    final result = cleaned.join('\n');

    // Gemini 2.5 Flash supports 1M tokens — keep up to 120k chars
    if (result.length > 120000) {
      return result.substring(0, 120000);
    }
    return result;
  }

  // ─── JSON Parser ──────────────────────────────────────────────────────────
  /// Converts Gemini's JSON response into SubjectInfo list.
  static List<SubjectInfo> _parseJsonToSubjects(String jsonStr) {
    // Robustly extract just the JSON part, ignoring any AI conversational text.
    String clean = jsonStr;
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(clean);
    if (match != null) {
      clean = match.group(0)!;
    }

    if (clean.isEmpty) {
      throw Exception('Regex extraction failed. Raw text was: $jsonStr');
    }

    Map<String, dynamic>? data;
    try {
      data = json.decode(clean);
    } catch (e) {
      if (e is FormatException && e.message.contains('Unexpected end of input')) {
        // AI truncated the output string, missing closing bounds. Auto-repair it.
        final List<String> closures = [
          '}', ']}', '}]}', ']} ]}', '}]}]}', ']}]}]}', '}]}]}]}'
        ];
        
        // Clean trailing commas if any
        String repairBase = clean.trim();
        if (repairBase.endsWith(',')) {
          repairBase = repairBase.substring(0, repairBase.length - 1);
        }

        for (String suffix in closures) {
          try {
            data = json.decode(repairBase + suffix);
            break; // Successfully repaired!
          } catch (_) {}
        }

        if (data == null) {
          // Try closing an unclosed string value first
          for (String suffix in closures) {
            try {
              data = json.decode(repairBase + '"' + suffix);
              break;
            } catch (_) {}
          }
        }
      }
      
      if (data == null) throw e; // If all repairs failed, crash it up
    }

    final List<dynamic> subjectsJson = data?['subjects'] ?? data?['subs'] ?? [];
    final subjects = <SubjectInfo>[];

    for (var sj in subjectsJson) {
        final code = (sj['code'] ?? '').toString();
        final name = (sj['subjectName'] ?? sj['name'] ?? 'Unknown Subject').toString();
        final semesterVal = sj['semester'] ?? sj['sem'];
        final semester = semesterVal is int
            ? semesterVal
            : int.tryParse(semesterVal?.toString() ?? '');
        
        final creditsVal = sj['credits'] ?? sj['cred'];
        final credits = creditsVal is int
            ? creditsVal
            : int.tryParse(creditsVal?.toString() ?? '3') ?? 3;
            
        final modulesJson = (sj['modules'] as List<dynamic>?) ?? (sj['mods'] as List<dynamic>?) ?? [];

        final modules = <ModuleInfo>[];
        for (var mj in modulesJson) {
          final topicsVal = mj['topics'] ?? mj['top'];
          final topicsList = (topicsVal as List<dynamic>?)
                  ?.map((t) => t.toString())
                  .where((t) => t.isNotEmpty)
                  .toList() ??
              [];

          final numVal = mj['moduleNumber'] ?? mj['num'];
          final titleVal = mj['moduleTitle'] ?? mj['title'];
          final hrsVal = mj['hours'] ?? mj['hrs'];

          modules.add(ModuleInfo(
            number: (numVal is int)
                ? numVal
                : int.tryParse(numVal?.toString() ?? '0') ?? 0,
            name: (titleVal ?? 'Module').toString(),
            topics: topicsList.isNotEmpty
                ? topicsList
                : ['Topics covered in this module'],
            hours: _parseHours(hrsVal),
          ));
        }

        if (modules.isNotEmpty) {
          subjects.add(SubjectInfo(
            code: code,
            name: name,
            modules: modules,
            totalHours: modules.fold(0, (sum, m) => sum + m.hours),
            credits: credits,
            semester: semester,
            isSelected: true,
          ));
        }
      }

      return subjects;
  }

  // Helper to robustly parse hours from various formats (e.g., "06 Hrs", 6, "6")
  static int _parseHours(dynamic value) {
    if (value == null) return 6; // Default to 6 if completely missing
    if (value is int) return value;
    
    final str = value.toString().trim().toLowerCase();
    if (str.isEmpty) return 6;

    // Try to extract digits from strings like "06 Hrs", "6 hours", "6", etc.
    final match = RegExp(r'(\d+)').firstMatch(str);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 6;
    }
    
    return int.tryParse(str) ?? 6;
  }

  // ─── Regex Fallback ───────────────────────────────────────────────────────
  /// Simple regex fallback if Gemini AI fails (no internet, quota, etc.)
  static List<SubjectInfo> _regexFallback(String text, {String? debugError}) {
    final lines = text.split('\n').map((l) => l.trim()).toList();

    // Find 7-digit course codes
    final codeRegex = RegExp(r'^\d{7}$');
    final codes = <String>{};
    for (var line in lines) {
      if (codeRegex.hasMatch(line)) codes.add(line);
    }

    if (codes.isEmpty) {
      // Absolute fallback: just return the text as a generic subject
      final validLines = lines.where((l) => l.length > 5).toList();
      return validLines.isEmpty
          ? []
          : [
              SubjectInfo(
                code: '',
                name: 'Syllabus',
                modules: [
                  ModuleInfo(
                    number: 1,
                    name: 'All Topics',
                    topics: validLines.take(30).toList(),
                    hours: validLines.length,
                  ),
                ],
              ),
            ];
    }

    // Basic extraction: find subject names near codes
    final subjects = <SubjectInfo>[];
    for (var code in codes) {
      final idx = lines.indexOf(code);
      if (idx == -1) continue;

      // Get subject name from next few non-empty lines
      String name = '';
      for (int j = idx + 1; j < lines.length && j <= idx + 3; j++) {
        final line = lines[j];
        if (line.isEmpty || RegExp(r'^[\d\s\-–]+$').hasMatch(line)) continue;
        if (RegExp(r'^\d{7}$').hasMatch(line)) break;
        name = line.replaceAll(RegExp(r'\s+[\d\-–\s]+$'), '').trim();
        if (name.length > 3) break;
      }

      if (name.length < 3) continue;

      subjects.add(SubjectInfo(
        code: code,
        name: name,
        modules: [
          ModuleInfo(
            number: 1,
            name: 'Module 1',
            topics: ['Topics from $name'],
            hours: 4,
          ),
        ],
        isSelected: true,
      ));
    }

    if (debugError != null) {
      subjects.insert(0, SubjectInfo(
        code: 'ERR',
        name: 'AI Failed: $debugError',
        modules: [
          ModuleInfo(
            number: 1,
            name: 'Error Details',
            topics: [debugError],
            hours: 1,
          )
        ],
        isSelected: true,
      ));
    }

    return subjects;
  }

  // ─── Topic Resources & Quiz (Lazy-loaded via Gemini) ──────────────────────
  /// Fetches reference links, YouTube videos, and quiz questions for a topic.
  /// Called lazily when a student opens a study session.
  static Future<Map<String, dynamic>> getTopicResources({
    required String subject,
    required String topic,
    required String moduleName,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 4096,
          responseMimeType: 'application/json',
        ),
      );

      final prompt = '''
You are a study resource finder for engineering students studying at Mumbai University.

Subject: $subject
Module: $moduleName
Topic: $topic

Provide study resources and quiz for this specific topic. Return ONLY valid JSON:

{
  "resourceLinks": [
    {"title": "Article Title", "url": "https://...", "source": "GeeksforGeeks"},
    {"title": "Article Title", "url": "https://...", "source": "Tutorialspoint"}
  ],
  "youtubeVideos": [
    {"title": "Video Title", "videoId": "youtube_video_id", "channel": "Channel Name"}
  ],
  "quiz": [
    {
      "question": "What is ...?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctIndex": 0,
      "explanation": "Brief explanation of why this is correct"
    }
  ]
}

RULES:
1. Provide 2-3 reference article links from reputable sites (GeeksforGeeks, Tutorialspoint, Javatpoint, Wikipedia, official docs).
2. Provide 1-2 YouTube video IDs from popular educational channels (like Neso Academy, Gate Smashers, Jenny's Lectures, Unacademy, etc.).
3. Provide exactly 5 MCQ quiz questions with 4 options each.
4. Questions should test understanding, not just memorization.
5. Make questions progressively harder (easy → medium → hard).
6. Only provide REAL, existing URLs and video IDs that are likely valid.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';

      // Parse response
      String clean = text.trim();
      if (clean.startsWith('```')) {
        clean = clean.replaceFirst(RegExp(r'^```json?\s*'), '');
        clean = clean.replaceFirst(RegExp(r'```\s*$'), '');
      }

      return json.decode(clean) as Map<String, dynamic>;
    } catch (e) {
      return {
        'resourceLinks': [],
        'youtubeVideos': [],
        'quiz': [],
        'error': e.toString(),
      };
    }
  }

  /// Legacy compatibility
  static Map<String, List<String>> parseSyllabus(String text) {
    // Sync wrapper for older code - not recommended
    final Map<String, List<String>> result = {};
    return result;
  }
}
