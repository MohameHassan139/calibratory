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
  // HR: x ± (x*5/100) ± 1
  // SPO2: x ± (x*2/100) ± 0
  // NIBP: x ± (x*2/100) ± 0
  // Respiration: x ± (x*2/100) ± 0
  // Temperature: x ± (x*0.2/100) ± 0
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
    [240, 200],
  ];

  // Respiration setting values (BPM)
  static const List<double> respirationSettings = [5, 10, 15, 30];

  // Temperature setting values (°C)
  static const List<double> tempSettings = [25, 33, 37, 41];

  // Compute accepted range for HR: x ± (x*5/100) ± 1
  static List<double> hrAcceptedRange(double x) {
    final tol = (x * 5 / 100) + 1;
    return [x - tol, x + tol];
  }

  // SPO2: x ± (x*2/100)
  static List<double> spo2AcceptedRange(double x) {
    final tol = x * 2 / 100;
    return [x - tol, x + tol];
  }

  // NIBP: x ± (x*2/100)
  static List<double> nibpAcceptedRange(double x) {
    final tol = x * 2 / 100;
    return [x - tol, x + tol];
  }

  // Respiration: x ± (x*2/100)  [based on ±1% but the sheet shows ±2%]
  static List<double> respirationAcceptedRange(double x) {
    final tol = x * 1 / 100;
    return [x - tol, x + tol];
  }

  // Temperature: x ± (x*0.2/100)
  static List<double> tempAcceptedRange(double x) {
    final tol = x * 0.2 / 100;
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
    'ECG Machines',
    'NIBP Monitors',
    'Pulse Oximeters',
    'Fetal Monitors',
    'Infusion Pumps',
    'Syringe Pumps',
    'Manual Defibrillators',
    'AEDs',
    'Ventilators',
    'CPAP / BiPAP',
    'Suction Machines',
    'Electrosurgical Units (ESU)',
    'Oxygen Cylinder',
    'Electrical Safety',
  ];
}
