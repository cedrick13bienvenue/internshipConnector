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
