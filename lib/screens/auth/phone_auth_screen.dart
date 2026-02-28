import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _codeSent = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;
  String _countryCode = '+91';

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _fullPhoneNumber => '$_countryCode${_phoneController.text.trim()}';

  String get _otpCode =>
      _otpControllers.map((c) => c.text).join();

  Future<void> _sendOtp() async {
    if (_phoneController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid phone number'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(_fullPhoneNumber);

    if (success && mounted) {
      setState(() => _codeSent = true);
      _startResendTimer();
      _otpFocusNodes[0].requestFocus();
    }
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the complete OTP'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(_otpCode);

    if (success && mounted) {
      if (authProvider.needsRoleSelection) {
        Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);
      } else if (authProvider.userModel?.isStudent == true) {
        Navigator.pushReplacementNamed(context, AppRoutes.studentDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.mentorDashboard);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_codeSent) {
              setState(() => _codeSent = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _codeSent ? _buildOtpView() : _buildPhoneView(),
          ),
        ),
      ),
    );
  }

  // ─── Phone Number Entry ──────────────────────────────────
  Widget _buildPhoneView() {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.phone_android_rounded,
            color: AppTheme.accentBlue,
            size: 36,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Phone\nVerification',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryNavy,
                height: 1.1,
                letterSpacing: -1,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll send you an OTP to verify your phone number',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
        ),
        const SizedBox(height: 36),

        // Phone input
        Text(
          'Phone Number',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country code
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _countryCode,
                  items: const [
                    DropdownMenuItem(value: '+91', child: Text('🇮🇳  +91')),
                    DropdownMenuItem(value: '+1', child: Text('🇺🇸  +1')),
                    DropdownMenuItem(value: '+44', child: Text('🇬🇧  +44')),
                    DropdownMenuItem(value: '+61', child: Text('🇦🇺  +61')),
                    DropdownMenuItem(value: '+971', child: Text('🇦🇪  +971')),
                  ],
                  onChanged: (v) => setState(() => _countryCode = v ?? '+91'),
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Phone number
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Enter phone number',
                  counterText: '',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Error
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.error != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.error!,
                          style: TextStyle(color: AppTheme.errorRed, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Send OTP button
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return AppButton(
              text: 'Send OTP',
              onPressed: _sendOtp,
              isLoading: auth.phoneAuthLoading,
              icon: Icons.send_rounded,
            );
          },
        ),
      ],
    );
  }

  // ─── OTP Verification ────────────────────────────────────
  Widget _buildOtpView() {
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),

        // Icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: AppTheme.successGreen,
            size: 36,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Enter OTP',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryNavy,
                height: 1.1,
                letterSpacing: -1,
              ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: _fullPhoneNumber,
                style: TextStyle(
                  color: AppTheme.primaryNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // OTP input boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) {
            return SizedBox(
              width: 50,
              height: 60,
              child: TextFormField(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  color: AppTheme.primaryNavy,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  filled: true,
                  fillColor: _otpControllers[i].text.isNotEmpty
                      ? AppTheme.accentBlue.withOpacity(0.05)
                      : AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _otpControllers[i].text.isNotEmpty
                          ? AppTheme.accentBlue
                          : Colors.transparent,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: _otpControllers[i].text.isNotEmpty
                          ? AppTheme.accentBlue
                          : Colors.transparent,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppTheme.accentBlue, width: 2),
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // Rebuild to update border color
                  if (value.isNotEmpty && i < 5) {
                    _otpFocusNodes[i + 1].requestFocus();
                  }
                  if (value.isEmpty && i > 0) {
                    _otpFocusNodes[i - 1].requestFocus();
                  }
                  // Auto-verify when all 6 digits entered
                  if (_otpCode.length == 6) {
                    _verifyOtp();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 32),

        // Error
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.error != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.errorRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.error!,
                          style: TextStyle(color: AppTheme.errorRed, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Verify button
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return AppButton(
              text: 'Verify & Sign In',
              onPressed: _verifyOtp,
              isLoading: auth.isLoading,
              icon: Icons.verified_rounded,
            );
          },
        ),
        const SizedBox(height: 20),

        // Resend OTP
        Center(
          child: _resendSeconds > 0
              ? Text(
                  'Resend OTP in ${_resendSeconds}s',
                  style: TextStyle(
                    color: AppTheme.textLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : TextButton(
                  onPressed: () {
                    final authProvider =
                        Provider.of<AuthProvider>(context, listen: false);
                    authProvider.resendOtp(_fullPhoneNumber);
                    _startResendTimer();
                  },
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
