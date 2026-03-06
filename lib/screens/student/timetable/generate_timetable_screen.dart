import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/timetable/college_timetable_input.dart';
import '../../../services/pdf_service.dart';
import '../../../services/timetable_generator_service.dart';
import '../../../services/holiday_service.dart' as hs;
import '../../../services/firestore_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/timetable_model.dart';

class GenerateTimetableScreen extends StatefulWidget {
  const GenerateTimetableScreen({super.key});

  @override
  State<GenerateTimetableScreen> createState() =>
      _GenerateTimetableScreenState();
}

class _GenerateTimetableScreenState extends State<GenerateTimetableScreen> {
  int _currentStep = 0;
  static const _totalSteps = 9;

  // Step 1: Upload
  List<PlatformFile> _pickedFiles = [];

  // Step 2: Processing (auto)
  bool _isProcessing = false;
  String _processingStatus = 'Extracting text from PDF...';

  // Step 3: Subjects
  List<SubjectInfo> _extractedSubjects = [];
  bool _selectAll = true;

  // Step 4: College Timetable
  List<CollegeSlot> _collegeSlots = [];

  // Step 5: Lifestyle
  final LifestyleConstraints _constraints = LifestyleConstraints();

  // Step 6: Exam Schedule (NEW)
  int _ptCount = 1;
  // Each PT has a start and end date
  List<DateTime?> _ptStartDates = [null, null, null];
  List<DateTime?> _ptEndDates = [null, null, null];
  DateTime? _finalExamStartDate;
  DateTime? _finalExamEndDate;

  // Step 7: Summary
  Map<String, dynamic> _summary = {};

  // Step 8: Generating (auto)
  bool _isGenerating = false;
  String _generatingStatus = 'Fetching holidays...';

  // Step 9: Preview
  StudyPlan? _studyPlan;
  List<HolidayInfo> _holidays = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: Text('Smart Timetable',
            style: Theme.of(context).textTheme.headlineSmall),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Skip auto steps when going back
            if (_currentStep > 0 &&
                _currentStep != 1 &&
                _currentStep != 7) {
              int prev = _currentStep - 1;
              if (prev == 1) prev = 0; // skip scan
              if (prev == 7) prev = 6; // skip generating
              setState(() => _currentStep = prev);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(child: _buildStepContent()),
          if (_currentStep != 1 && _currentStep != 7) _buildBottomActions(),
        ],
      ),
    );
  }

  // ─── Step Indicator ─────────────────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isCurrent ? 22 : 16,
                  height: isCurrent ? 22 : 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? AppTheme.accentBlue
                        : Colors.grey.shade300,
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                                color: AppTheme.accentBlue
                                    .withValues(alpha: 0.4),
                                blurRadius: 6)
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: isCurrent ? 9 : 7,
                    ),
                  ),
                ),
                if (index < _totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isActive
                          ? AppTheme.accentBlue
                          : Colors.grey.shade300,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildUploadStep();
      case 1:
        return _buildProcessingStep();
      case 2:
        return _buildSubjectSelectionStep();
      case 3:
        return _buildCollegeTimetableStep();
      case 4:
        return _buildLifestyleStep();
      case 5:
        return _buildExamScheduleStep();
      case 6:
        return _buildSummaryStep();
      case 7:
        return _buildGeneratingStep();
      case 8:
        return _buildPreviewStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 1: Upload Syllabus PDF
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildUploadStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Icon(Icons.auto_stories,
                    size: 48, color: AppTheme.accentBlue),
                const SizedBox(height: 16),
                Text('Upload Syllabus',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Upload one or more university syllabus PDFs',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Upload Box (if empty) or "Add More" Button
          if (_pickedFiles.isEmpty)
            _buildUploadBox()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Uploaded Files (${_pickedFiles.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add More'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accentBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._pickedFiles.map((file) => _buildFileCard(file)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.accentBlue.withValues(alpha: 0.3),
              width: 2,
              style: BorderStyle.none), // Border logic handled by AppCard or manual
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 56,
              color: AppTheme.accentBlue,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap to Upload PDF(s)',
              style: TextStyle(
                color: AppTheme.accentBlue,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Select multiple files if needed',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileCard(PlatformFile file) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded,
                  color: AppTheme.accentBlue, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${(file.size / 1024).toStringAsFixed(1)} KB',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.visibility_outlined,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
              onPressed: () => _viewFile(file),
              tooltip: 'View PDF',
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
              onPressed: () {
                setState(() => _pickedFiles.remove(file));
              },
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }

  void _viewFile(PlatformFile file) {
    // Show a dialog with file info and an option to extract/preview text
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(file.name),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Size: ${(file.size / 1024).toStringAsFixed(1)} KB'),
              const SizedBox(height: 16),
              const Text(
                'Extracted Text Preview:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: FutureBuilder<String>(
                  future: PdfService.extractText(file.bytes!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error extracting text: ${snapshot.error}',
                          style: const TextStyle(fontSize: 11, color: Colors.red));
                    }
                    final text = snapshot.data ?? 'No text found';
                    return SingleChildScrollView(
                      child: Text(
                        text.length > 2000 ? '${text.substring(0, 2000)}...' : text,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This preview shows the raw text that will be used for AI analysis.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        // Only add files that aren't already picked (by name)
        for (var newFile in result.files) {
          if (!_pickedFiles.any((f) => f.name == newFile.name)) {
            _pickedFiles.add(newFile);
          }
        }
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 2: Processing PDF (auto-advance)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProcessingStep() {
    return _AnimatedLoadingScreen(
      title: 'Analyzing Your Syllabus',
      statusText: _processingStatus,
      icon: Icons.auto_stories,
      color: AppTheme.accentBlue,
      stages: const [
        _LoadingStage('📄', 'Reading PDF'),
        _LoadingStage('🔍', 'Finding subjects'),
        _LoadingStage('📚', 'Extracting topics'),
        _LoadingStage('✅', 'Almost done'),
      ],
      tips: const [
        '💡 Spaced repetition improves retention by 200%',
        '🧠 Active recall is the most effective study method',
        '📊 Students who plan study 40% more efficiently',
        '⏰ The Pomodoro technique boosts focus by 25%',
        '🎯 Setting specific goals doubles completion rates',
        '📖 Teaching others helps you remember 90% more',
        '📝 Writing notes by hand improves understanding and memory',
        '🔁 Reviewing within 24 hours prevents major forgetting',
        '📚 Studying in short sessions beats long cramming sessions',
        '🎧 Instrumental music can improve concentration for some learners',
        '🌙 Proper sleep strengthens memory consolidation',
        '🚶 Short breaks increase long-term productivity',
        '❓ Practice testing is more effective than rereading',
        '🧩 Mixing subjects (interleaving) improves problem-solving skills',
        '📵 Keeping phone away reduces distraction significantly',
        '🗂️ Organizing study material reduces cognitive overload',
        '🥤 Staying hydrated helps maintain focus and energy',
        '🧘 Deep breathing for 2 minutes resets mental fatigue',
        '📅 Studying at the same time daily builds strong habits',
        '🔍 Explaining concepts in simple words improves clarity',
        '🎯 Studying with clear objectives increases motivation',
      ],
    );
  }

  Future<void> _processPdf() async {
    if (_pickedFiles.isEmpty) return;
    setState(() {
      _isProcessing = true;
      _processingStatus = '📄 Extracting text from ${_pickedFiles.length} file(s)...';
    });

    try {
      String combinedText = '';
      
      // Step 1: Extract text from all files
      for (int i = 0; i < _pickedFiles.length; i++) {
        final file = _pickedFiles[i];
        if (file.bytes == null) continue;
        
        setState(() => _processingStatus = '📄 Reading ${file.name} (${i + 1}/${_pickedFiles.length})...');
        final text = await PdfService.extractText(file.bytes!);
        combinedText += "\n\n--- FILE: ${file.name} ---\n\n$text";
      }

      if (mounted) {
        setState(() => _processingStatus = '🔍 Scanning for subjects & modules...');
      }

      // Step 2: AI parsing (with minimum delay for UX)
      final results = await Future.wait([
        PdfService.parseUniversitySyllabus(combinedText),
        Future.delayed(const Duration(milliseconds: 1500)),
      ]);
      final subjects = results[0] as List<SubjectInfo>;

      if (mounted) {
        setState(() => _processingStatus = '✅ Found ${subjects.length} subjects!');
        await Future.delayed(const Duration(milliseconds: 800));
      }

      if (mounted) {
        setState(() {
          _extractedSubjects = subjects;
          _isProcessing = false;
          _currentStep = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _currentStep = 0);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 3: Subject Selection
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSubjectSelectionStep() {
    if (_extractedSubjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text('No subjects found',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Try uploading a different PDF',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      );
    }

    // Group subjects by semester
    final grouped = <int?, List<SubjectInfo>>{};
    for (var s in _extractedSubjects) {
      grouped.putIfAbsent(s.semester, () => []).add(s);
    }
    // Sort by semester (null last)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => (a ?? 99).compareTo(b ?? 99));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Select Subjects',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('${_extractedSubjects.length} subjects found across ${sortedKeys.length} semester(s)',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13)),
        const SizedBox(height: 16),

        // Select All
        AppCard(
          child: CheckboxListTile(
            value: _selectAll,
            activeColor: AppTheme.accentBlue,
            title: const Text('Select All',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                '${_extractedSubjects.where((s) => s.isSelected).length} of ${_extractedSubjects.length} selected'),
            onChanged: (val) {
              setState(() {
                _selectAll = val ?? true;
                for (var s in _extractedSubjects) {
                  s.isSelected = _selectAll;
                }
              });
            },
          ),
        ),
        const SizedBox(height: 16),

        // Subjects grouped by semester
        ...sortedKeys.expand((semester) {
          final subjects = grouped[semester]!;
          return [
            // Semester header
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      semester != null
                          ? 'Semester $semester'
                          : 'Other',
                      style: const TextStyle(
                        color: AppTheme.accentBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${subjects.length} subjects',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
                  ),
                ],
              ),
            ),
            // Subject cards
            ...subjects.map((subject) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    child: ListTile(
                      leading: Checkbox(
                        value: subject.isSelected,
                        activeColor: AppTheme.accentBlue,
                        onChanged: (val) {
                          setState(() {
                            subject.isSelected = val ?? true;
                            _selectAll = _extractedSubjects
                                .every((s) => s.isSelected);
                          });
                        },
                      ),
                      title: Text(
                        subject.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${subject.moduleCount} modules • ${subject.topicCount} topics • ~${subject.estimatedStudyHours.toStringAsFixed(0)} hrs',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: subject.modules.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.info_outline, size: 20),
                              onPressed: () => _showSubjectDetails(subject),
                            )
                          : null,
                    ),
                  ),
                )),
          ];
        }),
      ],
    );
  }


  void _showSubjectDetails(SubjectInfo subject) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Text(subject.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${subject.code} • ${subject.credits} credits',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
              const Divider(height: 24),
              ...subject.modules.map((module) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Module ${module.number}: ${module.name}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text('${module.hours} hrs • ${module.topics.length} topics',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 11)),
                      const SizedBox(height: 6),
                      ...module.topics.map((t) => Padding(
                            padding: const EdgeInsets.only(left: 12, bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.circle,
                                    size: 5, color: AppTheme.accentBlue),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(t,
                                        style: const TextStyle(fontSize: 12))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 12),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 4: College Timetable
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCollegeTimetableStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('College Timetable',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('Tap time slots where you have college lectures',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13)),
        const SizedBox(height: 20),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CollegeTimetableInput(
              slots: _collegeSlots,
              onChanged: (slots) => _collegeSlots = slots,
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: ListTile(
            leading:
                const Icon(Icons.info_outline, color: AppTheme.accentBlue),
            title: const Text('Study only after college',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle: Text(
              'On college days, sessions are scheduled only in the evening after your last lecture',
              style:
                  TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 5: Lifestyle Constraints
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLifestyleStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Your Daily Routine',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('Tell us about your schedule so we plan around it',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13)),
        const SizedBox(height: 24),
        _buildSliderCard(Icons.bedtime, Colors.indigo, 'Sleep Duration',
            _constraints.sleepHours, 'hrs', 5, 10, 10,
            (v) => setState(() => _constraints.sleepHours = v)),
        _buildSliderCard(Icons.directions_bus, Colors.blue,
            'Daily Travel Time (college days only)',
            _constraints.travelMinutes, 'min', 0, 180, 18,
            (v) => setState(() => _constraints.travelMinutes = v)),
        _buildSliderCard(Icons.person, Colors.green,
            'Family / Personal Time',
            _constraints.personalMinutes, 'min', 0, 180, 18,
            (v) => setState(() => _constraints.personalMinutes = v)),
        _buildSliderCard(Icons.coffee, Colors.brown, 'Break Time',
            _constraints.breakMinutes, 'min', 0, 120, 12,
            (v) => setState(() => _constraints.breakMinutes = v)),
        const SizedBox(height: 8),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text('Unavailable (college days)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_constraints.totalUnavailableHours.toStringAsFixed(1)} hrs',
                      style: const TextStyle(
                          color: AppTheme.accentBlue,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text('Unavailable (holidays/weekends)',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(_constraints.totalUnavailableHours - _constraints.travelMinutes / 60).toStringAsFixed(1)} hrs',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSliderCard(IconData icon, Color iconColor, String title,
      double value, String unit, double min, double max, int divisions,
      ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13))),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${value.toStringAsFixed(unit == 'hrs' ? 1 : 0)} $unit',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
              Slider(
                value: value, min: min, max: max,
                divisions: divisions,
                activeColor: iconColor,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 6: Exam Schedule (NEW)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildExamScheduleStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Exam Schedule',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Set your periodic test and final exam dates. Syllabus will be divided accordingly.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13),
        ),
        const SizedBox(height: 24),

        // PT Count
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Number of Periodic Tests (PT)',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [1, 2, 3].map((count) {
                    final isSelected = _ptCount == count;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: count < 3 ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _ptCount = count),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.accentBlue
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.accentBlue
                                    : AppTheme.divider,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'PT $count',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // PT Date Ranges
        ...List.generate(_ptCount, (i) => _buildDateRangePickerCard(
              label: 'PT ${i + 1}',
              icon: Icons.quiz,
              iconColor: Colors.orange,
              startDate: _ptStartDates[i],
              endDate: _ptEndDates[i],
              onTapStart: () => _pickExamDate(i, isStart: true, isPt: true),
              onTapEnd: () => _pickExamDate(i, isStart: false, isPt: true),
            )),

        // Final Exam Date Range
        _buildDateRangePickerCard(
          label: 'Final Exam',
          icon: Icons.school,
          iconColor: Colors.red,
          startDate: _finalExamStartDate,
          endDate: _finalExamEndDate,
          onTapStart: () => _pickExamDate(0, isStart: true, isPt: false),
          onTapEnd: () => _pickExamDate(0, isStart: false, isPt: false),
        ),

        const SizedBox(height: 12),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    const Text('How it works',
                        style: TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                _infoRow('Before PT1',
                    _ptCount == 1 ? 'Complete full syllabus' : 'Complete first portion'),
                if (_ptCount >= 2)
                  _infoRow('PT1 → PT2', 'Complete second portion'),
                if (_ptCount >= 3)
                  _infoRow('PT2 → PT3', 'Complete third portion'),
                _infoRow(
                    'After last PT → Finals',
                    'Revision of ALL topics (no college hours)'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppTheme.accentBlue)),
          ),
          Expanded(
            child: Text(desc,
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePickerCard({
    required String label,
    required IconData icon,
    required Color iconColor,
    DateTime? startDate,
    DateTime? endDate,
    required VoidCallback onTapStart,
    required VoidCallback onTapEnd,
  }) {
    final fmt = DateFormat('dd MMM yyyy');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  const SizedBox(width: 8),
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onTapStart,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: startDate != null
                              ? AppTheme.accentBlue.withValues(alpha: 0.1)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: startDate != null
                                  ? AppTheme.accentBlue
                                  : AppTheme.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('From',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                            const SizedBox(height: 2),
                            Text(
                              startDate != null
                                  ? fmt.format(startDate)
                                  : 'Select date',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: startDate != null
                                    ? AppTheme.accentBlue
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward, size: 16),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: onTapEnd,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: endDate != null
                              ? AppTheme.accentBlue.withValues(alpha: 0.1)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: endDate != null
                                  ? AppTheme.accentBlue
                                  : AppTheme.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('To',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                            const SizedBox(height: 2),
                            Text(
                              endDate != null
                                  ? fmt.format(endDate)
                                  : 'Select date',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: endDate != null
                                    ? AppTheme.accentBlue
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickExamDate(int index,
      {required bool isStart, required bool isPt}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isPt) {
          if (isStart) {
            _ptStartDates[index] = picked;
          } else {
            _ptEndDates[index] = picked;
          }
        } else {
          if (isStart) {
            _finalExamStartDate = picked;
          } else {
            _finalExamEndDate = picked;
          }
        }
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 7: Summary
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSummaryStep() {
    final selected = _extractedSubjects.where((s) => s.isSelected).toList();
    final totalTopics = selected.fold(0, (sum, s) => sum + s.topicCount);
    final totalHours =
        selected.fold(0.0, (sum, s) => sum + s.estimatedStudyHours);
    final weeklyHrs =
        _summary['weeklyAvailableHours']?.toStringAsFixed(1) ?? '~';
    final predictedEnd = _summary['predictedEndDate'] as DateTime?;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Plan Summary',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('Review before generating',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13)),
        const SizedBox(height: 24),

        Row(children: [
          Expanded(child: _summaryCard(Icons.book, '${selected.length}',
              'Subjects', Colors.indigo)),
          const SizedBox(width: 12),
          Expanded(child: _summaryCard(Icons.topic, '$totalTopics',
              'Topics', Colors.blue)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _summaryCard(Icons.access_time,
              '${totalHours.toStringAsFixed(0)}h', 'Study Time',
              Colors.orange)),
          const SizedBox(width: 12),
          Expanded(child: _summaryCard(Icons.calendar_today,
              '$weeklyHrs h', 'Per Week', Colors.green)),
        ]),
        const SizedBox(height: 12),

        if (predictedEnd != null)
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.flag, color: AppTheme.successGreen),
              title: const Text('Completion Target',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('dd MMM yyyy').format(predictedEnd)),
            ),
          ),
        const SizedBox(height: 12),

        // Exam info
        if (_ptCount > 0) ...[
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Exam Schedule',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...List.generate(_ptCount, (i) {
                    final sd = _ptStartDates[i];
                    final ed = _ptEndDates[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PT ${i + 1}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Flexible(
                            child: Text(sd != null && ed != null
                                ? '${DateFormat('dd MMM').format(sd)} – ${DateFormat('dd MMM').format(ed)}'
                                : 'Not set',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_finalExamStartDate != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Final Exam',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.red)),
                        Flexible(
                          child: Text(
                            '${DateFormat('dd MMM').format(_finalExamStartDate!)}${_finalExamEndDate != null ? ' – ${DateFormat('dd MMM').format(_finalExamEndDate!)}' : ''}',
                              style: const TextStyle(color: Colors.red),
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],

        // Holidays
        if (_holidays.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Upcoming Holidays',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._holidays.take(5).map((h) => ListTile(
                dense: true,
                leading: const Icon(Icons.celebration,
                    color: Colors.orange, size: 20),
                title: Text(h.name, style: const TextStyle(fontSize: 13)),
                trailing: Text(DateFormat('dd MMM').format(h.date),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
              )),
        ],
      ],
    );
  }

  Widget _summaryCard(IconData icon, String value, String label, Color color) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 8: Generating (auto)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGeneratingStep() {
    return _AnimatedLoadingScreen(
      title: 'Crafting Your Plan',
      statusText: _generatingStatus,
      icon: Icons.calendar_month,
      color: const Color(0xFF8B5CF6),
      stages: const [
        _LoadingStage('📅', 'Checking calendar'),
        _LoadingStage('📊', 'Scheduling sessions'),
        _LoadingStage('🔄', 'Balancing subjects'),
        _LoadingStage('✨', 'Finishing up'),
      ],
      tips: const [
        '📅 Your plan adapts to your college schedule',
        '🔄 Subjects are rotated daily for variety',
        '🏖️ Holidays get 1.5× more study time',
        '📝 Each session includes quiz & resources',
        '🎯 Equal coverage ensures no subject falls behind',
      ],
    );
  }

  Future<void> _generatePlan() async {
    setState(() {
      _isGenerating = true;
      _generatingStatus = 'Fetching holidays...';
    });

    try {
      _holidays = await hs.HolidayService.getHolidays();

      if (mounted) setState(() => _generatingStatus = 'Building exam schedule...');
      await Future.delayed(const Duration(milliseconds: 400));

      // Build ExamSchedule from user input
      ExamSchedule? examSchedule;
      final ptDates = <ExamDate>[];
      for (int i = 0; i < _ptCount; i++) {
        if (_ptStartDates[i] != null) {
          ptDates.add(ExamDate(
            label: 'PT ${i + 1}',
            startDate: _ptStartDates[i]!,
            endDate: _ptEndDates[i] ?? _ptStartDates[i]!,
          ));
        }
      }
      if (ptDates.isNotEmpty || _finalExamStartDate != null) {
        examSchedule = ExamSchedule(
          ptCount: _ptCount,
          ptDates: ptDates,
          finalExamDate: _finalExamStartDate != null
              ? ExamDate(
                  label: 'Final',
                  startDate: _finalExamStartDate!,
                  endDate: _finalExamEndDate ?? _finalExamStartDate!,
                )
              : null,
        );
      }

      if (mounted) setState(() => _generatingStatus = 'Distributing topics...');
      await Future.delayed(const Duration(milliseconds: 400));

      final startDate = DateTime.now().add(const Duration(days: 1));
      final plan = TimetableGeneratorService.generateStudyPlan(
        subjects: _extractedSubjects,
        collegeSlots: _collegeSlots,
        constraints: _constraints,
        holidays: _holidays,
        startDate: startDate,
        examSchedule: examSchedule,
      );

      if (mounted) setState(() => _generatingStatus = 'Finalizing...');
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _studyPlan = plan;
          _isGenerating = false;
          _currentStep = 8;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _currentStep = 6);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 9: Preview & Save
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPreviewStep() {
    if (_studyPlan == null || _studyPlan!.sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            Text('No sessions generated',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Try adjusting your constraints',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          ],
        ),
      );
    }

    // Group by date
    final grouped = <String, List<TimetableSession>>{};
    for (var session in _studyPlan!.sessions) {
      final key = DateFormat('yyyy-MM-dd').format(session.date);
      grouped.putIfAbsent(key, () => []).add(session);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const Icon(Icons.check_circle,
                size: 48, color: AppTheme.successGreen),
            const SizedBox(height: 12),
            Text('Plan Ready!',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              '${_studyPlan!.sessions.length} sessions across ${grouped.length} days',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: grouped.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final dateKey = grouped.keys.elementAt(index);
              final daySessions = grouped[dateKey]!;
              final date = DateTime.parse(dateKey);
              final isHoliday =
                  daySessions.isNotEmpty && daySessions.first.isHolidaySession;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Text(DateFormat('EEE, dd MMM').format(date),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      if (isHoliday)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('🎉 Holiday/Weekend',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange.shade800)),
                        ),
                      const Spacer(),
                      Text('${daySessions.length} sessions',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12)),
                    ]),
                  ),
                  ...daySessions.map((session) {
                    final color = Color(int.parse(
                        session.colorHex.replaceFirst('#', '0xff')));
                    return Card(
                      elevation: 0,
                      color: AppTheme.surface,
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: AppTheme.divider),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(Icons.book, color: color, size: 16),
                        ),
                        title: Text(session.topic,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                            '${session.subject} • ${session.moduleName ?? ""}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text(
                          '${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Bottom Navigation
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Row(
        children: [
          if (_currentStep > 0 && _currentStep >= 2)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  int prev = _currentStep - 1;
                  if (prev == 1) prev = 0;
                  if (prev == 7) prev = 6;
                  setState(() => _currentStep = prev);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0 && _currentStep >= 2)
            const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _onNextPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 8
                    ? AppTheme.successGreen
                    : AppTheme.primaryNavy,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _getButtonText(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0: return 'Scan PDF';
      case 6: return 'Generate Plan';
      case 8: return 'Save & Start';
      default: return 'Next';
    }
  }

  Future<void> _onNextPressed() async {
    switch (_currentStep) {
      case 0: // Upload → Processing
        if (_pickedFiles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please upload at least one PDF syllabus')));
          return;
        }
        setState(() => _currentStep = 1);
        _processPdf();
        break;

      case 2: // Subjects → College
        final hasSelected = _extractedSubjects.any((s) => s.isSelected);
        if (!hasSelected) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Select at least one subject')));
          return;
        }
        setState(() => _currentStep = 3);
        break;

      case 3: // College → Lifestyle
        setState(() => _currentStep = 4);
        break;

      case 4: // Lifestyle → Exam Schedule
        setState(() => _currentStep = 5);
        break;

      case 5: // Exam Schedule → Summary
        // Pre-fetch holidays and calculate summary
        try {
          _holidays = await hs.HolidayService.getHolidays();
        } catch (_) {
          _holidays = [];
        }
        final startDate = DateTime.now().add(const Duration(days: 1));

        ExamSchedule? examSchedule;
        final ptDates = <ExamDate>[];
        for (int i = 0; i < _ptCount; i++) {
          if (_ptStartDates[i] != null) {
            ptDates.add(ExamDate(
              label: 'PT${i + 1}',
              startDate: _ptStartDates[i]!,
              endDate: _ptEndDates[i] ?? _ptStartDates[i]!,
            ));
          }
        }
        if (ptDates.isNotEmpty || _finalExamStartDate != null) {
          examSchedule = ExamSchedule(
            ptCount: _ptCount,
            ptDates: ptDates,
            finalExamDate: _finalExamStartDate != null
                ? ExamDate(
                    label: 'Final',
                    startDate: _finalExamStartDate!,
                    endDate: _finalExamEndDate ?? _finalExamStartDate!,
                  )
                : null,
          );
        }

        _summary = TimetableGeneratorService.calculateSummary(
          subjects: _extractedSubjects,
          collegeSlots: _collegeSlots,
          constraints: _constraints,
          holidays: _holidays,
          startDate: startDate,
          examSchedule: examSchedule,
        );
        setState(() => _currentStep = 6);
        break;

      case 6: // Summary → Generating
        setState(() => _currentStep = 7);
        _generatePlan();
        break;

      case 8: // Preview → Save
        await _savePlan();
        break;
    }
  }

  Future<void> _savePlan() async {
    if (_studyPlan == null) return;
    try {
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.uid ?? '';
      if (userId.isNotEmpty) {
        final firestore = FirestoreService();
        await firestore.saveStudyPlan(userId, _studyPlan!);
        await firestore.updateUser(userId, {'isTimetableCreated': true});
      }
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/student/dashboard', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🎉 Smart Timetable Created!'),
          backgroundColor: AppTheme.successGreen,
        ));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, '/student/dashboard', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Timetable created (save pending)')));
      }
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Animated Loading Screen (used for PDF processing & plan generation)
// ═════════════════════════════════════════════════════════════════════════════
class _LoadingStage {
  final String emoji;
  final String label;
  const _LoadingStage(this.emoji, this.label);
}

class _AnimatedLoadingScreen extends StatefulWidget {
  final String title;
  final String statusText;
  final IconData icon;
  final Color color;
  final List<_LoadingStage> stages;
  final List<String> tips;

  const _AnimatedLoadingScreen({
    required this.title,
    required this.statusText,
    required this.icon,
    required this.color,
    required this.stages,
    required this.tips,
  });

  @override
  State<_AnimatedLoadingScreen> createState() => _AnimatedLoadingScreenState();
}

class _AnimatedLoadingScreenState extends State<_AnimatedLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  int _currentTipIndex = 0;
  int _currentStageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Cycle tips every 3 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      setState(() {
        _currentTipIndex = (_currentTipIndex + 1) % widget.tips.length;
      });
      return true;
    });

    // Advance stages every 2.5 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return false;
      if (_currentStageIndex < widget.stages.length - 1) {
        setState(() => _currentStageIndex++);
      }
      return true;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pulsing icon with gradient ring
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) {
              final scale = 1.0 + (_pulseController.value * 0.08);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        widget.color.withValues(alpha: 0.15),
                        widget.color.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.25),
                      width: 3,
                    ),
                  ),
                  child: Icon(widget.icon, size: 42, color: widget.color),
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // Title
          Text(widget.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),

          // Stage progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.stages.length, (i) {
              final isActive = i <= _currentStageIndex;
              final isCurrent = i == _currentStageIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: isCurrent ? 40 : 28,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: isActive
                            ? widget.color
                            : widget.color.withValues(alpha: 0.15),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.stages[i].emoji,
                      style: TextStyle(
                        fontSize: isActive ? 16 : 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Current stage label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              widget.stages[_currentStageIndex].label,
              key: ValueKey(_currentStageIndex),
              style: TextStyle(
                color: widget.color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Status text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              widget.statusText,
              key: ValueKey(widget.statusText),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Study tip card (rotating)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.15),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Container(
              key: ValueKey(_currentTipIndex),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.color.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.tips[_currentTipIndex],
                      style: const TextStyle(fontSize: 13, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


