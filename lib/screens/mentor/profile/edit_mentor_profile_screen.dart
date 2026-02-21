import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../app/theme.dart';
import '../../../app/design_system.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../widgets/common/app_button.dart';

class EditMentorProfileScreen extends StatefulWidget {
  const EditMentorProfileScreen({super.key});

  @override
  State<EditMentorProfileScreen> createState() =>
      _EditMentorProfileScreenState();
}

class _EditMentorProfileScreenState extends State<EditMentorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _qualificationController;
  late TextEditingController _experienceController;
  late TextEditingController _expertiseController;
  late TextEditingController _hourlyRateController;

  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  List<String> _selectedSubjects = [];

  final List<String> _availableSubjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'English',
    'Hindi',
    'History',
    'Geography',
    'Economics',
    'Business Studies',
    'Accountancy',
    'Political Science',
    'Psychology',
    'Sociology',
    'Art & Design',
    'Music',
    'Physical Education',
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _qualificationController = TextEditingController(
      text: user?.institution ?? '',
    );
    _experienceController = TextEditingController(
      text: user?.experienceYears.toString() ?? '',
    );
    _expertiseController = TextEditingController(text: user?.course ?? '');
    _hourlyRateController = TextEditingController(text: '');
    _selectedSubjects = user?.subjectsTaught ?? [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _expertiseController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Change Profile Photo',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DesignSystem.primaryPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: DesignSystem.primaryPurple,
                ),
              ),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (photo != null) {
                  setState(() => _selectedImage = File(photo.path));
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DesignSystem.primaryIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.photo_library_rounded,
                  color: DesignSystem.primaryIndigo,
                ),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (photo != null) {
                  setState(() => _selectedImage = File(photo.path));
                }
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_rounded, color: Colors.red),
                ),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedImage = null);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSubjectPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Subjects',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {});
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _availableSubjects.length,
                  itemBuilder: (context, index) {
                    final subject = _availableSubjects[index];
                    final isSelected = _selectedSubjects.contains(subject);
                    return CheckboxListTile(
                      title: Text(subject),
                      value: isSelected,
                      activeColor: DesignSystem.primaryPurple,
                      onChanged: (value) {
                        setModalState(() {
                          if (value == true) {
                            _selectedSubjects.add(subject);
                          } else {
                            _selectedSubjects.remove(subject);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userModel?.uid;

      if (userId == null) {
        throw Exception('User not found');
      }

      // Prepare data to update
      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'institution': _qualificationController.text.trim(),
        'experienceYears': int.tryParse(_experienceController.text.trim()) ?? 0,
        'course': _expertiseController.text.trim(),
        'subjectsTaught': _selectedSubjects,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Update Firestore
      await _firestoreService.updateUser(userId, updateData);

      // Refresh user data in provider
      await authProvider.reloadUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to update profile: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: DesignSystem.primaryPurple.withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: DesignSystem.primaryPurple,
                            width: 3,
                          ),
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _selectedImage == null
                            ? Center(
                                child: Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text[0].toUpperCase()
                                      : 'M',
                                  style: TextStyle(
                                    color: DesignSystem.primaryPurple,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: DesignSystem.primaryPurple,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Section: Personal Information
              _buildSectionHeader('Personal Information'),
              _buildField('Full Name', _nameController, Icons.person_rounded),
              _buildField(
                'Email',
                _emailController,
                Icons.email_rounded,
                readOnly: true,
              ),
              _buildField(
                'Phone',
                _phoneController,
                Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              _buildField(
                'Bio',
                _bioController,
                Icons.info_outline_rounded,
                maxLines: 3,
                hint: 'Tell students about yourself...',
              ),

              const SizedBox(height: 16),

              // Section: Professional Information
              _buildSectionHeader('Professional Information'),
              _buildField(
                'Qualification',
                _qualificationController,
                Icons.school_rounded,
                hint: 'e.g., M.Tech, PhD, B.Ed',
              ),
              _buildField(
                'Years of Experience',
                _experienceController,
                Icons.work_rounded,
                keyboardType: TextInputType.number,
              ),
              _buildField(
                'Area of Expertise',
                _expertiseController,
                Icons.lightbulb_rounded,
                hint: 'e.g., JEE Preparation, NEET Biology',
              ),
              _buildField(
                'Hourly Rate (₹)',
                _hourlyRateController,
                Icons.currency_rupee_rounded,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Section: Subjects
              _buildSectionHeader('Subjects You Teach'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showSubjectPicker,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: DesignSystem.primaryPurple,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _selectedSubjects.isEmpty
                            ? Text(
                                'Select subjects you teach',
                                style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedSubjects.map((subject) {
                                  return Chip(
                                    label: Text(
                                      subject,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: DesignSystem.primaryPurple
                                        .withValues(alpha: 0.1),
                                    side: BorderSide.none,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  );
                                }).toList(),
                              ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : AppButton(
                      text: 'Save Changes',
                      onPressed: _saveProfile,
                      icon: Icons.check_rounded,
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: DesignSystem.primaryPurple,
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: DesignSystem.primaryPurple, size: 22),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: DesignSystem.primaryPurple, width: 2),
          ),
        ),
        validator: (v) => label == 'Full Name' && (v == null || v.isEmpty)
            ? 'Name is required'
            : null,
      ),
    );
  }
}
