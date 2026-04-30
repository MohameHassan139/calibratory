// lib/presentation/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController _auth = Get.find();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            title: 'Sign in to\nyour Account',
            subtitle: 'Welcome back to Caliborty',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'Email',
                      hint: 'Enter your email',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) =>
                          v!.contains('@') ? null : 'Enter a valid email',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passCtrl,
                      obscureText: _obscure,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.textHint,
                        ),
                      ),
                      validator: (v) =>
                          v!.length >= 6 ? null : 'Minimum 6 characters',
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                        child: const Text(
                          'Forget Password?',
                          style: TextStyle(color: AppColors.accent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => PrimaryButton(
                          label: 'Login',
                          isLoading: _auth.isLoading.value,
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              _auth.login(_emailCtrl.text.trim(),
                                  _passCtrl.text.trim());
                            }
                          },
                        )),
                    const SizedBox(height: 24),

                    // Social login divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or login using',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialBtn(icon: Icons.apple, onTap: () {}),
                        const SizedBox(width: 16),
                        _SocialBtn(
                            icon: Icons.g_mobiledata_rounded, onTap: () {}),
                        const SizedBox(width: 16),
                        _SocialBtn(icon: Icons.facebook, onTap: () {}),
                      ],
                    ),

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.register),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 28),
      ),
    );
  }
}

// ── Register Screen ──────────────────────────────────────────────────────────

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _repassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController _auth = Get.find();
  bool _obscure = true;
  bool _reObscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AuthHeader(
            title: 'Create Account',
            subtitle: 'Sign up to access your account.',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    CustomTextField(
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      controller: _nameCtrl,
                      prefixIcon: Icons.person_outline,
                      validator: (v) =>
                          v!.length > 2 ? null : 'Enter your full name',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Email',
                      hint: 'Enter your email',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (v) =>
                          v!.contains('@') ? null : 'Enter a valid email',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Phone',
                      hint: 'Enter your phone number',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                      validator: (v) =>
                          v!.length > 5 ? null : 'Enter a valid phone',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passCtrl,
                      obscureText: _obscure,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscure = !_obscure),
                        child: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textHint),
                      ),
                      validator: (v) =>
                          v!.length >= 6 ? null : 'Minimum 6 characters',
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Re-enter Password',
                      hint: '••••••••',
                      controller: _repassCtrl,
                      obscureText: _reObscure,
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _reObscure = !_reObscure),
                        child: Icon(
                            _reObscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textHint),
                      ),
                      validator: (v) =>
                          v == _passCtrl.text ? null : 'Passwords do not match',
                    ),
                    const SizedBox(height: 28),
                    Obx(() => PrimaryButton(
                          label: 'Sign Up',
                          isLoading: _auth.isLoading.value,
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              _auth.register(
                                fullName: _nameCtrl.text.trim(),
                                email: _emailCtrl.text.trim(),
                                phone: _phoneCtrl.text.trim(),
                                password: _passCtrl.text.trim(),
                              );
                            }
                          },
                        )),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? '),
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Forgot Password Screen ───────────────────────────────────────────────────

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthController _auth = Get.find();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      await _auth.forgotPassword(
        _emailCtrl.text.trim(),
        onSuccess: () => setState(() => _emailSent = true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              AuthHeader(
                title: _emailSent ? 'Check Your\nEmail' : 'Forget Password?',
                subtitle: _emailSent
                    ? 'Reset link sent to ${_emailCtrl.text.trim()}'
                    : 'Enter your email and we will send you reset instructions.',
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textWhite),
                  onPressed: () => Get.back(),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _emailSent ? _buildSuccessState() : _buildFormState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(32),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.mail_outline_rounded,
                    size: 60, color: AppColors.accent),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppColors.surface, shape: BoxShape.circle),
                    child: const Icon(Icons.lock_outline,
                        size: 18, color: AppColors.accent),
                  ),
                )
              ],
            ),
          ).animate().fadeIn().scale(),
          const SizedBox(height: 40),
          CustomTextField(
            label: 'Email',
            hint: 'Enter your email',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (v) => v!.contains('@') ? null : 'Enter a valid email',
          ),
          const SizedBox(height: 24),
          Obx(() => PrimaryButton(
                label: 'Send Reset Link',
                isLoading: _auth.isLoading.value,
                onTap: _submit,
              )),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Remembered your password? '),
              GestureDetector(
                onTap: () => Get.back(),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              size: 60, color: Colors.green),
        ).animate().fadeIn().scale(),
        const SizedBox(height: 32),
        Text(
          'We sent a password reset link to:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _emailCtrl.text.trim(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Click the link in the email to reset your password. Check your spam folder if you don\'t see it.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        PrimaryButton(
          label: 'Back to Login',
          onTap: () => Get.back(),
        ),
        const SizedBox(height: 16),
        Obx(() => TextButton(
              onPressed: _auth.isLoading.value ? null : _submit,
              child: _auth.isLoading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Resend Email',
                      style: TextStyle(color: AppColors.accent),
                    ),
            )),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}
