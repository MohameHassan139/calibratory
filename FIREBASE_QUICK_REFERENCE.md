# Firebase Quick Reference

## Setup Checklist

- [ ] Add Firebase dependencies to `pubspec.yaml`
- [ ] Initialize Firebase in `main.dart`
- [ ] Configure Firestore security rules
- [ ] Configure Storage security rules
- [ ] Create Firestore indexes (if needed)
- [ ] Test Firebase connection

## Data Upload Locations

| Data Type | Collection | Access |
|-----------|-----------|--------|
| Complete Session | `calibrations` | Engineer only |
| Public Summary | `public_calibrations` | Public |
| Qualitative Tests | `qualitative_results` | Engineer |
| Measurements | `quantitative_results` | Engineer |
| Notes | `notes` | Engineer |
| Final Results | `final_results` | Engineer |
| Engineer Profile | `engineers/{uid}` | Engineer only |
| Client Data | `clients/{name}` | Client |
| Certificate | Storage: `certificates/{uid}/...` | Engineer only |

## Code Snippets

### Complete Upload
```dart
final manager = FirebaseUploadManager();
await manager.uploadCompleteCalibration(
  session,
  certificatePath: certPath,
  clientEmail: email,
);
```

### Individual Uploads
```dart
await FirebaseService.uploadCalibrationSession(session);
await FirebaseService.saveEngineerData(engineerId, session);
await FirebaseService.saveClientData(session, email);
await FirebaseService.saveQualitativeResults(session);
await FirebaseService.saveQuantitativeResults(session);
await FirebaseService.saveNotes(session);
await FirebaseService.saveFinalResults(session);
```

### Fetch Data
```dart
// Engineer's calibrations
final cals = await FirebaseService.fetchEngineerCalibrations(uid);

// Public calibration
final cal = await FirebaseService.fetchPublicCalibration(serialNumber);
```

### Monitor Progress
```dart
Obx(() => Text('${manager.uploadStatus.value}')),
Obx(() => LinearProgressIndicator(value: manager.uploadProgress.value)),
```

## Firestore Collections Structure

```
calibrations/
├── {docId}
│   ├── engineerId
│   ├── serialNumber
│   ├── qualitativeResults
│   ├── quantitativeResults (HR, SPO2, NIBP, etc.)
│   ├── notes
│   ├── certificateUrl
│   └── ...

public_calibrations/
├── {docId}
│   ├── hospitalName
│   ├── serialNumber
│   ├── overallResult
│   └── ...

qualitative_results/
├── {docId}
│   ├── qualitativeResults
│   ├── ecgRepresentation
│   └── ...

quantitative_results/
├── {docId}
│   ├── hrRows
│   ├── spo2Rows
│   ├── nibpRows
│   ├── respirationRows
│   ├── temp1Rows
│   ├── temp2Rows
│   └── ...

final_results/
├── {docId}
│   ├── qualitativeResult
│   ├── quantitativeResult
│   ├── overallResult
│   └── ...

engineers/
├── {uid}
│   ├── fullName
│   ├── email
│   ├── totalCalibrations
│   └── calibrations/
│       └── {docId}

clients/
├── {clientName}
│   ├── clientEmail
│   ├── hospitalName
│   └── calibrations/
│       └── {docId}
```

## Security Rules

### Firestore
```
// Engineers: read/write own data
match /engineers/{uid} {
  allow read, write: if request.auth.uid == uid;
}

// Clients: read own calibrations
match /clients/{clientId}/calibrations/{doc=**} {
  allow read: if request.auth.uid != null;
}

// Public: readable by anyone
match /public_calibrations/{doc=**} {
  allow read: if true;
}
```

### Storage
```
// Certificates: engineer only
match /certificates/{engineerId}/{allPaths=**} {
  allow read, write: if request.auth.uid == engineerId;
}
```

## Common Queries

### Get Engineer's Calibrations
```dart
db.collection('calibrations')
  .where('engineerId', '==', uid)
  .orderBy('createdAt', descending: true)
  .get()
```

### Get by Serial Number
```dart
db.collection('calibrations')
  .where('serialNumber', '==', serialNumber)
  .orderBy('createdAt', descending: true)
  .get()
```

### Get PASS Results
```dart
db.collection('final_results')
  .where('overallResult', '==', 'PASS')
  .orderBy('createdAt', descending: true)
  .get()
```

### Get by Date Range
```dart
db.collection('calibrations')
  .where('createdAt', '>=', startDate)
  .where('createdAt', '<=', endDate)
  .orderBy('createdAt', descending: true)
  .get()
```

## Upload Flow

```
1. Generate Certificate
   ↓
2. Upload Main Session → calibrations/
   ↓
3. Upload Engineer Data → engineers/{uid}/calibrations/
   ↓
4. Upload Client Data → clients/{name}/calibrations/
   ↓
5. Upload Qualitative → qualitative_results/
   ↓
6. Upload Quantitative → quantitative_results/
   ↓
7. Upload Notes → notes/
   ↓
8. Upload Final Results → final_results/
   ↓
9. Upload Certificate → Storage
   ↓
10. Upload Public Data → public_calibrations/
```

## Data Categories

### Public Data (Accessible to Anyone)
- Hospital name
- Device info (manufacturer, model, serial)
- Department
- Visit date
- Certificate number
- Results (PASS/FAIL)
- Certificate URL

### Engineer Data (Private)
- All measurement data
- Qualitative test results
- Notes
- Engineer observations
- Complete session details

### Client Data (For Hospital)
- Device info
- Calibration results
- Certificate number
- Visit date
- Overall result

### Qualitative Data
- 14 visual inspection items
- 8 ECG representation tests
- Pass/Fail status for each

### Quantitative Data
- Heart Rate: 6 rows of readings
- SPO2: 5 rows of readings
- NIBP: 6 pairs (systolic/diastolic)
- Respiration: 4 rows
- Temperature 1: 3 rows
- Temperature 2: 3 rows

## Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| `permission-denied` | No access | Check security rules |
| `unavailable` | Service down | Retry later |
| `network-error` | No connection | Check network |
| `invalid-argument` | Bad data | Validate data |
| `not-found` | Document missing | Check document ID |

## Performance Tips

1. **Batch Operations** - Upload multiple items together
2. **Pagination** - Load data in pages
3. **Caching** - Enable local cache
4. **Indexes** - Create indexes for frequent queries
5. **Compression** - Compress large files before upload

## Monitoring

### Check Upload Status
```dart
manager.uploadProgress.listen((p) => print('${(p*100).toInt()}%'));
manager.uploadStatus.listen((s) => print(s));
```

### Verify in Firebase Console
1. Firestore Database → Collections
2. Storage → Certificates folder
3. Realtime Database (if used)

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Upload fails | No network | Check connection |
| Permission denied | Security rules | Update rules |
| Data not visible | Wrong collection | Check collection name |
| Slow upload | Large file | Compress or split |
| Certificate missing | Upload failed | Retry upload |

## Files Reference

- `firebase_service.dart` - Core upload/fetch methods
- `firebase_upload_manager.dart` - High-level orchestration
- `calibration_controller.dart` - Calls upload on completion
- `FIREBASE_SCHEMA.md` - Detailed schema
- `FIREBASE_IMPLEMENTATION_GUIDE.md` - Full guide

## Next Steps

1. ✅ Review `FIREBASE_SCHEMA.md` for data structure
2. ✅ Read `FIREBASE_IMPLEMENTATION_GUIDE.md` for setup
3. ✅ Configure Firebase Console
4. ✅ Set security rules
5. ✅ Test upload flow
6. ✅ Monitor in Firebase Console

