import 'dart:async';
import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/app_feedback.dart';
import 'package:billify/core/utils/validators.dart';
import 'package:billify/presentation/widgets/custom_button.dart';
import 'package:billify/presentation/widgets/custom_text_field.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  int _currentStep = 0; // 0: Phone, 1: OTP, 2: New Password

  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendTimer = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleRequestOtp() async {
    AppFeedback.unfocus();
    if (!_phoneFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final phone = _phoneController.text.trim();
      await ref.read(authProvider.notifier).requestForgotPasswordOtp(phone);

      if (!mounted) return;
      setState(() {
        _currentStep = 1;
        _isLoading = false;
      });
      _startResendTimer();
      AppFeedback.showSuccess(context, 'OTP sent to $phone');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.showError(context, e);
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendTimer > 0) return;
    AppFeedback.unfocus();
    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      await ref.read(authProvider.notifier).requestForgotPasswordOtp(phone);

      if (!mounted) return;
      setState(() => _isLoading = false);
      _startResendTimer();
      AppFeedback.showSuccess(context, 'New OTP sent to $phone');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.showError(context, e);
    }
  }

  Future<void> _handleVerifyOtp() async {
    AppFeedback.unfocus();
    if (!_otpFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final phone = _phoneController.text.trim();
      final otp = _otpController.text.trim();
      await ref.read(authProvider.notifier).verifyOtp(phone, otp);

      if (!mounted) return;
      setState(() {
        _currentStep = 2;
        _isLoading = false;
      });
      AppFeedback.showSuccess(context, 'OTP verified successfully');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.showError(context, e);
    }
  }

  Future<void> _handleResetPassword() async {
    AppFeedback.unfocus();
    if (!_passwordFormKey.currentState!.validate()) return;

    final newPass = _passwordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass != confirmPass) {
      AppFeedback.showError(context, 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final phone = _phoneController.text.trim();
      final otp = _otpController.text.trim();
      await ref.read(authProvider.notifier).resetForgotPassword(phone, otp, newPass);

      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.showSuccess(
        context,
        'Password reset successfully. Please login with your new password.',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.showError(context, e);
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: AppTheme.authGradient),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // App Bar / Navigation Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: _handleBack,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Step ${_currentStep + 1} of 3',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Hero(
                    tag: 'logo',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _currentStep == 0
                            ? Icons.phone_android_rounded
                            : _currentStep == 1
                                ? Icons.mark_email_read_outlined
                                : Icons.lock_reset_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentStep == 0
                        ? 'Forgot Password'
                        : _currentStep == 1
                            ? 'Verify OTP'
                            : 'Set New Password',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _currentStep == 0
                          ? 'Enter your registered phone number to receive a verification code'
                          : _currentStep == 1
                              ? 'Enter the 6-digit OTP sent to ${_phoneController.text}'
                              : 'Create a new secure password for your account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Bottom White / Card Container
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.white
                            : Theme.of(context).cardColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 36,
                        ),
                        child: _buildCurrentStepView(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildPhoneStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildNewPasswordStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPhoneStep() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: 'Enter registered 10-digit mobile',
            prefixIcon: Icons.phone_outlined,
            validator: Validators.validatePhone,
            keyboardType: TextInputType.phone,
            autofocus: true,
          ),
          const SizedBox(height: 36),
          CustomButton(
            text: 'SEND OTP',
            onPressed: _handleRequestOtp,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Login'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _otpController,
            label: '6-Digit OTP',
            hint: 'Enter OTP code',
            prefixIcon: Icons.security_rounded,
            keyboardType: TextInputType.number,
            autofocus: true,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter 6-digit OTP';
              }
              if (val.trim().length != 6) {
                return 'OTP must be exactly 6 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() => _currentStep = 0),
                child: const Text('Change Number'),
              ),
              _resendTimer > 0
                  ? Text(
                      'Resend in ${_resendTimer}s',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : TextButton(
                      onPressed: _handleResendOtp,
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'VERIFY OTP',
            onPressed: _handleVerifyOtp,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _passwordController,
            label: 'New Password',
            hint: 'Enter new password (min 6 characters)',
            isPassword: true,
            prefixIcon: Icons.lock_outline,
            validator: Validators.validatePassword,
            autofocus: true,
          ),
          const SizedBox(height: 20),
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            hint: 'Re-enter new password',
            isPassword: true,
            prefixIcon: Icons.lock_reset,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Please confirm your new password';
              }
              if (val != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 36),
          CustomButton(
            text: 'RESET PASSWORD',
            onPressed: _handleResetPassword,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}
