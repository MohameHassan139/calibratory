# Caliborty - Medical Equipment Calibration App
## وحدة معايرة واستشارات الأجهزة الطبية (UMECC)
### Faculty of Engineering · Minia University

---

## 📱 App Overview

**Caliborty** is a Flutter mobile application for the UMECC unit that enables biomedical engineers to:
- Conduct full patient monitor calibration workflows
- Generate ISO 13485-compliant calibration certificates (Word .docx)
- Store certificates on Supabase cloud storage
- Deliver certificates to clients via email
- Create price offers for maintenance services
- Track calibration history

---

## 🏗️ Architecture

```
Clean Architecture + GetX State Management

lib/
├── core/
│   ├── constants/        → Routes, strings, monitor constants
│   └── theme/            → AppTheme, AppColors
├── data/
│   └── models/           → CalibrationSession, AppUser, PriceOffer
└── presentation/
    ├── controllers/       → AuthController, CalibrationController
    ├── screens/
    │   ├── splash/        → Animated splash
    │   ├── onboarding/    → 3-page onboarding
    │   ├── auth/          → Login, Register, Forgot Password
    │   ├── home/          → Dashboard with stats
    │   ├── calibration/   → Full calibration flow (7 steps)
    │   ├── price_offer/   → Revenue calculator
    │   ├── history/       → Past sessions
    │   └── profile/       → User profile
    ├── services/
    │   ├── certificate_service.dart  → DOCX generation
    │   └── email_service.dart        → Firebase Cloud Function call
    └── widgets/           → Shared reusable widgets
```

---

## 🔧 Services

| Service | Purpose |
|---------|---------|
| **Firebase Auth** | Login, Register, Forgot Password |
| **Cloud Firestore** | Store calibration sessions, user data, price offers |
| **Supabase Storage** | Store generated .docx certificate files |
| **Firebase Cloud Functions** | Send certificate email to client (nodemailer) |

---

## 📋 Calibration Flow (Monitor)

### Step 1: Public Data
- Customer Name, Order Date, Visit Date, Visit Time
- Department, Manufacturer, Serial Number, Model

### Step 2: Qualitative Test
Each item: **Pass / Fail / N/A**

| Section | Items |
|---------|-------|
| Physical | Chassis, Casters, AC plug, Line Cord, Screen, Controls, Battery, Indicator, Labeling, Alarms, Module Housing, Mounting |
| Cables | SPO2 cable, NIBP Cuff, NIBP cable, TEMP CABLE/S, ECG CABLE |
| ECG Representation | AF, PVC, VF, PAT, AFL, PVT, Standard signals, ECG waveforms |

### Steps 3-7: Measurement Tables

#### Cable Visibility Rules
```
HR Table:           ECG cable ≠ N/A  AND  SPO2 cable ≠ N/A
SPO2 Table:         SPO2 cable ≠ N/A
NIBP Table:         NIBP Cuff ≠ N/A AND ≠ Fail  AND  NIBP cable ≠ N/A AND ≠ Fail
Respiration Table:  ECG cable ≠ N/A
Temp Tables (×2):   TEMP CABLE/S ≠ N/A
```

#### Accepted Ranges (from handwritten notes + PDF)
| Parameter | Formula |
|-----------|---------|
| Heart Rate | `x ± (x×5/100) ± 1` |
| SPO2 | `x ± (x×2/100)` |
| NIBP | `x ± (x×2/100)` |
| Respiration | `x ± (x×1/100)` |
| Temperature | `x ± (x×0.2/100)` |

#### Measurement Logic
- Engineer enters **3 readings** per row
- App computes **average**
- Checks if average is within accepted range
- Sets **Status: Pass/Fail**
- If cable is N/A → all values in that table = **"NF"** in certificate

#### Overall Result
- `نتيجة الاختبار = PASS` only if ALL rows in ALL visible tables = Pass
- Any single Fail → Overall = **FAIL**

---

## 📄 Certificate Generation

- Template: `assets/monitor_certificate.docx`
- Engine: `docx_template` package
- Variables replaced: customer data, table rows, status values
- NF tables: all cells filled with "NF"
- Uploaded to Supabase bucket: `certificates/{engineerId}/{serial}_{timestamp}.docx`
- Public URL stored in Firestore and sent to client

---

## 💰 Price Offer

14 device types:
ECG Machines, NIBP Monitors, Pulse Oximeters, Fetal Monitors, Infusion Pumps, 
Syringe Pumps, Manual Defibrillators, AEDs, Ventilators, CPAP/BiPAP, 
Suction Machines, ESU, Oxygen Cylinder, Electrical Safety

Per device: Price × Qty + Electric Check ☑ / Function Check ☑
Total computed automatically. Email sent to client on save.

---

## 🚀 Setup Instructions

### 1. Flutter Setup
```bash
flutter pub get
```

### 2. Firebase Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and init
firebase login
firebase init

# Add google-services.json (Android) / GoogleService-Info.plist (iOS)
```

### 3. Firebase Configuration
Create `lib/firebase_options.dart` via:
```bash
flutterfire configure
```

### 4. Supabase Setup
1. Create project at supabase.com
2. Create bucket named `certificates` (public)
3. Update `main.dart` with your URL and anon key

### 5. Cloud Functions (Email)
```bash
cd functions
npm install
firebase functions:config:set email.user="your@gmail.com" email.password="app_password"
firebase deploy --only functions
```

### 6. Fonts
Download and add to `assets/fonts/`:
- Syne (Regular, Bold, ExtraBold) — fonts.google.com/specimen/Syne
- DM Sans (Regular, Medium, Bold) — fonts.google.com/specimen/DM+Sans

### 7. Certificate Template
Add `monitor_certificate.docx` to `assets/` and update `pubspec.yaml`:
```yaml
assets:
  - assets/monitor_certificate.docx
```

The template should use `{{variable_name}}` placeholders matching the keys 
used in `CertificateService.generateCertificate()`.

---

## 📦 Key Dependencies

| Package | Version | Use |
|---------|---------|-----|
| get | ^4.6.6 | State management + routing |
| firebase_auth | ^5.3.1 | Authentication |
| cloud_firestore | ^5.4.3 | Database |
| supabase_flutter | ^2.5.6 | File storage |
| docx_template | ^0.4.2 | Word document generation |
| flutter_animate | ^4.5.0 | Animations |
| smooth_page_indicator | ^1.2.0 | Onboarding dots |

---

## 🎨 Design System

| Token | Value |
|-------|-------|
| Primary (Navy) | #0D1B2A |
| Accent (Blue) | #1565C0 |
| Background | #F4F6FA |
| Success | #00C853 |
| Error | #E53935 |
| Font Display | Syne |
| Font Body | DM Sans |

---

## 📂 Firestore Collections

```
users/{uid}
  fullName, email, phone, role, photoUrl, createdAt

calibrations/{calibrationId}  
  engineerId, customerName, orderDate, visitDate, department,
  manufacturer, serialNumber, model, qualitativeResults,
  ecgRepresentation, hrRows, spo2Rows, nibpRows, respirationRows,
  temp1Rows, temp2Rows, notes, overallResult, certificateUrl,
  supabasePath, createdAt, status

price_offers/{offerId}
  engineerId, clientName, clientEmail, items[], total, createdAt
```

---

*Built with ❤️ for UMECC · Biomedical Engineering Department*
