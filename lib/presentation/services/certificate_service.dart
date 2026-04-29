// lib/presentation/services/certificate_service.dart
//
// Fills assets/monitor_certificate.docx by replacing {Key} placeholders
// with real session data, then re-zips and saves the result.
//
// ── Qualitative Table Keys (from template image) ─────────────────────────────
//  Visual Inspection:
//   {Cha} Chassis/Housing      {Con} Controls/Switches
//   {Mou} Mount                {Bat} Battery/charger
//   {Cas} Casters/Brakes       {Ind} Indicator/Displays
//   {AC}  AC plug              {Lab} Labeling
//   {Lin} Line Cord            {Ala} Alarms
//   {Scr} Screen               {Hou} Module Housing
//   {SPO} SPO2 cable           {Tro} Mounting/Trolley
//  ECG Representation:
//   {Atr} Atrial Fibrillation  {Prem} Premature ventricle contraction
//   {Ven} Ventricle Fibrillation {Paro} Paroxysmal Atrial Tachycardia
//   {Atrf} Atrial Flutter      {Poly} Polymorphic Ventricular Tachycardia
//   {Rep} Representation of Standard signals
//   {ECG} Represent ECG waveforms with different Amplitudes
//
// ── Header / Info Keys ────────────────────────────────────────────────────────
//   {HospitalName}  customer / hospital name
//   {Manufacturer}  device manufacturer
//   {Model}         device model
//   {SerialNo}      serial number
//   {Department}    department
//   {VisitDate}     visit date  dd/mm/yyyy
//   {OrderDate}     order date  dd/mm/yyyy
//   {EngineerName}  engineer full name
//   {CertNo}        certificate number
//   {Final_Qualitative} qualitative result  (PASS / FAIL / N/F)
//   {Final_Quantitative} quantitative result (PASS / FAIL / N/F)
//   {Final}             combined result — AND of both (PASS / FAIL / N/F)
//
// ── Measurement Table Keys ────────────────────────────────────────────────────
//  Heart Rate rows (6 rows × 4 cols):
//   {HR1_Avg} {HR1_Err} {HR1_Unc} {HR1_Sta}  ... {HR6_Sta}
//  SPO2 rows (5 rows):
//   {SP1_Avg} {SP1_Err} {SP1_Unc} {SP1_Sta}  ... {SP5_Sta}
//  NIBP rows (6 pairs × sys+dia, defaults: sys=60,80,100,120,180,240 / dia=30,40,60,80,140,200):
//   Value-based:  {NIBP_S_Set60} {NIBP_S_Avg60} {NIBP_S_Err60} {NIBP_S_Acc60} {NIBP_S_Sta60} {NIBP_S_Unc60}
//                 {NIBP_D_Set30} {NIBP_D_Avg30} {NIBP_D_Err30} {NIBP_D_Acc30} {NIBP_D_Sta30} {NIBP_D_Unc30}
//   Index-based:  {NIBP_S_Set1}  {NIBP_S_Avg1}  {NIBP_S_Err1}  {NIBP_S_Acc1}  {NIBP_S_Sta1}  {NIBP_S_Unc1}
//                 {NIBP_D_Set1}  {NIBP_D_Avg1}  {NIBP_D_Err1}  {NIBP_D_Acc1}  {NIBP_D_Sta1}  {NIBP_D_Unc1}
//                 ... rows 1–6
//   Legacy aliases also populated: {Set_Sys60}, {Set_Dia30}
//  Respiration rows (4 rows):
//   {RR1_Avg} {RR1_Err} {RR1_Unc} {RR1_Sta}  ... {RR4_Sta}
//  Temperature sensor 1 (3 rows: 33, 37, 41 °C):
//   {Tem_Set33} {Tem_Avg33} {Tem_Err33} {Tem_Acc33} {Tem_Sta33} {Tem_Unc33}
//   {Tem_Set37} {Tem_Avg37} {Tem_Err37} {Tem_Acc37} {Tem_Sta37} {Tem_Unc37}
//   {Tem_Set41} {Tem_Avg41} {Tem_Err41} {Tem_Acc41} {Tem_Sta41} {Tem_Unc41}
//  Temperature sensor 2 (3 rows: 33, 37, 41 °C):
//   {Tem2_Set33} {Tem2_Avg33} {Tem2_Err33} {Tem2_Acc33} {Tem2_Sta33} {Tem2_Unc33}
//   {Tem2_Set37} {Tem2_Avg37} {Tem2_Err37} {Tem2_Acc37} {Tem2_Sta37} {Tem2_Unc37}
//   {Tem2_Set41} {Tem2_Avg41} {Tem2_Err41} {Tem2_Acc41} {Tem2_Sta41} {Tem2_Unc41}

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
        final String xml = String.fromCharCodes(file.content as List<int>);
        final String patched = _patchDocument(xml, session);
        final List<int> bytes = patched.codeUnits;
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
    map['{OrderDate}'] = _fmtDate(s.orderDate);
    map['{EngineerName}'] = s.engineerName;
    map['{CertNo}'] = s.certificateNumber ?? '';

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
      if (!hr || row == null) {
        map['{Heart_set$defaultBpm}'] = defaultBpm.toString();
        map['{Heart_Ave$defaultBpm}'] = 'N/A';
        map['{Heart_Error$defaultBpm}'] = 'N/A';
        map['{Heart_Acc$defaultBpm}'] = 'N/A';
        map['{Heart_Sta$defaultBpm}'] = 'N/A';
        map['{Heart_unc$defaultBpm}'] = 'N/A';
      } else {
        final double avg = row.computedAverage;
        final double err = (row.settingValue - avg).abs();
        final range = MonitorConstants.hrAcceptedRange(row.settingValue);
        // Map both the default key and the actual key (in case user changed the value)
        for (final key in {defaultBpm, bpm}) {
          map['{Heart_set$key}'] = bpm.toString();
          map['{Heart_Ave$key}'] = avg.toStringAsFixed(2);
          map['{Heart_Error$key}'] = err.toStringAsFixed(2);
          map['{Heart_Acc$key}'] = '${range[0].toStringAsFixed(1)} - ${range[1].toStringAsFixed(1)}';
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
      if (!sp || row == null) {
        map['{SPO2_Set$defaultVal}'] = defaultVal.toString();
        map['{SPO2_Avg$defaultVal}'] = 'N/A';
        map['{SPO2_Err$defaultVal}'] = 'N/A';
        map['{SPO2_Acc$defaultVal}'] = 'N/A';
        map['{SPO2_Sta$defaultVal}'] = 'N/A';
        map['{SPO2_Unc$defaultVal}'] = 'N/A';
      } else {
        final double avg = row.computedAverage;
        final double err = (row.settingValue - avg).abs();
        final range = MonitorConstants.spo2AcceptedRange(row.settingValue);
        for (final key in {defaultVal, val}) {
          map['{SPO2_Set$key}'] = val.toString();
          map['{SPO2_Avg$key}'] = avg.toStringAsFixed(2);
          map['{SPO2_Err$key}'] = err.toStringAsFixed(2);
          map['{SPO2_Acc$key}'] =
              '${range[0].toStringAsFixed(1)} - ${range[1].toStringAsFixed(1)}';
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

      if (!nb || row == null) {
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
        final sysAcc = '${sysRange[0].toStringAsFixed(1)} - ${sysRange[1].toStringAsFixed(1)}';
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
        final diaAcc = '${diaRange[0].toStringAsFixed(1)} - ${diaRange[1].toStringAsFixed(1)}';
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
      if (!rr || row == null) {
        map['{Resp_Set$defaultBpm}'] = defaultBpm.toString();
        map['{Resp_Avg$defaultBpm}'] = 'N/A';
        map['{Resp_Err$defaultBpm}'] = 'N/A';
        map['{Resp_Acc$defaultBpm}'] = 'N/A';
        map['{Resp_Sta$defaultBpm}'] = 'N/A';
        map['{Resp_Unc$defaultBpm}'] = 'N/A';
      } else {
        final double avg = row.computedAverage;
        final double err = (row.settingValue - avg).abs();
        final range = MonitorConstants.respirationAcceptedRange(row.settingValue);
        for (final key in {defaultBpm, bpm}) {
          map['{Resp_Set$key}'] = bpm.toString();
          map['{Resp_Avg$key}'] = avg.toStringAsFixed(2);
          map['{Resp_Err$key}'] = err.toStringAsFixed(2);
          map['{Resp_Acc$key}'] =
              '${range[0].toStringAsFixed(1)} - ${range[1].toStringAsFixed(1)}';
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
      if (!tm || row == null) {
        map['{Tem_Set$defaultVal}'] = defaultVal.toString();
        map['{Tem_Avg$defaultVal}'] = 'N/A';
        map['{Tem_Err$defaultVal}'] = 'N/A';
        map['{Tem_Acc$defaultVal}'] = 'N/A';
        map['{Tem_Sta$defaultVal}'] = 'N/A';
        map['{Tem_Unc$defaultVal}'] = 'N/A';
      } else {
        final double avg = row.computedAverage;
        final double err = (row.settingValue - avg).abs();
        final range = MonitorConstants.tempAcceptedRange(row.settingValue);
        for (final key in {defaultVal, val}) {
          map['{Tem_Set$key}'] = val.toString();
          map['{Tem_Avg$key}'] = avg.toStringAsFixed(3);
          map['{Tem_Err$key}'] = err.toStringAsFixed(3);
          map['{Tem_Acc$key}'] =
              '${range[0].toStringAsFixed(2)} - ${range[1].toStringAsFixed(2)}';
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
      if (!tm || row == null) {
        map['{Tem2_Set$defaultVal}'] = defaultVal.toString();
        map['{Tem2_Avg$defaultVal}'] = 'N/A';
        map['{Tem2_Err$defaultVal}'] = 'N/A';
        map['{Tem2_Acc$defaultVal}'] = 'N/A';
        map['{Tem2_Sta$defaultVal}'] = 'N/A';
        map['{Tem2_Unc$defaultVal}'] = 'N/A';
      } else {
        final double avg = row.computedAverage;
        final double err = (row.settingValue - avg).abs();
        final range = MonitorConstants.tempAcceptedRange(row.settingValue);
        for (final key in {defaultVal, val}) {
          map['{Tem2_Set$key}'] = val.toString();
          map['{Tem2_Avg$key}'] = avg.toStringAsFixed(3);
          map['{Tem2_Err$key}'] = err.toStringAsFixed(3);
          map['{Tem2_Acc$key}'] =
              '${range[0].toStringAsFixed(2)} - ${range[1].toStringAsFixed(2)}';
          map['{Tem2_Sta$key}'] =
              row.status == true ? 'PASS' : row.status == false ? 'FAIL' : 'N/A';
          map['{Tem2_Unc$key}'] = _typeA(row.reads, decimals: 4);
        }
      }
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
