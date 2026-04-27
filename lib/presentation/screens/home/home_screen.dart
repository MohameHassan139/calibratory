// lib/presentation/screens/home/home_screen.dart
import 'package:caliborty/presentation/screens/extra_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/calibration_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final AuthController _auth = Get.find();
  final CalibrationController _calibCtrl = Get.find();

  final List<Widget> _pages = [
    const _DashboardPage(),
    const HistoryScreen(),
    const PriceOfferScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_tab],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _tab,
          onTap: (i) => setState(() => _tab = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textHint,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 11,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'HOME'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history_rounded),
                label: 'HISTORY'),
            BottomNavigationBarItem(
                icon: Icon(Icons.request_quote_outlined),
                activeIcon: Icon(Icons.request_quote_rounded),
                label: 'PRICE'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'PROFILE'),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard Page ───────────────────────────────────────────────────────────

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final calibCtrl = Get.find<CalibrationController>();

    return CustomScrollView(
      slivers: [
        // App bar
        SliverAppBar(
          floating: true,
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.biotech_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Caliborty',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Engineering Portal',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Obx(() => CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: auth.appUser.value?.photoUrl != null
                      ? NetworkImage(auth.appUser.value!.photoUrl!)
                      : null,
                  child: auth.appUser.value?.photoUrl == null
                      ? Text(
                          auth.appUser.value?.fullName
                                  .substring(0, 1)
                                  .toUpperCase() ??
                              'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        )
                      : null,
                )),
            const SizedBox(width: 16),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Welcome
              Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          fontFamily: 'Syne',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Welcome back, ${auth.appUser.value?.fullName.split(' ').first ?? 'Engineer'}',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )),

              const SizedBox(height: 24),

              // Stats row
              Obx(() => Row(
                    children: [
                      _StatCard(
                        label: 'Total',
                        value: calibCtrl.history.length.toString(),
                        icon: Icons.science_outlined,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Passed',
                        value: calibCtrl.history
                            .where((h) => h.overallResult == true)
                            .length
                            .toString(),
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Failed',
                        value: calibCtrl.history
                            .where((h) => h.overallResult == false)
                            .length
                            .toString(),
                        icon: Icons.cancel_outlined,
                        color: AppColors.error,
                      ),
                    ],
                  )),

              const SizedBox(height: 28),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // New Calibration Card
              _ActionCard(
                icon: Icons.build_circle_outlined,
                title: 'New Calibration',
                subtitle:
                    'Register medical device calibration data and safety tests.',
                tags: const ['PRIORITY 1', 'ISO 13485'],
                onTap: () {
                  calibCtrl.startNewSession();
                  Get.toNamed(AppRoutes.calibrationPublicData);
                },
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideX(begin: -0.05, end: 0),

              const SizedBox(height: 12),

              // Price Offer Card
              Obx(() => _ActionCard(
                        icon: Icons.description_outlined,
                        title: 'Create Price Offer',
                        subtitle:
                            'Generate maintenance quotes and service level agreements.',
                        badge: calibCtrl.history
                                .where((h) => h.status == 'draft')
                                .isNotEmpty
                            ? '${calibCtrl.history.where((h) => h.status == 'draft').length} Drafts pending'
                            : null,
                        onTap: () => Get.toNamed(AppRoutes.priceOffer),
                      ))
                  .animate(delay: 200.ms)
                  .fadeIn()
                  .slideX(begin: -0.05, end: 0),

              const SizedBox(height: 12),

              // Recent History
              _ActionCard(
                icon: Icons.history_edu_outlined,
                title: 'Calibration History',
                subtitle:
                    'View all past calibration sessions and certificates.',
                onTap: () {},
              ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.05, end: 0),

              const SizedBox(height: 28),

              // Recent sessions
              const Text(
                'Recent Sessions',
                style: TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              Obx(() {
                final recent = calibCtrl.history.take(3).toList();
                if (recent.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.science_outlined,
                              size: 40, color: AppColors.textHint),
                          SizedBox(height: 12),
                          Text(
                            'No calibrations yet',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: recent
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _RecentSessionCard(session: s),
                          ))
                      .toList(),
                );
              }),

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Syne',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> tags;
  final String? badge;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tags = const [],
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.accent, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: tags
                          .map((t) => Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppColors.accent.withOpacity(0.2)),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                  if (badge != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded,
                            size: 12, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 22),
          ],
        ),
      ),
    );
  }
}

class _RecentSessionCard extends StatelessWidget {
  final dynamic session;
  const _RecentSessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (session.overallResult == true
                      ? AppColors.success
                      : session.overallResult == false
                          ? AppColors.error
                          : AppColors.warning)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              session.overallResult == true
                  ? Icons.check_circle_outline
                  : session.overallResult == false
                      ? Icons.cancel_outlined
                      : Icons.pending_outlined,
              color: session.overallResult == true
                  ? AppColors.success
                  : session.overallResult == false
                      ? AppColors.error
                      : AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.customerName.isEmpty
                      ? 'Unnamed Patient'
                      : session.customerName,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${session.manufacturer} · ${session.model}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${session.createdAt.day}/${session.createdAt.month}',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
