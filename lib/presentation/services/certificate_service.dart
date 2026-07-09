
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/models.dart';

class CertificateService {
  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a filled .docx certificate for [session].
  /// Returns the absolute path of the written file.
  static Future<String> generateCertificate(CalibrationSession session) async {
    final ByteData data =
        await rootBundle.load('assets/monitor_certificate.docx');
    final Uint8List templateBytes = data.buffer.asUint8List();

    final Archive archive = ZipDecoder().decodeBytes(templateBytes);

    final List<ArchiveFile> newFiles = [];
    for (final file in archive) {
      if (file.name == 'word/document.xml') {
        final String xml = utf8.decode(file.content as List<int>, allowMalformed: true);
        final String patched = _patchDocument(xml, session);
        final List<int> bytes = utf8.encode(patched);
        newFiles.add(ArchiveFile(file.name, bytes.length, bytes));
      } else {
        newFiles.add(file);
      }
    }

    final Archive newArchive = Archive();
    for (final f in newFiles) {
      newArchive.addFile(f);
    }
    final List<int>? outBytes = ZipEncoder().encode(newArchive);
    if (outBytes == null) throw Exception('Certificate ZIP encoding failed');

    final dir = await getApplicationDocumentsDirectory();
    final String uid = const Uuid().v4().substring(0, 8);
    final String fileName = 'cert_${session.serialNumber}_$uid.docx';
    final String path = '${dir.path}/$fileName';
    await File(path).writeAsBytes(outBytes);
    return path;
  }

  /// Generate a filled syringe pump certificate (.docx) for [session].
  /// Returns the absolute path of the written file.
  static Future<String> generateSyringeCertificate(
      CalibrationSession session) async {
    final ByteData data =
        await rootBundle.load('assets/syringe_certificate.docx');
    final Uint8List templateBytes = data.buffer.asUint8List();

    final Archive archive = ZipDecoder().decodeBytes(templateBytes);

    final List<ArchiveFile> newFiles = [];
    for (final file in archive) {
      if (file.name == 'word/document.xml') {
        final String xml =
            utf8.decode(file.content as List<int>, allowMalformed: true);
        final String patched = _patchSyringeDocument(xml, session);
        final List<int> bytes = utf8.encode(patched);
        newFiles.add(ArchiveFile(file.name, bytes.length, bytes));
      } else {
        newFiles.add(file);
      }
    }

    final Archive newArchive = Archive();
    for (final f in newFiles) {
      newArchive.addFile(f);
    }
    final List<int>? outBytes = ZipEncoder().encode(newArchive);
    if (outBytes == null)
      throw Exception('Syringe certificate ZIP encoding failed');

    final dir = await getApplicationDocumentsDirectory();
    final String uid = const Uuid().v4().substring(0, 8);
    final String fileName = 'syringe_cert_${session.serialNumber}_$uid.docx';
    final String path = '${dir.path}/$fileName';
    await File(path).writeAsBytes(outBytes);
    return path;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD REPLACEMENT MAP
  // ═══════════════════════════════════════════════════════════════════════════

  static Map<String, String> _buildMap(CalibrationSession s) {
    final map = <String, String>{};

    // ── Header fields ─────────────────────────────────────────────────────────
    map['{HospitalName}'] =
        s.hospitalName.isNotEmpty ? s.hospitalName : s.customerName;
    map['{Manufacturer}'] = s.manufacturer;
    map['{Model}'] = s.model;
    map['{SerialNo}'] = s.serialNumber;
    map['{Department}'] = s.department;
    map['{VisitDate}'] = _fmtDate(s.visitDate);
    map['{Visit Date}'] = _fmtDate(s.visitDate);
    map['{OrderDate}'] = _fmtDate(s.orderDate);
    map['{Order Date}'] = _fmtDate(s.orderDate);
    map['{EngineerName}'] = s.engineerName;
    map['{CertNo}'] = s.certificateNumber ?? '';

    // Testing Device mapping
    map['{TestDeviceManufacturer}'] = s.testDeviceManufacturer;
    map['{TestDeviceMfr}'] = s.testDeviceManufacturer;
    map['{Test Device Manufacturer}'] = s.testDeviceManufacturer;
    map['{TestDeviceModel}'] = s.testDeviceModel;
    map['{Test Device Model}'] = s.testDeviceModel;
    map['{TestDeviceSerialNo}'] = s.testDeviceSerialNumber;
    map['{TestDeviceSerialNumber}'] = s.testDeviceSerialNumber;
    map['{Test Device SerialNo}'] = s.testDeviceSerialNumber;
    map['{Test Device Serial Number}'] = s.testDeviceSerialNumber;

    // Test Info mapping
    map['{TestType}'] = s.testType;
    map['{Test Type}'] = s.testType;
    map['{TestLab}'] = s.testLab;
    map['{Test Lab}'] = s.testLab;
    map['{LabName}'] = s.testLab;
    map['{Lab Name}'] = s.testLab;

    // ── Overall results ───────────────────────────────────────────────────────
    map['{Final_Qualitative}'] = s.qualitativeResult ?? 'N/F';
    map['{Final_Quantitative}'] = s.quantitativeResult ?? 'N/F';
    map['{Final}'] = s.overallResult ?? 'N/F';
    // Legacy aliases
    map['{QualResult}'] = s.qualitativeResult ?? 'N/F';
    map['{QuantResult}'] = s.quantitativeResult ?? 'N/F';
    map['{OverallResult}'] = s.overallResult ?? 'N/F';

    // ── Qualitative — Visual Inspection ──────────────────────────────────────
    final q = s.qualitativeResults;
    map['{Cha}'] = _qs(q['Chassis/Housing']);
    map['{Con}'] = _qs(q['Controls/Switches']);
    map['{Mou}'] = _qs(q['Mount']);
    map['{Bat}'] = _qs(q['Battery/charger']);
    map['{Cas}'] = _qs(q['Casters/Brakes']);
    map['{Ind}'] = _qs(q['Indicator/Displays']);
    map['{AC}'] = _qs(q['AC plug']);
    map['{Lab}'] = _qs(q['Labeling']);
    map['{Lin}'] = _qs(q['Line Cord']);
    map['{Ala}'] = _qs(q['Alarms']);
    map['{Scr}'] = _qs(q['Screen']);
    map['{Hou}'] = _qs(q['Module Housing']);
    map['{SPO}'] = _qs(q['SPO2 cable']);
    map['{Tro}'] = _qs(q['Mounting/Trolley']);

    // ── Qualitative — ECG Representation ─────────────────────────────────────
    final e = s.ecgRepresentation;
    map['{Atr}'] = _qs(e['Atrial Fibrillation']);
    map['{Prem}'] = _qs(e['Premature ventricle contraction']);
    map['{Ven}'] = _qs(e['Ventricle Fibrillation']);
    map['{Paro}'] = _qs(e['Paroxysmal Atrial Tachycardia (PAT)']);
    map['{Atrf}'] = _qs(e['Atrial Flutter']);
    map['{Poly}'] = _qs(e['Polymorphic Ventricular Tachycardia (PVT)']);
    map['{Rep}'] = _qs(
        e['Representation of Standard signals (Triangle, Square, Sinusoid)']);
    map['{ECG}'] = _qs(e[
        'Represent ECG waveforms with different Amplitudes (0.5,1,1.5,2,2.5,3,3.5)']);

    // ── Heart Rate (6 rows: default 40, 60, 80, 100, 150, 200 BPM) ──────────
    final bool hr = s.showHrTable;
    const hrDefaults = [40, 60, 80, 100, 150, 200];
    for (int i = 0; i < hrDefaults.length; i++) {
      final int defaultBpm = hrDefaults[i];
      final MeasurementRow? row = hr && i < s.hrRows.length ? s.hrRows[i] : null;
      // Use actual setting value from row (user may have changed it)
      final int bpm = row != null ? row.settingValue.toInt() : defaultBpm;
      if (!hr) {
        // Table not shown — N/A
        map['{Heart_set$defaultBpm}'] = defaultBpm.toString();
        map['{Heart_Ave$defaultBpm}'] = 'N/A';
        map['{Heart_Error$defaultBpm}'] = 'N/A';
        map['{Heart_Acc$defaultBpm}'] = 'N/A';
        map['{Heart_Sta$defaultBpm}'] = 'N/A';
        map['{Heart_unc$defaultBpm}'] = 'N/A';
      } else if (row == null) {
        // Row was removed by user — NI
        map['{Heart_set$defaultBpm}'] = defaultBpm.toString();
        map['{Heart_Ave$defaultBpm}'] = 'NI';
        map['{Heart_Error$defaultBpm}'] = 'NI';
        map['{Heart_Acc$defaultBpm}'] = 'NI';
        map['{Heart_Sta$defaultBpm}'] = 'NI';
        map['{Heart_unc$defaultBpm}'] = 'NI';
      } else {
        final double avg = row.computedAverage;
        final double err = (row.settingValue - avg).abs();
        final range = MonitorConstants.hrAcceptedRange(row.settingValue);
        // Map both the default key and the actual key (in case user changed the value)
        for (final key in {defaultBpm, bpm}) {
          map['{Heart_set$key}'] = bpm.toString();
          map['{Heart_Ave$key}'] = avg.toStringAsFixed(2);
          map['{Heart_Error$key}'] = err.toStringAsFixed(2);
          map['{Heart_Acc$key}'] =
              '${range[0].toStringAsFixed(3)} - ${range[1].toStringAsFixed(3)}';
          map['{Heart_Sta$key}'] = row.status == true ? 'PASS' : row.status == false ? 'FAIL' : 'N/A';
          map['{Heart_unc$key}'] = _typeA(row.reads, decimals: 4);
        }
      }
    }

    // ── SPO2 (5 rows: default 75, 85, 90, 94, 98 %) ──────────────────────────
    final bool sp = s.showSpo2Table;
    const spo2Defaults = [75, 85, 90, 94, 98];
    for (int i = 0; i < spo2Defaults.length; i++) {
      final int defaultVal = spo2Defaults[i];
      final MeasurementRow? row =
          sp && i < s.spo2Rows.length ? s.spo2Rows[i] : null;
      final int val = row != null ? row.settingValue.toInt() : defaultVal;
      if (!sp) {
        map['{SPO2_Set$defaultVal}'] = defaultVal.toString();
        map['{SPO2_Avg$defaultVal}'] = 'N/A';
        map['{SPO2_Err$defaultVal}'] = 'N/A';
        map['{SPO2_Acc$defaultVal}'] = 'N/A';
        map['{SPO2_Sta$defaultVal}'] = 'N/A';
        map['{SPO2_Unc$defaultVal}'] = 'N/A';
      } else if (row == null) {
        map['{SPO2_Set$defaultVal}'] = defaultVal.toString();
        map['{SPO2_Avg$defaultVal}'] = 'NI';
        map['{SPO2_Err$defaultVal}'] = 'NI';
        map['{SPO2_Acc$defaultVal}'] = 'NI';
        map['{SPO2_Sta$defaultVal}'] = 'NI';
        map['{SPO2_Unc$defaultVal}'] = 'NI';
      } else {
        final double avg = row.computedAverage;
        final double err = (row.settingValue - avg).abs();
        final range = MonitorConstants.spo2AcceptedRange(row.settingValue);
        for (final key in {defaultVal, val}) {
          map['{SPO2_Set$key}'] = val.toString();
          map['{SPO2_Avg$key}'] = avg.toStringAsFixed(2);
          map['{SPO2_Err$key}'] = err.toStringAsFixed(2);
          map['{SPO2_Acc$key}'] =
              '${range[0].toStringAsFixed(3)} - ${range[1].toStringAsFixed(3)}';
          map['{SPO2_Sta$key}'] =
              row.status == true ? 'PASS' : row.status == false ? 'FAIL' : 'N/A';
          map['{SPO2_Unc$key}'] = _typeA(row.reads, decimals: 4);
        }
      }
    }

    // ── NIBP (6 pairs: sys/dia with defaults 60/30, 80/40, 100/60, 120/80, 180/140, 240/200) ──
    final bool nb = s.showNibpTable;
    const nibpSysDefaults = [60, 80, 100, 120, 180, 240];
    const nibpDiaDefaults = [30, 40, 60, 80, 140, 200];
    for (int i = 0; i < nibpSysDefaults.length; i++) {
      final int defSys = nibpSysDefaults[i];
      final int defDia = nibpDiaDefaults[i];
      final int rowNum = i + 1; // 1-based index for word template
      final NIBPRow? row = nb && i < s.nibpRows.length ? s.nibpRows[i] : null;
      final int sys = row != null ? row.systolicSetting.toInt() : defSys;
      final int dia = row != null ? row.diastolicSetting.toInt() : defDia;

      if (!nb) {
        // Systolic N/A — value-based keys
        map['{Set_Sys$defSys}'] = defSys.toString();
        map['{NIBP_S_Set$defSys}'] = defSys.toString();
        map['{NIBP_S_Avg$defSys}'] = 'N/A';
        map['{NIBP_S_Err$defSys}'] = 'N/A';
        map['{NIBP_S_Acc$defSys}'] = 'N/A';
        map['{NIBP_S_Sta$defSys}'] = 'N/A';
        map['{NIBP_S_Unc$defSys}'] = 'N/A';
        // Systolic N/A — index-based keys
        map['{NIBP_S_Set$rowNum}'] = defSys.toString();
        map['{NIBP_S_Avg$rowNum}'] = 'N/A';
        map['{NIBP_S_Err$rowNum}'] = 'N/A';
        map['{NIBP_S_Acc$rowNum}'] = 'N/A';
        map['{NIBP_S_Sta$rowNum}'] = 'N/A';
        map['{NIBP_S_Unc$rowNum}'] = 'N/A';
        // Diastolic N/A — value-based keys
        map['{Set_Dia$defDia}'] = defDia.toString();
        map['{NIBP_D_Set$defDia}'] = defDia.toString();
        map['{NIBP_D_Avg$defDia}'] = 'N/A';
        map['{NIBP_D_Err$defDia}'] = 'N/A';
        map['{NIBP_D_Acc$defDia}'] = 'N/A';
        map['{NIBP_D_Sta$defDia}'] = 'N/A';
        map['{NIBP_D_Unc$defDia}'] = 'N/A';
        // Diastolic N/A — index-based keys
        map['{NIBP_D_Set$rowNum}'] = defDia.toString();
        map['{NIBP_D_Avg$rowNum}'] = 'N/A';
        map['{NIBP_D_Err$rowNum}'] = 'N/A';
        map['{NIBP_D_Acc$rowNum}'] = 'N/A';
        map['{NIBP_D_Sta$rowNum}'] = 'N/A';
        map['{NIBP_D_Unc$rowNum}'] = 'N/A';
      } else if (row == null) {
        // Row removed by user — NI
        map['{Set_Sys$defSys}'] = defSys.toString();
        map['{NIBP_S_Set$defSys}'] = defSys.toString();
        map['{NIBP_S_Avg$defSys}'] = 'NI';
        map['{NIBP_S_Err$defSys}'] = 'NI';
        map['{NIBP_S_Acc$defSys}'] = 'NI';
        map['{NIBP_S_Sta$defSys}'] = 'NI';
        map['{NIBP_S_Unc$defSys}'] = 'NI';
        map['{NIBP_S_Set$rowNum}'] = defSys.toString();
        map['{NIBP_S_Avg$rowNum}'] = 'NI';
        map['{NIBP_S_Err$rowNum}'] = 'NI';
        map['{NIBP_S_Acc$rowNum}'] = 'NI';
        map['{NIBP_S_Sta$rowNum}'] = 'NI';
        map['{NIBP_S_Unc$rowNum}'] = 'NI';
        map['{Set_Dia$defDia}'] = defDia.toString();
        map['{NIBP_D_Set$defDia}'] = defDia.toString();
        map['{NIBP_D_Avg$defDia}'] = 'NI';
        map['{NIBP_D_Err$defDia}'] = 'NI';
        map['{NIBP_D_Acc$defDia}'] = 'NI';
        map['{NIBP_D_Sta$defDia}'] = 'NI';
        map['{NIBP_D_Unc$defDia}'] = 'NI';
        map['{NIBP_D_Set$rowNum}'] = defDia.toString();
        map['{NIBP_D_Avg$rowNum}'] = 'NI';
        map['{NIBP_D_Err$rowNum}'] = 'NI';
        map['{NIBP_D_Acc$rowNum}'] = 'NI';
        map['{NIBP_D_Sta$rowNum}'] = 'NI';
        map['{NIBP_D_Unc$rowNum}'] = 'NI';
      } else {
        // Systolic
        final sysReads = row.systolicReads;
        final sysAvg = sysReads.isEmpty
            ? 0.0
            : sysReads.reduce((a, b) => a + b) / sysReads.length;
        final sysErr = (row.systolicSetting - sysAvg).abs();
        final sysRange = MonitorConstants.nibpAcceptedRange(row.systolicSetting);
        final sysSta = row.systolicStatus == true ? 'PASS' : row.systolicStatus == false ? 'FAIL' : 'N/A';
        final sysUnc = _typeA(sysReads, decimals: 4);
        final sysAcc =
            '${sysRange[0].toStringAsFixed(3)} - ${sysRange[1].toStringAsFixed(3)}';
        // value-based keys
        for (final k in {defSys, sys}) {
          map['{Set_Sys$k}'] = sys.toString();
          map['{NIBP_S_Set$k}'] = sys.toString();
          map['{NIBP_S_Avg$k}'] = sysAvg.toStringAsFixed(2);
          map['{NIBP_S_Err$k}'] = sysErr.toStringAsFixed(2);
          map['{NIBP_S_Acc$k}'] = sysAcc;
          map['{NIBP_S_Sta$k}'] = sysSta;
          map['{NIBP_S_Unc$k}'] = sysUnc;
        }
        // index-based keys
        map['{NIBP_S_Set$rowNum}'] = sys.toString();
        map['{NIBP_S_Avg$rowNum}'] = sysAvg.toStringAsFixed(2);
        map['{NIBP_S_Err$rowNum}'] = sysErr.toStringAsFixed(2);
        map['{NIBP_S_Acc$rowNum}'] = sysAcc;
        map['{NIBP_S_Sta$rowNum}'] = sysSta;
        map['{NIBP_S_Unc$rowNum}'] = sysUnc;

        // Diastolic
        final diaReads = row.diastolicReads;
        final diaAvg = diaReads.isEmpty
            ? 0.0
            : diaReads.reduce((a, b) => a + b) / diaReads.length;
        final diaErr = (row.diastolicSetting - diaAvg).abs();
        final diaRange = MonitorConstants.nibpAcceptedRange(row.diastolicSetting);
        final diaSta = row.diastolicStatus == true ? 'PASS' : row.diastolicStatus == false ? 'FAIL' : 'N/A';
        final diaUnc = _typeA(diaReads, decimals: 4);
        final diaAcc =
            '${diaRange[0].toStringAsFixed(3)} - ${diaRange[1].toStringAsFixed(3)}';
        // value-based keys
        for (final k in {defDia, dia}) {
          map['{Set_Dia$k}'] = dia.toString();
          map['{NIBP_D_Set$k}'] = dia.toString();
          map['{NIBP_D_Avg$k}'] = diaAvg.toStringAsFixed(2);
          map['{NIBP_D_Err$k}'] = diaErr.toStringAsFixed(2);
          map['{NIBP_D_Acc$k}'] = diaAcc;
          map['{NIBP_D_Sta$k}'] = diaSta;
          map['{NIBP_D_Unc$k}'] = diaUnc;
        }
        // index-based keys
        map['{NIBP_D_Set$rowNum}'] = dia.toString();
        map['{NIBP_D_Avg$rowNum}'] = diaAvg.toStringAsFixed(2);
        map['{NIBP_D_Err$rowNum}'] = diaErr.toStringAsFixed(2);
        map['{NIBP_D_Acc$rowNum}'] = diaAcc;
        map['{NIBP_D_Sta$rowNum}'] = diaSta;
        map['{NIBP_D_Unc$rowNum}'] = diaUnc;
      }
    }

    // ── Respiration (4 rows: default 5, 10, 15, 30 BPM) ─────────────────────
    final bool rr = s.showRespirationTable;
    const rrDefaults = [5, 10, 15, 30];
    for (int i = 0; i < rrDefaults.length; i++) {
      final int defaultBpm = rrDefaults[i];
      final MeasurementRow? row =
          rr && i < s.respirationRows.length ? s.respirationRows[i] : null;
      final int bpm = row != null ? row.settingValue.toInt() : defaultBpm;
      if (!rr) {
        map['{Resp_Set$defaultBpm}'] = defaultBpm.toString();
        map['{Resp_Avg$defaultBpm}'] = 'N/A';
        map['{Resp_Err$defaultBpm}'] = 'N/A';
        map['{Resp_Acc$defaultBpm}'] = 'N/A';
        map['{Resp_Sta$defaultBpm}'] = 'N/A';
        map['{Resp_Unc$defaultBpm}'] = 'N/A';
      } else if (row == null) {
        map['{Resp_Set$defaultBpm}'] = defaultBpm.toString();
        map['{Resp_Avg$defaultBpm}'] = 'NI';
        map['{Resp_Err$defaultBpm}'] = 'NI';
        map['{Resp_Acc$defaultBpm}'] = 'NI';
        map['{Resp_Sta$defaultBpm}'] = 'NI';
        map['{Resp_Unc$defaultBpm}'] = 'NI';
      } else {
        final double avg = row.computedAverage;
        final double err = (row.settingValue - avg).abs();
        final range = MonitorConstants.respirationAcceptedRange(row.settingValue);
        for (final key in {defaultBpm, bpm}) {
          map['{Resp_Set$key}'] = bpm.toString();
          map['{Resp_Avg$key}'] = avg.toStringAsFixed(2);
          map['{Resp_Err$key}'] = err.toStringAsFixed(2);
          map['{Resp_Acc$key}'] =
              '${range[0].toStringAsFixed(3)} - ${range[1].toStringAsFixed(3)}';
          map['{Resp_Sta$key}'] =
              row.status == true ? 'PASS' : row.status == false ? 'FAIL' : 'N/A';
          map['{Resp_Unc$key}'] = _typeA(row.reads, decimals: 4);
        }
      }
    }

    // ── Temperature sensor 1 (3 rows: default 33, 37, 41 °C) ────────────────
    final bool tm = s.showTempTables;
    const tempDefaults = [33, 37, 41];
    for (int i = 0; i < tempDefaults.length; i++) {
      final int defaultVal = tempDefaults[i];
      // find matching row by index (rows are ordered by tempSettings)
      // tempSettings = [25, 33, 37, 41] → index offset: 33→1, 37→2, 41→3
      final int rowIdx = i + 1; // skip the 25°C row
      final MeasurementRow? row =
          tm && rowIdx < s.temp1Rows.length ? s.temp1Rows[rowIdx] : null;
      final int val = row != null ? row.settingValue.toInt() : defaultVal;
      if (!tm) {
        map['{Tem_Set$defaultVal}'] = defaultVal.toString();
        map['{Tem_Avg$defaultVal}'] = 'N/A';
        map['{Tem_Err$defaultVal}'] = 'N/A';
        map['{Tem_Acc$defaultVal}'] = 'N/A';
        map['{Tem_Sta$defaultVal}'] = 'N/A';
        map['{Tem_Unc$defaultVal}'] = 'N/A';
      } else if (row == null) {
        map['{Tem_Set$defaultVal}'] = defaultVal.toString();
        map['{Tem_Avg$defaultVal}'] = 'NI';
        map['{Tem_Err$defaultVal}'] = 'NI';
        map['{Tem_Acc$defaultVal}'] = 'NI';
        map['{Tem_Sta$defaultVal}'] = 'NI';
        map['{Tem_Unc$defaultVal}'] = 'NI';
      } else {
        final double avg = row.computedAverage;
        final double err = (row.settingValue - avg).abs();
        final range = MonitorConstants.tempAcceptedRange(row.settingValue);
        for (final key in {defaultVal, val}) {
          map['{Tem_Set$key}'] = val.toString();
          map['{Tem_Avg$key}'] = avg.toStringAsFixed(3);
          map['{Tem_Err$key}'] = err.toStringAsFixed(3);
          map['{Tem_Acc$key}'] =
              '${range[0].toStringAsFixed(3)} - ${range[1].toStringAsFixed(3)}';
          map['{Tem_Sta$key}'] =
              row.status == true ? 'PASS' : row.status == false ? 'FAIL' : 'N/A';
          map['{Tem_Unc$key}'] = _typeA(row.reads, decimals: 4);
        }
      }
    }

    // ── Temperature sensor 2 (3 rows: default 33, 37, 41 °C) ────────────────
    for (int i = 0; i < tempDefaults.length; i++) {
      final int defaultVal = tempDefaults[i];
      final int rowIdx = i + 1;
      final MeasurementRow? row =
          tm && rowIdx < s.temp2Rows.length ? s.temp2Rows[rowIdx] : null;
      final int val = row != null ? row.settingValue.toInt() : defaultVal;
      if (!tm) {
        map['{Tem2_Set$defaultVal}'] = defaultVal.toString();
        map['{Tem2_Avg$defaultVal}'] = 'N/A';
        map['{Tem2_Err$defaultVal}'] = 'N/A';
        map['{Tem2_Acc$defaultVal}'] = 'N/A';
        map['{Tem2_Sta$defaultVal}'] = 'N/A';
        map['{Tem2_Unc$defaultVal}'] = 'N/A';
      } else if (row == null) {
        map['{Tem2_Set$defaultVal}'] = defaultVal.toString();
        map['{Tem2_Avg$defaultVal}'] = 'NI';
        map['{Tem2_Err$defaultVal}'] = 'NI';
        map['{Tem2_Acc$defaultVal}'] = 'NI';
        map['{Tem2_Sta$defaultVal}'] = 'NI';
        map['{Tem2_Unc$defaultVal}'] = 'NI';
      } else {
        final double avg = row.computedAverage;
        final double err = (row.settingValue - avg).abs();
        final range = MonitorConstants.tempAcceptedRange(row.settingValue);
        for (final key in {defaultVal, val}) {
          map['{Tem2_Set$key}'] = val.toString();
          map['{Tem2_Avg$key}'] = avg.toStringAsFixed(3);
          map['{Tem2_Err$key}'] = err.toStringAsFixed(3);
          map['{Tem2_Acc$key}'] =
              '${range[0].toStringAsFixed(3)} - ${range[1].toStringAsFixed(3)}';
          map['{Tem2_Sta$key}'] =
              row.status == true ? 'PASS' : row.status == false ? 'FAIL' : 'N/A';
          map['{Tem2_Unc$key}'] = _typeA(row.reads, decimals: 4);
        }
      }
    }

    return map;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD SYRINGE REPLACEMENT MAP
  // ═══════════════════════════════════════════════════════════════════════════

  static Map<String, String> _buildSyringeMap(CalibrationSession s) {
    final map = <String, String>{};

    // ── Header fields (same as monitor certificate) ───────────────────────
    map['{HospitalName}'] =
        s.hospitalName.isNotEmpty ? s.hospitalName : s.customerName;
    map['{Manufacturer}'] = s.manufacturer;
    map['{Model}'] = s.model;
    map['{SerialNo}'] = s.serialNumber;
    map['{Department}'] = s.department;
    map['{VisitDate}'] = _fmtDate(s.visitDate);
    map['{Visit Date}'] = _fmtDate(s.visitDate);
    map['{OrderDate}'] = _fmtDate(s.orderDate);
    map['{Order Date}'] = _fmtDate(s.orderDate);
    map['{EngineerName}'] = s.engineerName;
    map['{CertNo}'] = s.certificateNumber ?? '';

    // Testing device
    map['{TestDeviceManufacturer}'] = s.testDeviceManufacturer;
    map['{TestDeviceMfr}'] = s.testDeviceManufacturer;
    map['{TestDeviceModel}'] = s.testDeviceModel;
    map['{TestDeviceSerialNo}'] = s.testDeviceSerialNumber;
    map['{TestDeviceSerialNumber}'] = s.testDeviceSerialNumber;

    // Test info
    map['{TestType}'] = s.testType;
    map['{TestLab}'] = s.testLab;
    map['{LabName}'] = s.testLab;

    // Overall results
    map['{Final_Qualitative}'] = s.qualitativeResult ?? 'N/F';
    map['{Final_Quantitative}'] = s.quantitativeResult ?? 'N/F';
    map['{Final}'] = s.overallResult ?? 'N/F';
    map['{QualResult}'] = s.qualitativeResult ?? 'N/F';
    map['{QuantResult}'] = s.quantitativeResult ?? 'N/F';
    map['{OverallResult}'] = s.overallResult ?? 'N/F';

    // ── Qualitative — Visual Inspection (syringe pump items) ──────────────
    final q = s.qualitativeResults;
    map['{Cha}'] = _qs(q['Chassis/Housing']);
    map['{Con}'] = _qs(q['Controls /Switches']);
    map['{Mou}'] = _qs(q['Mount']);
    map['{Doo}'] = _qs(q['Door/Misloaded Infusion Set']);
    map['{cas}'] = _qs(q['Casters/Brakes']);
    map['{Bat}'] = _qs(q['Battery/charger']);
    map['{AC}'] = _qs(q['AC plug']);
    map['{Ind}'] = _qs(q['Indicator/Displays']);
    map['{Lin}'] = _qs(q['Line Cord']);
    map['{Lab}'] = _qs(q['Labeling']);
    map['{Cab}'] = _qs(q['Cables']);
    map['{Air}'] = _qs(q['Air-in-Line']);
    map['{Scr}'] = _qs(q['Screen']);
    map['{Emp}'] = _qs(q['Empty Container']);
    map['{Flo}'] = _qs(q['Flow-Stop Mechanism(s)']);
    map['{Inf}'] = _qs(q['Infusion Complete']);

    // ── Quantitative — Flow Rate Measurement (10, 15, 20 mL/hr) ──────────
    const flowSettings = SyringeConstants.flowSettings;
    const flowRanges = SyringeConstants.flowAcceptedRanges;

    final suffixes = ['10', '15', '20'];
    for (int i = 0; i < flowSettings.length; i++) {
      final String suf = suffixes[i];
      final double setting = flowSettings[i];
      final List<double> accepted = flowRanges[i];
      final String accStr = '(${accepted[0]}  -  ${accepted[1]})';

      final MeasurementRow? row =
          i < s.syringeFlowRows.length ? s.syringeFlowRows[i] : null;

      if (row == null) {
        map['{flow_set_$suf}'] = setting.toStringAsFixed(0);
        map['{flow_avg_$suf}'] = 'N/A';
        map['{flow_err_$suf}'] = 'N/A';
        map['{flow_acc_$suf}'] = accStr;
        map['{flow_sta_$suf}'] = 'N/A';
        map['{flow_unc_$suf}'] = 'N/A';
      } else {
        final double avg = row.computedAverage;
        final double err = (setting - avg).abs();
        final double errPct = setting > 0 ? (err / setting) * 100 : 0;
        map['{flow_set_$suf}'] = setting.toStringAsFixed(0);
        map['{flow_avg_$suf}'] = avg.toStringAsFixed(3);
        map['{flow_err_$suf}'] = errPct.toStringAsFixed(2);
        map['{flow_acc_$suf}'] = accStr;
        map['{flow_sta_$suf}'] = row.status == true
            ? 'PASS'
            : row.status == false
                ? 'FAIL'
                : 'N/A';
        map['{flow_unc_$suf}'] = _typeA(row.reads, decimals: 4);
      }
    }

    // ── Quantitative — Occlusion Pressure Measurement ─────────────────────
    // Row index 0 = Peak value (mmHg), index 1 = Time to Alarm (sec)
    final OcclusionRow? peakRow =
        s.syringeOcclusionRows.isNotEmpty ? s.syringeOcclusionRows[0] : null;
    final OcclusionRow? timeRow =
        s.syringeOcclusionRows.length > 1 ? s.syringeOcclusionRows[1] : null;

    // Peak value
    if (peakRow == null) {
      map['{occ_avg_peak}'] = 'N/A';
      map['{occ_sta_peak}'] = 'N/A';
      map['{occ_unc_peak}'] = 'N/A';
    } else {
      final double avg = peakRow.computedAverage;
      map['{occ_avg_peak}'] = avg.toStringAsFixed(2);
      map['{occ_sta_peak}'] = peakRow.status == true
          ? 'PASS'
          : peakRow.status == false
              ? 'FAIL'
              : 'N/A';
      map['{occ_unc_peak}'] = _typeA(peakRow.reads, decimals: 4);
    }

    // Time to alarm
    if (timeRow == null) {
      map['{occ_avg_time}'] = 'N/A';
      map['{occ_sta_time}'] = 'N/A';
      map['{occ_unc_time}'] = 'N/A';
    } else {
      final double avg = timeRow.computedAverage;
      map['{occ_avg_time}'] = avg.toStringAsFixed(2);
      map['{occ_sta_time}'] = timeRow.status == true
          ? 'PASS'
          : timeRow.status == false
              ? 'FAIL'
              : 'N/A';
      map['{occ_unc_time}'] = _typeA(timeRow.reads, decimals: 4);
    }

    return map;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PATCH SYRINGE DOCUMENT
  // ═══════════════════════════════════════════════════════════════════════════

  static String _patchSyringeDocument(String xml, CalibrationSession s) {
    final Map<String, String> replacements = _buildSyringeMap(s);
    return _collapseAndReplace(xml, replacements);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERATE SPHYGMOMANOMETER CERTIFICATE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a filled sphygmomanometer certificate (.docx) for [session].
  static Future<String> generateSphygmomanometerCertificate(
      CalibrationSession session) async {
    final ByteData data =
        await rootBundle.load('assets/sphygmomanometer_certificate.docx');
    final Uint8List templateBytes = data.buffer.asUint8List();
    final Archive archive = ZipDecoder().decodeBytes(templateBytes);

    final List<ArchiveFile> newFiles = [];
    for (final file in archive) {
      if (file.name == 'word/document.xml') {
        final String xml =
            utf8.decode(file.content as List<int>, allowMalformed: true);
        final String patched = _patchSphygmoDocument(xml, session);
        final List<int> bytes = utf8.encode(patched);
        newFiles.add(ArchiveFile(file.name, bytes.length, bytes));
      } else {
        newFiles.add(file);
      }
    }

    final Archive newArchive = Archive();
    for (final f in newFiles) newArchive.addFile(f);
    final List<int>? outBytes = ZipEncoder().encode(newArchive);
    if (outBytes == null)
      throw Exception('Sphygmomanometer certificate ZIP encoding failed');

    final dir = await getApplicationDocumentsDirectory();
    final String uid = const Uuid().v4().substring(0, 8);
    final String fileName = 'sphygmo_cert_${session.serialNumber}_$uid.docx';
    final String path = '${dir.path}/$fileName';
    await File(path).writeAsBytes(outBytes);
    return path;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD SPHYGMOMANOMETER MAP
  // ═══════════════════════════════════════════════════════════════════════════

  static Map<String, String> _buildSphygmoMap(CalibrationSession s) {
    final map = <String, String>{};

    // ── Header (same keys as other certificates) ─────────────────────────
    map['{HospitalName}'] =
        s.hospitalName.isNotEmpty ? s.hospitalName : s.customerName;
    map['{Manufacturer}'] = s.manufacturer;
    map['{Model}'] = s.model;
    map['{SerialNo}'] = s.serialNumber;
    map['{Department}'] = s.department;
    map['{VisitDate}'] = _fmtDate(s.visitDate);
    map['{Visit Date}'] = _fmtDate(s.visitDate);
    map['{OrderDate}'] = _fmtDate(s.orderDate);
    map['{Order Date}'] = _fmtDate(s.orderDate);
    map['{EngineerName}'] = s.engineerName;
    map['{CertNo}'] = s.certificateNumber ?? '';
    map['{TestDeviceManufacturer}'] = s.testDeviceManufacturer;
    map['{TestDeviceMfr}'] = s.testDeviceManufacturer;
    map['{TestDeviceModel}'] = s.testDeviceModel;
    map['{TestDeviceSerialNo}'] = s.testDeviceSerialNumber;
    map['{TestDeviceSerialNumber}'] = s.testDeviceSerialNumber;
    map['{TestType}'] = s.testType;
    map['{TestLab}'] = s.testLab;
    map['{LabName}'] = s.testLab;
    map['{Final_Qualitative}'] = s.qualitativeResult ?? 'N/F';
    map['{Final_Quantitative}'] = s.quantitativeResult ?? 'N/F';
    map['{Final}'] = s.overallResult ?? 'N/F';
    map['{QualResult}'] = s.qualitativeResult ?? 'N/F';
    map['{QuantResult}'] = s.quantitativeResult ?? 'N/F';
    map['{OverallResult}'] = s.overallResult ?? 'N/F';

    // ── Qualitative — Visual Inspection ──────────────────────────────────
    final q = s.qualitativeResults;
    map['{Cha}'] = _qs(q['Chassis/Housing']);
    map['{Han}'] = _qs(q['Hand pump (bulb)']);
    map['{NIBP}'] = _qs(q['NIBP Cuff']);
    map['{Pre_ru}'] = _qs(q['Pressure ruler glass']);
    map['{Mer}'] = _qs(q['Mercury Container']);
    map['{pre_ca}'] = _qs(q['Pressure Cables']);

    // ── Quantitative — Static Pressure Measurement ───────────────────────
    const settings = SphygmoConstants.staticSettings;
    const ranges = SphygmoConstants.staticAcceptedRanges;
    final suffixes = ['0', '50', '100', '150', '200', '250'];

    for (int i = 0; i < settings.length; i++) {
      final String suf = suffixes[i];
      final double setting = settings[i];
      final List<double> accepted = ranges[i];
      final String accStr =
          setting == 0 ? '0' : '(${accepted[0]}  -  ${accepted[1]})';

      final MeasurementRow? row =
          i < s.sphygmoStaticRows.length ? s.sphygmoStaticRows[i] : null;

      if (row == null) {
        map['{sta_set_$suf}'] = setting.toStringAsFixed(0);
        map['{sta_avg_$suf}'] = 'N/A';
        map['{sta_err_$suf}'] = 'N/A';
        map['{sta_acc_$suf}'] = accStr;
        map['{sta_sta_$suf}'] = 'N/A';
        map['{sta_unc_$suf}'] = 'N/A';
      } else {
        final double avg = row.computedAverage;
        final double err = (setting - avg).abs();
        map['{sta_set_$suf}'] = setting.toStringAsFixed(0);
        map['{sta_avg_$suf}'] = avg.toStringAsFixed(3);
        map['{sta_err_$suf}'] = err.toStringAsFixed(3);
        map['{sta_acc_$suf}'] = accStr;
        map['{sta_sta_$suf}'] = row.status == true
            ? 'PASS'
            : row.status == false
                ? 'FAIL'
                : 'N/A';
        map['{sta_unc_$suf}'] = _typeA(row.reads, decimals: 4);
      }
    }

    return map;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PATCH SPHYGMOMANOMETER DOCUMENT
  // ═══════════════════════════════════════════════════════════════════════════

  static String _patchSphygmoDocument(String xml, CalibrationSession s) {
    final Map<String, String> replacements = _buildSphygmoMap(s);
    return _collapseAndReplace(xml, replacements);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERATE ECG MACHINE CERTIFICATE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a filled ECG machine certificate (.docx) for [session].
  static Future<String> generateEcgMachineCertificate(
      CalibrationSession session) async {
    final ByteData data = await rootBundle.load('assets/ECG_certificate.docx');
    final Uint8List templateBytes = data.buffer.asUint8List();
    final Archive archive = ZipDecoder().decodeBytes(templateBytes);

    final List<ArchiveFile> newFiles = [];
    for (final file in archive) {
      if (file.name == 'word/document.xml') {
        final String xml =
            utf8.decode(file.content as List<int>, allowMalformed: true);
        final String patched = _patchEcgMachineDocument(xml, session);
        final List<int> bytes = utf8.encode(patched);
        newFiles.add(ArchiveFile(file.name, bytes.length, bytes));
      } else {
        newFiles.add(file);
      }
    }

    final Archive newArchive = Archive();
    for (final f in newFiles) newArchive.addFile(f);
    final List<int>? outBytes = ZipEncoder().encode(newArchive);
    if (outBytes == null)
      throw Exception('ECG certificate ZIP encoding failed');

    final dir = await getApplicationDocumentsDirectory();
    final String uid = const Uuid().v4().substring(0, 8);
    final String fileName = 'ecg_cert_${session.serialNumber}_$uid.docx';
    final String path = '${dir.path}/$fileName';
    await File(path).writeAsBytes(outBytes);
    return path;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD ECG MACHINE MAP
  // ═══════════════════════════════════════════════════════════════════════════

  static Map<String, String> _buildEcgMachineMap(CalibrationSession s) {
    final map = <String, String>{};

    // ── Header (shared with all certificates) ────────────────────────────
    map['{HospitalName}'] =
        s.hospitalName.isNotEmpty ? s.hospitalName : s.customerName;
    map['{Manufacturer}'] = s.manufacturer;
    map['{Model}'] = s.model;
    map['{SerialNo}'] = s.serialNumber;
    map['{Department}'] = s.department;
    map['{VisitDate}'] = _fmtDate(s.visitDate);
    map['{Visit Date}'] = _fmtDate(s.visitDate);
    map['{OrderDate}'] = _fmtDate(s.orderDate);
    map['{Order Date}'] = _fmtDate(s.orderDate);
    map['{EngineerName}'] = s.engineerName;
    map['{CertNo}'] = s.certificateNumber ?? '';
    map['{TestDeviceManufacturer}'] = s.testDeviceManufacturer;
    map['{TestDeviceMfr}'] = s.testDeviceManufacturer;
    map['{TestDeviceModel}'] = s.testDeviceModel;
    map['{TestDeviceSerialNo}'] = s.testDeviceSerialNumber;
    map['{TestDeviceSerialNumber}'] = s.testDeviceSerialNumber;
    map['{TestType}'] = s.testType;
    map['{TestLab}'] = s.testLab;
    map['{LabName}'] = s.testLab;
    map['{Final_Qualitative}'] = s.qualitativeResult ?? 'N/F';
    map['{Final_Quantitative}'] = s.quantitativeResult ?? 'N/F';
    map['{Final}'] = s.overallResult ?? 'N/F';
    map['{QualResult}'] = s.qualitativeResult ?? 'N/F';
    map['{QuantResult}'] = s.quantitativeResult ?? 'N/F';
    map['{OverallResult}'] = s.overallResult ?? 'N/F';

    // ── Qualitative — Visual Inspection ──────────────────────────────────
    final q = s.qualitativeResults;
    map['{Cha}'] = _qs(q['Chassis/Housing']);
    map['{Con}'] = _qs(q['Controls /Switches']);
    map['{Mou}'] = _qs(q['Mount']);
    map['{ECG}'] = _qs(q['10 ECG Electrodes/Leads']);
    map['{Cas}'] = _qs(q['Casters/Brakes']);
    map['{Batt}'] = _qs(q['Battery/charger']);
    map['{AC}'] = _qs(q['AC plug']);
    map['{Ind}'] = _qs(q['Indicator/Displays']);
    map['{Lin}'] = _qs(q['Line Cord']);
    map['{Lab}'] = _qs(q['Labeling']);
    map['{Cab}'] = _qs(q['Cables']);
    map['{Pap}'] = _qs(q['Printer & papers']);
    map['{Scr}'] = _qs(q['Screen']);
    map['{Rep}'] = _qs(
        q['Representation of Standard signals (Triangle, Square, Sinusoid)']);
    map['{Pri}'] = _qs(q['Printing ECG waveform']);
    map['{Wav}'] = _qs(q[
        'Represent ECG waveforms with different Amplitudes 0.5, 1,1.5,2,2.5,3,3.5']);

    // ── Qualitative — ECG Arrhythmia ─────────────────────────────────────
    map['{Atr}'] = _qs(q['Atrial Fibrillation']);
    map['{Pre_v}'] = _qs(q['Premature ventricle contraction']);
    map['{Ven}'] = _qs(q['Ventricle Fibrillation']);
    map['{Par}'] = _qs(q['Paroxysmal Atrial Tachycardia (PAT)']);
    map['{Atr_flu}'] = _qs(q['Atrial Flutter']);
    map['{Pol}'] = _qs(q['Polymorphic Ventricular Tachycardia (PVT)']);

    // ── Quantitative — Heart Rate Measurement ────────────────────────────
    const settings = EcgMachineConstants.hrSettings;
    const ranges = EcgMachineConstants.hrAcceptedRanges;
    final suffixes = ['40', '60', '80', '100', '150', '200'];

    for (int i = 0; i < settings.length; i++) {
      final String suf = suffixes[i];
      final double setting = settings[i];
      final List<double> accepted = ranges[i];
      final String accStr = '(${accepted[0]}  -  ${accepted[1]})';

      final MeasurementRow? row =
          i < s.ecgMachineHrRows.length ? s.ecgMachineHrRows[i] : null;

      if (row == null) {
        map['{hea_set_$suf}'] = setting.toStringAsFixed(0);
        map['{hea_avg_$suf}'] = 'N/A';
        map['{hea_err_$suf}'] = 'N/A';
        map['{hea_acc_$suf}'] = accStr;
        map['{hea_sta_$suf}'] = 'N/A';
        map['{hea_unc_$suf}'] = 'N/A';
      } else {
        final double avg = row.computedAverage;
        final double err = (setting - avg).abs();
        map['{hea_set_$suf}'] = setting.toStringAsFixed(0);
        map['{hea_avg_$suf}'] = avg.toStringAsFixed(2);
        map['{hea_err_$suf}'] = err.toStringAsFixed(2);
        map['{hea_acc_$suf}'] = accStr;
        map['{hea_sta_$suf}'] = row.status == true
            ? 'PASS'
            : row.status == false
                ? 'FAIL'
                : 'N/A';
        map['{hea_unc_$suf}'] = _typeA(row.reads, decimals: 4);
      }
    }

    return map;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PATCH ECG MACHINE DOCUMENT
  // ═══════════════════════════════════════════════════════════════════════════

  static String _patchEcgMachineDocument(String xml, CalibrationSession s) {
    return _collapseAndReplace(xml, _buildEcgMachineMap(s));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENERATE INFUSION PUMP CERTIFICATE
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<String> generateInfusionCertificate(
      CalibrationSession session) async {
    final ByteData data =
        await rootBundle.load('assets/infusion_certificate.docx');
    final Uint8List templateBytes = data.buffer.asUint8List();
    final Archive archive = ZipDecoder().decodeBytes(templateBytes);
    final List<ArchiveFile> newFiles = [];
    for (final file in archive) {
      if (file.name == 'word/document.xml') {
        final String xml =
            utf8.decode(file.content as List<int>, allowMalformed: true);
        final List<int> bytes =
            utf8.encode(_collapseAndReplace(xml, _buildInfusionMap(session)));
        newFiles.add(ArchiveFile(file.name, bytes.length, bytes));
      } else {
        newFiles.add(file);
      }
    }
    final Archive newArchive = Archive();
    for (final f in newFiles) newArchive.addFile(f);
    final List<int>? outBytes = ZipEncoder().encode(newArchive);
    if (outBytes == null)
      throw Exception('Infusion certificate ZIP encoding failed');
    final dir = await getApplicationDocumentsDirectory();
    final String uid = const Uuid().v4().substring(0, 8);
    final String path =
        '${dir.path}/infusion_cert_${session.serialNumber}_$uid.docx';
    await File(path).writeAsBytes(outBytes);
    return path;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD INFUSION MAP
  // ═══════════════════════════════════════════════════════════════════════════

  static Map<String, String> _buildInfusionMap(CalibrationSession s) {
    final map = <String, String>{};

    // ── Header ────────────────────────────────────────────────────────────
    map['{HospitalName}'] =
        s.hospitalName.isNotEmpty ? s.hospitalName : s.customerName;
    map['{Manufacturer}'] = s.manufacturer;
    map['{Model}'] = s.model;
    map['{SerialNo}'] = s.serialNumber;
    map['{Department}'] = s.department;
    map['{VisitDate}'] = _fmtDate(s.visitDate);
    map['{Visit Date}'] = _fmtDate(s.visitDate);
    map['{OrderDate}'] = _fmtDate(s.orderDate);
    map['{Order Date}'] = _fmtDate(s.orderDate);
    map['{EngineerName}'] = s.engineerName;
    map['{CertNo}'] = s.certificateNumber ?? '';
    map['{TestDeviceManufacturer}'] = s.testDeviceManufacturer;
    map['{TestDeviceMfr}'] = s.testDeviceManufacturer;
    map['{TestDeviceModel}'] = s.testDeviceModel;
    map['{TestDeviceSerialNo}'] = s.testDeviceSerialNumber;
    map['{TestDeviceSerialNumber}'] = s.testDeviceSerialNumber;
    map['{TestType}'] = s.testType;
    map['{TestLab}'] = s.testLab;
    map['{LabName}'] = s.testLab;
    map['{Final_Qualitative}'] = s.qualitativeResult ?? 'N/F';
    map['{Final_Quantitative}'] = s.quantitativeResult ?? 'N/F';
    map['{Final}'] = s.overallResult ?? 'N/F';
    map['{QualResult}'] = s.qualitativeResult ?? 'N/F';
    map['{QuantResult}'] = s.quantitativeResult ?? 'N/F';
    map['{OverallResult}'] = s.overallResult ?? 'N/F';

    // ── Qualitative ───────────────────────────────────────────────────────
    final q = s.qualitativeResults;
    map['{Cha}'] = _qs(q['Chassis/Housing']);
    map['{Con}'] = _qs(q['Controls /Switches']);
    map['{Mou}'] = _qs(q['Mount']);
    map['{Doo}'] = _qs(q['Door/Misloaded Infusion Set']);
    map['{Cas}'] = _qs(q['Casters/Brakes']);
    map['{Bat}'] = _qs(q['Battery/charger']);
    map['{AC}'] = _qs(q['AC plug']);
    map['{Ind}'] = _qs(q['Indicator/Displays']);
    map['{Lin}'] = _qs(q['Line Cord']);
    map['{Lab}'] = _qs(q['Labeling']);
    map['{Cab}'] = _qs(q['Cables']);
    map['{Air}'] = _qs(q['Air-in-Line']);
    map['{Scr}'] = _qs(q['Screen']);
    map['{Emp}'] = _qs(q['Empty Container']);
    map['{Flo}'] = _qs(q['Flow-Stop Mechanism(s)']);
    map['{Inf}'] = _qs(q['Infusion Complete']);

    // ── Quantitative — Flow Rate ─────────────────────────────────────────
    const settings = InfusionConstants.flowSettings;
    const ranges = InfusionConstants.flowAcceptedRanges;
    final suffixes = ['30', '60', '100', '240', '300', '600'];

    for (int i = 0; i < settings.length; i++) {
      final String suf = suffixes[i];
      final double setting = settings[i];
      final String accStr = '(${ranges[i][0]}  -  ${ranges[i][1]})';
      final MeasurementRow? row =
          i < s.infusionFlowRows.length ? s.infusionFlowRows[i] : null;
      if (row == null) {
        map['{set_$suf}'] = setting.toStringAsFixed(0);
        map['{avg_$suf}'] = 'N/A';
        map['{err_$suf}'] = 'N/A';
        map['{acc_$suf}'] = accStr;
        map['{sta_$suf}'] = 'N/A';
        map['{unc_$suf}'] = 'N/A';
      } else {
        final double avg = row.computedAverage;
        final double errPct =
            setting > 0 ? (setting - avg).abs() / setting * 100 : 0;
        map['{set_$suf}'] = setting.toStringAsFixed(0);
        map['{avg_$suf}'] = avg.toStringAsFixed(3);
        map['{err_$suf}'] = errPct.toStringAsFixed(2);
        map['{acc_$suf}'] = accStr;
        map['{sta_$suf}'] = row.status == true
            ? 'PASS'
            : row.status == false
                ? 'FAIL'
                : 'N/A';
        map['{unc_$suf}'] = _typeA(row.reads, decimals: 4);
      }
    }

    // ── Quantitative — Occlusion ─────────────────────────────────────────
    final OcclusionRow? peakRow =
        s.infusionOcclusionRows.isNotEmpty ? s.infusionOcclusionRows[0] : null;
    final OcclusionRow? timeRow =
        s.infusionOcclusionRows.length > 1 ? s.infusionOcclusionRows[1] : null;

    if (peakRow == null) {
      map['{occ_avg_peak}'] = 'N/A';
      map['{occ_sta_peak}'] = 'N/A';
      map['{occ_unc_peak}'] = 'N/A';
    } else {
      final double avg = peakRow.computedAverage;
      map['{occ_avg_peak}'] = avg.toStringAsFixed(2);
      map['{occ_sta_peak}'] = peakRow.status == true
          ? 'PASS'
          : peakRow.status == false
              ? 'FAIL'
              : 'N/A';
      map['{occ_unc_peak}'] = _typeA(peakRow.reads, decimals: 4);
    }

    if (timeRow == null) {
      map['{occ_avg_time}'] = 'N/A';
      map['{occ_sta_time}'] = 'N/A';
      map['{occ_unc_time}'] = 'N/A';
    } else {
      final double avg = timeRow.computedAverage;
      map['{occ_avg_time}'] = avg.toStringAsFixed(2);
      map['{occ_sta_time}'] = timeRow.status == true
          ? 'PASS'
          : timeRow.status == false
              ? 'FAIL'
              : 'N/A';
      map['{occ_unc_time}'] = _typeA(timeRow.reads, decimals: 4);
    }

    return map;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PATCH DOCUMENT
  // ═══════════════════════════════════════════════════════════════════════════

  static String _patchDocument(String xml, CalibrationSession s) {
    final Map<String, String> replacements = _buildMap(s);

    // Word splits placeholders like {Cha} across runs with different rPr.
    // Strategy: within each <w:p>, collapse ALL run text into the first run,
    // do replacements, then restore.
    String doc = _collapseAndReplace(xml, replacements);

    return doc;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COLLAPSE RUNS, REPLACE, RESTORE
  // ═══════════════════════════════════════════════════════════════════════════

  static String _collapseAndReplace(
      String xml, Map<String, String> replacements) {
    final paraRe = RegExp(r'<w:p[ >].*?</w:p>', dotAll: true);

    return xml.replaceAllMapped(paraRe, (m) {
      final String para = m.group(0)!;

      // Collect all <w:t> text values in order (ignoring pPr content)
      final tRe = RegExp(r'<w:t(?:[^>]*)>(.*?)</w:t>', dotAll: true);
      final fullText = tRe.allMatches(para).map((r) => r.group(1)!).join();

      // Check if this paragraph contains any placeholder
      bool hasPlaceholder = false;
      for (final key in replacements.keys) {
        if (fullText.contains(_unesc(key))) {
          hasPlaceholder = true;
          break;
        }
      }
      if (!hasPlaceholder) return para;

      // Apply replacements to the full text
      String replaced = fullText;
      for (final entry in replacements.entries) {
        replaced = replaced.replaceAll(_unesc(entry.key), _unesc(entry.value));
      }

      // Split paragraph into pPr part and runs part
      // pPr always comes before any <w:r>
      final pPrRe = RegExp(r'^(.*?)(<w:r[ >])', dotAll: true);
      final pPrMatch = pPrRe.firstMatch(para);
      final String beforeRuns = pPrMatch != null ? pPrMatch.group(1)! : '';
      // Everything from the closing tag of the paragraph
      final String paraClose = '</w:p>';

      // Only match runs (not pPr)
      final runRe = RegExp(r'<w:r(?:[ >]).*?</w:r>', dotAll: true);
      final runs = runRe.allMatches(para).toList();
      if (runs.isEmpty) return para;

      // Use first run's rPr for the merged run
      final firstRun = runs.first.group(0)!;
      final rPrRe = RegExp(r'<w:rPr>.*?</w:rPr>', dotAll: true);
      final rPr = rPrRe.firstMatch(firstRun)?.group(0) ?? '';
      final space =
          replaced.startsWith(' ') || replaced.endsWith(' ') ? ' preserve' : '';
      final newRun =
          '<w:r>$rPr<w:t xml:space="$space">${_esc(replaced)}</w:t></w:r>';

      // Rebuild: pPr + single merged run + </w:p>
      return '$beforeRuns$newRun$paraClose';
    });
  }

  // ── Unescape XML entities back to plain text ──────────────────────────────
  static String _unesc(String v) => v
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// ItemStatus → short label for the certificate
  static String _qs(ItemStatus? s) {
    if (s == null) return 'N/A';
    switch (s) {
      case ItemStatus.pass:
        return 'Pass';
      case ItemStatus.fail:
        return 'Fail';
      case ItemStatus.notAvailable:
        return 'N/A';
    }
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '--/--/----';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Type A uncertainty of the mean: s / sqrt(n)
  static String _typeA(List<double> reads, {int decimals = 4}) {
    if (reads.length < 2) return '0.${'0' * decimals}';
    final double mean = reads.reduce((a, b) => a + b) / reads.length;
    double sumSq = 0;
    for (final r in reads) {
      sumSq += (r - mean) * (r - mean);
    }
    final double s = _sqrt(sumSq / (reads.length - 1));
    return (s / _sqrt(reads.length.toDouble())).toStringAsFixed(decimals);
  }

  static double _sqrt(double v) {
    if (v <= 0) return 0;
    double x = v;
    for (int i = 0; i < 50; i++) {
      x = (x + v / x) / 2;
    }
    return x;
  }

  /// Escape XML special characters
  static String _esc(String v) => v
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
