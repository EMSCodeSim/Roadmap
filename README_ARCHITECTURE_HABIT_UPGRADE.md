# FireOps Career Road — Architecture Foundations + Habit Loop Upgrade

This upgrade reduces long-term maintenance cost and prepares the product for stronger daily-habit features.

## What changed

### 1. Domain models extracted from AppState
The following types previously lived inside `lib/state/app_state.dart` and are now first-class models:

- `RoadmapRequirement`
- `RequirementActivityStatus`
- `TrainingSchedule`
- `PathRequirementOverride`
- `Roadmap` (including `nextStep` / progress helpers)
- `PendingCertMatch`

**New file:** `lib/models/roadmap_models.dart`

`AppState` now imports these models instead of defining them. This makes the domain reusable by services, PDF export, tests, and future controllers without depending on the full `ChangeNotifier`.

### 2. Shared UI primitives
Three small, reusable widgets were added so large pages stop re-implementing the same patterns:

| Widget | Purpose |
|--------|---------|
| `StatusPill` | Compact status chip (current / expiring / next step / etc.) |
| `ProgressRing` | Circular readiness / completion indicator |
| `SectionHeader` | Consistent title + optional subtitle + trailing action |

**Files:**
- `lib/widgets/status_pill.dart`
- `lib/widgets/progress_ring.dart`
- `lib/widgets/section_header.dart`

### 3. Notification preferences scaffold
`NotificationPreferencesStore` stores local toggles for:

- Daily Focus reminders
- Certification expiry alerts
- Target-date risk alerts

No OS notification permission or scheduling is wired yet. This is the data layer only so a later upgrade can add `flutter_local_notifications` without another data-model change.

**File:** `lib/services/notification_preferences_store.dart`

### 4. Daily Focus copy clarity
Visual Home Daily Focus helper text now explicitly names the session loop: **Learn → Practice → Record**.

## Why this matters

- `AppState` dropped from ~1,600 lines toward a thinner coordinator role.
- Domain logic can be unit-tested without UI or `ChangeNotifier`.
- Future work (Riverpod/Bloc split, Isar/Drift migration, real local notifications) has cleaner seams.
- UI consistency improves as pages adopt the shared widgets.

## How to apply

```bash
python3 tools/apply_architecture_habit_upgrade.py
dart format lib/models/roadmap_models.dart lib/state/app_state.dart lib/widgets lib/services/notification_preferences_store.dart
flutter analyze
flutter test
```

## Follow-on work (recommended next upgrades)

1. Adopt `ProgressRing` + `StatusPill` on `VisualHomePage` Career Readiness and Cert cards.
2. Split remaining AppState responsibilities into focused controllers (`ProfileController`, `CertificationsController`, `TaskBookController`, `CareerRecordController`).
3. Move `FireOpsCatalog` static data into JSON/YAML assets.
4. Wire `flutter_local_notifications` on top of `NotificationPreferencesStore`.
5. Expand widget tests around `Roadmap.nextStep` and the Daily Focus → Record path.

## Compatibility

- No portfolio schema change.
- No SharedPreferences key changes except the new optional notification preference keys.
- Existing backups and task-book progress remain valid.
