// lib/presentation/services/certificate_service.dart
//
// Generates a filled .docx from assets/monitor_certificate.docx by:
//   1. Unzipping the asset (docx = ZIP)
//   2. Patching word/document.xml (text replacements + cell injection by paraId)
//   3. Re-zipping and saving to the app documents directory.
//
// Template placeholder map:
// ┌─────────────────────┬───────────────────────────────────────────────────┐
// │ Template text       │ Replaced with                                     │
// ├─────────────────────┼───────────────────────────────────────────────────┤
// │ UMECC xxx /         │ UMECC <certNo left part> /                        │
// │ xxxx ( xx pages)    │ <certNo right part> ( N pages)                    │
// │ (UMECCxxx/xxxx:...) │ page footer on every page                         │
// │ xxxxx               │ hospital name (blue bold cell)                    │
// │ xxxx (1st)          │ manufacturer                                      │
// │ xxxx (2nd)          │ model                                             │
// │ xxxx (3rd, yellow)  │ serial number                                     │
// │ xxxx (4th)          │ qualitative overall result                        │
// │ xxxx (5th)          │ quantitative overall result                       │
// │ xxxx (6th)          │ combined overall result                           │
// │ Xx/xx/xxxx          │ test date (all occurrences)                       │
// │ م / -------         │ م / <engineer name> (all page footers)            │
// └─────────────────────┴───────────────────────────────────────────────────┘
//
// Measurement cells are injected by unique w14:paraId attributes extracted
// directly from the unpacked template XML (no run-time re-analysis needed).

import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/models.dart';

class CertificateService {
  // ═══════════════════════════════════════════════════════════════════════════
  // PUBLIC API
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate a filled certificate for [session].
  /// Returns the absolute path of the written .docx file.
  static Future<String> generateCertificate(CalibrationSession session) async {
    // Load template bytes from Flutter assets
    final ByteData data =
        await rootBundle.load('assets/monitor_certificate.docx');
    final Uint8List templateBytes = data.buffer.asUint8List();

    // Decode ZIP
    final Archive archive = ZipDecoder().decodeBytes(templateBytes);

    // Patch document.xml
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

    // Re-encode as ZIP
    final Archive newArchive = Archive();
    for (final f in newFiles) {
      newArchive.addFile(f);
    }
    final List<int>? outBytes = ZipEncoder().encode(newArchive);
    if (outBytes == null) throw Exception('Certificate ZIP encoding failed');

    // Write to disk
    final dir = await getApplicationDocumentsDirectory();
    final String id = const Uuid().v4().substring(0, 8);
    final String fileName = 'cert_${session.serialNumber}_$id.docx';
    final String path = '${dir.path}/$fileName';
    await File(path).writeAsBytes(outBytes);
    return path;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE PATCH
  // ═══════════════════════════════════════════════════════════════════════════

  static String _patchDocument(String xml, CalibrationSession s) {
    String doc = xml;

    // ── Certificate number & page footers ────────────────────────────────────
    final String certNo = s.certificateNumber ?? 'XXX/XXXX';
    final List<String> cnParts = certNo.split('/');
    final String cnLeft = cnParts.first.trim();
    final String cnRight = cnParts.length > 1 ? cnParts.last.trim() : 'XXXX';
    const String totalPages = '4';

    doc = doc.replaceAll('UMECC xxx /', 'UMECC $cnLeft /');
    doc = doc.replaceAll('xxxx ( xx pages)', '$cnRight ( $totalPages pages)');
    doc = doc.replaceAll(
        ' (UMECCxxx/xxxx: Page1/xx)', ' (UMECC$certNo: Page1/$totalPages)');
    doc = doc.replaceAll(
        '(UMECC xx/xxxx: Page2/xx)', '(UMECC$certNo: Page2/$totalPages)');
    doc = doc.replaceAll(
        '(UMECC xx/xxxx: Page3/xx)', '(UMECC$certNo: Page3/$totalPages)');
    doc = doc.replaceAll(
        '(UMECC xx/xxxx: Page4/xx)', '(UMECC$certNo: Page4/$totalPages)');

    // ── Test date (all occurrences of Xx/xx/xxxx) ────────────────────────────
    doc = doc.replaceAll('Xx/xx/xxxx', _fmt(s.testDate));

    // ── Engineer name (all page footers) ────────────────────────────────────
    doc = doc.replaceAll('م / -------', 'م / ${s.engineerName}');
    doc = doc.replaceAll('م /--------', 'م / ${s.engineerName}');
    doc = doc.replaceAll('م/ ---------', 'م / ${s.engineerName}');

    // ── Hospital / customer (XXXXX large blue cell) ──────────────────────────
    doc = doc.replaceAll('xxxxx', _esc(s.hospitalName));

    // ── Device fields: 3 sequential 'xxxx' occurrences in device table ───────
    doc = _replaceNth(
        doc, '<w:t>xxxx</w:t>', 1, '<w:t>${_esc(s.manufacturer)}</w:t>');
    doc = _replaceNth(doc, '<w:t>xxxx</w:t>', 1, '<w:t>${_esc(s.model)}</w:t>');
    doc = _replaceNth(
        doc, '<w:t>xxxx</w:t>', 1, '<w:t>${_esc(s.serialNumber)}</w:t>');

    // ── Result table: qualitative, quantitative, overall result ──────────────
    final String qualRes = (s.qualitativeResult?.isNotEmpty == true)
        ? s.qualitativeResult!
        : 'PASS';
    final String quantRes = (s.quantitativeResult?.isNotEmpty == true)
        ? s.quantitativeResult!
        : 'PASS';
    final String overallRes = s.overallResult == 'PASS' ? 'PASS' : 'FAIL';

    doc = _replaceNth(doc, '<w:t>xxxx</w:t>', 1, '<w:t>$qualRes</w:t>');
    doc = _replaceNth(doc, '<w:t>xxxx</w:t>', 1, '<w:t>$quantRes</w:t>');
    doc = _replaceNth(doc, '<w:t>xxxx</w:t>', 1, '<w:t>$overallRes</w:t>');

    // Remaining stray xxxx → dash
    doc = doc.replaceAll('<w:t>xxxx</w:t>', '<w:t>-</w:t>');

    // ── Qualitative rows ──────────────────────────────────────────────────────
    final q = s.qualitativeResults;
    final e = s.ecgRepresentation;

    // Visual Inspection (paraId layout per row: [rowId, itemL_para, statusL, itemR_para, statusR])
    doc = _para(doc, '1198940D', _qs(q['Chassis/Housing']));
    doc = _para(doc, '02006B54', _qs(q['Controls /Switches']));
    doc = _para(doc, '2EFD8B61', _qs(q['Mount']));
    doc = _para(doc, '4E8B4941', _qs(q['Battery/charger']));
    doc = _para(doc, '1605DCD3', _qs(q['Casters/Brakes']));
    doc = _para(doc, '54231E35', _qs(q['Indicator/Displays']));
    doc = _para(doc, '59D2CE67', _qs(q['AC plug']));
    doc = _para(doc, '02E3CC1C', _qs(q['Labeling']));
    doc = _para(doc, '1B881361', _qs(q['Line Cord']));
    doc = _para(doc, '4190811B', _qs(q['Alarms']));
    doc = _para(doc, '29AE7E4C', _qs(q['Screen']));
    doc = _para(doc, '177A8D0F', _qs(q['Module Housing']));
    doc = _para(doc, '6D823AB8', _qs(q['SPO2 cable']));
    doc = _para(doc, '609C1DFA', _qs(q['Mounting/Trolley']));

    // ECG Representation
    doc = _para(doc, '64A76E59', _qs(e['Atrial Fibrillation']));
    doc = _para(doc, '0F19D85D', _qs(e['Premature ventricle contraction']));
    doc = _para(doc, '316BC411', _qs(e['Ventricle Fibrillation']));
    doc = _para(doc, '523CDB93', _qs(e['Paroxysmal Atrial Tachycardia (PAT)']));
    doc = _para(doc, '78B0C063', _qs(e['Atrial Flutter']));
    doc = _para(
        doc, '179754A4', _qs(e['Polymorphic Ventricular Tachycardia (PVT)']));
    doc = _para(
        doc,
        '77871EBC',
        _qs(e[
            'Representation of Standard signals (Triangle, Square, Sinusoid)']));
    doc = _para(
        doc,
        '137777A0',
        _qs(e[
            'Represent ECG waveforms with different Amplitudes 0.5, 1,1.5,2,2.5,3,3.5']));

    // ── Heart Rate ────────────────────────────────────────────────────────────
    final bool hr = s.showHrTable;
    final List<MeasurementRow> hrRows = s.hrRows;
    doc = _measRow(doc, hr && hrRows.isNotEmpty ? hrRows[0] : null,
        avg: '0721C277',
        err: '352E0F5F',
        sta: '697B3582',
        unc: '36C0A367',
        vis: hr);
    doc = _measRow(doc, hr && hrRows.length > 1 ? hrRows[1] : null,
        avg: '24403607',
        err: '4E656968',
        sta: '725EEF2D',
        unc: '3F0A9885',
        vis: hr);
    doc = _measRow(doc, hr && hrRows.length > 2 ? hrRows[2] : null,
        avg: '19085E37',
        err: '71131B20',
        sta: '1AE89D75',
        unc: '68ED52B0',
        vis: hr);
    doc = _measRow(doc, hr && hrRows.length > 3 ? hrRows[3] : null,
        avg: '3B22019C',
        err: '22A49125',
        sta: '09471107',
        unc: '0664E7ED',
        vis: hr);
    doc = _measRow(doc, hr && hrRows.length > 4 ? hrRows[4] : null,
        avg: '062B76EA',
        err: '4C7D9DB1',
        sta: '3DCA4F84',
        unc: '1559564B',
        vis: hr);
    doc = _measRow(doc, hr && hrRows.length > 5 ? hrRows[5] : null,
        avg: '3471BF9F',
        err: '0AD108D0',
        sta: '45874329',
        unc: '71284984',
        vis: hr);

    // ── Respiration ───────────────────────────────────────────────────────────
    final bool rr = s.showRespirationTable;
    final List<MeasurementRow> rrRows = s.respirationRows;
    doc = _measRow(doc, rr && rrRows.isNotEmpty ? rrRows[0] : null,
        avg: '32C9FECC',
        err: '0A40B074',
        sta: '0BCD65DB',
        unc: '61C9495D',
        vis: rr);
    doc = _measRow(doc, rr && rrRows.length > 1 ? rrRows[1] : null,
        avg: '39A62618',
        err: '36102F40',
        sta: '3C684369',
        unc: '06EED78F',
        vis: rr);
    doc = _measRow(doc, rr && rrRows.length > 2 ? rrRows[2] : null,
        avg: '166F2289',
        err: '408C90E6',
        sta: '677240AE',
        unc: '25283226',
        vis: rr);
    doc = _measRow(doc, rr && rrRows.length > 3 ? rrRows[3] : null,
        avg: '112492A5',
        err: '431A8667',
        sta: '669E0904',
        unc: '57CCD151',
        vis: rr);

    // ── NIBP ──────────────────────────────────────────────────────────────────
    final bool nb = s.showNibpTable;
    final List<NIBPRow> nbRows = s.nibpRows;
    // Each NIBPRow covers one systolic+diastolic pair (two template rows)
    doc = _nibpRow(doc, nb && nbRows.isNotEmpty ? nbRows[0] : null,
        avg: '7E1124CC', err: '72BDB093', sta: '5599C6E3', vis: nb, sys: true);
    doc = _nibpRow(doc, nb && nbRows.isNotEmpty ? nbRows[0] : null,
        avg: '071142CB', err: '3C3C26B6', sta: '3EB1A636', vis: nb, sys: false);
    doc = _nibpRow(doc, nb && nbRows.length > 1 ? nbRows[1] : null,
        avg: '1B008381', err: '7DC1B909', sta: '6368A5B8', vis: nb, sys: true);
    doc = _nibpRow(doc, nb && nbRows.length > 1 ? nbRows[1] : null,
        avg: '50D39417', err: '5FE50C12', sta: '261E6194', vis: nb, sys: false);
    doc = _nibpRow(doc, nb && nbRows.length > 2 ? nbRows[2] : null,
        avg: '2C521C61', err: '65178B7B', sta: '76979D41', vis: nb, sys: true);
    doc = _nibpRow(doc, nb && nbRows.length > 2 ? nbRows[2] : null,
        avg: '60E319A7', err: '035C13A2', sta: '46D7D1EC', vis: nb, sys: false);
    doc = _nibpRow(doc, nb && nbRows.length > 3 ? nbRows[3] : null,
        avg: '7462815F', err: '020A161F', sta: '5A432B55', vis: nb, sys: true);
    doc = _nibpRow(doc, nb && nbRows.length > 3 ? nbRows[3] : null,
        avg: '6CCDA4DB', err: '283A5C8C', sta: '2CE00778', vis: nb, sys: false);
    doc = _nibpRow(doc, nb && nbRows.length > 4 ? nbRows[4] : null,
        avg: '70F72C55', err: '556CA620', sta: '1455D17F', vis: nb, sys: true);
    doc = _nibpRow(doc, nb && nbRows.length > 4 ? nbRows[4] : null,
        avg: '2B05CA08', err: '1824720B', sta: '11F36641', vis: nb, sys: false);

    // ── SPO2 ──────────────────────────────────────────────────────────────────
    final bool sp = s.showSpo2Table;
    final List<MeasurementRow> spRows = s.spo2Rows;
    doc = _measRow(doc, sp && spRows.isNotEmpty ? spRows[0] : null,
        avg: '2FCA6772',
        err: '02EF5BFB',
        sta: '5D36EA65',
        unc: '1ECB128A',
        vis: sp);
    doc = _measRow(doc, sp && spRows.length > 1 ? spRows[1] : null,
        avg: '21AE1A66',
        err: '2F377354',
        sta: '060736A9',
        unc: '5DC8B14F',
        vis: sp);
    doc = _measRow(doc, sp && spRows.length > 2 ? spRows[2] : null,
        avg: '672FADB0',
        err: '2B2728F5',
        sta: '7742A5C1',
        unc: '52DDCD81',
        vis: sp);
    doc = _measRow(doc, sp && spRows.length > 3 ? spRows[3] : null,
        avg: '4746BB66',
        err: '7F9011F8',
        sta: '1FBC8D04',
        unc: '1F7A8974',
        vis: sp);
    doc = _measRow(doc, sp && spRows.length > 4 ? spRows[4] : null,
        avg: '6CC27AD1',
        err: '7BEE8687',
        sta: '4659650C',
        unc: '6E865805',
        vis: sp);

    // ── Temperature MODULE 1 ──────────────────────────────────────────────────
    final bool tm = s.showTempTables;
    final List<MeasurementRow> t1 = s.temp1Rows;
    doc = _measRow(doc, tm && t1.isNotEmpty ? t1[0] : null,
        avg: '6BA78C59',
        err: '15C027AC',
        sta: '3A662509',
        unc: '7BA7A6A7',
        vis: tm);
    doc = _measRow(doc, tm && t1.length > 1 ? t1[1] : null,
        avg: '3BDFF70B',
        err: '1A15281B',
        sta: '5FD6543B',
        unc: '3C6A3F17',
        vis: tm);
    doc = _measRow(doc, tm && t1.length > 2 ? t1[2] : null,
        avg: '5E9E0087',
        err: '6E872C2F',
        sta: '4E777064',
        unc: '571F82F2',
        vis: tm);

    // ── Temperature MODULE 2 ──────────────────────────────────────────────────
    final List<MeasurementRow> t2 = s.temp2Rows;
    doc = _measRow(doc, tm && t2.isNotEmpty ? t2[0] : null,
        avg: '50D4E4C3',
        err: '1258E602',
        sta: '0148687B',
        unc: '51DCDB2C',
        vis: tm);
    doc = _measRow(doc, tm && t2.length > 1 ? t2[1] : null,
        avg: '6051FA0F',
        err: '43F300A5',
        sta: '49DECED0',
        unc: '03B0EDD6',
        vis: tm);
    doc = _measRow(doc, tm && t2.length > 2 ? t2[2] : null,
        avg: '69440E7D',
        err: '72ECD3B5',
        sta: '6D5C9F3B',
        unc: '15558117',
        vis: tm);

    return doc;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ROW FILLERS
  // ═══════════════════════════════════════════════════════════════════════════

  static String _measRow(
    String doc,
    MeasurementRow? row, {
    required String avg,
    required String err,
    required String sta,
    required String unc,
    required bool vis,
  }) {
    if (!vis || row == null) {
      doc = _para(doc, avg, 'NF');
      doc = _para(doc, err, 'NF');
      doc = _para(doc, sta, 'NF');
      doc = _para(doc, unc, '-');
    } else {
      final double a = row.computedAverage;
      final double e = (row.settingValue - a).abs();
      doc = _para(doc, avg, a.toStringAsFixed(2));
      doc = _para(doc, err, e.toStringAsFixed(2));
      doc = _para(doc, sta,
          row.status == true ? 'PASS' : (row.status == false ? 'FAIL' : 'NF'));
      doc = _para(doc, unc, _typeA(row.reads));
    }
    return doc;
  }

  static String _nibpRow(
    String doc,
    NIBPRow? row, {
    required String avg,
    required String err,
    required String sta,
    required bool vis,
    required bool sys,
  }) {
    if (!vis || row == null) {
      doc = _para(doc, avg, 'NF');
      doc = _para(doc, err, 'NF');
      doc = _para(doc, sta, 'NF');
    } else {
      final List<double> reads = sys ? row.systolicReads : row.diastolicReads;
      final double a =
          reads.isEmpty ? 0 : reads.reduce((a, b) => a + b) / reads.length;
      final double set = sys ? row.systolicSetting : row.diastolicSetting;
      final double e = (set - a).abs();
      final bool? st = sys ? row.systolicStatus : row.diastolicStatus;
      doc = _para(doc, avg, a.toStringAsFixed(1));
      doc = _para(doc, err, e.toStringAsFixed(1));
      doc =
          _para(doc, sta, st == true ? 'PASS' : (st == false ? 'FAIL' : 'NF'));
    }
    return doc;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOW-LEVEL HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Inject plain text into the empty `<w:p>` with the given w14:paraId.
  static String _para(String doc, String paraId, String value) {
    final String marker = 'w14:paraId="$paraId"';
    final int mi = doc.indexOf(marker);
    if (mi < 0) return doc;
    final int close = doc.indexOf('</w:p>', mi);
    if (close < 0) return doc;

    const String rPr = '<w:rPr>'
        '<w:rFonts w:asciiTheme="majorBidi" w:hAnsiTheme="majorBidi" w:cstheme="majorBidi"/>'
        '<w:sz w:val="24"/><w:szCs w:val="24"/>'
        '</w:rPr>';
    final String run =
        '<w:r>$rPr<w:t xml:space="preserve">${_esc(value)}</w:t></w:r>';

    return doc.substring(0, close) + run + doc.substring(close);
  }

  /// Replace the Nth occurrence of [search] with [replace].
  static String _replaceNth(String text, String search, int n, String replace) {
    int count = 0;
    int idx = 0;
    while (true) {
      idx = text.indexOf(search, idx);
      if (idx < 0) return text;
      count++;
      if (count == n) {
        return text.substring(0, idx) +
            replace +
            text.substring(idx + search.length);
      }
      idx += search.length;
    }
  }

  static String _qs(ItemStatus? s) {
    if (s == null) return '';
    switch (s) {
      case ItemStatus.pass:
        return 'Pass';
      case ItemStatus.fail:
        return 'Fail';
      case ItemStatus.notAvailable:
        return 'N/A';
    }
  }

  static String _fmt(DateTime? d) {
    if (d == null) return 'XX/XX/XXXX';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Type A (standard uncertainty of the mean).
  static String _typeA(List<double> reads) {
    if (reads.length < 2) return '0.0000';
    final double mean = reads.reduce((a, b) => a + b) / reads.length;
    double sumSq = 0;
    for (final r in reads) {
      sumSq += (r - mean) * (r - mean);
    }
    final double s = _sqrt(sumSq / (reads.length - 1));
    return (s / _sqrt(reads.length.toDouble())).toStringAsFixed(4);
  }

  static double _sqrt(double v) {
    if (v <= 0) return 0;
    double x = v;
    for (int i = 0; i < 50; i++) {
      x = (x + v / x) / 2;
    }
    return x;
  }

  static String _esc(String v) => v
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
