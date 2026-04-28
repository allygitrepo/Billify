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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authProvider.notifier)
          .login(_emailController.text, _passwordController.text);

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
                                    controller: _emailController,
                                    label: 'Email',
                                    hint: 'Enter your email',
                                    prefixIcon: Icons.email_outlined,
                                    validator: Validators.validateEmail,
                                    keyboardType: TextInputType.emailAddress,
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
                                  const SizedBox(height: 40),
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
                                await ref
                                    .read(authProvider.notifier)
                                    .loginWithGoogle();
                                if (!mounted) return;

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
