# Firebase Database Schema - Calibration System

## Overview
This document describes the complete Firebase Firestore and Storage structure for the medical device calibration system.

---

## Firestore Collections

### 1. `calibrations` (Main Collection)
**Purpose:** Complete calibration session records with all data

**Document ID:** Auto-generated UUID

**Fields:**
```
{
  engineerId: string,
  engineerName: string,
  customerName: string,
  orderDate: timestamp,
  visitDate: timestamp,
  visitTime: string,
  department: string,
  manufacturer: string,
  serialNumber: string,
  model: string,
  
  // Qualitative Data
  qualitativeResults: {
    "Chassis/Housing": "pass|fail|na",
    "Controls/Switches": "pass|fail|na",
    "Mount": "pass|fail|na",
    "Battery/charger": "pass|fail|na",
    "Casters/Brakes": "pass|fail|na",
    "Indicator/Displays": "pass|fail|na",
    "AC plug": "pass|fail|na",
    "Labeling": "pass|fail|na",
    "Line Cord": "pass|fail|na",
    "Alarms": "pass|fail|na",
    "Screen": "pass|fail|na",
    "Module Housing": "pass|fail|na",
    "SPO2 cable": "pass|fail|na",
    "Mounting/Trolley": "pass|fail|na"
  },
  
  ecgRepresentation: {
    "Atrial Fibrillation": "pass|fail|na",
    "Premature ventricle contraction": "pass|fail|na",
    "Ventricle Fibrillation": "pass|fail|na",
    "Paroxysmal Atrial Tachycardia (PAT)": "pass|fail|na",
    "Atrial Flutter": "pass|fail|na",
    "Polymorphic Ventricular Tachycardia (PVT)": "pass|fail|na",
    "Representation of Standard signals (Triangle, Square, Sinusoid)": "pass|fail|na",
    "Represent ECG waveforms with different Amplitudes (0.5,1,1.5,2,2.5,3,3.5)": "pass|fail|na"
  },
  
  // Quantitative Data (Measurements)
  hrRows: [
    {
      settingValue: number,
      reads: [number, ...],
      average: number,
      status: boolean|null
    },
    ...
  ],
  
  spo2Rows: [
    {
      settingValue: number,
      reads: [number, ...],
      average: number,
      status: boolean|null
    },
    ...
  ],
  
  nibpRows: [
    {
      systolicSetting: number,
      diastolicSetting: number,
      systolicReads: [number, ...],
      diastolicReads: [number, ...],
      systolicStatus: boolean|null,
      diastolicStatus: boolean|null
    },
    ...
  ],
  
  respirationRows: [
    {
      settingValue: number,
      reads: [number, ...],
      average: number,
      status: boolean|null
    },
    ...
  ],
  
  temp1Rows: [
    {
      settingValue: number,
      reads: [number, ...],
      average: number,
      status: boolean|null
    },
    ...
  ],
  
  temp2Rows: [
    {
      settingValue: number,
      reads: [number, ...],
      average: number,
      status: boolean|null
    },
    ...
  ],
  
  // Notes & Results
  notes: string,
  hospitalName: string,
  testDate: timestamp,
  certificateNumber: string,
  qualitativeResult: "PASS|FAIL|N/F",
  quantitativeResult: "PASS|FAIL|N/F",
  overallResult: "PASS|FAIL|N/F",
  certificateUrl: string (Firebase Storage URL),
  supabasePath: string (optional, legacy),
  
  // Metadata
  createdAt: timestamp,
  status: "draft|completed"
}
```

**Indexes:**
- `engineerId` + `createdAt` (descending)
- `serialNumber` + `createdAt` (descending)
- `status` + `createdAt` (descending)

---

### 2. `public_calibrations` (Public Data)
**Purpose:** Publicly accessible calibration data (for clients/hospitals)

**Document ID:** Same as calibrations document

**Fields:**
```
{
  hospitalName: string,
  manufacturer: string,
  model: string,
  serialNumber: string,
  department: string,
  visitDate: timestamp,
  certificateNumber: string,
  qualitativeResult: "PASS|FAIL|N/F",
  quantitativeResult: "PASS|FAIL|N/F",
  overallResult: "PASS|FAIL|N/F",
  certificateUrl: string,
  createdAt: timestamp
}
```

**Security:** Can be read by anyone with serial number

---

### 3. `qualitative_results` (Qualitative Data)
**Purpose:** Detailed qualitative test results

**Document ID:** Same as calibrations document

**Fields:**
```
{
  calibrationId: string,
  serialNumber: string,
  qualitativeResults: {
    "item_name": "pass|fail|na",
    ...
  },
  ecgRepresentation: {
    "ecg_item": "pass|fail|na",
    ...
  },
  qualitativeResult: "PASS|FAIL|N/F",
  createdAt: timestamp
}
```

---

### 4. `quantitative_results` (Measurement Data)
**Purpose:** All measurement/quantitative test data

**Document ID:** Same as calibrations document

**Fields:**
```
{
  calibrationId: string,
  serialNumber: string,
  hrRows: [...],
  spo2Rows: [...],
  nibpRows: [...],
  respirationRows: [...],
  temp1Rows: [...],
  temp2Rows: [...],
  quantitativeResult: "PASS|FAIL|N/F",
  createdAt: timestamp
}
```

---

### 5. `notes` (Session Notes)
**Purpose:** Engineer notes and observations

**Document ID:** Same as calibrations document

**Fields:**
```
{
  calibrationId: string,
  serialNumber: string,
  notes: string,
  createdAt: timestamp
}
```

---

### 6. `final_results` (Summary Results)
**Purpose:** Final pass/fail summary for quick queries

**Document ID:** Same as calibrations document

**Fields:**
```
{
  calibrationId: string,
  serialNumber: string,
  certificateNumber: string,
  qualitativeResult: "PASS|FAIL|N/F",
  quantitativeResult: "PASS|FAIL|N/F",
  overallResult: "PASS|FAIL|N/F",
  testDate: timestamp,
  createdAt: timestamp
}
```

**Indexes:**
- `overallResult` + `createdAt` (descending)
- `serialNumber` + `createdAt` (descending)

---

### 7. `engineers` (Engineer Profiles)
**Purpose:** Engineer information and statistics

**Document ID:** User UID

**Fields:**
```
{
  uid: string,
  fullName: string,
  email: string,
  phone: string,
  role: "engineer|admin",
  photoUrl: string (optional),
  totalCalibrations: number,
  lastCalibrationDate: timestamp,
  createdAt: timestamp
}
```

**Sub-collection:** `calibrations`
- Contains references to all calibrations by this engineer
- Document ID: Same as calibrations document

---

### 8. `clients` (Client/Hospital Data)
**Purpose:** Client information and their calibrations

**Document ID:** Client name (spaces replaced with underscores)

**Fields:**
```
{
  clientName: string,
  clientEmail: string,
  hospitalName: string,
  department: string,
  createdAt: timestamp
}
```

**Sub-collection:** `calibrations`
- Contains all calibrations for this client
- Document ID: Same as calibrations document

**Fields in sub-collection:**
```
{
  clientName: string,
  clientEmail: string,
  hospitalName: string,
  department: string,
  serialNumber: string,
  manufacturer: string,
  model: string,
  certificateNumber: string,
  overallResult: "PASS|FAIL|N/F",
  visitDate: timestamp,
  createdAt: timestamp
}
```

---

## Firebase Storage Structure

### Certificate Files
**Path:** `certificates/{engineerId}/{serialNumber}_{certificateNumber}.docx`

**Example:** `certificates/user123/SN-12345_001-2026.docx`

**Access:** Private to engineer, downloadable via signed URL

---

## Data Upload Workflow

### Complete Upload Process
When calibration is finished, the following data is uploaded in order:

1. **Main Calibration Session** → `calibrations` collection
2. **Engineer Data** → `engineers/{uid}/calibrations` sub-collection
3. **Client Data** → `clients/{clientName}/calibrations` sub-collection
4. **Qualitative Results** → `qualitative_results` collection
5. **Quantitative Results** → `quantitative_results` collection
6. **Notes** → `notes` collection
7. **Final Results** → `final_results` collection
8. **Certificate File** → Firebase Storage
9. **Public Data** → `public_calibrations` collection

---

## Security Rules

### Firestore Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Engineers can read/write their own calibrations
    match /engineers/{uid} {
      allow read, write: if request.auth.uid == uid;
      match /calibrations/{document=**} {
        allow read, write: if request.auth.uid == uid;
      }
    }
    
    // Clients can read their own calibrations
    match /clients/{clientId}/calibrations/{document=**} {
      allow read: if request.auth.uid != null;
    }
    
    // Public calibrations readable by anyone with serial number
    match /public_calibrations/{document=**} {
      allow read: if true;
    }
    
    // Qualitative/Quantitative results readable by engineer
    match /qualitative_results/{document=**} {
      allow read, write: if request.auth.uid != null;
    }
    
    match /quantitative_results/{document=**} {
      allow read, write: if request.auth.uid != null;
    }
    
    // Final results readable by engineer
    match /final_results/{document=**} {
      allow read: if request.auth.uid != null;
    }
  }
}
```

### Storage Rules
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

## Query Examples

### Get all calibrations for an engineer
```
db.collection('calibrations')
  .where('engineerId', '==', engineerId)
  .orderBy('createdAt', 'desc')
  .get()
```

### Get calibrations by serial number
```
db.collection('calibrations')
  .where('serialNumber', '==', serialNumber)
  .orderBy('createdAt', 'desc')
  .get()
```

### Get all PASS results
```
db.collection('final_results')
  .where('overallResult', '==', 'PASS')
  .orderBy('createdAt', 'desc')
  .get()
```

### Get client calibrations
```
db.collection('clients')
  .doc(clientName)
  .collection('calibrations')
  .orderBy('createdAt', 'desc')
  .get()
```

---

## Data Retention & Archival

- **Active calibrations:** Kept in main collections indefinitely
- **Certificates:** Stored in Firebase Storage with 7-year retention policy
- **Backups:** Automated daily backups via Firebase
- **Archival:** Old records (>5 years) can be exported to Cloud Storage

---

## Integration with App

### Upload Manager Usage
```dart
final manager = FirebaseUploadManager();

// Complete upload with progress tracking
await manager.uploadCompleteCalibration(
  session,
  certificatePath: certPath,
  clientEmail: email,
  onStatusUpdate: (status) {
    print('Status: $status');
  },
);

// Check progress
print('Progress: ${manager.uploadProgress.value}');
print('Status: ${manager.uploadStatus.value}');
```

### Firebase Service Usage
```dart
// Upload individual components
await FirebaseService.uploadCalibrationSession(session);
await FirebaseService.saveEngineerData(engineerId, session);
await FirebaseService.saveClientData(session, clientEmail);

// Fetch data
final calibrations = await FirebaseService.fetchEngineerCalibrations(engineerId);
final publicData = await FirebaseService.fetchPublicCalibration(serialNumber);
```

---

## Monitoring & Analytics

### Key Metrics to Track
- Total calibrations per engineer
- Pass/Fail ratio
- Average time to complete calibration
- Certificate generation success rate
- Upload success rate

### Recommended Dashboards
- Engineer performance dashboard
- Client calibration history
- Device calibration trends
- System health monitoring

