import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/validators.dart';
import 'package:billify/presentation/widgets/custom_button.dart';
import 'package:billify/presentation/widgets/custom_text_field.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/presentation/widgets/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authProvider.notifier)
          .login(_phoneController.text, _passwordController.text);

      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState.isLoggedIn) {
        ref.invalidate(businessProvider);
        final businessState = ref.read(businessProvider);
        if (businessState.currentBusiness == null) {
          Navigator.pushReplacementNamed(context, '/business-setup');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (authState.error != null) {
        ErrorHandler.showErrorSnackBar(
          context,
          authState.errorObject ?? authState.error,
        );
      }
    }
  }

  void _showEmailNotRegisteredDialog({
    required String email,
    required String name,
    String? photo,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                color: AppTheme.primaryTeal,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Account Not Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No account is registered with this Google email:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined, size: 18, color: AppTheme.primaryTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you like to register a new account using this email address?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushNamed(
                context,
                '/register',
                arguments: {
                  'name': name,
                  'email': email,
                  'photo': photo,
                },
              );
            },
            child: const Text(
              'REGISTER NOW',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

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
                  const SizedBox(height: 48),
                  Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/billify.png',
                      width: 90,
                      height: 90,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Billify Login',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Simplify your business management',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 100),
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
                          vertical: 48,
                        ),
                        child: Column(
                          children: [
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  CustomTextField(
                                    controller: _phoneController,
                                    label: 'Phone Number',
                                    hint: 'Enter your phone number',
                                    prefixIcon: Icons.phone_outlined,
                                    validator: Validators.validatePhone,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 24),
                                  CustomTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hint: 'Enter your password',
                                    isPassword: true,
                                    prefixIcon: Icons.lock_outline,
                                    validator: Validators.validatePassword,
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/forgot-password',
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  CustomButton(
                                    text: 'LOGIN',
                                    onPressed: _handleLogin,
                                    isLoading: authState.isLoading,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/register'),
                                  child: Text(
                                    'Register',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(color: Colors.grey[300]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: Colors.grey[300]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            GestureDetector(
                              onTap: () async {
                                final result = await ref
                                    .read(authProvider.notifier)
                                    .loginWithGoogle();
                                if (!mounted) return;

                                if (result['success'] == true &&
                                    result['isRegistered'] == false) {
                                  _showEmailNotRegisteredDialog(
                                    email: result['email']?.toString() ?? '',
                                    name: result['name']?.toString() ?? '',
                                    photo: result['photo']?.toString(),
                                  );
                                  return;
                                }

                                final authState = ref.read(authProvider);
                                if (authState.isLoggedIn) {
                                  ref.invalidate(businessProvider);
                                  final businessState = ref.read(
                                    businessProvider,
                                  );
                                  if (businessState.currentBusiness == null) {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/business-setup',
                                    );
                                  } else {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/home',
                                    );
                                  }
                                } else if (authState.error != null) {
                                  ErrorHandler.showErrorSnackBar(
                                    context,
                                    authState.errorObject ?? authState.error,
                                  );
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Image.asset(
                                  'assets/sign_in_with_google.webp',
                                  fit: BoxFit.contain,
                                  height: 52, // Standard height for better UI
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        height: 52,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.login, size: 20),
                                            SizedBox(width: 12),
                                            Text('Sign in with Google'),
                                          ],
                                        ),
                                      ),
                                ),
                              ),
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
          if (authState.isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    if (authState.loadingMessage != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        authState.loadingMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
