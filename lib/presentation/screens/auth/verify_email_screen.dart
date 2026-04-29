// lib/presentation/screens/auth/verify_email_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/shared_widgets.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.find();
    final email = auth.firebaseUser.value?.email ?? '';

    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            title: 'Verify Your\nEmail',
            subtitle: 'One last step before you get started',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.mark_email_unread_outlined,
                        size: 60, color: AppColors.accent),
                  ).animate().fadeIn().scale(),
                  const SizedBox(height: 32),
                  Text(
                    'We sent a verification link to:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Click the link in the email to verify your account, then tap the button below.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  Obx(() => PrimaryButton(
                        label: "I've Verified My Email",
                        isLoading: auth.isLoading.value,
                        onTap: auth.checkEmailVerified,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => OutlinedButton(
                        onPressed:
                            auth.isLoading.value ? null : auth.resendVerificationEmail,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          side: const BorderSide(color: AppColors.accent),
                        ),
                        child: const Text(
                          'Resend Verification Email',
                          style: TextStyle(color: AppColors.accent),
                        ),
                      )),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () async {
                      await auth.logout();
                    },
                    child: const Text(
                      'Use a different account',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
            ),
          ),
        ],
      ),
    );
  }
}
