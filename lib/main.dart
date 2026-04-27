// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/models/models.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/controllers/calibration_controller.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/auth/auth_screens.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/calibration/calibration_screens.dart';
import 'presentation/screens/extra_screens.dart';

// 01005083126@Aa
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp();

  // Supabase - file storage only
  await Supabase.initialize(
    url: 'https://brvdlavrbafptzcmdqfq.supabase.co',
    anonKey: 'sb_publishable_T82kFbE3qGgsZs7CAFyxQA_4M1kjyhG',
  );

  // Register GetX controllers
  Get.put(AuthController(), permanent: true);
  Get.put(CalibrationController(), permanent: true);

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
        GetPage(name: AppRoutes.home, page: () => const HomeScreen()),

        // Calibration flow
        GetPage(
            name: AppRoutes.calibrationPublicData,
            page: () => const PublicDataScreen()),
        GetPage(
            name: AppRoutes.calibrationQualitative,
            page: () => const QualitativeTestScreen()),

        // Heart Rate - uses generic table screen
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
              nextRoute: _getNextRouteAfterHR(ctrl),
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
              nextRoute: _getNextRouteAfterSPO2(ctrl),
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
              nextRoute: _getNextRouteAfterResp(ctrl),
              stepIndex: 5,
              isVisible: ctrl.session.value?.showRespirationTable ?? false,
            );
          },
        ),

        // Temperature - two sensors
        GetPage(
          name: AppRoutes.calibrationTemp,
          page: () => const TemperatureScreen(),
        ),

        GetPage(
            name: AppRoutes.calibrationSummary,
            page: () => const CalibrationSummaryScreen()),
        GetPage(
            name: AppRoutes.priceOffer, page: () => const PriceOfferScreen()),
        GetPage(name: AppRoutes.history, page: () => const HistoryScreen()),
        GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
      ],
    );
  }

  static String _getNextRouteAfterHR(CalibrationController ctrl) {
    final s = ctrl.session.value!;
    if (s.showSpo2Table) return AppRoutes.calibrationSPO2;
    if (s.showNibpTable) return AppRoutes.calibrationNIBP;
    if (s.showRespirationTable) return AppRoutes.calibrationRespiration;
    if (s.showTempTables) return AppRoutes.calibrationTemp;
    return AppRoutes.calibrationSummary;
  }

  static String _getNextRouteAfterSPO2(CalibrationController ctrl) {
    final s = ctrl.session.value!;
    if (s.showNibpTable) return AppRoutes.calibrationNIBP;
    if (s.showRespirationTable) return AppRoutes.calibrationRespiration;
    if (s.showTempTables) return AppRoutes.calibrationTemp;
    return AppRoutes.calibrationSummary;
  }

  static String _getNextRouteAfterResp(CalibrationController ctrl) {
    final s = ctrl.session.value!;
    if (s.showTempTables) return AppRoutes.calibrationTemp;
    return AppRoutes.calibrationSummary;
  }
}

// ── Temperature Screen (2 sensors) ───────────────────────────────────────────
class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({super.key});

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final CalibrationController _ctrl = Get.find();

  // Two sets of row controllers for 2 temp sensors
  late List<List<TextEditingController>> temp1Controllers;
  late List<List<TextEditingController>> temp2Controllers;
  late List<MeasurementRow> temp1Rows;
  late List<MeasurementRow> temp2Rows;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    temp1Rows = MonitorConstants.tempSettings
        .map((s) => MeasurementRow(settingValue: s))
        .toList();
    temp2Rows = MonitorConstants.tempSettings
        .map((s) => MeasurementRow(settingValue: s))
        .toList();
    temp1Controllers = List.generate(temp1Rows.length,
        (_) => List.generate(3, (_) => TextEditingController()));
    temp2Controllers = List.generate(temp2Rows.length,
        (_) => List.generate(3, (_) => TextEditingController()));
  }

  void _computeAndSave() {
    void compute(
        List<MeasurementRow> rows, List<List<TextEditingController>> ctrls) {
      for (int i = 0; i < rows.length; i++) {
        final reads = ctrls[i]
            .map((c) => double.tryParse(c.text.trim()))
            .whereType<double>()
            .toList();
        rows[i] =
            MeasurementRow(settingValue: rows[i].settingValue, reads: reads);
        if (reads.isNotEmpty) {
          final avg = reads.reduce((a, b) => a + b) / reads.length;
          rows[i].average = avg;
          final range =
              MonitorConstants.tempAcceptedRange(rows[i].settingValue);
          rows[i].status = avg >= range[0] && avg <= range[1];
        }
      }
    }

    compute(temp1Rows, temp1Controllers);
    compute(temp2Rows, temp2Controllers);
    _ctrl.updateTempRows(temp1Rows, temp2Rows);
    Get.toNamed(AppRoutes.calibrationSummary);
  }

  @override
  Widget build(BuildContext context) {
    if (!(_ctrl.session.value?.showTempTables ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ctrl.updateTempRows([], []);
        Get.toNamed(AppRoutes.calibrationSummary);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temperature Measurement'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'Sensor 1'), Tab(text: 'Sensor 2')],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _TempTable(
                    rows: temp1Rows,
                    controllers: temp1Controllers,
                    onChanged: () => setState(() {})),
                _TempTable(
                    rows: temp2Rows,
                    controllers: temp2Controllers,
                    onChanged: () => setState(() {})),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _computeAndSave,
                child: const Text('Complete Measurements'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TempTable extends StatelessWidget {
  final List<MeasurementRow> rows;
  final List<List<TextEditingController>> controllers;
  final VoidCallback onChanged;
  const _TempTable(
      {required this.rows, required this.controllers, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final i = e.key;
          final row = e.value;
          final range = MonitorConstants.tempAcceptedRange(row.settingValue);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Setting: ${row.settingValue.toStringAsFixed(0)}°C',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const Spacer(),
                    Text(
                        'Range: ${range[0].toStringAsFixed(3)}-${range[1].toStringAsFixed(3)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ...List.generate(
                        3,
                        (j) => Expanded(
                              child: Padding(
                                padding:
                                    EdgeInsets.only(right: j < 2 ? 8.0 : 0),
                                child: TextField(
                                  controller: controllers[i][j],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: 'Read ${j + 1}',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 10),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  onChanged: (_) => onChanged(),
                                ),
                              ),
                            )),
                    const SizedBox(width: 8),
                    if (row.status != null)
                      Icon(
                        row.status! ? Icons.check_circle : Icons.cancel,
                        color:
                            row.status! ? AppColors.success : AppColors.error,
                      )
                    else
                      const Icon(Icons.circle_outlined,
                          color: AppColors.textHint),
                  ],
                ),
                if (row.average != null) ...[
                  const SizedBox(height: 6),
                  Text('Average: ${row.average!.toStringAsFixed(3)}°C',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
