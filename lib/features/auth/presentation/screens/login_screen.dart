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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authControllerProvider.notifier).signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleGoogleLogin() async {
    final success = await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleGuestLogin() async {
    final success = await ref.read(authControllerProvider.notifier).signInAsGuest();
    if (success && mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space24,
              vertical: AppDimens.space32,
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
                      title: 'Welcome Back, Scholar',
                      subtitle: 'Sign in to access your lectures, revision notes, and quizzes.',
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
                      hintText: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                      onSubmitted: (_) => _handleEmailLogin(),
                    ),
                    const SizedBox(height: AppDimens.space12),

                    // Forgot Password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(AppRoutes.forgotPassword),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: AppTextStyles.caption(AppColors.crimsonRed).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space24),

                    // Primary Sign In Button
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleEmailLogin,
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
                              'Sign In',
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

                    // Google Sign-In Button
                    OutlinedButton.icon(
                      onPressed: authState.isLoading ? null : _handleGoogleLogin,
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
                    const SizedBox(height: AppDimens.space12),

                    // Guest Mode Button
                    TextButton(
                      onPressed: authState.isLoading ? null : _handleGuestLogin,
                      child: Text(
                        'Continue as Guest (مہمان کے طور پر داخل ہوں)',
                        style: AppTextStyles.body(AppColors.darkTextSecondary),
                      ),
                    ),
                    const SizedBox(height: AppDimens.space24),

                    // Footer Link: Go to Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTextStyles.body(AppColors.darkTextSecondary),
                        ),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.signup),
                          child: Text(
                            'Sign Up',
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
