# FireOps Career Road — App Store Submission

## Binary
- App name: FireOps Career Road
- Version: 1.1.10
- Build: 17
- Bundle ID: `com.fireopssim.careerroadmap`
- Minimum iOS: 15.1
- iPhone and iPad supported
- No in-app purchases

## App Store URLs
- Privacy Policy: https://fireopssim.com/career-road-privacy.html
- Support URL: https://fireopssim.com/career-road-support.html
- Marketing URL: https://fireopssim.com/firefighter-career

## Recommended category
- Primary: Education
- Secondary: Productivity

## App Review notes draft
FireOps Career Road is a local-first professional development and career-record app for fire and EMS professionals. The personal Career Road, personal Task Books, Quick Log history, credentials, goals, and career records work without creating an account and are stored locally on the device.

Version 1.2 adds an optional native Department workspace. Reviewers can continue using the complete personal Career Road without an account. Department features use a ResponderRoadmap account to load assigned Task Books, submit work, and—when the account role permits—review member submissions without redirecting to a website. Provide an active department demo account in App Review Information when submitting this update.

The app is not an ePCR or patient record. Users are instructed not to enter patient-identifying information.

Reset App in Settings deletes locally stored personal career information.

## App Privacy answers to verify in App Store Connect
Personal career records stored only on-device are not collected by the developer.

The submitted iOS experience does not expose department sign-in or department data submission. Verify the final App Store Connect privacy answers against the exact signed binary before submission.

Backup and restore use the system document picker for user-selected career backup files. Exported files leave the app only when the user explicitly chooses to save or share them. The app does not request Photo Library permission in this release.

## Before pressing Submit for Review
- Upload a release archive built with Apple's currently accepted production Xcode/iOS SDK (not a beta SDK for App Store production).
- Confirm version 1.1.10 build 17 appears under the iOS version in App Store Connect.
- Select a primary category.
- Complete the current age-rating questionnaire accurately.
- Complete App Privacy using the data practices above and the final submitted binary.
- Add screenshots that show the actual app experience, not just splash/login screens.
- Enter App Review contact name, email, and phone. Phone must use international format with `+` and country code.
- Do not provide department demo credentials for this first submission.
- Verify Privacy Policy and Support URLs load publicly without login.
- Test fresh install and onboarding on a physical iPhone.
- Test Personal Task Book, a qualification checklist, and a task detail screen.
- Save Quick Log entries from Home and from a Task Book task, then confirm they appear immediately in Log and under the TASK BOOK filter.
- Test certifications add/edit, backup/export/restore, and Settings reset.
- Test the supported iPad layouts and orientations because this build declares iPad support.
- Confirm the Task Book screen has no Personal/Department selector.
- Confirm `/department`, `/portal`, and `/portal/login` are not registered routes in the iOS build.
- Confirm resources with no usable URL are not presented as disabled or “coming soon” actions.
