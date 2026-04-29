import 'package:flutter/material.dart';
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
        Obx(() => ActionCard(
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
            )).animate(delay: 200.ms).fadeIn().slideX(begin: -0.05, end: 0),
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
