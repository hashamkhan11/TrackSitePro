# TrackSitePro

TrackSitePro (internally: SNGPL Contractor Project Management App) is a
Flutter app for managing contractor-run construction/field projects: tracking
project progress, daily progress reports (DPRs), resources, expenses,
payments, and invoices, with role-based dashboards for the different people
involved in a project.

## Roles

The app has three roles, stored on each user's `users/{uid}` document:

- **Contractor** — owns a firm, creates and manages projects under it,
  assigns supervisors, and handles payments/invoices/expenses for their own
  projects.
- **Supervisor** — added to a specific firm by its contractor; manages the
  day-to-day of the projects they're assigned to (DPRs, resources, documents)
  without contractor-level financial control.
- **Admin** — cross-firm oversight: broader read access across firms and
  projects, and the only role allowed to touch approval/status and payment
  fields that the UI treats as admin-only actions.

Which dashboard a signed-in user lands on (`lib/screens/dashboard/`) is
decided by this role at login (`lib/screens/auth/role_redirector.dart`).

## Data model (Firestore)

- `users/{uid}` — profile + `role` (`contractor` | `supervisor` | `admin`)
- `firms/{firmId}` — a contractor's firm; `firms/{firmId}/supervisors/{uid}`,
  `firms/{firmId}/documents/{docId}`
- `projects/{projectId}` — scoped to a firm; subcollections for
  `payments`, `expenses`, `invoices`, `documents`, `dprs`, `resources`
- `notifications/{uid}/user_notifications/{id}`
- `categories/{id}`, `schedule_of_rates/{id}` — admin-managed reference data

Firestore and Storage security rules enforcing this ownership model live at
the repo root (`firestore.rules`, `storage.rules`) — see the comments at the
top of each file for the reasoning and for the manual validation/deploy
steps required before they take effect on the live project.

## Tech stack

- **Flutter** (Dart) — cross-platform client, targeting Android and iOS
- **Firebase** — Authentication, Cloud Firestore, Cloud Storage
- PDF generation for invoices (`lib/services/pdf_invoice_generator.dart`)

## Getting started

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install)
   and make sure `flutter doctor` is clean for the platforms you're
   targeting.
2. Install dependencies:
   ```
   flutter pub get
   ```
3. Set up a Firebase project and generate `lib/firebase_options.dart` for it
   with the FlutterFire CLI:
   ```
   flutterfire configure
   ```
4. Run the app:
   ```
   flutter run
   ```

## Testing & analysis

```
flutter analyze
flutter test
```

## Deploying security rules

Committing `firestore.rules` / `storage.rules` to this repo does **not**
deploy them. After validating changes (Firebase Emulator Suite or the Rules
Playground in the console), deploy explicitly:

```
firebase deploy --only firestore:rules,storage:rules
```
