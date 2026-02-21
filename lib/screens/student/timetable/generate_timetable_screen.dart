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
  PlatformFile? _pickedFile;

  // Step 2: Processing (auto)

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
  final List<DateTime?> _ptStartDates = [null, null, null];
  final List<DateTime?> _ptEndDates = [null, null, null];
  DateTime? _finalExamStartDate;
  DateTime? _finalExamEndDate;

  // Step 7: Summary
  Map<String, dynamic> _summary = {};

  // Step 8: Generating (auto)
  String _generatingStatus = 'Fetching holidays...';

  // Step 9: Preview
  StudyPlan? _studyPlan;
  List<HolidayInfo> _holidays = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Smart Timetable',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Skip auto steps when going back
            if (_currentStep > 0 && _currentStep != 1 && _currentStep != 7) {
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
                              color: AppTheme.accentBlue.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_stories, size: 48, color: AppTheme.accentBlue),
          const SizedBox(height: 16),
          Text(
            'Upload Syllabus',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your university syllabus PDF',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: _pickedFile != null
                    ? Border.all(color: AppTheme.successGreen, width: 2)
                    : null,
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
                  Icon(
                    _pickedFile != null
                        ? Icons.check_circle
                        : Icons.cloud_upload_outlined,
                    size: 56,
                    color: _pickedFile != null
                        ? AppTheme.successGreen
                        : AppTheme.accentBlue,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _pickedFile?.name ?? 'Tap to Upload PDF',
                    style: TextStyle(
                      color: _pickedFile != null
                          ? AppTheme.successGreen
                          : AppTheme.accentBlue,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_pickedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
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

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result != null) {
      setState(() => _pickedFile = result.files.single);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 2: Processing PDF (auto-advance)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProcessingStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: AppTheme.accentBlue,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Analyzing Syllabus...',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Extracting subjects, modules & topics',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPdf() async {
    if (_pickedFile == null || _pickedFile!.bytes == null) return;

    try {
      final results = await Future.wait([
        Future(() async {
          final text = await PdfService.extractText(_pickedFile!.bytes!);
          return PdfService.parseUniversitySyllabus(text);
        }),
        Future.delayed(const Duration(milliseconds: 2000)),
      ]);
      final subjects = results[0] as List<SubjectInfo>;

      if (mounted) {
        setState(() {
          _extractedSubjects = subjects;
          _currentStep = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            Text(
              'No subjects found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try uploading a different PDF',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Select Subjects',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Choose subjects for your study plan',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),

        // Select All
        AppCard(
          child: CheckboxListTile(
            value: _selectAll,
            activeColor: AppTheme.accentBlue,
            title: const Text(
              'Select All',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${_extractedSubjects.length} subjects found'),
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
        const SizedBox(height: 12),

        // Subject list - simple cards (not expansion tiles for speed)
        ..._extractedSubjects.map(
          (subject) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: ListTile(
                leading: Checkbox(
                  value: subject.isSelected,
                  activeColor: AppTheme.accentBlue,
                  onChanged: (val) {
                    setState(() {
                      subject.isSelected = val ?? true;
                      _selectAll = _extractedSubjects.every(
                        (s) => s.isSelected,
                      );
                    });
                  },
                ),
                title: Text(
                  subject.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${subject.moduleCount} modules • ${subject.topicCount} topics • ~${subject.estimatedStudyHours.toStringAsFixed(0)} hrs',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                trailing: subject.modules.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.info_outline, size: 20),
                        onPressed: () => _showSubjectDetails(subject),
                      )
                    : null,
              ),
            ),
          ),
        ),
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
              Text(
                subject.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${subject.code} • ${subject.credits} credits',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              Divider(height: 24),
              ...subject.modules.map(
                (module) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Module ${module.number}: ${module.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${module.hours} hrs • ${module.topics.length} topics',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...module.topics.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 5,
                              color: AppTheme.accentBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
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
        Text(
          'College Timetable',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Tap time slots where you have college lectures',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 13,
          ),
        ),
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
            leading: const Icon(Icons.info_outline, color: AppTheme.accentBlue),
            title: const Text(
              'Study only after college',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            subtitle: Text(
              'On college days, sessions are scheduled only in the evening after your last lecture',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
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
        Text(
          'Your Daily Routine',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Tell us about your schedule so we plan around it',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),
        _buildSliderCard(
          Icons.bedtime,
          Colors.indigo,
          'Sleep Duration',
          _constraints.sleepHours,
          'hrs',
          5,
          10,
          10,
          (v) => setState(() => _constraints.sleepHours = v),
        ),
        _buildSliderCard(
          Icons.directions_bus,
          Colors.blue,
          'Daily Travel Time (college days only)',
          _constraints.travelMinutes,
          'min',
          0,
          180,
          18,
          (v) => setState(() => _constraints.travelMinutes = v),
        ),
        _buildSliderCard(
          Icons.person,
          Colors.green,
          'Family / Personal Time',
          _constraints.personalMinutes,
          'min',
          0,
          180,
          18,
          (v) => setState(() => _constraints.personalMinutes = v),
        ),
        _buildSliderCard(
          Icons.coffee,
          Colors.brown,
          'Break Time',
          _constraints.breakMinutes,
          'min',
          0,
          120,
          12,
          (v) => setState(() => _constraints.breakMinutes = v),
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Unavailable (college days)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${_constraints.totalUnavailableHours.toStringAsFixed(1)} hrs',
                      style: const TextStyle(
                        color: AppTheme.accentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Unavailable (holidays/weekends)',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${(_constraints.totalUnavailableHours - _constraints.travelMinutes / 60).toStringAsFixed(1)} hrs (no travel)',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 12,
                      ),
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

  Widget _buildSliderCard(
    IconData icon,
    Color iconColor,
    String title,
    double value,
    String unit,
    double min,
    double max,
    int divisions,
    ValueChanged<double> onChanged,
  ) {
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
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${value.toStringAsFixed(unit == 'hrs' ? 1 : 0)} $unit',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: value,
                min: min,
                max: max,
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
        Text(
          'Exam Schedule',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Set your periodic test and final exam dates. Syllabus will be divided accordingly.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),

        // PT Count
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Number of Periodic Tests (PT)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [1, 2, 3].map((count) {
                    final isSelected = _ptCount == count;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: count < 3 ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _ptCount = count),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.accentBlue
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.accentBlue
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outline.withOpacity(0.3),
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
        ...List.generate(
          _ptCount,
          (i) => _buildDateRangePickerCard(
            label: 'PT ${i + 1}',
            icon: Icons.quiz,
            iconColor: Colors.orange,
            startDate: _ptStartDates[i],
            endDate: _ptEndDates[i],
            onTapStart: () => _pickExamDate(i, isStart: true, isPt: true),
            onTapEnd: () => _pickExamDate(i, isStart: false, isPt: true),
          ),
        ),

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
                    const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'How it works',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _infoRow(
                  'Before PT1',
                  _ptCount == 1
                      ? 'Complete full syllabus'
                      : 'Complete first portion',
                ),
                if (_ptCount >= 2)
                  _infoRow('PT1 → PT2', 'Complete second portion'),
                if (_ptCount >= 3)
                  _infoRow('PT2 → PT3', 'Complete third portion'),
                _infoRow(
                  'After last PT → Finals',
                  'Revision of ALL topics (no college hours)',
                ),
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
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppTheme.accentBlue,
              ),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
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
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
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
                          vertical: 10,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: startDate != null
                              ? AppTheme.accentBlue.withValues(alpha: 0.1)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: startDate != null
                                ? AppTheme.accentBlue
                                : Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'From',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
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
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.5),
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
                          vertical: 10,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: endDate != null
                              ? AppTheme.accentBlue.withValues(alpha: 0.1)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: endDate != null
                                ? AppTheme.accentBlue
                                : Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
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
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.5),
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

  Future<void> _pickExamDate(
    int index, {
    required bool isStart,
    required bool isPt,
  }) async {
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
    final totalHours = selected.fold(
      0.0,
      (sum, s) => sum + s.estimatedStudyHours,
    );
    final weeklyHrs =
        _summary['weeklyAvailableHours']?.toStringAsFixed(1) ?? '~';
    final predictedEnd = _summary['predictedEndDate'] as DateTime?;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Plan Summary', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Review before generating',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: _summaryCard(
                Icons.book,
                '${selected.length}',
                'Subjects',
                Colors.indigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                Icons.topic,
                '$totalTopics',
                'Topics',
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                Icons.access_time,
                '${totalHours.toStringAsFixed(0)}h',
                'Study Time',
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                Icons.calendar_today,
                '$weeklyHrs h',
                'Per Week',
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (predictedEnd != null)
          AppCard(
            child: ListTile(
              leading: const Icon(Icons.flag, color: AppTheme.successGreen),
              title: const Text(
                'Completion Target',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
                  const Text(
                    'Exam Schedule',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_ptCount, (i) {
                    final sd = _ptStartDates[i];
                    final ed = _ptEndDates[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PT ${i + 1}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            sd != null && ed != null
                                ? '${DateFormat('dd MMM').format(sd)} – ${DateFormat('dd MMM').format(ed)}'
                                : 'Not set',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_finalExamStartDate != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Final Exam',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          '${DateFormat('dd MMM').format(_finalExamStartDate!)}${_finalExamEndDate != null ? ' – ${DateFormat('dd MMM').format(_finalExamEndDate!)}' : ''}',
                          style: const TextStyle(color: Colors.red),
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
          Text(
            'Upcoming Holidays',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._holidays
              .take(5)
              .map(
                (h) => ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.celebration,
                    color: Colors.orange,
                    size: 20,
                  ),
                  title: Text(h.name, style: const TextStyle(fontSize: 13)),
                  trailing: Text(
                    DateFormat('dd MMM').format(h.date),
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  Widget _summaryCard(IconData icon, String value, String label, Color color) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 8: Generating (auto)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildGeneratingStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              color: AppTheme.accentBlue,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Generating Your Plan',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _generatingStatus,
              key: ValueKey(_generatingStatus),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePlan() async {
    setState(() {
      _generatingStatus = 'Fetching holidays...';
    });

    try {
      _holidays = await hs.HolidayService.getHolidays();

      if (mounted) {
        setState(() => _generatingStatus = 'Building exam schedule...');
      }
      await Future.delayed(const Duration(milliseconds: 400));

      // Build ExamSchedule from user input
      ExamSchedule? examSchedule;
      final ptDates = <ExamDate>[];
      for (int i = 0; i < _ptCount; i++) {
        if (_ptStartDates[i] != null) {
          ptDates.add(
            ExamDate(
              label: 'PT ${i + 1}',
              startDate: _ptStartDates[i]!,
              endDate: _ptEndDates[i] ?? _ptStartDates[i]!,
            ),
          );
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
          _currentStep = 8;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            Text(
              'No sessions generated',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your constraints',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
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
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                size: 48,
                color: AppTheme.successGreen,
              ),
              const SizedBox(height: 12),
              Text(
                'Plan Ready!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${_studyPlan!.sessions.length} sessions across ${grouped.length} days',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
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
                    child: Row(
                      children: [
                        Text(
                          DateFormat('EEE, dd MMM').format(date),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (isHoliday)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '🎉 Holiday/Weekend',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          '${daySessions.length} sessions',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...daySessions.map((session) {
                    final color = Color(
                      int.parse(session.colorHex.replaceFirst('#', '0xff')),
                    );
                    return Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(Icons.book, color: color, size: 16),
                        ),
                        title: Text(
                          session.topic,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${session.subject} • ${session.moduleName ?? ""}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          '${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0 && _currentStep >= 2) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _onNextPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 8
                    ? AppTheme.successGreen
                    : Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _getButtonText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Scan PDF';
      case 6:
        return 'Generate Plan';
      case 8:
        return 'Save & Start';
      default:
        return 'Next';
    }
  }

  Future<void> _onNextPressed() async {
    switch (_currentStep) {
      case 0: // Upload → Processing
        if (_pickedFile == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please upload a PDF first')),
          );
          return;
        }
        setState(() => _currentStep = 1);
        _processPdf();
        break;

      case 2: // Subjects → College
        final hasSelected = _extractedSubjects.any((s) => s.isSelected);
        if (!hasSelected) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select at least one subject')),
          );
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
            ptDates.add(
              ExamDate(
                label: 'PT${i + 1}',
                startDate: _ptStartDates[i]!,
                endDate: _ptEndDates[i] ?? _ptStartDates[i]!,
              ),
            );
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
    if (_studyPlan == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No study plan to save')));
      return;
    }
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.uid ?? '';
      if (userId.isNotEmpty) {
        final firestore = FirestoreService();
        await firestore.saveStudyPlan(userId, _studyPlan!);
        await firestore.updateUser(userId, {'isTimetableCreated': true});
      }
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/student/dashboard',
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Smart Timetable Created!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/student/dashboard',
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timetable created (save pending)')),
        );
      }
    }
  }
}
