// lib/presentation/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/models.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Upload complete calibration session to Firebase
  /// Uploads: public data, engineer data, notes, client data, qualitative/quantitative results
  /// Note: Certificate file is NOT uploaded to Storage (kept locally only)
  static Future<void> uploadCalibrationSession(
    CalibrationSession session, {
    String? certificatePath,
  }) async {
    try {
      // Prepare session data (certificate path stored locally, not uploaded)
      final sessionData = session.toFirestore();

      // Save to Firestore
      final docRef = _firestore
          .collection('calibrations')
          .doc(session.id ?? _firestore.collection('calibrations').doc().id);

      await docRef.set(sessionData, SetOptions(merge: true));

      // Update engineer's calibration count
      await _updateEngineerStats(session.engineerId);

      // Create public data record (for client access if needed)
      await savePublicData(session);

      print('✅ Calibration uploaded to Firebase: ${docRef.id}');
    } catch (e) {
      print('❌ Firebase upload error: $e');
      rethrow;
    }
  }

  /// Save public data (accessible to clients/hospitals)
  static Future<void> savePublicData(CalibrationSession session) async {
    try {
      final publicData = {
        'hospitalName': session.hospitalName,
        'manufacturer': session.manufacturer,
        'model': session.model,
        'serialNumber': session.serialNumber,
        'department': session.department,
        'visitDate': Timestamp.fromDate(session.visitDate),
        'certificateNumber': session.certificateNumber,
        'qualitativeResult': session.qualitativeResult,
        'quantitativeResult': session.quantitativeResult,
        'overallResult': session.overallResult,
        'createdAt': Timestamp.fromDate(session.createdAt),
      };

      await _firestore
          .collection('public_calibrations')
          .doc(session.id)
          .set(publicData, SetOptions(merge: true));

      print('✅ Public data saved');
    } catch (e) {
      print('❌ Public data save error: $e');
      rethrow;
    }
  }

  /// Save engineer data (private to engineer)
  static Future<void> saveEngineerData(
    String engineerId,
    CalibrationSession session,
  ) async {
    try {
      final engineerData = {
        'engineerId': engineerId,
        'engineerName': session.engineerName,
        'calibrationId': session.id,
        'serialNumber': session.serialNumber,
        'certificateNumber': session.certificateNumber,
        'testDate': Timestamp.fromDate(session.testDate ?? DateTime.now()),
        'createdAt': Timestamp.fromDate(session.createdAt),
      };

      await _firestore
          .collection('engineers')
          .doc(engineerId)
          .collection('calibrations')
          .doc(session.id)
          .set(engineerData, SetOptions(merge: true));

      print('✅ Engineer data saved');
    } catch (e) {
      print('❌ Engineer data save error: $e');
      rethrow;
    }
  }

  /// Save client/hospital data
  static Future<void> saveClientData(
    CalibrationSession session,
    String? clientEmail,
  ) async {
    try {
      final clientData = {
        'clientName': session.customerName,
        'clientEmail': clientEmail,
        'hospitalName': session.hospitalName,
        'department': session.department,
        'serialNumber': session.serialNumber,
        'manufacturer': session.manufacturer,
        'model': session.model,
        'certificateNumber': session.certificateNumber,
        'overallResult': session.overallResult,
        'visitDate': Timestamp.fromDate(session.visitDate),
        'createdAt': Timestamp.fromDate(session.createdAt),
      };

      await _firestore
          .collection('clients')
          .doc(session.customerName.replaceAll(' ', '_'))
          .collection('calibrations')
          .doc(session.id)
          .set(clientData, SetOptions(merge: true));

      print('✅ Client data saved');
    } catch (e) {
      print('❌ Client data save error: $e');
      rethrow;
    }
  }

  /// Save qualitative results
  static Future<void> saveQualitativeResults(
    CalibrationSession session,
  ) async {
    try {
      final qualData = {
        'calibrationId': session.id,
        'serialNumber': session.serialNumber,
        'qualitativeResults': session.qualitativeResults
            .map((k, v) => MapEntry(k, v.code)),
        'ecgRepresentation': session.ecgRepresentation
            .map((k, v) => MapEntry(k, v.code)),
        'qualitativeResult': session.qualitativeResult,
        'createdAt': Timestamp.fromDate(session.createdAt),
      };

      await _firestore
          .collection('qualitative_results')
          .doc(session.id)
          .set(qualData, SetOptions(merge: true));

      print('✅ Qualitative results saved');
    } catch (e) {
      print('❌ Qualitative results save error: $e');
      rethrow;
    }
  }

  /// Save quantitative results (measurements)
  static Future<void> saveQuantitativeResults(
    CalibrationSession session,
  ) async {
    try {
      final quantData = {
        'calibrationId': session.id,
        'serialNumber': session.serialNumber,
        'hrRows': session.hrRows.map((r) => r.toMap()).toList(),
        'spo2Rows': session.spo2Rows.map((r) => r.toMap()).toList(),
        'nibpRows': session.nibpRows.map((r) => r.toMap()).toList(),
        'respirationRows': session.respirationRows.map((r) => r.toMap()).toList(),
        'temp1Rows': session.temp1Rows.map((r) => r.toMap()).toList(),
        'temp2Rows': session.temp2Rows.map((r) => r.toMap()).toList(),
        'quantitativeResult': session.quantitativeResult,
        'createdAt': Timestamp.fromDate(session.createdAt),
      };

      await _firestore
          .collection('quantitative_results')
          .doc(session.id)
          .set(quantData, SetOptions(merge: true));

      print('✅ Quantitative results saved');
    } catch (e) {
      print('❌ Quantitative results save error: $e');
      rethrow;
    }
  }

  /// Save notes
  static Future<void> saveNotes(
    CalibrationSession session,
  ) async {
    try {
      if (session.notes.isEmpty) return;

      final notesData = {
        'calibrationId': session.id,
        'serialNumber': session.serialNumber,
        'notes': session.notes,
        'createdAt': Timestamp.fromDate(session.createdAt),
      };

      await _firestore
          .collection('notes')
          .doc(session.id)
          .set(notesData, SetOptions(merge: true));

      print('✅ Notes saved');
    } catch (e) {
      print('❌ Notes save error: $e');
      rethrow;
    }
  }

  /// Save final results summary
  static Future<void> saveFinalResults(
    CalibrationSession session,
  ) async {
    try {
      final finalData = {
        'calibrationId': session.id,
        'serialNumber': session.serialNumber,
        'certificateNumber': session.certificateNumber,
        'qualitativeResult': session.qualitativeResult,
        'quantitativeResult': session.quantitativeResult,
        'overallResult': session.overallResult,
        'testDate': Timestamp.fromDate(session.testDate ?? DateTime.now()),
        'createdAt': Timestamp.fromDate(session.createdAt),
      };

      await _firestore
          .collection('final_results')
          .doc(session.id)
          .set(finalData, SetOptions(merge: true));

      print('✅ Final results saved');
    } catch (e) {
      print('❌ Final results save error: $e');
      rethrow;
    }
  }

  /// Update engineer statistics
  static Future<void> _updateEngineerStats(String engineerId) async {
    try {
      final engineerRef = _firestore.collection('engineers').doc(engineerId);
      await engineerRef.update({
        'totalCalibrations': FieldValue.increment(1),
        'lastCalibrationDate': Timestamp.now(),
      }).catchError((_) {
        // Document doesn't exist, create it
        return engineerRef.set({
          'totalCalibrations': 1,
          'lastCalibrationDate': Timestamp.now(),
        });
      });

      print('✅ Engineer stats updated');
    } catch (e) {
      print('❌ Engineer stats update error: $e');
      // Don't rethrow - this is non-critical
    }
  }

  /// Fetch calibration history for engineer
  static Future<List<CalibrationSession>> fetchEngineerCalibrations(
    String engineerId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('calibrations')
          .where('engineerId', isEqualTo: engineerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CalibrationSession.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      // Index not yet built — fall back to unordered query and sort in Dart
      if (e.code == 'failed-precondition' || e.code == 'unavailable') {
        final snapshot = await _firestore
            .collection('calibrations')
            .where('engineerId', isEqualTo: engineerId)
            .get();

        final list = snapshot.docs
            .map((doc) => CalibrationSession.fromFirestore(doc))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch public calibration data by serial number
  static Future<CalibrationSession?> fetchPublicCalibration(
    String serialNumber,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('public_calibrations')
          .where('serialNumber', isEqualTo: serialNumber)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return CalibrationSession.fromFirestore(snapshot.docs.first);
    } catch (e) {
      print('❌ Fetch public calibration error: $e');
      rethrow;
    }
  }
}
