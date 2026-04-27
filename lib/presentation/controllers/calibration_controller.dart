// lib/presentation/controllers/calibration_controller.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/models.dart';
import '../../core/constants/app_constants.dart';
import 'auth_controller.dart';
import '../services/certificate_service.dart';
import '../services/email_service.dart';

class CalibrationController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthController _authCtrl = Get.find();

  final Rx<CalibrationSession?> session = Rx<CalibrationSession?>(null);
  final RxBool isLoading = false.obs;
  final RxInt currentStep = 0.obs;

  // History
  final RxList<CalibrationSession> history = <CalibrationSession>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  void startNewSession() {
    final user = _authCtrl.appUser.value!;
    session.value = CalibrationSession(
      engineerId: user.uid,
      engineerName: user.fullName,
      customerName: '',
      orderDate: DateTime.now(),
      visitDate: DateTime.now(),
      visitTime: '',
      department: '',
      manufacturer: '',
      serialNumber: '',
      model: '',
      createdAt: DateTime.now(),
    );
    currentStep.value = 0;
  }

  void updatePublicData({
    required String customerName,
    required DateTime orderDate,
    required DateTime visitDate,
    required String visitTime,
    required String department,
    required String manufacturer,
    required String serialNumber,
    required String model,
  }) {
    session.update((s) {
      s!.customerName = customerName;
      s.orderDate = orderDate;
      s.visitDate = visitDate;
      s.visitTime = visitTime;
      s.department = department;
      s.manufacturer = manufacturer;
      s.serialNumber = serialNumber;
      s.model = model;
    });
  }

  void updateQualitative(Map<String, ItemStatus> results) {
    session.update((s) {
      s!.qualitativeResults = Map.from(results);
    });
  }

  void updateEcgRepresentation(Map<String, ItemStatus> results) {
    session.update((s) {
      s!.ecgRepresentation = Map.from(results);
    });
  }

  void updateHrRows(List<MeasurementRow> rows) {
    session.update((s) => s!.hrRows = rows);
    _validateHr();
  }

  void updateSpo2Rows(List<MeasurementRow> rows) {
    session.update((s) => s!.spo2Rows = rows);
    _validateSpo2();
  }

  void updateNibpRows(List<NIBPRow> rows) {
    session.update((s) => s!.nibpRows = rows);
    _validateNibp();
  }

  void updateRespirationRows(List<MeasurementRow> rows) {
    session.update((s) => s!.respirationRows = rows);
    _validateRespiration();
  }

  void updateTempRows(List<MeasurementRow> temp1, List<MeasurementRow> temp2) {
    session.update((s) {
      s!.temp1Rows = temp1;
      s.temp2Rows = temp2;
    });
    _validateTemp();
  }

  void _validateHr() {
    final rows = session.value!.hrRows;
    for (var row in rows) {
      if (row.reads.isNotEmpty) {
        final avg = row.computedAverage;
        row.average = avg;
        final range = MonitorConstants.hrAcceptedRange(row.settingValue);
        row.status = avg >= range[0] && avg <= range[1];
      }
    }
  }

  void _validateSpo2() {
    final rows = session.value!.spo2Rows;
    for (var row in rows) {
      if (row.reads.isNotEmpty) {
        final avg = row.computedAverage;
        row.average = avg;
        final range = MonitorConstants.spo2AcceptedRange(row.settingValue);
        row.status = avg >= range[0] && avg <= range[1];
      }
    }
  }

  void _validateNibp() {
    final rows = session.value!.nibpRows;
    for (var row in rows) {
      if (row.systolicReads.isNotEmpty) {
        final sysAvg = row.systolicReads.reduce((a, b) => a + b) /
            row.systolicReads.length;
        final sysRange =
            MonitorConstants.nibpAcceptedRange(row.systolicSetting);
        row.systolicStatus = sysAvg >= sysRange[0] && sysAvg <= sysRange[1];
      }
      if (row.diastolicReads.isNotEmpty) {
        final diaAvg = row.diastolicReads.reduce((a, b) => a + b) /
            row.diastolicReads.length;
        final diaRange =
            MonitorConstants.nibpAcceptedRange(row.diastolicSetting);
        row.diastolicStatus = diaAvg >= diaRange[0] && diaAvg <= diaRange[1];
      }
    }
  }

  void _validateRespiration() {
    final rows = session.value!.respirationRows;
    for (var row in rows) {
      if (row.reads.isNotEmpty) {
        final avg = row.computedAverage;
        row.average = avg;
        final range =
            MonitorConstants.respirationAcceptedRange(row.settingValue);
        row.status = avg >= range[0] && avg <= range[1];
      }
    }
  }

  void _validateTemp() {
    for (var rows in [session.value!.temp1Rows, session.value!.temp2Rows]) {
      for (var row in rows) {
        if (row.reads.isNotEmpty) {
          final avg = row.computedAverage;
          row.average = avg;
          final range = MonitorConstants.tempAcceptedRange(row.settingValue);
          row.status = avg >= range[0] && avg <= range[1];
        }
      }
    }
  }

  bool _computeAllPass() {
    final s = session.value!;
    final allStatuses = <bool>[];
    if (s.showHrTable) {
      allStatuses.addAll(s.hrRows.map((r) => r.status ?? false));
    }
    if (s.showSpo2Table) {
      allStatuses.addAll(s.spo2Rows.map((r) => r.status ?? false));
    }
    if (s.showNibpTable) {
      for (var row in s.nibpRows) {
        if (row.systolicStatus != null) allStatuses.add(row.systolicStatus!);
        if (row.diastolicStatus != null) allStatuses.add(row.diastolicStatus!);
      }
    }
    if (s.showRespirationTable) {
      allStatuses.addAll(s.respirationRows.map((r) => r.status ?? false));
    }
    if (s.showTempTables) {
      allStatuses.addAll(s.temp1Rows.map((r) => r.status ?? false));
      allStatuses.addAll(s.temp2Rows.map((r) => r.status ?? false));
    }
    if (allStatuses.isEmpty) return true;
    return allStatuses.every((st) => st == true);
  }

  bool _computeQualPass() {
    final q = session.value!.qualitativeResults;
    return q.values
        .every((v) => v == ItemStatus.pass || v == ItemStatus.notAvailable);
  }

  String _nextCertNumber() {
    final year = DateTime.now().year;
    final count = history.length + 1;
    return '\${count.toString().padLeft(3, ';
    0;
    ')}/$year';
  }

  Future<void> completeCalibration(
      {String notes = '', String? clientEmail}) async {
    isLoading.value = true;
    try {
      final s = session.value!;
      s.notes = notes;
      s.testDate = DateTime.now();
      s.certificateNumber = _nextCertNumber();
      final passed = _computeAllPass();
      final qualPassed = _computeQualPass();
      s.qualitativeResult = qualPassed ? 'PASS' : 'FAIL';
      s.quantitativeResult = passed ? 'PASS' : 'FAIL';
      s.overallResult = (qualPassed && passed) ? 'PASS' : 'FAIL';
      s.hospitalName = s.customerName;
      s.status = 'completed';

      // Generate certificate .docx
      final certPath = await CertificateService.generateCertificate(s);

      // Upload to Supabase
      final supabase = Supabase.instance.client;
      final path =
          'certificates/${s.engineerId}/${s.serialNumber}_${DateTime.now().millisecondsSinceEpoch}.docx';
      final certFile = File(certPath);
      await supabase.storage.from('certificates').upload(path, certFile);
      final url = supabase.storage.from('certificates').getPublicUrl(path);

      s.certificateUrl = url;
      s.supabasePath = path;

      // Save to Firestore
      final docRef = await _db.collection('calibrations').add(s.toFirestore());
      s.id = docRef.id;

      loadHistory();
      Get.offAllNamed(AppRoutes.calibrationSummary);
    } catch (e) {
      Get.snackbar('Error', 'Failed to complete calibration: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadHistory() async {
    final uid = _authCtrl.appUser.value?.uid;
    if (uid == null) return;
    final query = await _db
        .collection('calibrations')
        .where('engineerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
    history.value =
        query.docs.map((d) => CalibrationSession.fromFirestore(d)).toList();
  }
}
