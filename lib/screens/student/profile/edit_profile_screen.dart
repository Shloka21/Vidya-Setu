import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/common/app_button.dart';

import 'package:vidyasetu/services/localization_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _institutionController;
  late TextEditingController _courseController;

  File? _pickedImage;
  bool _isUploading = false;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _institutionController = TextEditingController(text: user?.institution ?? '');
    _courseController = TextEditingController(text: user?.course ?? '');
    _existingImageUrl = user?.profileImageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _institutionController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    // Show bottom sheet with options
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                context.tr('change_profile_photo'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt_rounded, color: AppTheme.accentBlue),
                ),
                title: Text(context.tr('take_photo'), style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(context.tr('use_your_camera'), style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library_rounded, color: AppTheme.accentPurple),
                ),
                title: Text(context.tr('choose_from_gallery'), style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(context.tr('pick_an_existing_photo'), style: TextStyle(color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (_existingImageUrl != null || _pickedImage != null) ...[
                Divider(),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.delete_rounded, color: AppTheme.errorRed),
                  ),
                  title: Text(context.tr('remove_photo'), style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.errorRed)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedImage = null;
                      _existingImageUrl = null;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() => _pickedImage = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('could_not_pick_image')}: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_pickedImage == null) return _existingImageUrl;

    try {
      final ref = FirebaseStorage.instance.ref('profiles/$uid.jpg');
      final uploadTask = ref.putFile(
        _pickedImage!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Show upload progress via snackbar
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
      });

      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Image upload failed: $e');
      return _existingImageUrl; // Fall back to existing URL
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userModel?.uid;
    if (uid == null) return;

    setState(() => _isUploading = true);

    try {
      // Upload image if a new one was picked
      String? imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(uid);
      }

      // If the user removed the photo (both null), delete from storage
      if (_pickedImage == null && _existingImageUrl == null && auth.userModel?.profileImageUrl != null) {
        try {
          await FirebaseStorage.instance.ref('profiles/$uid.jpg').delete();
        } catch (_) {
          // File might not exist, ignore
        }
        imageUrl = null;
      }

      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'institution': _institutionController.text.trim(),
        'course': _courseController.text.trim(),
        'profileImageUrl': imageUrl,
      };
      
      await FirestoreService().updateUser(uid, data);

      // Also update the Firebase Auth display name & photo URL
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(_nameController.text.trim());
        if (imageUrl != null) {
          await firebaseUser.updatePhotoURL(imageUrl);
        }
      }

      await auth.reloadUser(); // Refresh local user model

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('profile_updated_successfully')),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error')}: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _testAlarm() async {
    try {
      final notifService = NotificationService();
      await notifService.init();

      // Fire an IMMEDIATE notification (not scheduled) to verify the system
      final diagnostics = await notifService.showTestAlarm();

      if (mounted) {
        final notifEnabled = diagnostics['notificationsEnabled'];
        final exactAlarms = diagnostics['exactAlarmsEnabled'];

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(context.tr('alarm_diagnostics')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('an_immediate_test_notification_was_just'),
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 16),
                _diagRow(context.tr('notifications_enabled'), notifEnabled == true),
                _diagRow(context.tr('exact_alarms_allowed'), exactAlarms == true),
                _diagRow(context.tr('service_initialized'), diagnostics['initialized'] == true),
                SizedBox(height: 12),
                if (notifEnabled != true || exactAlarms != true)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.warningAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.warningAmber.withOpacity(0.3)),
                    ),
                    child: Text(
                      context.tr('some_permissions_are_missing') + 
                      '\n• Go to Settings → Apps → Vidya Setu → Notifications → Enable All\n' +
                      '• Go to Settings → Apps → Vidya Setu → Alarms & Reminders → Allow\n' +
                      '• Go to Settings → Apps → Vidya Setu → Display over other apps → Allow',
                      style: TextStyle(fontSize: 11, height: 1.5),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.tr('ok')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('alarm_error')}: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Widget _diagRow(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: ok ? AppTheme.successGreen : AppTheme.errorRed,
            size: 18,
          ),
          SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(title: Text(context.tr('edit_profile'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar with image picking
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.accentBlue, width: 3),
                          image: _pickedImage != null
                              ? DecorationImage(
                                  image: FileImage(_pickedImage!),
                                  fit: BoxFit.cover,
                                )
                              : _existingImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(_existingImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: (_pickedImage == null && _existingImageUrl == null)
                            ? Center(
                                child: Text(
                                  _nameController.text.isNotEmpty
                                      ? _nameController.text[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: AppTheme.accentBlue,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.tr('tap_to_change_photo'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (_isUploading) ...[
                SizedBox(height: 8),
                LinearProgressIndicator(),
                SizedBox(height: 4),
                Text(
                  context.tr('uploading_image'),
                  style: TextStyle(
                    color: AppTheme.accentBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              SizedBox(height: 24),
              _buildField(context.tr('full_name'), _nameController, Icons.person_rounded),
              _buildField(context.tr('email'), _emailController, Icons.email_rounded,
                  readOnly: true),
              _buildField(context.tr('phone'), _phoneController, Icons.phone_rounded,
                  keyboardType: TextInputType.phone),
              _buildField(
                  context.tr('institution'), _institutionController, Icons.school_rounded),
              _buildField(
                  context.tr('course__grade'), _courseController, Icons.class_rounded),
              _buildField(context.tr('bio'), _bioController, Icons.info_outline_rounded,
                  maxLines: 3),
              const SizedBox(height: 24),
              AppButton(
                text: _isUploading ? 'Saving...' : 'Save Changes',
                onPressed: _isUploading ? () {} : _saveProfile,
                icon: Icons.check_rounded,
              ),
              const SizedBox(height: 16),

              // ── Test Alarm Button ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.warningAmber.withOpacity(0.4)),
                  color: AppTheme.warningAmber.withOpacity(0.05),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _testAlarm,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.alarm_rounded, color: AppTheme.warningAmber, size: 20),
                          SizedBox(width: 8),
                          Text(
                            context.tr('test_notification_alarm'),
                            style: TextStyle(
                              color: AppTheme.warningAmber,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6),
              Text(
                context.tr('fires_a_test_alarm_in_5_seconds__try_loc'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
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
          prefixIcon: Icon(icon, color: AppTheme.accentBlue, size: 22),
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: AppTheme.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppTheme.accentBlue, width: 2),
          ),
        ),
        validator: (v) =>
            label == 'Full Name' && (v == null || v.isEmpty)
                ? 'Name is required'
                : null,
      ),
    );
  }
}
