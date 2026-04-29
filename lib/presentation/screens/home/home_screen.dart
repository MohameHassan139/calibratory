import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/calibration_controller.dart';
import '../../widgets/home/stat_card.dart';
import '../../widgets/home/action_card.dart';
import '../../widgets/home/recent_session_card.dart';
import '../history/history_screen.dart';
import '../price/price_offer_screen.dart';
import '../profile/profile_screen.dart';
import '../devices/devices_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  final List<Widget> _pages = const [
    _DashboardPage(),
    HistoryScreen(),
    PriceOfferScreen(),
    ProfileScreen(),
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
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history_rounded),
              label: 'HISTORY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.request_quote_outlined),
              activeIcon: Icon(Icons.request_quote_rounded),
              label: 'PRICE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard Page ────────────────────────────────────────────────────────────

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final calibCtrl = Get.find<CalibrationController>();

    return CustomScrollView(
      slivers: [
        _DashboardAppBar(auth: auth),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _WelcomeSection(auth: auth),
              const SizedBox(height: 24),
              _StatsRow(calibCtrl: calibCtrl),
              const SizedBox(height: 28),
              const _SectionTitle('Quick Actions'),
              const SizedBox(height: 16),
              _QuickActions(calibCtrl: calibCtrl),
              const SizedBox(height: 28),
              const _SectionTitle('Recent Sessions'),
              const SizedBox(height: 12),
              _RecentSessions(calibCtrl: calibCtrl),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Dashboard sub-widgets ─────────────────────────────────────────────────────

class _DashboardAppBar extends StatelessWidget {
  final AuthController auth;
  const _DashboardAppBar({required this.auth});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
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
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  final AuthController auth;
  const _WelcomeSection({required this.auth});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
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
        ));
  }
}

class _StatsRow extends StatelessWidget {
  final CalibrationController calibCtrl;
  const _StatsRow({required this.calibCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          children: [
            StatCard(
              label: 'Total',
              value: calibCtrl.history.length.toString(),
              icon: Icons.science_outlined,
              color: AppColors.accent,
            ),
            const SizedBox(width: 12),
            StatCard(
              label: 'Passed',
              value: calibCtrl.history
                  .where((h) => h.overallResult == 'PASS')
                  .length
                  .toString(),
              icon: Icons.check_circle_outline,
              color: AppColors.success,
            ),
            const SizedBox(width: 12),
            StatCard(
              label: 'Failed',
              value: calibCtrl.history
                  .where((h) => h.overallResult == 'FAIL')
                  .length
                  .toString(),
              icon: Icons.cancel_outlined,
              color: AppColors.error,
            ),
          ],
        ));
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Syne',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final CalibrationController calibCtrl;
  const _QuickActions({required this.calibCtrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActionCard(
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
        _PriceAdjustmentsCard()
            .animate(delay: 200.ms)
            .fadeIn()
            .slideX(begin: -0.05, end: 0),
        const SizedBox(height: 12),
        ActionCard(
          icon: Icons.history_edu_outlined,
          title: 'Calibration History',
          subtitle: 'View all past calibration sessions and certificates.',
          onTap: () {},
        ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.05, end: 0),
      ],
    );
  }
}

// ── Price Adjustments Card ────────────────────────────────────────────────────

class _PriceAdjustmentsCard extends StatelessWidget {
  const _PriceAdjustmentsCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('devices').snapshots(),
      builder: (context, snapshot) {
        final total = snapshot.data?.docs.length ?? 0;
        // progress = devices with both prices set / total (or just a fixed demo)
        final filled = snapshot.data?.docs.where((d) {
              final data = d.data();
              return (data['function_price'] ?? 0) > 0 &&
                  (data['safety_price'] ?? 0) > 0;
            }).length ??
            0;
        final progress = total == 0 ? 0.0 : filled / total;

        return GestureDetector(
          onTap: () => Get.to(() => const DevicesManagementScreen()),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.local_offer_rounded,
                      color: Color(0xFF7C3AED), size: 26),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Price Adjustments',
                              style: TextStyle(
                                fontFamily: 'Syne',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textHint, size: 22),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Update global pricing for spare\nparts and technician hours.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF7C3AED)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            total == 0
                                ? 'NO DEVICES YET'
                                : '$filled / $total DEVICES PRICED',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textHint,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            total == 0
                                ? '0%'
                                : '${(progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecentSessions extends StatelessWidget {
  final CalibrationController calibCtrl;
  const _RecentSessions({required this.calibCtrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
                  child: RecentSessionCard(session: s),
                ))
            .toList(),
      );
    });
  }
}
