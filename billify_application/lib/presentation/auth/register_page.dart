import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/validators.dart';
import 'package:billify/presentation/widgets/custom_button.dart';
import 'package:billify/presentation/widgets/custom_text_field.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/registration_provider.dart';
import 'package:billify/presentation/widgets/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoadingOtp = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoadingOtp = true);
      
      try {
        await ref.read(registrationProvider.notifier).updateUserStep(
              name: _nameController.text,
              email: _emailController.text,
              password: _passwordController.text,
              phone: _phoneController.text,
            );

        if (mounted) {
          // 1. Request OTP
          ErrorHandler.showSuccessSnackBar(context, 'Requesting OTP code...');
          
          await ref.read(authProvider.notifier).requestOtp(_emailController.text);
          
          if (mounted) {
            setState(() => _isLoadingOtp = false);
            ErrorHandler.showSuccessSnackBar(
              context, 
              'Verification code sent to ${_emailController.text}'
            );
            _showOTPBottomSheet(context, _emailController.text);
          }
        }
      } catch (e) {
        setState(() => _isLoadingOtp = false);
        if (mounted) {
          ErrorHandler.showErrorSnackBar(context, e);
        }
      }
    }
  }

  void _showOTPBottomSheet(BuildContext context, String email) {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
          final textColor = isDark ? Colors.white : Colors.black87;
          final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[600];
          
          String? errorMessage;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Verify Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We\'ve sent a 6-digit code to',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryTextColor, fontSize: 16),
                  ),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: otpController,
                    label: 'OTP Code',
                    hint: '••••••',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.security_outlined,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      letterSpacing: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 40),
                  CustomButton(
                    text: 'VERIFY & CONTINUE',
                    isLoading: isVerifying,
                    onPressed: () async {
                      if (otpController.text.length < 6) {
                        ErrorHandler.showErrorSnackBar(
                          context,
                          'Please enter a valid 6-digit OTP',
                        );
                        return;
                      }

                      setModalState(() => isVerifying = true);
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        // 1. Verify OTP standalone
                        final response = await ref
                            .read(authProvider.notifier)
                            .verifyOtp(email, otpController.text);

                        if (mounted) {
                          // 2. Save OTP in provider
                          await ref
                              .read(registrationProvider.notifier)
                              .updateOtpStep(otpController.text);

                          if (mounted) {
                            Navigator.pop(context); // Close bottom sheet
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Email verified successfully!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );

                            // 3. Move to Business Setup
                            Navigator.pushNamed(
                              context,
                              '/business-setup',
                              arguments: {'isRegistration': true},
                            );
                          }
                        }
                      } catch (e) {
                        setModalState(() {
                          isVerifying = false;
                          errorMessage = ErrorHandler.getUserFriendlyMessage(e);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: isVerifying
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await ref
                                  .read(authProvider.notifier)
                                  .requestOtp(email);
                              if (mounted) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('New code sent successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                final message = ErrorHandler.getUserFriendlyMessage(e);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(message),
                                    backgroundColor: Colors.red.shade600,
                                  ),
                                );
                              }
                            }
                          },
                    child: Text(
                      'Resend Verification Code',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.authGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Join Billify and grow your business today',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),
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
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 40,
                    ),
                    child: Column(
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                hint: 'Enter your full name',
                                prefixIcon: Icons.person_outline,
                                validator: (v) =>
                                    Validators.validateRequired(v, 'Full Name'),
                              ),
                              const SizedBox(height: 20),
                              CustomTextField(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'Enter your email',
                                prefixIcon: Icons.email_outlined,
                                validator: Validators.validateEmail,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),
                              CustomTextField(
                                controller: _phoneController,
                                label: 'Phone Number',
                                hint: 'Enter phone number',
                                prefixIcon: Icons.phone_outlined,
                                validator: Validators.validatePhone,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 20),
                              CustomTextField(
                                controller: _passwordController,
                                label: 'Password',
                                hint: 'Min 6 characters',
                                isPassword: true,
                                prefixIcon: Icons.lock_outline,
                                validator: Validators.validatePassword,
                              ),
                              const SizedBox(height: 32),
                              CustomButton(
                                text: 'NEXT: BUSINESS DETAILS',
                                onPressed: _handleRegister,
                                isLoading: authState.isLoading || _isLoadingOtp,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
