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

## Getting Started

### Prerequisites

- Flutter 3.32+ and Dart 3.8+ (`flutter --version`)
- Chrome browser (the app targets Flutter web)
- A Firebase project with **Authentication** (Email/Password) and **Firestore** enabled
- A Cloudinary account with an unsigned upload preset for profile photos
- Node.js 18+ (only needed to run the admin seeding script)

### 1. Clone and install dependencies

```bash
git clone https://github.com/<your-username>/alu-connect.git
cd alu-connect
flutter pub get
```

### 2. Configure Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Email/Password** under Authentication → Sign-in method
3. Create a Firestore database (Start in production mode is fine; rules below)
4. Register a **Web** app and download the config
5. Run `flutterfire configure` (requires `dart pub global activate flutterfire_cli`) — this generates `lib/firebase_options.dart` which is gitignored

### 3. Configure environment variables

Create a `.env` file at the project root (gitignored):

```env
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_unsigned_preset
```

### 4. Firestore security rules (recommended minimum)

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

### 5. Run the app

```bash
flutter run -d chrome
```

Open Chrome DevTools → Toggle device toolbar and pick a phone viewport for the intended mobile layout.

---

## Admin Account Setup

The admin account cannot be created through the normal signup flow. It must be provisioned server-side using the Firebase Admin SDK seeding script.

### One-time setup

```bash
cd scripts
npm install firebase-admin
```

Download your **Service Account Key** from Firebase Console → Project Settings → Service Accounts → Generate new private key. Save the file as `scripts/serviceAccountKey.json` (it is gitignored — never commit it).

### Run the script

```bash
node seed_admin.js
```

The script will:
1. Look up any existing user with `admin@aluconnect.com` in Firebase Auth and delete them
2. Delete the corresponding Firestore `users/` document if it exists
3. Create a fresh Auth user with `emailVerified: true`
4. Write the Firestore document with `role: 'admin'`, `isOnboarded: true`

**Admin credentials**

| Field | Value |
|-------|-------|
| Email | `admin@aluconnect.com` |
| Password | `Admin@2026` |

> Change the password in the Firebase Console after first login.

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
