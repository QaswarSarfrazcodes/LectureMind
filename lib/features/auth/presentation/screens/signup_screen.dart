import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authControllerProvider.notifier).signUpWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleGoogleSignup() async {
    final success = await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.pureWhite),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space24,
              vertical: AppDimens.space16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      title: 'Start Your Journey',
                      subtitle: 'Create a free account to unlock AI lecture notes and oral tutoring.',
                    ),
                    const SizedBox(height: AppDimens.space32),

                    // Error Banner
                    if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppDimens.space12),
                        decoration: BoxDecoration(
                          color: AppColors.crimsonRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                          border: Border.all(
                            color: AppColors.crimsonRed.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.crimsonRed,
                              size: 20,
                            ),
                            const SizedBox(width: AppDimens.space12),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: AppTextStyles.caption(AppColors.crimsonRed),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.space20),
                    ],

                    // Full Name Field
                    AuthTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      hintText: 'e.g. Fatima Ali',
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Email Field
                    AuthTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hintText: 'student@university.edu',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Password Field
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hintText: 'Minimum 6 characters',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: (val) {
                        if (val == null || val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.space16),

                    // Confirm Password Field
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      prefixIcon: Icons.lock_clock_outlined,
                      isPassword: true,
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      onSubmitted: (_) => _handleSignup(),
                    ),
                    const SizedBox(height: AppDimens.space24),

                    // Sign Up Button
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.crimsonRed,
                        foregroundColor: AppColors.pureWhite,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(vertical: AppDimens.space16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        ),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.pureWhite,
                              ),
                            )
                          : Text(
                              'Create Account',
                              style: AppTextStyles.bodyStrong(AppColors.pureWhite).copyWith(
                                fontSize: 16,
                              ),
                            ),
                    ),
                    const SizedBox(height: AppDimens.space24),

                    // Divider: OR
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.navyBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppDimens.space16),
                          child: Text(
                            'OR',
                            style: AppTextStyles.caption(AppColors.darkTextSecondary),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.navyBorder)),
                      ],
                    ),
                    const SizedBox(height: AppDimens.space24),

                    // Google Sign-Up Button
                    OutlinedButton.icon(
                      onPressed: authState.isLoading ? null : _handleGoogleSignup,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.navyMid,
                        side: const BorderSide(color: AppColors.navyBorder),
                        padding: const EdgeInsets.symmetric(vertical: AppDimens.space16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        ),
                      ),
                      icon: const Icon(
                        Icons.g_mobiledata_rounded,
                        size: 26,
                        color: AppColors.pureWhite,
                      ),
                      label: Text(
                        'Continue with Google',
                        style: AppTextStyles.body(AppColors.pureWhite).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space24),

                    // Footer Link: Go to Sign In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTextStyles.body(AppColors.darkTextSecondary),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Text(
                            'Sign In',
                            style: AppTextStyles.bodyStrong(AppColors.crimsonRed),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
