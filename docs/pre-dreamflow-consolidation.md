# Responder Roadmap — Pre-Dreamflow consolidation

This is the final product/UX scope for the mobile app before the Dreamflow visual-polish pass.

## Source of truth

- Backend/API: `EMSCodeSim/ResponderRoadmap` main.
- Mobile app: `EMSCodeSim/Roadmap` main.
- Backend #114–#116 are implemented. Do not invent replacement APIs or mock production states.
- Department authorization is distinct from possessing a credential or completing training.
- Official department completion remains server-confirmed and auditable.

## Keep and consolidate

### One Needs My Action experience
Use one role-aware action queue rather than competing inboxes. It should surface, when applicable:

- returned assignments/corrections
- new assignments and task books
- evaluations requested of the signed-in evaluator
- credential expiration/missing-expiration actions
- training sheets needing required fields or instructor approval
- RMS entry/reconciliation actions
- qualification requirements awaiting action

Existing personal career reminders can remain personal, but department actions should not be duplicated across multiple department inbox screens.

### Quick Add
Quick Add remains the primary field-entry action. Keep it fast and role-aware.

Member-capable actions:
- Training/activity
- Call/experience
- Skill
- Driving
- Exposure
- Credential/certificate
- Scan QR

Authorized instructor/evaluator actions should additionally expose:
- Skill Checkoff
- Create Training Sheet

Do not show administrative actions to users who lack permission.

### Personal vs Department
Every eligible personal record must clearly state either:

- `Personal only`
- `Shared with department`

Sharing personal activity does not automatically create official training credit, an evaluation, or department authorization.

Exposure records must continue to state that they are not an official occupational exposure report and that the department's official reporting process/officer notification is still required.

### My Roadmap
My Roadmap should answer:

1. What am I working toward?
2. What is complete?
3. What is waiting on someone else?
4. What do I need to do next?

For department qualifications, show the next missing requirement rather than only a percentage.

Example:

`Tender Driver — In Training — 5 of 6 complete — Next: Road Evaluation`

Never equate 100% training progress with department authorization unless the backend explicitly returns the authorized state.

### Department / Who Can Do What
Acting Officer and higher, when permitted by the backend, need fast read access to department qualifications.

Support:
- search by member
- search by qualification/role
- view Approved / In Training / Restricted / Renewal Required states
- view the next missing requirement where available

Use language such as `Approved to Perform Role`. Do not claim a member is on duty or available today unless actual staffing data exists.

### Training Sheets
Mobile lifecycle:

`Quick Add → Training Sheet → select department template → roster/QR → required fields → instructor approval → Ready for RMS → Mark Entered into RMS → Complete`

If material data changes after RMS entry, show `RMS reconciliation required` and return it to Actions Needed.

### Credentials
Support:
- expiration date
- Does Not Expire
- Current
- Expiring Soon
- Expired
- Expiration Missing

Do not silently treat a credential with a required but missing expiration date as current.

### Sync states
Important department writes must use explicit server-confirmed states:

- Synced
- Waiting to Sync
- Sync Failed — Retry

Do not display a successful evaluation, approval, credential update, training-sheet approval, or RMS entry until the server confirms it.

## Navigation target

Dreamflow should simplify the primary mobile navigation toward:

- Home
- Department
- Quick Add (primary action, not a content tab)
- My Roadmap
- Profile

Career Record/Log and Credentials remain full features but should live under the appropriate Home/My Roadmap/Profile entry points rather than each consuming permanent primary-navigation space.

Do not remove their routes or stored data during the navigation cleanup.

## Do not add

Do not turn Responder Roadmap into shift scheduling or staffing software.

The app may answer `Who is department-approved to drive the medic?` when authorization data supports it. It must not imply `Who is assigned to Medic 181 today?` without a real staffing source.

Do not add duplicate dashboards, command centers, inboxes, setup wizards, or parallel versions of existing screens.

## Dreamflow boundary

Dreamflow may substantially improve layout, visual hierarchy, navigation presentation, empty/loading/error states, accessibility, and interaction polish.

Dreamflow must not reinterpret:
- authorization rules
- evaluator permissions
- task-book approval logic
- training-sheet lifecycle
- RMS reconciliation
- credential verification/expiration semantics
- personal-vs-department privacy
- audit timestamps
- server-confirmed states

If the API does not expose a capability, identify the missing dependency rather than faking it.

## Release gate

Before merging Dreamflow work:

1. `flutter analyze` passes.
2. Existing Flutter tests pass.
3. No small-screen overflow.
4. Role-based controls are verified.
5. Quick Add remains reachable and fast.
6. Department writes visibly distinguish pending/failed/synced states.
7. Existing personal records, task books, credentials, and department links are preserved.
8. New #114–#116 mobile screens use the real Responder Roadmap backend contract.
