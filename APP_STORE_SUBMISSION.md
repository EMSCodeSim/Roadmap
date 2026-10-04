# Responder Roadmap — App Store Submission

## Binary
- App name: Responder Roadmap
- Version: 1.2.5
- Build: 35
- Bundle ID: `com.fireopssim.careerroadmap`
- Minimum iOS: 15.1
- iPhone and iPad supported
- No in-app purchases

## Product positioning
Responder Roadmap is a professional development, credential, task-book, and department training companion for fire and EMS professionals.

The app supports two clearly separated record types:
- Personal career records stored locally on the device.
- Department-connected records loaded from and submitted to ResponderRoadmap when the user signs into a department account.

Personal records do not become official department records unless the user explicitly uses an available department-sharing workflow. Department authorization, evaluations, Task Book approvals, Training Sheets, and RMS handoff states remain server-authoritative.

## App Store URLs
- Privacy Policy: https://fireopssim.com/career-road-privacy.html
- Support URL: https://fireopssim.com/career-road-support.html
- Marketing URL: https://responderroadmap.com

## Recommended category
- Primary: Education
- Secondary: Productivity

## App Review notes draft
Responder Roadmap is a fire/EMS professional-development and department-training companion.

The Personal Roadmap can be used without joining a department. Personal Task Books, Quick Add history, career goals, credentials, and supporting records are stored locally on the device unless the user explicitly chooses a department-sharing workflow.

Users who are assigned to a participating department can sign in to the native Department workspace to receive Task Books and assignments, review department requirements, scan class QR codes, submit work, maintain supported credential information, and—where their role permits—perform evaluations or other department actions.

Department records are not stored as a separate local source of truth. Official department status, approvals, qualifications, Training Sheet/RMS workflow states, and audit timestamps come from ResponderRoadmap.

The app is not an ePCR and is not intended for patient-identifying information. Exposure logging is explicitly labeled as a personal/training record and does not replace the department's official occupational exposure-reporting process.

Reset App in Settings deletes locally stored personal career information. It does not delete official department records stored by the department service.

## App Privacy answers to verify in App Store Connect
Review App Privacy against the final signed binary and production backend behavior.

At minimum, verify the declarations for any department-connected data handled by the service, including account/contact information, credential information, training/assignment activity, evaluation records, and identifiers needed for authentication or department membership.

Personal career information that remains only on-device should not be described as developer-collected solely because it exists locally.

Backup and restore use the system document picker for user-selected career backup files. Exported files leave the app only when the user explicitly chooses to save or share them.

Do not copy prior App Privacy answers forward without checking them against the department-connected release.

## Release workflow checks
- Confirm the production API base URL is correct for the signed build.
- Verify app login works for a member account and an authorized evaluator/officer account.
- Verify Personal and Department records remain visibly distinct.
- Verify Quick Add is reachable from every primary navigation tab.
- Verify Personal only / Share with department choices behave as labeled.
- Verify Exposure shows the official-report warning.
- Verify Department inbox/action badges update correctly.
- Verify Synced / Waiting to upload / Sync failed states are understandable and retryable.
- Verify credential expiration date and Does Not Expire behavior against the live contract.
- Verify notification permission prompts occur only when needed and the app still works if permission is denied.
- Verify class QR scanning and roster registration on a physical iPhone.
- Verify department assignment and Task Book deep links.
- Verify role-gated evaluation/Skill Checkoff actions.
- Verify Training Sheet → roster → instructor approval → RMS Actions Needed → RMS Entered workflow where exposed in this binary.
- Verify Acting Officer+ qualification lookup does not expose write permissions they should not have.
- Verify a regular member cannot access department-wide Who Can Do What data.
- Verify logout clears the department session without deleting personal Career Road data.

## Before pressing Submit for Review
- Upload a release archive built with Apple's currently accepted production Xcode/iOS SDK.
- Confirm version 1.2.5 build 35 appears under the iOS version in App Store Connect.
- Confirm the displayed product name is Responder Roadmap.
- Select a primary category.
- Complete the current age-rating questionnaire accurately.
- Complete App Privacy against the final signed binary and production backend.
- Add screenshots showing Home/My Roadmap, Quick Add, Credentials, and the Department workspace.
- Enter App Review contact name, email, and phone. Phone should use international format with `+` and country code.
- Provide working department review credentials if App Review needs to inspect authenticated department functionality.
- Explain any role-specific review account in App Review Notes.
- Verify Privacy Policy, Support, and Marketing URLs load publicly without login.
- Test fresh install and onboarding on a physical iPhone.
- Test Personal Task Book, qualification checklist, and task detail.
- Test Quick Add from Home, My Roadmap, Record, Credentials, and Department.
- Confirm a new Quick Add record appears immediately in the appropriate personal record view.
- Test certifications add/edit, expiration behavior, backup/export/restore, and Settings reset.
- Test the supported iPad layouts and orientations because the build declares iPad support.
- Test small iPhone layouts with increased text size for overflow.
- Verify camera permission copy and QR scanner behavior.
- Verify no placeholder, demo-only, disabled, or “coming soon” production actions are visible.
- Verify no stale version strings or legacy FireOps Career Road product naming remain in user-visible UI.
- Run the full Flutter validation workflow and require green Analyze, test, and unsigned iOS release-build jobs before archiving for submission.

## Release gate
Do not submit the build if any of the following are true:
- Flutter analyze fails.
- Any required automated test fails.
- The unsigned iOS release build fails.
- Production authentication cannot complete.
- A department action appears successful before the server confirms it.
- Personal information is unintentionally shared with a department.
- Department permissions differ from the server contract.
- App Store metadata describes functionality or privacy behavior that does not match the signed binary.
