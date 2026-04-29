# Firebase Services

This directory contains all Firebase-related services for the calibration system.

## Files

### `firebase_service.dart`
Core Firebase service with methods for uploading and retrieving calibration data.

**Key Methods:**
- `uploadCalibrationSession()` - Upload complete calibration with certificate
- `saveEngineerData()` - Save engineer-specific data
- `saveClientData()` - Save client/hospital data
- `saveQualitativeResults()` - Save qualitative test results
- `saveQuantitativeResults()` - Save measurement data
- `saveNotes()` - Save engineer notes
- `saveFinalResults()` - Save final pass/fail results
- `savePublicData()` - Save publicly accessible data
- `fetchEngineerCalibrations()` - Get all calibrations for an engineer
- `fetchPublicCalibration()` - Get public calibration by serial number

### `firebase_upload_manager.dart`
High-level manager for orchestrating complete upload workflows with progress tracking.

**Key Methods:**
- `uploadCompleteCalibration()` - Upload all data with progress updates
- `uploadPublicDataOnly()` - Quick upload of public data only
- `retryUpload()` - Retry failed uploads

**Observable Properties:**
- `isUploading` - Whether upload is in progress
- `uploadStatus` - Current upload status message
- `uploadProgress` - Upload progress (0.0 to 1.0)

### `certificate_service.dart`
Generates Word document certificates with calibration data.

**Key Methods:**
- `generateCertificate()` - Generate filled .docx certificate

### `email_service.dart`
Handles email notifications and communications.

## Usage Examples

### Complete Upload with Progress

```dart
final manager = FirebaseUploadManager();

final success = await manager.uploadCompleteCalibration(
  session,
  certificatePath: certPath,
  clientEmail: 'client@hospital.com',
  onStatusUpdate: (status) {
    print('Status: $status');
  },
);
```

### Upload Individual Components

```dart
// Upload just the main session
await FirebaseService.uploadCalibrationSession(session);

// Upload engineer data
await FirebaseService.saveEngineerData(engineerId, session);

// Upload client data
await FirebaseService.saveClientData(session, clientEmail);
```

### Fetch Data

```dart
// Get all calibrations for an engineer
final calibrations = await FirebaseService.fetchEngineerCalibrations(engineerId);

// Get public calibration by serial number
final calibration = await FirebaseService.fetchPublicCalibration(serialNumber);
```

### Monitor Progress

```dart
Obx(() {
  return Column(
    children: [
      Text('Status: ${manager.uploadStatus.value}'),
      LinearProgressIndicator(
        value: manager.uploadProgress.value,
      ),
    ],
  );
});
```

## Data Uploaded

When `uploadCompleteCalibration()` is called, the following data is uploaded:

1. **Main Calibration** - Complete session with all measurements
2. **Engineer Data** - Engineer profile and calibration reference
3. **Client Data** - Client/hospital information
4. **Qualitative Results** - Visual inspection and ECG tests
5. **Quantitative Results** - All measurement data (HR, SPO2, NIBP, etc.)
6. **Notes** - Engineer observations
7. **Final Results** - Pass/Fail summary
8. **Certificate File** - Generated Word document
9. **Public Data** - Publicly accessible summary

## Firebase Collections

- `calibrations` - Main calibration records
- `public_calibrations` - Public data
- `qualitative_results` - Qualitative test results
- `quantitative_results` - Measurement data
- `notes` - Engineer notes
- `final_results` - Pass/Fail summary
- `engineers/{uid}/calibrations` - Engineer's calibrations
- `clients/{clientName}/calibrations` - Client's calibrations

## Error Handling

All methods throw exceptions on failure. Wrap calls in try-catch:

```dart
try {
  await FirebaseService.uploadCalibrationSession(session);
} on FirebaseException catch (e) {
  print('Firebase error: ${e.code}');
} catch (e) {
  print('Error: $e');
}
```

## Security

- Engineer data is private to the engineer
- Client data is accessible to the client
- Public data is readable by anyone
- Certificate files are private to the engineer
- All operations require Firebase authentication

See `FIREBASE_SCHEMA.md` for detailed security rules.

## Performance

- Batch operations are used for efficiency
- Data is cached locally when possible
- Uploads are optimized for mobile networks
- Progress tracking allows UI updates

## Testing

See `FIREBASE_IMPLEMENTATION_GUIDE.md` for testing examples.

## Troubleshooting

### Upload Fails
1. Check network connection
2. Verify Firebase is initialized
3. Check security rules in Firebase Console
4. Ensure user is authenticated

### Data Not Appearing
1. Check Firestore collections in Firebase Console
2. Verify security rules allow read/write
3. Check browser console for errors
4. Ensure document IDs are correct

### Slow Upload
1. Check network speed
2. Reduce data size if possible
3. Use batch operations
4. Enable offline persistence

## Related Files

- `lib/presentation/controllers/calibration_controller.dart` - Uses these services
- `FIREBASE_SCHEMA.md` - Database schema documentation
- `FIREBASE_IMPLEMENTATION_GUIDE.md` - Complete implementation guide

