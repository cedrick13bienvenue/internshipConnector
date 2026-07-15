# ALU Connect

**A role-based mobile platform connecting ALU students with campus startup opportunities.**

ALU Connect bridges ALU students seeking internship experience with student-led startups and early-stage ventures on campus. Startups post opportunities; students discover, apply, and track their applications in real time — replacing informal word-of-mouth and scattered group-chat postings that currently mediate this exchange.

> **Demo Video:** [https://youtu.be/oFa65CZeCs4](https://youtu.be/oFa65CZeCs4)
> **Technical Report:** [`CedricBienvenue_FinalFlutterProject.pdf`](CedricBienvenue_FinalFlutterProject.pdf)
> **Author:** Cedrick Bienvenue · ALU · July 2026

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.32 / Dart 3.8 |
| Authentication | Firebase Auth (email/password, role-based) |
| Database | Cloud Firestore (real-time streams) |
| State Management | BLoC / Cubit (`flutter_bloc`) |
| Navigation | GoRouter (declarative, role-aware) |
| Image Hosting | Cloudinary (profile photos) |
| Admin Provisioning | Firebase Admin SDK (Node.js seeding script) |
| Platform Target | Chrome (web, mobile DevTools view) |

---

## Features

### Student
- Role-based registration with ALU email (`@alustudent.com`) and email verification
- Opportunity discovery feed with real-time Firestore streaming
- Category filter chips and in-memory keyword search (no extra reads)
- Opportunity bookmarking
- One-click application with cover note and resume URL (Google Drive / Dropbox)
- Application status tracking pipeline: Applied → Under Review → Shortlisted → Interview → Accepted / Rejected
- In-app notifications with unread bell badge when startup updates application status

### Startup
- Role-based registration with ALU email and two-layer verification (email + admin approval)
- Pending verification banner blocks posting until admin approves
- Post, edit, close (status update), and permanently delete opportunities
- Applicants tab grouped by opportunity with applicant count and starred count per group
- Drill-down per opportunity: sort by newest/oldest, filter by status or starred
- Star / mark applicants for review
- Copy applicant email directly from the detail page for follow-up outside the platform
- Status changes automatically notify the student in-app

### Admin
- Separate dashboard accessible only to the `admin` role
- Review and approve pending startup registrations (flips `isVerified` in Firestore)
- Admin account provisioned via Firebase Admin SDK seeding script (not the public signup flow)

---

## Architecture

ALU Connect follows a strict three-layer architecture:

```
UI (Widgets)  →  BLoC / Cubit  →  Repository  →  Firebase
     ↑                ↑                              |
     └────────────────┴──────── state stream ────────┘
```

- **UI layer** — stateless widgets that render from BLoC/Cubit state. No direct Firestore calls anywhere in the UI.
- **BLoC / Cubit layer** — owns feature state (auth, opportunity feed, applications, notifications). Emits immutable state; widgets subscribe via `BlocBuilder` / `BlocListener`.
- **Repository layer** — the sole layer that talks to Firestore. All reads use `.snapshots()` streams for real-time updates. Isolating this layer means the backend can be swapped without touching UI or state code.
- **GoRouter** — declarative, role-aware routing. The `redirect` function enforces: unverified → `/verify-email`, not onboarded → `/onboarding`, admin → `/admin`, everyone else → `/home`.
- **Conditional imports** — `web.dart` / `stub.dart` pairs isolate any browser-only API (e.g. `dart:html` for iframe resume embedding) so the same feature code compiles for both web and mobile targets.

---

## Folder Structure

```
lib/
├── core/
│   ├── constants/        # Colors, app constants, strings
│   ├── router/           # GoRouter setup and role-based redirect logic
│   ├── theme/            # App theme
│   └── utils/            # Validators, toast helpers
│
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── models/   # UserModel
    │   │   └── repositories/ # AuthRepository (Firebase Auth + Firestore)
    │   └── presentation/
    │       ├── cubit/    # AuthCubit + AuthState
    │       └── pages/    # Login, Signup, Onboarding, EmailVerification, Splash
    │
    ├── opportunities/
    │   ├── data/
    │   │   ├── models/   # OpportunityModel
    │   │   └── repositories/ # OpportunityRepository (CRUD + streams)
    │   └── presentation/
    │       ├── cubit/    # OpportunityCubit + OpportunityState
    │       ├── pages/    # Detail, Post, Edit, Explore
    │       └── widgets/  # OpportunityCard, BookmarkButton
    │
    ├── applications/
    │   ├── data/
    │   │   ├── models/   # ApplicationModel (status pipeline, isStarred)
    │   │   └── repositories/ # ApplicationRepository (updateStatus writes notification)
    │   └── presentation/
    │       └── pages/    # Form, ApplicantsTab, OpportunityApplicants, ApplicantDetail, ResumeViewer
    │
    ├── startups/
    │   ├── data/
    │   │   ├── models/   # StartupModel
    │   │   └── repositories/ # StartupRepository
    │   └── presentation/
    │       ├── cubit/    # StartupCubit
    │       └── pages/    # Profile, Registration, Edit
    │
    ├── notifications/
    │   ├── data/
    │   │   ├── models/   # NotificationModel
    │   │   └── repositories/ # NotificationRepository (single-field query + in-memory sort)
    │   └── presentation/
    │       └── pages/    # NotificationsPage
    │
    ├── home/
    │   └── presentation/
    │       └── pages/    # HomeTabPage (student + startup views), MainShellPage
    │
    ├── profile/
    │   └── presentation/
    │       └── pages/    # ProfileTabPage, EditStudentProfilePage
    │
    └── admin/
        └── presentation/
            └── pages/    # AdminDashboardPage (startup approval)

scripts/
└── seed_admin.js         # Firebase Admin SDK script to provision admin account
```

---

## Firebase / Firestore Schema

### Collections

**`users/{uid}`**
| Field | Type | Notes |
|-------|------|-------|
| `uid` | string | matches Firebase Auth UID |
| `email` | string | must end in `@alustudent.com` |
| `fullName` | string | |
| `role` | `student` \| `startup` \| `admin` | drives routing and UI |
| `isOnboarded` | bool | false until onboarding wizard completes |
| `isEmailVerified` | bool | mirrored from Firebase Auth |
| `bio` | string? | student only |
| `skills` | string[] | student only |
| `program` | string? | student only |
| `photoUrl` | string? | Cloudinary CDN URL |
| `savedOpportunities` | string[] | opportunity IDs bookmarked by student |
| `createdAt` | Timestamp | |

**`startups/{startupId}`**
| Field | Type | Notes |
|-------|------|-------|
| `ownerId` | string | user UID of founding startup member |
| `name` | string | |
| `description` | string | |
| `categories` | string[] | used for filtering |
| `websiteUrl` | string? | |
| `verificationStatus` | `pending` \| `verified` | admin toggles to `verified` |
| `logoUrl` | string? | |
| `createdAt` | Timestamp | |

**`opportunities/{opportunityId}`**
| Field | Type | Notes |
|-------|------|-------|
| `startupId` | string | |
| `startupName` | string | denormalized for card display |
| `title` | string | |
| `description` | string | |
| `category` | string | |
| `type` | string | e.g. Internship, Part-time |
| `status` | `open` \| `closed` | startup can close without deleting |
| `postedAt` | Timestamp | |

**`applications/{applicationId}`**
| Field | Type | Notes |
|-------|------|-------|
| `opportunityId` | string | |
| `startupId` | string | |
| `studentId` | string | |
| `studentName` | string | denormalized |
| `studentEmail` | string | denormalized for startup to copy |
| `coverNote` | string | |
| `resumeUrl` | string | Google Drive / Dropbox link |
| `status` | `applied` \| `under_review` \| `shortlisted` \| `interview` \| `accepted` \| `rejected` | |
| `isStarred` | bool | startup stars applicants |
| `appliedAt` | Timestamp | |

**`notifications/{notificationId}`**
| Field | Type | Notes |
|-------|------|-------|
| `userId` | string | student receiving the notification |
| `title` | string | |
| `body` | string | |
| `isRead` | bool | |
| `createdAt` | Timestamp | written by `ApplicationRepository.updateStatus` |

> Notifications are queried with a single `.where('userId')` filter and sorted in-memory to avoid requiring a Firestore composite index.

---

## Local Setup — Complete Guide

Follow every step in order. The app will not run if any step is skipped.

---

### Step 1 — Install Flutter

1. Download the Flutter SDK from [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) for your OS
2. Extract and add the `flutter/bin` folder to your `PATH`
3. Verify:

```bash
flutter --version
# should print Flutter 3.32.x • Dart 3.8.x
```

4. Install Chrome if you don't have it — the app targets Flutter web only
5. Run the Flutter doctor to check for any missing dependencies:

```bash
flutter doctor
```

---

### Step 2 — Clone the repository

```bash
git clone https://github.com/<your-username>/alu-connect.git
cd alu-connect
flutter pub get
```

`flutter pub get` downloads all Dart/Flutter packages listed in `pubspec.yaml`.

---

### Step 3 — Create a Firebase project

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and click **Add project**
2. Give it a name (e.g. `alu-connect`), disable Google Analytics if you don't need it, click **Create project**

#### Enable Email/Password Authentication

1. In the Firebase console, go to **Build → Authentication → Get started**
2. Under **Sign-in method**, click **Email/Password** and toggle it **Enabled** → Save

#### Create a Firestore database

1. Go to **Build → Firestore Database → Create database**
2. Choose **Start in production mode** → select a region close to you → **Enable**

#### Apply security rules

In the Firestore console go to **Rules** tab and paste:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    match /startups/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /opportunities/{id} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    match /applications/{id} {
      allow read, write: if request.auth != null;
    }
    match /notifications/{id} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Click **Publish**.

---

### Step 4 — Connect Flutter to Firebase (FlutterFire CLI)

1. Install the FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

2. Log in to Firebase from the terminal:

```bash
firebase login
```

3. Inside the project root, run:

```bash
flutterfire configure
```

- Select your Firebase project from the list
- Select only **Web** as the target platform
- This generates `lib/firebase_options.dart` — it is gitignored and must never be committed

---

### Step 5 — Set up Cloudinary (profile photo uploads)

1. Create a free account at [cloudinary.com](https://cloudinary.com)
2. From the **Dashboard**, note your **Cloud name** (shown at the top)
3. Go to **Settings → Upload → Upload presets → Add upload preset**
   - Set **Signing mode** to **Unsigned**
   - Give it a name (e.g. `alu_connect_unsigned`)
   - Save

---

### Step 6 — Create the `.env` file

In the project root, create a file named `.env` (gitignored — never commit it):

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name_here
CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset_name_here
```

Replace the values with what you copied from the Cloudinary dashboard.

---

### Step 7 — Seed the admin account

The admin user cannot sign up through the app. It must be created server-side using the Firebase Admin SDK seeding script.

#### 7a. Install Node.js dependencies

```bash
cd scripts
npm install firebase-admin
```

#### 7b. Download your Service Account Key

1. In the Firebase console, go to **Project Settings → Service Accounts**
2. Click **Generate new private key** → **Generate key** — a JSON file downloads
3. Rename it `serviceAccountKey.json` and place it inside the `scripts/` folder

> This file contains sensitive credentials. It is gitignored — never commit it.

#### 7c. Run the seeding script

```bash
node seed_admin.js
```

Expected output:

```
Deleted existing auth user: ...   (or: No existing admin user found...)
Created auth user: <uid>
Firestore user doc created

✓ Admin seeded successfully
  Email:    admin@aluconnect.com
  Password: Admin@2026
```

#### Admin credentials

| Field | Value |
|-------|-------|
| Email | `admin@aluconnect.com` |
| Password | `Admin@2026` |

> Re-run the script any time you lose access to the admin account — it will delete and re-create it.

Go back to the project root after running the script:

```bash
cd ..
```

---

### Step 8 — Run the app

```bash
flutter run -d chrome
```

Chrome will open automatically. To simulate a mobile viewport:

1. Open **Chrome DevTools** (F12 or Cmd+Option+I)
2. Click the **Toggle device toolbar** icon (phone/tablet icon)
3. Pick any phone preset (e.g. iPhone 12 Pro)

---

### Full setup checklist

| # | Step | Done |
|---|------|------|
| 1 | Flutter 3.32+ installed and `flutter doctor` passes | ☐ |
| 2 | Repository cloned and `flutter pub get` run | ☐ |
| 3 | Firebase project created with Auth + Firestore enabled | ☐ |
| 4 | Firestore rules published | ☐ |
| 5 | `flutterfire configure` run — `lib/firebase_options.dart` generated | ☐ |
| 6 | Cloudinary account created with an unsigned upload preset | ☐ |
| 7 | `.env` file created with Cloudinary values | ☐ |
| 8 | `scripts/serviceAccountKey.json` added | ☐ |
| 9 | `node seed_admin.js` run successfully | ☐ |
| 10 | `flutter run -d chrome` launches the app | ☐ |

---

## Demo

### Video Walkthrough

[![ALU Connect Demo](https://img.shields.io/badge/Watch%20Demo-YouTube-red?logo=youtube)](https://youtu.be/oFa65CZeCs4)

> **[https://youtu.be/oFa65CZeCs4](https://youtu.be/oFa65CZeCs4)**

The demo covers:
- Student signup with ALU email + email verification
- Student onboarding (skills, program)
- Startup registration and pending verification state
- Admin login and startup approval flow
- Posting, closing, and deleting an opportunity
- Student applying with a cover note and resume link
- Startup managing applicants (star, status update)
- In-app notification received by the student

### Screenshots

| Role | Screen |
|------|--------|
| Student | Opportunity feed with category filters and live search |
| Student | Application status tracker (Applied → Accepted) |
| Startup | Applicants tab grouped by opportunity |
| Admin | Dashboard — pending startup approval queue |

---

## Technical Report

The full technical report, including system design decisions, data flow diagrams, ERD, and evaluation against the assignment rubric, is available in the repository:

> [`CedricBienvenue_FinalFlutterProject.pdf`](CedricBienvenue_FinalFlutterProject.pdf)

### Key design decisions documented in the report

- **BLoC/Cubit over setState** — Chosen for clear separation of business logic and testability across features with complex async flows (auth, applications, notifications)
- **Firestore streams over polling** — Real-time `snapshots()` throughout so the UI reflects backend state without manual refresh
- **Single-field queries + in-memory sort** — Avoids composite Firestore index requirements on the free Spark plan while preserving sort order
- **Optimistic state emit** — Cubits emit new state before the Firestore write completes; users see instant feedback without waiting for round-trip latency
- **Conditional web/stub imports** — Isolates `dart:html` usage so startup resume embedding compiles cleanly on all targets
- **Admin SDK seeding** — Admin account created server-side to bypass the public signup flow; avoids a fake email recovery scenario

---

## License

This project was built for the ALU Flutter Development final assignment (July 2026).

© 2026 Cedrick Bienvenue · African Leadership University
