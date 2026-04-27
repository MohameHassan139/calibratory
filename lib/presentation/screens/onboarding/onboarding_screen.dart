// lib/presentation/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _current = 0;

  final List<_OnboardingItem> pages = [
    _OnboardingItem(
      icon: Icons.handshake_rounded,
      title: 'Empowering Your Journey',
      subtitle: 'Teamwork and leadership in medical equipment calibration.',
      color: const Color(0xFF1565C0),
    ),
    _OnboardingItem(
      icon: Icons.trending_up_rounded,
      title: 'Together, We Rise',
      subtitle: 'Support and mentorship are just a step away.',
      color: const Color(0xFF0288D1),
    ),
    _OnboardingItem(
      icon: Icons.verified_rounded,
      title: 'Precision Calibration',
      subtitle: 'Generate certified calibration reports with a single workflow.',
      color: const Color(0xFF00897B),
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _buildPage(pages[i]),
          ),

          // Top skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 24,
            child: TextButton(
              onPressed: _finish,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Bottom area
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _controller,
                  count: pages.length,
                  effect: const ExpandingDotsEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    activeDotColor: AppColors.accent,
                    dotColor: AppColors.border,
                  ),
                ),
                const SizedBox(height: 32),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _current == pages.length - 1
                      ? SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _finish,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: const Text('Get Started'),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _finish,
                              child: const Text(
                                'Skip',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _controller.nextPage(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              ),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    )
                                  ],
                                ),
                                child: const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(48),
              border: Border.all(color: item.color.withOpacity(0.15), width: 1.5),
            ),
            child: Icon(item.icon, size: 90, color: item.color),
          ).animate().fadeIn(duration: 500.ms).scale(
              begin: const Offset(0.85, 0.85),
              duration: 600.ms,
              curve: Curves.easeOut),

          const SizedBox(height: 48),

          Text(
            item.title,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          Text(
            item.subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),

          const SizedBox(height: 140),
        ],
      ),
    );
  }
}

class _OnboardingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  _OnboardingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
