// lib/data/models/calibration_session_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ItemStatus { pass, fail, notAvailable }

extension ItemStatusExt on ItemStatus {
  String get label {
    switch (this) {
      case ItemStatus.pass:
        return 'Pass';
      case ItemStatus.fail:
        return 'Fail';
      case ItemStatus.notAvailable:
        return 'N/A';
    }
  }

  String get code {
    switch (this) {
      case ItemStatus.pass:
        return 'pass';
      case ItemStatus.fail:
        return 'fail';
      case ItemStatus.notAvailable:
        return 'na';
    }
  }

  static ItemStatus fromCode(String code) {
    switch (code) {
      case 'pass':
        return ItemStatus.pass;
      case 'fail':
        return ItemStatus.fail;
      default:
        return ItemStatus.notAvailable;
    }
  }
}

class MeasurementRow {
  final double settingValue;
  final List<double> reads; // up to 5 reads
  double? average;
  bool? status; // true = pass, false = fail, null = NF

  MeasurementRow({
    required this.settingValue,
    this.reads = const [],
    this.average,
    this.status,
  });

  double get computedAverage =>
      reads.isEmpty ? 0 : reads.reduce((a, b) => a + b) / reads.length;

  Map<String, dynamic> toMap() => {
        'settingValue': settingValue,
        'reads': reads,
        'average': average,
        'status': status,
      };

  factory MeasurementRow.fromMap(Map<String, dynamic> m) => MeasurementRow(
        settingValue: (m['settingValue'] as num).toDouble(),
        reads: List<double>.from((m['reads'] as List).map((e) => (e as num).toDouble())),
        average: m['average'] != null ? (m['average'] as num).toDouble() : null,
        status: m['status'],
      );
}

class NIBPRow {
  final double systolicSetting;
  final double diastolicSetting;
  final List<double> systolicReads;
  final List<double> diastolicReads;
  bool? systolicStatus;
  bool? diastolicStatus;

  NIBPRow({
    required this.systolicSetting,
    required this.diastolicSetting,
    this.systolicReads = const [],
    this.diastolicReads = const [],
    this.systolicStatus,
    this.diastolicStatus,
  });

  Map<String, dynamic> toMap() => {
        'systolicSetting': systolicSetting,
        'diastolicSetting': diastolicSetting,
        'systolicReads': systolicReads,
        'diastolicReads': diastolicReads,
        'systolicStatus': systolicStatus,
        'diastolicStatus': diastolicStatus,
      };

  factory NIBPRow.fromMap(Map<String, dynamic> m) => NIBPRow(
        systolicSetting: (m['systolicSetting'] as num).toDouble(),
        diastolicSetting: (m['diastolicSetting'] as num).toDouble(),
        systolicReads: List<double>.from((m['systolicReads'] as List).map((e) => (e as num).toDouble())),
        diastolicReads: List<double>.from((m['diastolicReads'] as List).map((e) => (e as num).toDouble())),
        systolicStatus: m['systolicStatus'],
        diastolicStatus: m['diastolicStatus'],
      );
}

class CalibrationSession {
  String? id;
  String engineerId;
  String engineerName;

  // Customer Data
  String customerName;
  DateTime orderDate;
  DateTime visitDate;
  String visitTime;

  // Monitor Data
  String department;
  String manufacturer;
  String serialNumber;
  String model;

  // Qualitative Test - key: item name, value: status
  Map<String, ItemStatus> qualitativeResults;

  // ECG representation
  Map<String, ItemStatus> ecgRepresentation;

  // Measurement tables
  List<MeasurementRow> hrRows;
  List<MeasurementRow> spo2Rows;
  List<NIBPRow> nibpRows;
  List<MeasurementRow> respirationRows;
  List<MeasurementRow> temp1Rows;
  List<MeasurementRow> temp2Rows;

  // Notes
  String notes;

  // Certificate metadata
  String hospitalName;
  DateTime? testDate;
  String? certificateNumber;
  String? qualitativeResult;
  String? quantitativeResult;

  // Result
  String? overallResult; // 'PASS' | 'FAIL'

  // Certificate file
  String? certificateUrl;
  String? supabasePath;

  DateTime createdAt;
  String status; // 'draft', 'completed'

  CalibrationSession({
    this.id,
    required this.engineerId,
    required this.engineerName,
    required this.customerName,
    required this.orderDate,
    required this.visitDate,
    required this.visitTime,
    required this.department,
    required this.manufacturer,
    required this.serialNumber,
    required this.model,
    this.qualitativeResults = const {},
    this.ecgRepresentation = const {},
    this.hrRows = const [],
    this.spo2Rows = const [],
    this.nibpRows = const [],
    this.respirationRows = const [],
    this.temp1Rows = const [],
    this.temp2Rows = const [],
    this.notes = '',
    String? hospitalName,
    this.testDate,
    this.certificateNumber,
    this.qualitativeResult,
    this.quantitativeResult,
    this.overallResult,
    this.certificateUrl,
    this.supabasePath,
    required this.createdAt,
    this.status = 'draft',
  }) : hospitalName = hospitalName ?? customerName;

  // Cable availability checks
  bool get hasEcgCable =>
      qualitativeResults['ECG CABLE'] != ItemStatus.notAvailable;

  bool get hasSpo2Cable =>
      qualitativeResults['SPO2 cable'] != ItemStatus.notAvailable;

  bool get hasNibpCable =>
      qualitativeResults['NIBP Cuff'] != ItemStatus.notAvailable &&
      qualitativeResults['NIBP Cuff'] != ItemStatus.fail &&
      qualitativeResults['NIBP cable'] != ItemStatus.notAvailable &&
      qualitativeResults['NIBP cable'] != ItemStatus.fail;

  bool get hasTempCable =>
      qualitativeResults['TEMP CABLE/S'] != ItemStatus.notAvailable;

  // Table visibility rules
  bool get showHrTable => hasEcgCable && hasSpo2Cable;
  bool get showSpo2Table => hasSpo2Cable;
  bool get showNibpTable => hasNibpCable;
  bool get showRespirationTable => hasEcgCable;
  bool get showTempTables => hasTempCable;

  Map<String, dynamic> toFirestore() => {
        'engineerId': engineerId,
        'engineerName': engineerName,
        'customerName': customerName,
        'orderDate': Timestamp.fromDate(orderDate),
        'visitDate': Timestamp.fromDate(visitDate),
        'visitTime': visitTime,
        'department': department,
        'manufacturer': manufacturer,
        'serialNumber': serialNumber,
        'model': model,
        'qualitativeResults':
            qualitativeResults.map((k, v) => MapEntry(k, v.code)),
        'ecgRepresentation':
            ecgRepresentation.map((k, v) => MapEntry(k, v.code)),
        'hrRows': hrRows.map((r) => r.toMap()).toList(),
        'spo2Rows': spo2Rows.map((r) => r.toMap()).toList(),
        'nibpRows': nibpRows.map((r) => r.toMap()).toList(),
        'respirationRows': respirationRows.map((r) => r.toMap()).toList(),
        'temp1Rows': temp1Rows.map((r) => r.toMap()).toList(),
        'temp2Rows': temp2Rows.map((r) => r.toMap()).toList(),
        'notes': notes,
        'hospitalName': hospitalName,
        'testDate': testDate != null ? Timestamp.fromDate(testDate!) : null,
        'certificateNumber': certificateNumber,
        'qualitativeResult': qualitativeResult,
        'quantitativeResult': quantitativeResult,
        'overallResult': overallResult,
        'certificateUrl': certificateUrl,
        'supabasePath': supabasePath,
        'createdAt': Timestamp.fromDate(createdAt),
        'status': status,
      };

  factory CalibrationSession.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return CalibrationSession(
      id: doc.id,
      engineerId: d['engineerId'] ?? '',
      engineerName: d['engineerName'] ?? '',
      customerName: d['customerName'] ?? '',
      orderDate: (d['orderDate'] as Timestamp).toDate(),
      visitDate: (d['visitDate'] as Timestamp).toDate(),
      visitTime: d['visitTime'] ?? '',
      department: d['department'] ?? '',
      manufacturer: d['manufacturer'] ?? '',
      serialNumber: d['serialNumber'] ?? '',
      model: d['model'] ?? '',
      qualitativeResults: (d['qualitativeResults'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, ItemStatusExt.fromCode(v as String))),
      ecgRepresentation: (d['ecgRepresentation'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, ItemStatusExt.fromCode(v as String))),
      hrRows: (d['hrRows'] as List? ?? [])
          .map((e) => MeasurementRow.fromMap(e as Map<String, dynamic>))
          .toList(),
      spo2Rows: (d['spo2Rows'] as List? ?? [])
          .map((e) => MeasurementRow.fromMap(e as Map<String, dynamic>))
          .toList(),
      nibpRows: (d['nibpRows'] as List? ?? [])
          .map((e) => NIBPRow.fromMap(e as Map<String, dynamic>))
          .toList(),
      respirationRows: (d['respirationRows'] as List? ?? [])
          .map((e) => MeasurementRow.fromMap(e as Map<String, dynamic>))
          .toList(),
      temp1Rows: (d['temp1Rows'] as List? ?? [])
          .map((e) => MeasurementRow.fromMap(e as Map<String, dynamic>))
          .toList(),
      temp2Rows: (d['temp2Rows'] as List? ?? [])
          .map((e) => MeasurementRow.fromMap(e as Map<String, dynamic>))
          .toList(),
      notes: d['notes'] ?? '',
      overallResult: d['overallResult'] as String?,
      testDate: d['testDate'] != null ? (d['testDate'] as dynamic).toDate() : null,
      certificateNumber: d['certificateNumber'] as String?,
      qualitativeResult: d['qualitativeResult'] as String?,
      quantitativeResult: d['quantitativeResult'] as String?,
      certificateUrl: d['certificateUrl'],
      supabasePath: d['supabasePath'],
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      status: d['status'] ?? 'draft',
    );
  }
}

// User model
class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String role; // 'engineer', 'admin'
  final String? photoUrl;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.role = 'engineer',
    this.photoUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return AppUser(
      uid: doc.id,
      fullName: d['fullName'] ?? '',
      email: d['email'] ?? '',
      phone: d['phone'] ?? '',
      role: d['role'] ?? 'engineer',
      photoUrl: d['photoUrl'],
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }
}

// Price offer model
class PriceOffer {
  String? id;
  String engineerId;
  String clientName;
  String clientEmail;
  List<PriceItem> items;
  double total;
  DateTime createdAt;

  PriceOffer({
    this.id,
    required this.engineerId,
    required this.clientName,
    required this.clientEmail,
    required this.items,
    required this.total,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
        'engineerId': engineerId,
        'clientName': clientName,
        'clientEmail': clientEmail,
        'items': items.map((i) => i.toMap()).toList(),
        'total': total,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class PriceItem {
  final String deviceName;
  final double price;
  final int quantity;
  final bool electricCheck;
  final bool functionCheck;

  PriceItem({
    required this.deviceName,
    required this.price,
    required this.quantity,
    required this.electricCheck,
    required this.functionCheck,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() => {
        'deviceName': deviceName,
        'price': price,
        'quantity': quantity,
        'electricCheck': electricCheck,
        'functionCheck': functionCheck,
      };
}
