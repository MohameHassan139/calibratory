import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../data/models/models.dart';
import '../../services/certificate_service.dart';


class CalibrationDetailScreen extends StatelessWidget {
  final CalibrationSession session;

  const CalibrationDetailScreen({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calibration Details'),
        elevation: 0,
        actions: [
          _CertificateActions(session: session),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _HeaderSection(session: session),
            const SizedBox(height: 12),
            _DeviceInfoSection(session: session),
            const SizedBox(height: 12),
            _ResultsSection(session: session),
            if (session.qualitativeResults.isNotEmpty ||
                session.ecgRepresentation.isNotEmpty) ...[
              const SizedBox(height: 12),
              _QualitativeSection(session: session),
            ],
            if (session.hrRows.isNotEmpty ||
                session.spo2Rows.isNotEmpty ||
                session.nibpRows.isNotEmpty ||
                session.respirationRows.isNotEmpty ||
                session.temp1Rows.isNotEmpty ||
                session.temp2Rows.isNotEmpty) ...[
              const SizedBox(height: 12),
              _QuantitativeSection(session: session),
            ],
            if (session.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _NotesSection(session: session),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Certificate Actions ───────────────────────────────────────────────────────

class _CertificateActions extends StatefulWidget {
  final CalibrationSession session;
  const _CertificateActions({required this.session});

  @override
  State<_CertificateActions> createState() => _CertificateActionsState();
}

class _CertificateActionsState extends State<_CertificateActions> {
  bool _loading = false;

  Future<void> _viewFromCloud() async {
    final url = widget.session.certificateUrl;
    if (url == null || url.isEmpty) {
      Get.snackbar('Not Available', 'No cloud certificate found for this session.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _loading = true);
    try {
      final dir = await getTemporaryDirectory();
      final fileName = url.split('/').last.split('?').first;
      final localPath = '${dir.path}/$fileName';
      final file = File(localPath);

      if (!file.existsSync()) {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode != 200) {
          throw Exception('Download failed (${response.statusCode})');
        }
        await file.writeAsBytes(response.bodyBytes);
      }

      final result = await OpenFilex.open(localPath);
      if (result.type == ResultType.noAppToOpen) {
        Get.snackbar('No App Found',
            'Install Microsoft Word or a document viewer to open .docx files',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5));
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _downloadToDocuments() async {
    final url = widget.session.certificateUrl;
    if (url == null || url.isEmpty) {
      Get.snackbar('Not Available', 'No cloud certificate found for this session.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Download failed (${response.statusCode})');
      }

      final fileName =
          'cert_${widget.session.serialNumber}_${widget.session.certificateNumber?.replaceAll('/', '-') ?? 'cert'}.docx';

      // Try to save to the public Downloads folder on Android
      Directory? saveDir;
      if (Platform.isAndroid) {
        // /storage/emulated/0/Download — visible in Files app
        saveDir = Directory('/storage/emulated/0/Download');
        if (!saveDir.existsSync()) {
          saveDir = await getExternalStorageDirectory();
        }
      }
      saveDir ??= await getApplicationDocumentsDirectory();

      final localPath = '${saveDir.path}/$fileName';
      await File(localPath).writeAsBytes(response.bodyBytes);

      Get.snackbar(
        'Downloaded',
        'Saved to Downloads: $fileName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF22C55E),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _regenerateLocally() async {
    setState(() => _loading = true);
    try {
      final path = await CertificateService.generateCertificate(widget.session);
      await OpenFilex.open(path);
    } catch (e) {
      Get.snackbar('Error', e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final hasCloud = widget.session.certificateUrl?.isNotEmpty == true;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.description_outlined),
      tooltip: 'Certificate',
      onSelected: (value) {
        if (value == 'view') _viewFromCloud();
        if (value == 'download') _downloadToDocuments();
        if (value == 'regenerate') _regenerateLocally();
      },
      itemBuilder: (_) => [
        if (hasCloud) ...[
          const PopupMenuItem(
            value: 'view',
            child: Row(children: [
              Icon(Icons.open_in_new, size: 18),
              SizedBox(width: 10),
              Text('View Certificate'),
            ]),
          ),
          const PopupMenuItem(
            value: 'download',
            child: Row(children: [
              Icon(Icons.download_outlined, size: 18),
              SizedBox(width: 10),
              Text('Download Certificate'),
            ]),
          ),
          const PopupMenuDivider(),
        ],
        const PopupMenuItem(
          value: 'regenerate',
          child: Row(children: [
            Icon(Icons.refresh, size: 18),
            SizedBox(width: 10),
            Text('Regenerate Locally'),
          ]),
        ),
      ],
    );
  }
}

// ── Header Section ────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  final CalibrationSession session;
  const _HeaderSection({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.customerName.isEmpty
                          ? 'Unknown Hospital'
                          : session.customerName,
                      style: const TextStyle(
                        fontFamily: 'Syne',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.department,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (session.overallResult == 'PASS'
                          ? AppColors.success
                          : session.overallResult == 'FAIL'
                              ? AppColors.error
                              : AppColors.textHint)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  session.overallResult ?? 'N/F',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: session.overallResult == 'PASS'
                        ? AppColors.success
                        : session.overallResult == 'FAIL'
                            ? AppColors.error
                            : AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: '${session.visitDate.day}/${session.visitDate.month}/${session.visitDate.year}',
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.access_time_outlined,
                label: session.visitTime,
              ),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.badge_outlined,
                label: session.certificateNumber ?? 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Device Info Section ───────────────────────────────────────────────────────

class _DeviceInfoSection extends StatelessWidget {
  final CalibrationSession session;
  const _DeviceInfoSection({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Device Information',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Manufacturer', value: session.manufacturer),
          _InfoRow(label: 'Model', value: session.model),
          _InfoRow(label: 'Serial Number', value: session.serialNumber),
          _InfoRow(label: 'Engineer', value: session.engineerName),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Results Section ───────────────────────────────────────────────────────────

class _ResultsSection extends StatelessWidget {
  final CalibrationSession session;
  const _ResultsSection({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Results',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _ResultCard(
            label: 'Qualitative Result',
            value: session.qualitativeResult ?? 'N/F',
            color: _getResultColor(session.qualitativeResult),
          ),
          const SizedBox(height: 10),
          _ResultCard(
            label: 'Quantitative Result',
            value: session.quantitativeResult ?? 'N/F',
            color: _getResultColor(session.quantitativeResult),
          ),
          const SizedBox(height: 10),
          _ResultCard(
            label: 'Overall Result',
            value: session.overallResult ?? 'N/F',
            color: _getResultColor(session.overallResult),
            isMain: true,
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isMain;

  const _ResultCard({
    required this.label,
    required this.value,
    required this.color,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMain ? 14 : 13,
              fontWeight: isMain ? FontWeight.w700 : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: isMain ? 14 : 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _getResultColor(String? result) {
  if (result == 'PASS') return AppColors.success;
  if (result == 'FAIL') return AppColors.error;
  return AppColors.textHint;
}

// ── Qualitative Section ───────────────────────────────────────────────────────

class _QualitativeSection extends StatelessWidget {
  final CalibrationSession session;
  const _QualitativeSection({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Qualitative Tests',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (session.qualitativeResults.isNotEmpty) ...[
            const Text(
              'Visual Inspection',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...session.qualitativeResults.entries.map((e) =>
                _TestItem(name: e.key, status: e.value.label)),
            const SizedBox(height: 12),
          ],
          if (session.ecgRepresentation.isNotEmpty) ...[
            const Text(
              'ECG Representation',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...session.ecgRepresentation.entries.map((e) =>
                _TestItem(name: e.key, status: e.value.label)),
          ],
        ],
      ),
    );
  }
}

class _TestItem extends StatelessWidget {
  final String name;
  final String status;
  const _TestItem({required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    final isPass = status == 'Pass';
    final isFail = status == 'Fail';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isPass
                      ? AppColors.success
                      : isFail
                          ? AppColors.error
                          : AppColors.textHint)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isPass
                    ? AppColors.success
                    : isFail
                        ? AppColors.error
                        : AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quantitative Section ──────────────────────────────────────────────────────

class _QuantitativeSection extends StatelessWidget {
  final CalibrationSession session;
  const _QuantitativeSection({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quantitative Measurements',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (session.hrRows.isNotEmpty)
            _MeasurementGroup(
              title: 'Heart Rate',
              rows: session.hrRows,
              unit: 'BPM',
            ),
          if (session.spo2Rows.isNotEmpty)
            _MeasurementGroup(
              title: 'SPO2',
              rows: session.spo2Rows,
              unit: '%',
            ),
          if (session.nibpRows.isNotEmpty)
            _NIBPGroup(rows: session.nibpRows),
          if (session.respirationRows.isNotEmpty)
            _MeasurementGroup(
              title: 'Respiration',
              rows: session.respirationRows,
              unit: 'BPM',
            ),
          if (session.temp1Rows.isNotEmpty)
            _MeasurementGroup(
              title: 'Temperature Sensor 1',
              rows: session.temp1Rows,
              unit: '°C',
            ),
          if (session.temp2Rows.isNotEmpty)
            _MeasurementGroup(
              title: 'Temperature Sensor 2',
              rows: session.temp2Rows,
              unit: '°C',
            ),
        ],
      ),
    );
  }
}

class _MeasurementGroup extends StatelessWidget {
  final String title;
  final List<MeasurementRow> rows;
  final String unit;

  const _MeasurementGroup({
    required this.title,
    required this.rows,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map((row) => _MeasurementItem(
                setting: row.settingValue,
                average: row.average,
                status: row.status,
                unit: unit,
              )),
        ],
      ),
    );
  }
}

class _MeasurementItem extends StatelessWidget {
  final double setting;
  final double? average;
  final bool? status;
  final String unit;

  const _MeasurementItem({
    required this.setting,
    required this.average,
    required this.status,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isPass = status == true;
    final isFail = status == false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Set: ${setting.toStringAsFixed(1)} $unit',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Avg: ${average?.toStringAsFixed(2) ?? "N/A"} $unit',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (isPass
                      ? AppColors.success
                      : isFail
                          ? AppColors.error
                          : AppColors.textHint)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isPass ? 'PASS' : isFail ? 'FAIL' : 'N/A',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isPass
                    ? AppColors.success
                    : isFail
                        ? AppColors.error
                        : AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NIBPGroup extends StatelessWidget {
  final List<NIBPRow> rows;
  const _NIBPGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NIBP (Blood Pressure)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map((row) => Column(
                children: [
                  _MeasurementItem(
                    setting: row.systolicSetting,
                    average: row.systolicReads.isEmpty
                        ? null
                        : row.systolicReads.reduce((a, b) => a + b) /
                            row.systolicReads.length,
                    status: row.systolicStatus,
                    unit: 'mmHg (Sys)',
                  ),
                  _MeasurementItem(
                    setting: row.diastolicSetting,
                    average: row.diastolicReads.isEmpty
                        ? null
                        : row.diastolicReads.reduce((a, b) => a + b) /
                            row.diastolicReads.length,
                    status: row.diastolicStatus,
                    unit: 'mmHg (Dia)',
                  ),
                  const SizedBox(height: 6),
                ],
              )),
        ],
      ),
    );
  }
}

// ── Notes Section ─────────────────────────────────────────────────────────────

class _NotesSection extends StatelessWidget {
  final CalibrationSession session;
  const _NotesSection({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Engineer Notes',
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            session.notes,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
