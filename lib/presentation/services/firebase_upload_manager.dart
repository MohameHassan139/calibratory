// lib/presentation/services/firebase_upload_manager.dart
import 'package:get/get.dart';
import '../../data/models/models.dart';
import 'firebase_service.dart';

/// Manages the complete Firebase upload workflow for calibration sessions
class FirebaseUploadManager {
  static final FirebaseUploadManager _instance = FirebaseUploadManager._internal();

  factory FirebaseUploadManager() {
    return _instance;
  }

  FirebaseUploadManager._internal();

  final RxBool isUploading = false.obs;
  final RxString uploadStatus = ''.obs;
  final RxDouble uploadProgress = 0.0.obs;

  /// Upload complete calibration with all data categories
  Future<bool> uploadCompleteCalibration(
    CalibrationSession session, {
    String? certificatePath,
    String? clientEmail,
    void Function(String)? onStatusUpdate,
  }) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;

      // Step 1: Upload main calibration session (10%)
      _updateStatus('Uploading calibration session...', onStatusUpdate);
      await FirebaseService.uploadCalibrationSession(
        session,
        certificatePath: certificatePath,
      );
      uploadProgress.value = 0.1;

      // Step 2: Save engineer data (20%)
      _updateStatus('Saving engineer data...', onStatusUpdate);
      await FirebaseService.saveEngineerData(session.engineerId, session);
      uploadProgress.value = 0.2;

      // Step 3: Save client data (30%)
      _updateStatus('Saving client information...', onStatusUpdate);
      await FirebaseService.saveClientData(session, clientEmail);
      uploadProgress.value = 0.3;

      // Step 4: Save qualitative results (50%)
      _updateStatus('Saving qualitative results...', onStatusUpdate);
      await FirebaseService.saveQualitativeResults(session);
      uploadProgress.value = 0.5;

      // Step 5: Save quantitative results (70%)
      _updateStatus('Saving quantitative measurements...', onStatusUpdate);
      await FirebaseService.saveQuantitativeResults(session);
      uploadProgress.value = 0.7;

      // Step 6: Save notes (80%)
      _updateStatus('Saving notes...', onStatusUpdate);
      await FirebaseService.saveNotes(session);
      uploadProgress.value = 0.8;

      // Step 7: Save final results (100%)
      _updateStatus('Finalizing results...', onStatusUpdate);
      await FirebaseService.saveFinalResults(session);
      uploadProgress.value = 1.0;

      _updateStatus('Upload complete!', onStatusUpdate);
      return true;
    } catch (e) {
      _updateStatus('Upload failed: $e', onStatusUpdate);
      print('❌ Upload error: $e');
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  /// Upload only public data (for quick uploads)
  Future<bool> uploadPublicDataOnly(
    CalibrationSession session, {
    void Function(String)? onStatusUpdate,
  }) async {
    try {
      isUploading.value = true;
      _updateStatus('Uploading public data...', onStatusUpdate);
      await FirebaseService.savePublicData(session);
      return true;
    } catch (e) {
      _updateStatus('Public data upload failed: $e', onStatusUpdate);
      return false;
    } finally {
      isUploading.value = false;
    }
  }

  /// Retry failed upload
  Future<bool> retryUpload(
    CalibrationSession session, {
    String? certificatePath,
    String? clientEmail,
    void Function(String)? onStatusUpdate,
  }) async {
    _updateStatus('Retrying upload...', onStatusUpdate);
    return uploadCompleteCalibration(
      session,
      certificatePath: certificatePath,
      clientEmail: clientEmail,
      onStatusUpdate: onStatusUpdate,
    );
  }

  void _updateStatus(String status, void Function(String)? callback) {
    uploadStatus.value = status;
    callback?.call(status);
  }

  void reset() {
    isUploading.value = false;
    uploadStatus.value = '';
    uploadProgress.value = 0.0;
  }
}
