
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/models/models.dart';
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
import 'presentation/screens/calibration/syringe_screens.dart';
import 'presentation/screens/calibration/sphygmomanometer_screens.dart';
import 'presentation/screens/calibration/ecg_machine_screens.dart';
import 'presentation/screens/calibration/infusion_screens.dart';

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

        // ── Syringe Pump calibration flow ────────────────────────────────
        // Flow Rate — reuses the same MeasurementTableScreen as HR/SPO2/Resp
        GetPage(
          name: AppRoutes.syringeFlowRate,
          page: () {
            final ctrl = Get.find<CalibrationController>();
            return MeasurementTableScreen(
              title: 'Flow Rate Measurement',
              unit: 'mL/hr',
              settings: List<double>.from(SyringeConstants.flowSettings),
              acceptedRangeFunc: SyringeConstants.flowAcceptedRange,
              initialRows: ctrl.session.value?.syringeFlowRows ?? [],
              onSave: ctrl.updateSyringeFlowRows,
              nextRoute: AppRoutes.syringeOcclusion,
              stepIndex: 1,
              totalSteps: 3,
              stepLabels: const ['Qualitative', 'Flow Rate', 'Occlusion'],
              nextButtonLabel: 'Next: Occlusion Pressure',
            );
          },
        ),

        // Occlusion — two rows (Peak mmHg, Time-to-alarm sec) via MeasurementTableScreen.
        // Setting values encode row identity (0 = peak, 1 = time).
        // acceptedRangeFunc returns [0, limit] so avg <= limit means PASS.
        GetPage(
          name: AppRoutes.syringeOcclusion,
          page: () {
            final ctrl = Get.find<CalibrationController>();
            // Convert OcclusionRow list → MeasurementRow list (settingValue used as row id)
            final existingOcc = ctrl.session.value?.syringeOcclusionRows ?? [];
            final initRows = existingOcc.isNotEmpty
                ? existingOcc
                    .asMap()
                    .entries
                    .map((e) => MeasurementRow(
                          settingValue: e.key.toDouble(),
                          reads: List<double>.from(e.value.reads),
                          average: e.value.average,
                          status: e.value.status,
                        ))
                    .toList()
                : [
                    MeasurementRow(settingValue: 0), // Peak pressure
                    MeasurementRow(settingValue: 1), // Time to alarm
                  ];
            return MeasurementTableScreen(
              title: 'Occlusion Pressure',
              unit: 'mmHg / sec',
              settings: const [0, 1],
              acceptedRangeFunc: _occlusionRange,
              initialRows: initRows,
              onSave: (rows) => ctrl.updateSyringeOcclusionRows(
                rows
                    .asMap()
                    .entries
                    .map((e) => OcclusionRow(
                          label: e.key == 0
                              ? 'Peak value (mmHg)'
                              : 'Time to Alarm (sec)',
                          reads: e.value.reads,
                          average: e.value.average,
                          status: e.value.status,
                        ))
                    .toList(),
              ),
              nextRoute: AppRoutes.syringeSummary,
              stepIndex: 2,
              totalSteps: 3,
              stepLabels: const ['Qualitative', 'Flow Rate', 'Occlusion'],
              settingLabels: const [
                'Peak value\n(mmHg)',
                'Time to Alarm\n(sec)'
              ],
              nextButtonLabel: 'Complete & Review',
            );
          },
        ),

        GetPage(
          name: AppRoutes.syringeSummary,
          page: () => const SyringeSummaryScreen(),
        ),

        // ── Sphygmomanometer calibration flow ────────────────────────────
        // Static pressure — reuses MeasurementTableScreen (same as HR/SPO2/Resp)
        GetPage(
          name: AppRoutes.sphygmoStatic,
          page: () {
            final ctrl = Get.find<CalibrationController>();
            return MeasurementTableScreen(
              title: 'Static Pressure Measurement',
              unit: 'mmHg',
              settings: List<double>.from(SphygmoConstants.staticSettings),
              acceptedRangeFunc: SphygmoConstants.staticAcceptedRange,
              initialRows: ctrl.session.value?.sphygmoStaticRows ?? [],
              onSave: ctrl.updateSphygmoStaticRows,
              nextRoute: AppRoutes.sphygmoSummary,
              stepIndex: 1,
              totalSteps: 2,
              stepLabels: const ['Qualitative', 'Static Pressure'],
              nextButtonLabel: 'Complete & Review',
            );
          },
        ),

        GetPage(
          name: AppRoutes.sphygmoSummary,
          page: () => const SphygmoSummaryScreen(),
        ),

        // ── ECG Machine calibration flow ──────────────────────────────────
        // Heart Rate — reuses MeasurementTableScreen with ECG-specific settings
        GetPage(
          name: AppRoutes.ecgMachineHR,
          page: () {
            final ctrl = Get.find<CalibrationController>();
            return MeasurementTableScreen(
              title: 'Heart Rate Measurement',
              unit: 'BPM',
              settings: List<double>.from(EcgMachineConstants.hrSettings),
              acceptedRangeFunc: EcgMachineConstants.hrAcceptedRange,
              initialRows: ctrl.session.value?.ecgMachineHrRows ?? [],
              onSave: ctrl.updateEcgMachineHrRows,
              nextRoute: AppRoutes.ecgMachineSummary,
              stepIndex: 1,
              totalSteps: 2,
              stepLabels: const ['Qualitative', 'Heart Rate'],
              nextButtonLabel: 'Complete & Review',
            );
          },
        ),

        GetPage(
          name: AppRoutes.ecgMachineSummary,
          page: () => const EcgMachineSummaryScreen(),
        ),

        // ── Infusion Pump calibration flow ────────────────────────────────
        GetPage(
          name: AppRoutes.infusionFlowRate,
          page: () {
            final ctrl = Get.find<CalibrationController>();
            return MeasurementTableScreen(
              title: 'Flow Rate Measurement',
              unit: 'mL/hr',
              settings: List<double>.from(InfusionConstants.flowSettings),
              acceptedRangeFunc: InfusionConstants.flowAcceptedRange,
              initialRows: ctrl.session.value?.infusionFlowRows ?? [],
              onSave: ctrl.updateInfusionFlowRows,
              nextRoute: AppRoutes.infusionOcclusion,
              stepIndex: 1,
              totalSteps: 3,
              stepLabels: const ['Qualitative', 'Flow Rate', 'Occlusion'],
              nextButtonLabel: 'Next: Occlusion Pressure',
            );
          },
        ),

        GetPage(
          name: AppRoutes.infusionOcclusion,
          page: () {
            final ctrl = Get.find<CalibrationController>();
            final existingOcc = ctrl.session.value?.infusionOcclusionRows ?? [];
            final initRows = existingOcc.isNotEmpty
                ? existingOcc
                    .asMap()
                    .entries
                    .map((e) => MeasurementRow(
                          settingValue: e.key.toDouble(),
                          reads: List<double>.from(e.value.reads),
                          average: e.value.average,
                          status: e.value.status,
                        ))
                    .toList()
                : [
                    MeasurementRow(settingValue: 0), // Peak pressure
                    MeasurementRow(settingValue: 1), // Time to alarm
                  ];
            return MeasurementTableScreen(
              title: 'Occlusion Pressure',
              unit: 'mmHg / sec',
              settings: const [0, 1],
              acceptedRangeFunc: _infusionOcclusionRange,
              initialRows: initRows,
              onSave: (rows) => ctrl.updateInfusionOcclusionRows(
                rows
                    .asMap()
                    .entries
                    .map((e) => OcclusionRow(
                          label: e.key == 0
                              ? 'Peak value (mmHg)'
                              : 'Time to Alarm (sec)',
                          reads: e.value.reads,
                          average: e.value.average,
                          status: e.value.status,
                        ))
                    .toList(),
              ),
              nextRoute: AppRoutes.infusionSummary,
              stepIndex: 2,
              totalSteps: 3,
              stepLabels: const ['Qualitative', 'Flow Rate', 'Occlusion'],
              settingLabels: const [
                'Peak value\n(mmHg)',
                'Time to Alarm\n(sec)',
              ],
              nextButtonLabel: 'Complete & Review',
            );
          },
        ),

        GetPage(
          name: AppRoutes.infusionSummary,
          page: () => const InfusionSummaryScreen(),
        ),
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

  /// Occlusion accepted range:
  /// Row 0 (peak, mmHg) → [0, 723.8]   (pass when avg < 723.8)
  /// Row 1 (time, sec)  → [0, 12.0]    (pass when avg <= 12)
  static List<double> _occlusionRange(double settingValue) {
    if (settingValue == 0) return [0, SyringeConstants.occPeakAcceptedMax];
    return [0, SyringeConstants.occTimeAcceptedMax];
  }

  static List<double> _infusionOcclusionRange(double settingValue) {
    if (settingValue == 0) return [0, InfusionConstants.occPeakAcceptedMax];
    return [0, InfusionConstants.occTimeAcceptedMax];
  }
}


// (27.3 -32.7)
// (54.6 -65.4)
// (91 -109)
// (218.4  - 261.6)
// (273  -  327)
// (546  - 654)