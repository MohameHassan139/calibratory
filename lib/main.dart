
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/calibration_controller.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/auth_screens.dart';
import 'presentation/screens/auth/verify_email_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/calibration/calibration_screens.dart';
import 'presentation/screens/calibration/nibp_screen.dart';
import 'presentation/screens/calibration/summary_screen.dart';
import 'presentation/screens/calibration/temperature_screen.dart';
import 'presentation/screens/price/price_offer_screen.dart';
import 'presentation/screens/history/history_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/stats/calibration_stats_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Supabase.initialize(
    url: 'https://asqurcktgqwatfviwjuy.supabase.co',
    anonKey: 'sb_publishable_hu9LmF5-RVYXwY9vuu9mRA_vuninfgG',
  );

  runApp(const CalibOrtyApp());
}

class CalibOrtyApp extends StatelessWidget {
  const CalibOrtyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Caliborty',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialBinding: BindingsBuilder(() {
        Get.put(AuthController(), permanent: true);
        Get.put(CalibrationController(), permanent: true);
      }),
      initialRoute: AppRoutes.splash,
      getPages: [
        GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
        GetPage(
            name: AppRoutes.onboarding, page: () => const OnboardingScreen()),
        GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
        GetPage(name: AppRoutes.register, page: () => const RegisterScreen()),
        GetPage(
            name: AppRoutes.forgotPassword,
            page: () => const ForgotPasswordScreen()),
        GetPage(
            name: AppRoutes.verifyEmail, page: () => const VerifyEmailScreen()),
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),

        // Calibration flow
        GetPage(
            name: AppRoutes.calibrationPublicData,
            page: () => const PublicDataScreen()),
        GetPage(
            name: AppRoutes.calibrationQualitative,
            page: () => const QualitativeTestScreen()),

        // Heart Rate
        GetPage(
          name: AppRoutes.calibrationHR,
          page: () {
            final ctrl = Get.find<CalibrationController>();
            return MeasurementTableScreen(
              title: 'Heart Rate Measurement',
              unit: 'BPM',
              settings: MonitorConstants.hrSettings,
              acceptedRangeFunc: MonitorConstants.hrAcceptedRange,
              initialRows: ctrl.session.value?.hrRows ?? [],
              onSave: ctrl.updateHrRows,
              nextRoute: _nextAfterHR(ctrl),
              stepIndex: 2,
              isVisible: ctrl.session.value?.showHrTable ?? false,
            );
          },
        ),

        // SPO2
        GetPage(
          name: AppRoutes.calibrationSPO2,
          page: () {
            final ctrl = Get.find<CalibrationController>();
            return MeasurementTableScreen(
              title: 'SPO2 Measurement',
              unit: '%',
              settings: MonitorConstants.spo2Settings,
              acceptedRangeFunc: MonitorConstants.spo2AcceptedRange,
              initialRows: ctrl.session.value?.spo2Rows ?? [],
              onSave: ctrl.updateSpo2Rows,
              nextRoute: _nextAfterSPO2(ctrl),
              stepIndex: 3,
              isVisible: ctrl.session.value?.showSpo2Table ?? false,
            );
          },
        ),

        GetPage(
            name: AppRoutes.calibrationNIBP, page: () => const NIBPScreen()),

        // Respiration
        GetPage(
          name: AppRoutes.calibrationRespiration,
          page: () {
            final ctrl = Get.find<CalibrationController>();
            return MeasurementTableScreen(
              title: 'Respiration Measurement',
              unit: 'BPM',
              settings: MonitorConstants.respirationSettings,
              acceptedRangeFunc: MonitorConstants.respirationAcceptedRange,
              initialRows: ctrl.session.value?.respirationRows ?? [],
              onSave: ctrl.updateRespirationRows,
              nextRoute: _nextAfterResp(ctrl),
              stepIndex: 5,
              isVisible: ctrl.session.value?.showRespirationTable ?? false,
            );
          },
        ),

        // Temperature
        GetPage(
            name: AppRoutes.calibrationTemp,
            page: () => const TemperatureScreen()),

        GetPage(
            name: AppRoutes.calibrationSummary,
            page: () => const CalibrationSummaryScreen()),
        GetPage(
            name: AppRoutes.priceOffer, page: () => const PriceOfferScreen()),
        GetPage(name: AppRoutes.history, page: () => const HistoryScreen()),
        GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
        GetPage(
            name: AppRoutes.calibrationStats,
            page: () => const CalibrationStatsScreen()),
      ],
    );
  }

  static String _nextAfterHR(CalibrationController ctrl) {
    final s = ctrl.session.value!;
    if (s.showSpo2Table) return AppRoutes.calibrationSPO2;
    if (s.showNibpTable) return AppRoutes.calibrationNIBP;
    if (s.showRespirationTable) return AppRoutes.calibrationRespiration;
    if (s.showTempTables) return AppRoutes.calibrationTemp;
    return AppRoutes.calibrationSummary;
  }

  static String _nextAfterSPO2(CalibrationController ctrl) {
    final s = ctrl.session.value!;
    if (s.showNibpTable) return AppRoutes.calibrationNIBP;
    if (s.showRespirationTable) return AppRoutes.calibrationRespiration;
    if (s.showTempTables) return AppRoutes.calibrationTemp;
    return AppRoutes.calibrationSummary;
  }

  static String _nextAfterResp(CalibrationController ctrl) {
    final s = ctrl.session.value!;
    if (s.showTempTables) return AppRoutes.calibrationTemp;
    return AppRoutes.calibrationSummary;
  }
}
