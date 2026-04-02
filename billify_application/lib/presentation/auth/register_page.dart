import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/core/utils/validators.dart';
import 'package:billify_application/data/models/user_model.dart';
import 'package:billify_application/presentation/widgets/custom_button.dart';
import 'package:billify_application/presentation/widgets/custom_text_field.dart';
import 'package:billify_application/providers/auth_provider.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final user = UserModel(
        name: _nameController.text,
        email: _emailController.text,
        mobile: _phoneController.text,
        password: _passwordController.text,
      );

      await ref.read(authProvider.notifier).register(user);

      final authState = ref.read(authProvider);
      if (authState.error == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
        Navigator.pop(context);
      } else if (authState.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authState.error!)),
        );
      }
    }
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
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
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
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
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
                                validator: (v) => Validators.validateRequired(v, 'Full Name'),
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
                                text: 'REGISTER',
                                onPressed: _handleRegister,
                                isLoading: authState.isLoading,
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
                                color: Theme.of(context).textTheme.bodySmall?.color,
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
