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

**File:** `lib/models/roadmap_models.dart`

`AppState` imports and re-exports these models so existing `import '.../app_state.dart'` call sites keep working while services and unit tests can depend on the domain layer directly.

### 2. Shared UI primitives
Reusable widgets so large pages stop re-implementing the same patterns:

| Widget | Purpose |
|--------|---------|
| `StatusPill` | Compact status chip (current / expiring / next step / etc.) |
| `ProgressRing` | Circular readiness / completion indicator |
| `SectionHeader` | Consistent title + optional subtitle + trailing action |

**Files:**
- `lib/widgets/status_pill.dart`
- `lib/widgets/progress_ring.dart`
- `lib/widgets/section_header.dart`

`VisualHomePage` Career Readiness now uses `ProgressRing`. Advance hub status chips use `StatusPill`.

### 3. Notification preferences scaffold
`NotificationPreferencesStore` stores local toggles for:

- Daily Focus reminders
- Certification expiry alerts
- Target-date risk alerts

Settings exposes these toggles. OS notification permission/scheduling is still not wired — this is the data layer so a later upgrade can add `flutter_local_notifications` without another model change.

**File:** `lib/services/notification_preferences_store.dart`

### 4. Daily Focus copy clarity
Visual Home Daily Focus helper text explicitly names the session loop: **Learn → Practice → Record**.

### 5. Legacy page cleanup
Removed unused parallel implementations that were no longer routed:

- `lib/pages/home/home_page.dart`
- `lib/pages/onboarding/onboarding_flow_page.dart`
- `lib/pages/shell/app_shell_v2_page.dart`
- `lib/pages/career/career_record_page.dart`

### 6. Banner asset filename fix
Renamed the corrupted `career_road_bannejpg` asset to `career_road_banner.jpg` and registered both banner assets in `pubspec.yaml`.

## Why this matters

- `AppState` dropped from ~1,600 lines toward a thinner coordinator role.
- Domain logic can be unit-tested without UI or `ChangeNotifier` (`test/roadmap_models_test.dart`).
- Future work (Riverpod/Bloc split, Isar/Drift migration, real local notifications) has cleaner seams.
- UI consistency improves as pages adopt the shared widgets.

## Follow-on work (recommended next upgrades)

1. Split remaining AppState responsibilities into focused controllers (`ProfileController`, `CertificationsController`, `TaskBookController`, `CareerRecordController`).
2. Move `FireOpsCatalog` static data into JSON/YAML assets.
3. Wire `flutter_local_notifications` on top of `NotificationPreferencesStore`.
4. Expand widget tests around the Daily Focus → Record path.
5. Retire remaining legacy log routes (`/log/legacy`, vault/hub duplicates) once product confirms no deep-link dependency.

## Compatibility

- No portfolio schema change.
- No SharedPreferences key changes except the new optional notification preference keys.
- Existing backups and task-book progress remain valid.
- `AppState` still re-exports roadmap models for backwards-compatible imports.
