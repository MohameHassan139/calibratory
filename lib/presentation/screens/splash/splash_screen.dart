// lib/presentation/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final authCtrl = Get.find<AuthController>();

    if (!onboardingDone) {
      Get.offAllNamed(AppRoutes.onboarding);
    } else if (authCtrl.firebaseUser.value == null) {
      Get.offAllNamed(AppRoutes.login);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // UMECC Logo animated
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.accentBright.withOpacity(0.3), width: 1.5),
              ),
              child: const Icon(
                Icons.biotech_rounded,
                color: AppColors.accentBright,
                size: 60,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8), duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: 32),

            Text(
              'Caliborty',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.textWhite,
                    letterSpacing: 2,
                  ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0),

            const SizedBox(height: 8),

            Text(
              'وحدة معايرة واستشارات الأجهزة الطبية',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.accentBright.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
              textDirection: TextDirection.rtl,
            )
                .animate(delay: 500.ms)
                .fadeIn(duration: 500.ms),

            const SizedBox(height: 64),

            // Loading indicator
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.primaryLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBright),
                borderRadius: BorderRadius.circular(10),
              ),
            ).animate(delay: 700.ms).fadeIn(duration: 400.ms),

            const SizedBox(height: 16),

            Text(
              'UMECC · Faculty of Engineering · Minia University',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textWhite.withOpacity(0.4),
                    fontSize: 10,
                  ),
              textAlign: TextAlign.center,
            ).animate(delay: 800.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}
