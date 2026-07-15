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
