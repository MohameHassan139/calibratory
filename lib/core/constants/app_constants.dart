// lib/core/constants/app_routes.dart
class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String home = '/home';
  static const String newCalibration = '/new-calibration';
  static const String calibrationPublicData = '/calibration/public-data';
  static const String calibrationQualitative = '/calibration/qualitative';
  static const String calibrationHR = '/calibration/heart-rate';
  static const String calibrationSPO2 = '/calibration/spo2';
  static const String calibrationNIBP = '/calibration/nibp';
  static const String calibrationRespiration = '/calibration/respiration';
  static const String calibrationTemp = '/calibration/temperature';
  static const String calibrationSummary = '/calibration/summary';
  static const String priceOffer = '/price-offer';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String calibrationStats = '/calibration-stats';

  // ── Syringe Pump calibration steps ──────────────────────────────────────
  static const String syringeQualitative = '/calibration/syringe/qualitative';
  static const String syringeFlowRate = '/calibration/syringe/flow-rate';
  static const String syringeOcclusion = '/calibration/syringe/occlusion';
  static const String syringeSummary = '/calibration/syringe/summary';

  // ── Sphygmomanometer calibration steps ─────────────────────────────────
  static const String sphygmoStatic = '/calibration/sphygmomanometer/static';
  static const String sphygmoSummary = '/calibration/sphygmomanometer/summary';
}

// lib/core/constants/app_strings.dart
class AppStrings {
  static const String appName = 'Caliborty';
  static const String appTagline = 'UMECC · مستشارات الأجهزة الطبية';

  // Onboarding
  static const List<Map<String, String>> onboardingData = [
    {
      'title': 'Empowering Your Journey',
      'subtitle': 'Teamwork and leadership in medical equipment calibration.',
    },
    {
      'title': 'Together, We Rise',
      'subtitle': 'Support and mentorship are just a step away.',
    },
    {
      'title': 'Precision Calibration',
      'subtitle': 'Generate certified calibration reports with one tap.',
    },
  ];

  // Monitor cables
  static const String ecgCable = 'ECG CABLE';
  static const String spo2Cable = 'SPO2 cable';
  static const String nibpCuff = 'NIBP Cuff';
  static const String tempCable = 'TEMP CABLE/S';

  // Accepted ranges formulas
  // HR: x + x(±5)/100 ∓ 1
  // SPO2: x + x(±2)/100 ∓ 0
  // NIBP: Hardcoded values (no equation)
  // Respiration: x + x(±1)/100 ∓ 0
  // Temperature: x + x(±0.2)/100 ∓ 0
}

// lib/core/constants/monitor_data.dart
class MonitorConstants {
  // HR setting values (BPM)
  static const List<double> hrSettings = [40, 60, 80, 100, 150, 200];

  // SPO2 setting values (%)
  static const List<double> spo2Settings = [75, 85, 90, 94, 96, 98];

  // NIBP setting values - pairs [systolic, diastolic]
  static const List<List<double>> nibpSettings = [
    [60, 30],
    [80, 40],
    [100, 60],
    [120, 80],
    [180, 140],
  ];

  // Respiration setting values (BPM)
  static const List<double> respirationSettings = [5, 10, 15, 30];

  // Temperature setting values (°C)
  static const List<double> tempSettings = [25, 33, 37, 41];

  // Compute accepted range for HR: x + x(±5)/100 ∓ 1
  static List<double> hrAcceptedRange(double x) {
    double tol = (x * 5 / 100) - 1;
    return [x - tol, x + tol];
  }

  // SPO2: x + x(±2)/100 ∓ 0
  static List<double> spo2AcceptedRange(double x) {
    double tol = x * 2 / 100;
    return [x - tol, x + tol];
  }

  // NIBP: Hardcoded values (no equation)
  static List<double> nibpAcceptedRange(double x) {
    final int val = x.round();
    switch (val) {
      case 30:
        return [20.15, 39.85];
      case 40:
        return [29.8, 49.6];
      case 60:
        return [50.3, 69.7];
      case 80:
        return [69.6, 89.9];
      case 100:
        return [90.5, 109.5];
      case 120:
        return [110.6, 129.4];
      case 140:
        return [130.7, 149.3];
      case 180:
        return [170.9, 189.1];
      default:
        final tol = x * 2 / 100;
        return [x - tol, x + tol];
    }
  }

  // Respiration: x + x(±1)/100 ∓ 0
  static List<double> respirationAcceptedRange(double x) {
    double tol = x * 1 / 100;
    return [x - tol, x + tol];
  }

  // Temperature: x + x(±0.2)/100 ∓ 0
  static List<double> tempAcceptedRange(double x) {
    double tol = x * 0.2 / 100;
    return [x - tol, x + tol];
  }

  // Qualitative test items
  static const List<String> qualitativeItems = [
    'Chassis/Housing',
    'Controls/Switches',
    'Casters/Brakes',
    'Battery/charger',
    'AC plug',
    'Indicator/Displays',
    'Line Cord',
    'Labeling',
    'Screen',
    'Alarms',
    'SPO2 cable',
    'Module Housing',
    'NIBP Cuff',
    'Mounting/Trolley',
    'TEMP CABLE/S',
    'ECG CABLE',
    'NIBP cable', // Added per user requirement
  ];

  static const List<String> ecgRepresentationItems = [
    'Atrial Fibrillation',
    'Premature ventricle contraction',
    'Ventricle Fibrillation',
    'Paroxysmal Atrial Tachycardia (PAT)',
    'Atrial Flutter',
    'Polymorphic Ventricular Tachycardia (PVT)',
    'Representation of Standard signals (Triangle, Square, Sinusoid)',
    'Represent ECG waveforms with different Amplitudes (0.5,1,1.5,2,2.5,3,3.5)',
  ];

  // Device types for price offers
  static const List<String> deviceTypes = [
    'Patient Monitors',
    'ECG Machines',
    'NIBP Monitors',
    'Pulse Oximeters',
    'Fetal Monitors',
    'Infusion Pumps',
    'Syringe Pumps',
    'Manual Defibrillators',
    'Sphygmomanometers',
    'Ventilators',
    'CPAP / BiPAP',
    'Suction Machines',
    'Electrosurgical Units (ESU)',
    'Oxygen Cylinder',
    'Electrical Safety',
  ];
}

/// Constants specific to Syringe Pump calibration.
class SyringeConstants {
  // ── Qualitative test items (Visual Inspection) ───────────────────────────
  static const List<String> qualitativeItems = [
    'Chassis/Housing',
    'Controls /Switches',
    'Mount',
    'Door/Misloaded Infusion Set',
    'Casters/Brakes',
    'Battery/charger',
    'AC plug',
    'Indicator/Displays',
    'Line Cord',
    'Labeling',
    'Cables',
    'Air-in-Line',
    'Screen',
    'Empty Container',
    'Flow-Stop Mechanism(s)',
    'Infusion Complete',
  ];

  // ── Flow-rate setting values (mL/hr) ─────────────────────────────────────
  static const List<double> flowSettings = [10.0, 15.0, 20.0];

  // ── Flow-rate accepted ranges ±9% ────────────────────────────────────────
  // Const values: (9.1 – 10.9), (13.65 – 16.35), (18.2 – 21.8)
  static const List<List<double>> flowAcceptedRanges = [
    [9.1, 10.9], // 10 mL/hr ± 9%
    [13.65, 16.35], // 15 mL/hr ± 9%
    [18.2, 21.8], // 20 mL/hr ± 9%
  ];

  /// Returns the accepted range for a given flow setting value.
  static List<double> flowAcceptedRange(double setting) {
    for (int i = 0; i < flowSettings.length; i++) {
      if ((flowSettings[i] - setting).abs() < 0.01) {
        return flowAcceptedRanges[i];
      }
    }
    // Fallback: ±9%
    final tol = setting * 9 / 100;
    return [setting - tol, setting + tol];
  }

  // ── Occlusion accepted limits ─────────────────────────────────────────────
  static const double occPeakAcceptedMax = 723.8; // < 723.8 mmHg
  static const double occTimeAcceptedMax = 12.0; // <= 12 sec
}

/// Constants specific to Sphygmomanometer calibration.
class SphygmoConstants {
  // ── Qualitative test items (Visual Inspection) ───────────────────────────
  static const List<String> qualitativeItems = [
    'Chassis/Housing',
    'Hand pump (bulb)',
    'NIBP Cuff',
    'Pressure ruler glass',
    'Mercury Container',
    'Pressure Cables',
  ];

  // ── Static pressure setting values (mmHg) ───────────────────────────────
  static const List<double> staticSettings = [0, 50, 100, 150, 200, 250];

  // ── Static pressure accepted ranges (const ±2.5%) ────────────────────────
  // 0 → [0, 0], 50 → [48.75, 51.25], 100 → [97.5, 102.5],
  // 150 → [146.25, 153.75], 200 → [195, 205], 250 → [243.75, 256.25]
  static const List<List<double>> staticAcceptedRanges = [
    [0.0, 0.0],
    [48.75, 51.25],
    [97.5, 102.5],
    [146.25, 153.75],
    [195.0, 205.0],
    [243.75, 256.25],
  ];

  /// Returns the accepted range for a given static pressure setting.
  static List<double> staticAcceptedRange(double setting) {
    for (int i = 0; i < staticSettings.length; i++) {
      if ((staticSettings[i] - setting).abs() < 0.01) {
        return staticAcceptedRanges[i];
      }
    }
    // Fallback: ±2.5%
    final tol = setting * 2.5 / 100;
    return [setting - tol, setting + tol];
  }
}
