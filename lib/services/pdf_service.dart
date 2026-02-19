import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/timetable_model.dart';

class PdfService {
  // ─── Text Extraction ──────────────────────────────────────────────────────
  /// Extracts text from a PDF file.
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

  // ─── Main Parser ──────────────────────────────────────────────────────────
  /// Parses Mumbai University engineering syllabus PDF.
  ///
  /// Strategy:
  ///   1. Find all 7-digit course codes from Program Structure table
  ///   2. For each code, locate its DETAILED SYLLABUS section
  ///   3. Extract subject name from nearest header
  ///   4. Parse module table: Module No | Module Name | Hours | Topics
  ///   5. Skip noise: objectives, outcomes, teaching/exam schemes, references
  static List<SubjectInfo> parseUniversitySyllabus(String text) {
    final lines = text.split('\n').map((l) => l.trim()).toList();

    // ── Step 1: Collect all unique 7-digit course codes ─────────────────────
    final codeRegex = RegExp(r'^\d{7}$');
    final uniqueCodes = <String>[];
    final codeSeen = <String>{};

    for (var line in lines) {
      if (codeRegex.hasMatch(line) && !codeSeen.contains(line)) {
        codeSeen.add(line);
        uniqueCodes.add(line);
      }
    }

    if (uniqueCodes.isEmpty) return _parseGenericSyllabus(lines);

    // ── Step 2: For each code, extract subject info ─────────────────────────
    final subjects = <SubjectInfo>[];
    final processedNames = <String>{};

    for (var code in uniqueCodes) {
      // Find subject name
      final name = _extractSubjectName(lines, code);
      if (name == null || name.length < 3) continue;

      // Skip duplicates
      final key = name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (processedNames.contains(key)) continue;
      processedNames.add(key);

      // Find and parse DETAILED SYLLABUS section
      final modules = _extractModules(lines, code);

      subjects.add(SubjectInfo(
        code: code,
        name: name,
        modules: modules,
        totalHours: modules.fold(0, (sum, m) => sum + m.hours),
        credits: 3,
        isSelected: true,
      ));
    }

    if (subjects.isEmpty) return _parseGenericSyllabus(lines);
    return subjects;
  }

  // ─── Name Extraction ──────────────────────────────────────────────────────
  /// Finds the subject name associated with a course code.
  ///
  /// Strategy: Look at lines AFTER the code (in program structure table).
  /// The name may span 2-3 lines. Strip trailing table numbers.
  static String? _extractSubjectName(List<String> lines, String code) {
    // First pass: look for standalone code line
    for (int i = 0; i < lines.length; i++) {
      if (lines[i] != code) continue;

      final parts = <String>[];
      for (int j = i + 1; j < lines.length && j <= i + 5; j++) {
        final raw = lines[j].trim();
        if (raw.isEmpty) continue;
        if (RegExp(r'^\d{7}$').hasMatch(raw)) break;      // another code
        if (raw.startsWith('Total')) break;
        if (raw == '--' || raw == '-' || raw == '–') break;
        if (RegExp(r'^[\d\s\-–\+\*\#\.]+$').hasMatch(raw)) break;

        // Strip trailing table columns: "Computer Engineering 2 -- 1 2 1"
        String cleaned = raw.replaceAll(RegExp(r'\s+[\d\-–\s\*\#]+$'), '').trim();
        if (cleaned.isEmpty) break;
        if (_isNoise(cleaned)) break;
        if (cleaned.length < 2) continue;

        parts.add(cleaned);

        // Stop if we have enough
        if (parts.join(' ').length > 10) {
          final peek = (j + 1 < lines.length) ? lines[j + 1].trim() : '';
          if (RegExp(r'^[\d\s\-–\+\*\#\.]+$').hasMatch(peek) ||
              RegExp(r'^\d{7}$').hasMatch(peek)) break;
        }
      }

      if (parts.isNotEmpty) {
        final name = parts.join(' ').trim();
        if (name.length > 2 && !_isNoise(name)) return name;
      }
    }
    return null;
  }

  // ─── Module Extraction ────────────────────────────────────────────────────
  /// Locates the DETAILED SYLLABUS section for a code and extracts modules.
  ///
  /// Strategy:
  ///   1. Find ALL occurrences of the code
  ///   2. From each, search forward (up to 200 lines) for "DETAILED SYLLABUS"
  ///   3. Once found, parse the module table until "Books" or "Assessment"
  ///   4. Detect both Roman (I-VI) and Arabic (1-6) module numbering
  static List<ModuleInfo> _extractModules(List<String> lines, String code) {
    int sectionStart = -1;

    // Search all code occurrences for nearest DETAILED SYLLABUS
    for (int i = 0; i < lines.length; i++) {
      if (!lines[i].contains(code)) continue;

      for (int j = i + 1; j < lines.length && j < i + 200; j++) {
        final upper = lines[j].toUpperCase().trim();
        if (upper.contains('DETAILED SYLLABUS') ||
            upper.startsWith('DETAIL SYLLABUS') ||
            upper.contains('DETAILED CONTENT')) {
          sectionStart = j;
          break;
        }
      }
      if (sectionStart != -1) break;
    }

    if (sectionStart == -1) return [];

    // Find end of detailed syllabus section
    int sectionEnd = (sectionStart + 300).clamp(0, lines.length);
    for (int i = sectionStart + 3; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('Text Books') ||
          line.startsWith('Books:') ||
          line.startsWith('Reference Books') ||
          line.startsWith('Online References') ||
          line.startsWith('Online Resources') ||
          line.startsWith('Assessment:') ||
          line.startsWith('List of Experiments') ||
          line.startsWith('Suggested list') ||
          line.startsWith('Suggested List') ||
          line.startsWith('Sr No List of Assignments')) {
        sectionEnd = i;
        break;
      }
    }

    // ── Clean: strip noise lines from the section ───────────────────────────
    final cleanedLines = <String>[];
    for (int i = sectionStart + 1; i < sectionEnd; i++) {
      final line = lines[i].trim();
      if (_isTableHeader(line)) continue;
      if (_isSectionNoise(line)) continue;
      cleanedLines.add(line);
    }

    return _parseModuleRows(cleanedLines);
  }

  // ─── Module Table Parser ──────────────────────────────────────────────────
  /// Parses cleaned module rows, detecting both Roman and Arabic numbering.
  static List<ModuleInfo> _parseModuleRows(List<String> lines) {
    final modules = <ModuleInfo>[];

    // Detect format: check first few lines for roman vs arabic
    final romanRegex = RegExp(r'^(I{1,3}|IV|V|VI)$');
    final arabicModuleRegex = RegExp(r'^(\d)\s+(?!CO|LO|co|lo)([A-Z].{2,})');
    final romanToInt = {'I':1,'II':2,'III':3,'IV':4,'V':5,'VI':6};

    int currentNum = 0;
    String currentName = '';
    List<String> currentTopics = [];
    int currentHours = 0;
    bool collectingName = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) continue;

      // ── Skip prerequisite / module 0 ──────────────────────────────────
      if (line == '0' || line.toLowerCase().startsWith('prerequisite')) {
        if (currentNum > 0) {
          _saveModule(modules, currentNum, currentName, currentTopics, currentHours);
        }
        currentNum = 0;
        currentName = '';
        currentTopics = [];
        currentHours = 0;
        collectingName = false;
        continue;
      }
      if (currentNum == 0 && !romanRegex.hasMatch(line) &&
          arabicModuleRegex.firstMatch(line) == null &&
          !line.startsWith('1 ')) continue;

      // ── Roman numeral module boundary ─────────────────────────────────
      if (romanRegex.hasMatch(line)) {
        _saveModule(modules, currentNum, currentName, currentTopics, currentHours);
        currentNum = romanToInt[line] ?? 0;
        currentName = '';
        currentTopics = [];
        currentHours = 0;
        collectingName = true;
        continue;
      }

      // ── Arabic number module boundary (e.g., "1 Computer Fundamentals")
      final arabicMatch = arabicModuleRegex.firstMatch(line);
      if (arabicMatch != null) {
        final num = int.tryParse(arabicMatch.group(1)!) ?? 0;
        if (num >= 1 && num <= 6) {
          _saveModule(modules, currentNum, currentName, currentTopics, currentHours);
          currentNum = num;
          currentName = arabicMatch.group(2)!.trim();
          currentTopics = [];
          currentHours = 0;
          collectingName = currentName.length < 5;
          continue;
        }
      }

      if (currentNum == 0) continue;

      // ── Module name collection ────────────────────────────────────────
      if (collectingName) {
        if (!RegExp(r'^\d+$').hasMatch(line) &&
            !RegExp(r'^(CO|LO)\s?\d').hasMatch(line) &&
            line.length > 1) {
          if (currentName.isEmpty) {
            currentName = line;
          } else if (line.length < 40 && !line.contains(':') &&
              !RegExp(r'^\d+\.').hasMatch(line) &&
              !line.toLowerCase().contains('self-learning') &&
              !line.toLowerCase().contains('self-study')) {
            currentName += ' $line';
          } else {
            collectingName = false;
            // Fall through to topic parsing for this line
            _addAsTopicContent(currentTopics, line);
            continue;
          }
          if (currentName.length > 5) collectingName = false;
          continue;
        }
      }

      // ── Hours: standalone number 1-15 ─────────────────────────────────
      if (RegExp(r'^(\d{1,2})$').hasMatch(line)) {
        final h = int.parse(line);
        if (h >= 1 && h <= 15) { currentHours = h; continue; }
      }

      // ── Hours + CO: "4 CO 1" or "8 CO2" ──────────────────────────────
      final hrsCoMatch = RegExp(r'^(\d{1,2})\s+(CO|LO)\s?\d').firstMatch(line);
      if (hrsCoMatch != null) {
        currentHours = int.tryParse(hrsCoMatch.group(1)!) ?? currentHours;
        continue;
      }

      // ── CO/LO mapping line ────────────────────────────────────────────
      if (RegExp(r'^(CO|LO)\s?\d').hasMatch(line)) continue;

      // ── Self-learning topics ──────────────────────────────────────────
      if (line.toLowerCase().contains('self-learning') ||
          line.toLowerCase().contains('self-study') ||
          line.toLowerCase().contains('self learning')) {
        final colonIdx = line.indexOf(':');
        if (colonIdx != -1 && colonIdx < line.length - 2) {
          final selfContent = line.substring(colonIdx + 1).trim();
          if (selfContent.isNotEmpty) {
            // Split by comma for individual topics
            final selfTopics = selfContent.split(',')
                .map((t) => t.trim())
                .where((t) => t.length > 2)
                .toList();
            for (var t in selfTopics) {
              currentTopics.add('📖 $t');
            }
          }
        }
        continue;
      }

      // ── Topic content ─────────────────────────────────────────────────
      if (line.length > 2) {
        _addAsTopicContent(currentTopics, line);
      }
    }

    // Save last module
    _saveModule(modules, currentNum, currentName, currentTopics, currentHours);
    return modules;
  }

  /// Processes a line as topic content, splitting numbered items.
  static void _addAsTopicContent(List<String> topics, String line) {
    // Skip pure number/symbol lines
    if (RegExp(r'^[\d\s\-–\+\*\#]+$').hasMatch(line)) return;

    // Clean leading numbering
    String cleaned = line
        .replaceFirst(RegExp(r'^[\d]+\.\s*'), '')
        .replaceFirst(RegExp(r'^[a-z]\)\s*'), '')
        .replaceFirst(RegExp(r'^•\s*'), '')
        .trim();

    if (cleaned.isEmpty || cleaned.length < 3) return;

    // If line has multiple numbered items ("1. X 2. Y"), split them
    if (RegExp(r'\d+\.\s').hasMatch(cleaned)) {
      final parts = cleaned.split(RegExp(r'\d+\.\s+'));
      for (var p in parts) {
        final pt = p.trim();
        if (pt.length > 2) topics.add(pt);
      }
    } else {
      topics.add(cleaned);
    }
  }

  static void _saveModule(List<ModuleInfo> modules, int num, String name,
      List<String> topics, int hours) {
    if (num <= 0 || name.isEmpty) return;

    // Clean module name
    final cleanName = name
        .replaceAll(RegExp(r'\s+[\d\-–\s]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    modules.add(ModuleInfo(
      number: num,
      name: cleanName.isNotEmpty ? cleanName : name,
      topics: topics.isNotEmpty
          ? List<String>.from(topics)
          : ['Topics covered in ${cleanName.isNotEmpty ? cleanName : name}'],
      hours: hours > 0 ? hours : 4,
    ));
  }

  // ─── Noise Detection ──────────────────────────────────────────────────────
  static bool _isNoise(String text) {
    final lower = text.toLowerCase();
    return lower.contains('teaching scheme') ||
        lower.contains('credits assigned') ||
        lower.contains('contact hours') ||
        lower.contains('examination scheme') ||
        lower.contains('internal assessment') ||
        lower.contains('end sem') ||
        lower.contains('theory marks') ||
        lower.contains('term work') ||
        lower.contains('course code') ||
        lower.contains('course name') ||
        lower.contains('course description') ||
        lower.contains('evaluation scheme') ||
        lower.contains('theory pract') ||
        lower.contains('pract. tut') ||
        lower == 'total';
  }

  static bool _isTableHeader(String line) {
    final lower = line.toLowerCase();
    return (lower.contains('sr.') && lower.contains('no')) ||
        lower == 'name of module' ||
        lower == 'name of the module' ||
        lower == 'detailed content' ||
        lower == 'module' ||
        lower == 'hours' ||
        lower == 'topics' ||
        lower == 'hrs' ||
        lower == 'unit name' ||
        lower == 'topic name' ||
        lower == 'topic description' ||
        (lower.contains('co') && lower.contains('mapping'));
  }

  static bool _isSectionNoise(String line) {
    final lower = line.toLowerCase();
    return lower.startsWith('course objective') ||
        lower.startsWith('course outcome') ||
        lower.startsWith('lab objective') ||
        lower.startsWith('lab outcome') ||
        lower.startsWith('rationale') ||
        lower.startsWith('pre-requisite') ||
        lower.startsWith('prerequisite:');
  }

  // ─── Fallback Parser ──────────────────────────────────────────────────────
  static List<SubjectInfo> _parseGenericSyllabus(List<String> lines) {
    final validLines = lines.where((l) => l.trim().length > 5).toList();
    if (validLines.isEmpty) return [];
    return [
      SubjectInfo(
        code: '',
        name: 'General Syllabus',
        modules: [
          ModuleInfo(
            number: 1,
            name: 'All Topics',
            topics: validLines.take(30).map((l) => l.trim()).toList(),
            hours: validLines.length,
          ),
        ],
      ),
    ];
  }

  /// Legacy compatibility
  static Map<String, List<String>> parseSyllabus(String text) {
    final subjects = parseUniversitySyllabus(text);
    final Map<String, List<String>> result = {};
    for (var s in subjects) {
      result[s.name] = s.modules.expand((m) => m.topics).toList();
    }
    return result;
  }
}
