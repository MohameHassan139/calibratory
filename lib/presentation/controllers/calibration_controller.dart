// lib/presentation/controllers/calibration_controller.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/models.dart';
import '../../core/constants/app_constants.dart';
import 'auth_controller.dart';
import '../services/certificate_service.dart';
import '../services/firebase_service.dart';

class CalibrationController extends GetxController {
  final AuthController _authCtrl = Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<CalibrationSession?> session = Rx<CalibrationSession?>(null);
  final RxBool isLoading = false.obs;
  final RxInt currentStep = 0.obs;
  final RxList<CalibrationSession> history = <CalibrationSession>[].obs;

  @override
  void onInit() {
    super.onInit();
    // React every time appUser is set (login / re-auth).
    // _loadUserData in AuthController sets appUser.value after the async
    // Firestore fetch, so by the time this fires the uid is available.
    ever(_authCtrl.appUser, (user) {
      if (user != null) loadHistory();
    });
    // If the user is already loaded (hot-restart / controller re-creation)
    if (_authCtrl.appUser.value != null) loadHistory();
  }

  void startNewSession() {
    final user = _authCtrl.appUser.value;
    if (user == null) {
      Get.snackbar('Error', 'User data not loaded. Please try again.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
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
    session.update((s) => s!.qualitativeResults = Map.from(results));
  }

  void updateEcgRepresentation(Map<String, ItemStatus> results) {
    session.update((s) => s!.ecgRepresentation = Map.from(results));
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
    for (var row in session.value!.hrRows) {
      if (row.reads.isNotEmpty) {
        row.average = row.computedAverage;
        final range = MonitorConstants.hrAcceptedRange(row.settingValue);
        row.status = row.average! >= range[0] && row.average! <= range[1];
      }
    }
  }

  void _validateSpo2() {
    for (var row in session.value!.spo2Rows) {
      if (row.reads.isNotEmpty) {
        row.average = row.computedAverage;
        final range = MonitorConstants.spo2AcceptedRange(row.settingValue);
        row.status = row.average! >= range[0] && row.average! <= range[1];
      }
    }
  }

  void _validateNibp() {
    for (var row in session.value!.nibpRows) {
      if (row.systolicReads.isNotEmpty) {
        final avg = row.systolicReads.reduce((a, b) => a + b) / row.systolicReads.length;
        final range = MonitorConstants.nibpAcceptedRange(row.systolicSetting);
        row.systolicStatus = avg >= range[0] && avg <= range[1];
      }
      if (row.diastolicReads.isNotEmpty) {
        final avg = row.diastolicReads.reduce((a, b) => a + b) / row.diastolicReads.length;
        final range = MonitorConstants.nibpAcceptedRange(row.diastolicSetting);
        row.diastolicStatus = avg >= range[0] && avg <= range[1];
      }
    }
  }

  void _validateRespiration() {
    for (var row in session.value!.respirationRows) {
      if (row.reads.isNotEmpty) {
        row.average = row.computedAverage;
        final range = MonitorConstants.respirationAcceptedRange(row.settingValue);
        row.status = row.average! >= range[0] && row.average! <= range[1];
      }
    }
  }

  void _validateTemp() {
    for (var rows in [session.value!.temp1Rows, session.value!.temp2Rows]) {
      for (var row in rows) {
        if (row.reads.isNotEmpty) {
          row.average = row.computedAverage;
          final range = MonitorConstants.tempAcceptedRange(row.settingValue);
          row.status = row.average! >= range[0] && row.average! <= range[1];
        }
      }
    }
  }

  // Returns 'PASS', 'FAIL', or 'N/F'
  String _computeQualResult() {
    final values = session.value!.qualitativeResults.values.toList()
      ..addAll(session.value!.ecgRepresentation.values);
    if (values.isEmpty) return 'N/F';
    if (values.any((v) => v == ItemStatus.fail)) return 'FAIL';
    if (values.every((v) => v == ItemStatus.notAvailable)) return 'N/F';
    return 'PASS';
  }

  // Returns 'PASS', 'FAIL', or 'N/F'
  String _computeQuantResult() {
    final s = session.value!;
    final statuses = <bool?>[];

    if (s.showHrTable) statuses.addAll(s.hrRows.map((r) => r.status));
    if (s.showSpo2Table) statuses.addAll(s.spo2Rows.map((r) => r.status));
    if (s.showNibpTable) {
      for (final row in s.nibpRows) {
        statuses.add(row.systolicStatus);
        statuses.add(row.diastolicStatus);
      }
    }
    if (s.showRespirationTable) statuses.addAll(s.respirationRows.map((r) => r.status));
    if (s.showTempTables) {
      statuses.addAll(s.temp1Rows.map((r) => r.status));
      statuses.addAll(s.temp2Rows.map((r) => r.status));
    }

    final nonNull = statuses.whereType<bool>().toList();
    if (nonNull.isEmpty) return 'N/F';
    if (nonNull.any((st) => !st)) return 'FAIL';
    return 'PASS';
  }

  // AND logic: FAIL if either is FAIL, N/F if both are N/F, else PASS
  static String _combineResults(String qual, String quant) {
    if (qual == 'FAIL' || quant == 'FAIL') return 'FAIL';
    if (qual == 'N/F' && quant == 'N/F') return 'N/F';
    return 'PASS';
  }

  String _nextCertNumber() {
    final year = DateTime.now().year;
    final count = history.length + 1;
    return '${count.toString().padLeft(3, '0')}/$year';
  }

  Future<void> completeCalibration({String notes = '', String? clientEmail}) async {
    isLoading.value = true;
    try {
      final s = session.value!;

      s.notes = notes;
      s.testDate = DateTime.now();
      s.certificateNumber = _nextCertNumber();
      s.hospitalName = s.customerName;
      s.status = 'completed';
      s.id = s.id ?? _firestore.collection('calibrations').doc().id;

      final String qualResult = _computeQualResult();
      final String quantResult = _computeQuantResult();
      final String finalResult = _combineResults(qualResult, quantResult);

      s.qualitativeResult = qualResult;
      s.quantitativeResult = quantResult;
      s.overallResult = finalResult;

      Get.snackbar('Generating', 'Building certificate…',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));

      final String certPath = await CertificateService.generateCertificate(s);
      print('✅ Certificate at: $certPath');

      if (!File(certPath).existsSync()) {
        throw Exception('Certificate file was not created at $certPath');
      }

      // Add to local history
      history.insert(0, s);

      Get.snackbar('Uploading', 'Saving to Firebase…',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));

      // Upload all data to Firebase (certificate kept locally)
      await FirebaseService.uploadCalibrationSession(s);
      await FirebaseService.saveEngineerData(s.engineerId, s);
      await FirebaseService.saveClientData(s, clientEmail);
      await FirebaseService.saveQualitativeResults(s);
      await FirebaseService.saveQuantitativeResults(s);
      await FirebaseService.saveNotes(s);
      await FirebaseService.saveFinalResults(s);

      // Upload certificate .docx to Supabase storage and save URL to Firebase
      try {
        Get.snackbar('Uploading', 'Saving certificate to cloud…',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2));

        final certFile = File(certPath);
        final fileName = certPath.split('/').last;
        final storagePath = '${s.engineerId}/$fileName';

        await Supabase.instance.client.storage
            .from('calibration-certificates')
            .upload(storagePath, certFile,
                fileOptions: const FileOptions(upsert: true));

        // Get public URL and persist it on the session + Firestore
        final publicUrl = Supabase.instance.client.storage
            .from('calibration-certificates')
            .getPublicUrl(storagePath);

        s.certificateUrl = publicUrl;
        s.supabasePath = storagePath;

        // Patch the Firestore document with the certificate URL
        await _firestore.collection('calibrations').doc(s.id).update({
          'certificateUrl': publicUrl,
          'supabasePath': storagePath,
        });

        print('☁️ Certificate uploaded to Supabase: $storagePath');
      } catch (uploadErr) {
        // Non-fatal: log but don't block the user
        print('⚠️ Supabase upload failed: $uploadErr');
      }

      Get.snackbar('Done', 'Certificate ready ✓',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF22C55E),
          colorText: const Color(0xFFFFFFFF),
          duration: const Duration(seconds: 2));

      final OpenResult result = await OpenFilex.open(certPath);
      print('📂 OpenFilex: ${result.type} — ${result.message}');

      if (result.type == ResultType.noAppToOpen) {
        Get.snackbar('No App Found',
            'Install Microsoft Word or a document viewer to open .docx files',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5));
      } else if (result.type != ResultType.done) {
        Get.snackbar('Cannot Open', result.message,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5));
      }

      Get.offAllNamed(AppRoutes.calibrationSummary);
    } catch (e, stack) {
      print('❌ completeCalibration: $e\n$stack');
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadHistory() async {
    try {
      isLoading.value = true;
      final user = _authCtrl.appUser.value;
      if (user == null) {
        debugPrint('⚠️ loadHistory: appUser is null, skipping');
        return;
      }

      debugPrint('🔄 loadHistory: fetching for uid=${user.uid}');
      final calibrations =
          await FirebaseService.fetchEngineerCalibrations(user.uid);
      history.value = calibrations;
      debugPrint('✅ loadHistory: loaded ${calibrations.length} records');
    } catch (e) {
      debugPrint('❌ loadHistory error: $e');
      Get.snackbar(
        'History Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
