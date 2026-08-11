# FireOps Career Road — UI & Personal Log Upgrade

This upgrade focuses on daily usability and long-term career record reliability.

## Personal Log
- Role-based Quick Log starting layouts for Medic, Firefighter, Engineer / Driver, and Officer.
- Pinned and reorderable Quick Log buttons.
- User-created custom trackers with optional success/failure tracking.
- Fast one-tap routine logging with success/failure follow-up only when needed.
- Edit and delete for routine entries.
- Year selector, searchable year values, annual totals, success rates, and per-activity year trends.
- Past/custom backdated entry support.
- Backup and Restore using a portable FireOps Career Log JSON backup.
- Save failures are surfaced to the user instead of silently reporting success.

## Long-term storage
- Existing `fireops.careerRecords.v1` data migrates automatically.
- Career records are stored in year-based segments under the v2 storage layout.
- Routine entries update only the relevant year's segment rather than rewriting the user's entire career history.

## Navigation and UI
- Home opens on actionable career information instead of a tall marketing-image header.
- Primary destinations are Home, Path, Log, Growth, and Certs.
- Resources remain available as a secondary route instead of consuming a primary navigation slot.
- Personal Log and Detailed Evidence are named separately to clarify the two-speed workflow.

## Branding and assets
The one-time branch upgrade workflow repairs generated Android/iOS/web launcher assets, replaces corrupted graphic files with clean branded versions, and removes leftover Dreamflow/default platform naming before merge.
