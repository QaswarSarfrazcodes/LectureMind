import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).sendPasswordReset(_emailController.text);
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
                      title: 'Reset Password',
                      subtitle: 'Enter your registered email and we will send you password reset instructions.',
                    ),
                    const SizedBox(height: AppDimens.space32),

                    // Success Banner
                    if (authState.successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppDimens.space16),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: AppColors.success,
                              size: 22,
                            ),
                            const SizedBox(width: AppDimens.space12),
                            Expanded(
                              child: Text(
                                authState.successMessage!,
                                style: AppTextStyles.body(AppColors.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimens.space20),
                    ],

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
                      onSubmitted: (_) => _handleReset(),
                    ),
                    const SizedBox(height: AppDimens.space24),

                    // Reset Button
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleReset,
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
                              'Send Reset Link',
                              style: AppTextStyles.bodyStrong(AppColors.pureWhite).copyWith(
                                fontSize: 16,
                              ),
                            ),
                    ),
                    const SizedBox(height: AppDimens.space24),

                    // Return to Login Link
                    Center(
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Back to Sign In',
                          style: AppTextStyles.bodyStrong(AppColors.crimsonRed),
                        ),
                      ),
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
