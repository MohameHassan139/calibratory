# Firebase Implementation Guide - Calibration System

## Quick Start

### 1. Setup Firebase in Your Project

Ensure your `pubspec.yaml` has these dependencies:
```yaml
dependencies:
  cloud_firestore: ^4.14.0
  firebase_storage: ^11.5.0
  firebase_core: ^2.24.0
  get: ^4.6.0
```

### 2. Initialize Firebase in main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

### 3. Configure Firestore Security Rules

Go to Firebase Console → Firestore Database → Rules and paste:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Engineers can read/write their own data
    match /engineers/{uid} {
      allow read, write: if request.auth.uid == uid;
      match /calibrations/{document=**} {
        allow read, write: if request.auth.uid == uid;
      }
    }
    
    // Clients can read their calibrations
    match /clients/{clientId}/calibrations/{document=**} {
      allow read: if request.auth.uid != null;
    }
    
    // Public calibrations readable by anyone
    match /public_calibrations/{document=**} {
      allow read: if true;
    }
    
    // Authenticated users can read results
    match /qualitative_results/{document=**} {
      allow read, write: if request.auth.uid != null;
    }
    
    match /quantitative_results/{document=**} {
      allow read, write: if request.auth.uid != null;
    }
    
    match /final_results/{document=**} {
      allow read: if request.auth.uid != null;
    }
  }
}
```

### 4. Configure Storage Security Rules

Go to Firebase Console → Storage → Rules and paste:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /certificates/{engineerId}/{allPaths=**} {
      allow read, write: if request.auth.uid == engineerId;
    }
  }
}
```

---

## Data Upload Flow

### When Calibration is Completed

The `completeCalibration()` method in `CalibrationController` automatically:

1. **Generates certificate** (Word document)
2. **Uploads to Firebase** with all data:
   - Main calibration session
   - Engineer data
   - Client data
   - Qualitative results
   - Quantitative results
   - Notes
   - Final results
   - Certificate file

### Code Flow

```dart
// In CalibrationController.completeCalibration()

// 1. Generate certificate
final String certPath = await CertificateService.generateCertificate(s);

// 2. Upload all data to Firebase
await FirebaseService.uploadCalibrationSession(s, certificatePath: certPath);
await FirebaseService.saveEngineerData(s.engineerId, s);
await FirebaseService.saveClientData(s, clientEmail);
await FirebaseService.saveQualitativeResults(s);
await FirebaseService.saveQuantitativeResults(s);
await FirebaseService.saveNotes(s);
await FirebaseService.saveFinalResults(s);
```

---

## Data Categories Uploaded

### 1. Public Data
**Collection:** `public_calibrations`

Accessible to anyone. Contains:
- Hospital/Client name
- Device info (manufacturer, model, serial number)
- Department
- Visit date
- Certificate number
- Results (PASS/FAIL)
- Certificate URL

### 2. Engineer Data
**Collection:** `engineers/{uid}/calibrations`

Private to engineer. Contains:
- Engineer name and ID
- Calibration reference
- Device serial number
- Certificate number
- Test date

### 3. Client Data
**Collection:** `clients/{clientName}/calibrations`

Accessible to client. Contains:
- Client name and email
- Hospital name
- Department
- Device info
- Certificate number
- Overall result
- Visit date

### 4. Qualitative Results
**Collection:** `qualitative_results`

Contains all visual inspection and ECG representation test results:
- Chassis/Housing status
- Controls/Switches status
- Mount status
- Battery/charger status
- ... (14 items total)
- ECG representation tests (8 items)
- Overall qualitative result (PASS/FAIL/N/F)

### 5. Quantitative Results
**Collection:** `quantitative_results`

Contains all measurement data:
- Heart Rate rows (6 rows with readings)
- SPO2 rows (5 rows)
- NIBP rows (6 pairs of systolic/diastolic)
- Respiration rows (4 rows)
- Temperature sensor 1 (3 rows)
- Temperature sensor 2 (3 rows)
- Overall quantitative result (PASS/FAIL/N/F)

### 6. Notes
**Collection:** `notes`

Engineer's observations and notes about the calibration.

### 7. Final Results
**Collection:** `final_results`

Summary of all results:
- Qualitative result (PASS/FAIL/N/F)
- Quantitative result (PASS/FAIL/N/F)
- Overall result (PASS/FAIL/N/F)
- Certificate number
- Test date

### 8. Certificate File
**Storage Path:** `certificates/{engineerId}/{serialNumber}_{certificateNumber}.docx`

The generated Word document with all calibration data filled in.

---

## Using the Upload Manager

### Basic Usage

```dart
final manager = FirebaseUploadManager();

// Upload complete calibration
final success = await manager.uploadCompleteCalibration(
  session,
  certificatePath: certPath,
  clientEmail: 'client@hospital.com',
  onStatusUpdate: (status) {
    print('Upload status: $status');
  },
);

if (success) {
  print('✅ All data uploaded successfully');
} else {
  print('❌ Upload failed');
}
```

### With Progress Tracking

```dart
// In your UI
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

// Start upload
await manager.uploadCompleteCalibration(session);
```

### Retry Failed Upload

```dart
// If upload fails, retry
final success = await manager.retryUpload(
  session,
  certificatePath: certPath,
  clientEmail: email,
);
```

---

## Querying Data

### Get Engineer's Calibrations

```dart
final calibrations = await FirebaseService.fetchEngineerCalibrations(engineerId);
```

### Get Public Calibration by Serial Number

```dart
final calibration = await FirebaseService.fetchPublicCalibration(serialNumber);
```

### Custom Queries

```dart
// Get all PASS results
final passResults = await FirebaseFirestore.instance
    .collection('final_results')
    .where('overallResult', isEqualTo: 'PASS')
    .orderBy('createdAt', descending: true)
    .get();

// Get calibrations by date range
final startDate = DateTime(2026, 1, 1);
final endDate = DateTime(2026, 12, 31);

final results = await FirebaseFirestore.instance
    .collection('calibrations')
    .where('createdAt', isGreaterThanOrEqualTo: startDate)
    .where('createdAt', isLessThanOrEqualTo: endDate)
    .orderBy('createdAt', descending: true)
    .get();
```

---

## Error Handling

### Upload Errors

```dart
try {
  await FirebaseService.uploadCalibrationSession(session);
} on FirebaseException catch (e) {
  print('Firebase error: ${e.code} - ${e.message}');
  // Handle specific error codes
  if (e.code == 'permission-denied') {
    print('User does not have permission to upload');
  } else if (e.code == 'unavailable') {
    print('Firebase service is unavailable');
  }
} catch (e) {
  print('Unknown error: $e');
}
```

### Network Errors

```dart
try {
  await manager.uploadCompleteCalibration(session);
} catch (e) {
  if (e.toString().contains('Network')) {
    print('Network error - will retry when connection restored');
    // Implement retry logic
  }
}
```

---

## Best Practices

### 1. Always Assign Document IDs
```dart
// Generate ID before upload
session.id = session.id ?? FirebaseFirestore.instance
    .collection('calibrations')
    .doc()
    .id;
```

### 2. Use Batch Operations for Related Data
```dart
final batch = FirebaseFirestore.instance.batch();

// Add multiple operations
batch.set(doc1, data1);
batch.set(doc2, data2);
batch.update(doc3, data3);

// Commit all at once
await batch.commit();
```

### 3. Implement Offline Support
```dart
// Enable offline persistence
await FirebaseFirestore.instance.enableNetwork();

// Data will sync when connection is restored
```

### 4. Monitor Upload Progress
```dart
// Show progress to user
Obx(() {
  if (manager.isUploading.value) {
    return CircularProgressIndicator(
      value: manager.uploadProgress.value,
    );
  }
  return SizedBox.shrink();
});
```

### 5. Validate Data Before Upload
```dart
// Ensure all required fields are present
if (session.serialNumber.isEmpty) {
  throw Exception('Serial number is required');
}
if (session.certificateNumber == null) {
  throw Exception('Certificate number is required');
}
```

---

## Monitoring & Debugging

### Enable Firestore Logging

```dart
// In main.dart
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);

// Enable debug logging
if (kDebugMode) {
  FirebaseFirestore.instance.settings = const Settings(
    host: 'localhost:8080',
    sslEnabled: false,
  );
}
```

### Check Upload Status

```dart
// Monitor upload progress
manager.uploadProgress.listen((progress) {
  print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
});

manager.uploadStatus.listen((status) {
  print('Upload status: $status');
});
```

### Verify Data in Firebase Console

1. Go to Firebase Console
2. Select your project
3. Go to Firestore Database
4. Check collections:
   - `calibrations` - Main data
   - `public_calibrations` - Public data
   - `qualitative_results` - Qualitative tests
   - `quantitative_results` - Measurements
   - `final_results` - Summary results
5. Go to Storage to verify certificate files

---

## Troubleshooting

### Issue: Permission Denied
**Solution:** Check Firestore security rules and ensure user is authenticated

### Issue: Certificate Upload Fails
**Solution:** Verify Storage rules allow write access for the engineer

### Issue: Data Not Appearing in Firestore
**Solution:** 
1. Check network connection
2. Verify Firebase is initialized
3. Check security rules
4. Look at browser console for errors

### Issue: Slow Upload
**Solution:**
1. Check network speed
2. Reduce data size if possible
3. Use batch operations
4. Enable offline persistence

---

## Testing

### Unit Tests

```dart
test('uploadCalibrationSession uploads data correctly', () async {
  final session = CalibrationSession(
    engineerId: 'test-engineer',
    engineerName: 'Test Engineer',
    customerName: 'Test Hospital',
    orderDate: DateTime.now(),
    visitDate: DateTime.now(),
    visitTime: '10:00 AM',
    department: 'ICU',
    manufacturer: 'Philips',
    serialNumber: 'SN-12345',
    model: 'MP70',
    createdAt: DateTime.now(),
  );

  await FirebaseService.uploadCalibrationSession(session);
  
  // Verify data was uploaded
  final doc = await FirebaseFirestore.instance
      .collection('calibrations')
      .doc(session.id)
      .get();
  
  expect(doc.exists, true);
  expect(doc['serialNumber'], 'SN-12345');
});
```

### Integration Tests

```dart
testWidgets('Calibration upload flow works', (WidgetTester tester) async {
  // Build app
  await tester.pumpWidget(const MyApp());
  
  // Complete calibration
  await tester.tap(find.byText('Complete Calibration'));
  await tester.pumpAndSettle();
  
  // Verify upload success
  expect(find.text('Upload complete!'), findsOneWidget);
});
```

---

## Performance Optimization

### 1. Batch Uploads
```dart
// Upload multiple calibrations at once
final batch = FirebaseFirestore.instance.batch();
for (final session in sessions) {
  batch.set(
    FirebaseFirestore.instance.collection('calibrations').doc(session.id),
    session.toFirestore(),
  );
}
await batch.commit();
```

### 2. Pagination
```dart
// Load calibrations in pages
Query query = FirebaseFirestore.instance
    .collection('calibrations')
    .orderBy('createdAt', descending: true)
    .limit(20);

final firstPage = await query.get();
final nextQuery = query.startAfterDocument(firstPage.docs.last);
final secondPage = await nextQuery.get();
```

### 3. Caching
```dart
// Use local cache
FirebaseFirestore.instance.settings = const Settings(
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

---

## Support & Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Flutter Firebase Plugin](https://firebase.flutter.dev/)
- [Cloud Storage Documentation](https://firebase.google.com/docs/storage)

