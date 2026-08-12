# FireOps Career Road

FireOps Career Road is a private professional-growth and advancement app for firefighters and EMS professionals. It combines an actionable **Career Task Book**, a fast **Quick Log**, credential tracking, and a long-term **Career Record** so a user can plan advancement, do the work, preserve proof, and prepare for future promotions or job opportunities.

## Core experience

The product loop is:

**PLAN → WORK → RECORD → PROVE → ADVANCE**

### Home
A simple career snapshot showing the user's current level, active goal, certification health, and a fast Quick Log entry point.

### Task Book
The active career goal becomes a Career Task Book. Major requirements such as certifications, experience, department requirements, task books, and promotion steps can open into progressively deeper preparation tasks. FireOps-created task content is preparation guidance and does not replace official department, state, or credentialing requirements.

### Quick Log
Quick Log is designed for fast capture after a call, drill, class, shift, or career milestone. Users can record calls, skill repetitions, training time, drive time, leadership, teaching, awards, achievements, projects, education, custom activity, and Task Book progress without navigating through the full career history.

When a Quick Log entry is linked to a measurable Task Book requirement, eligible hours or repetitions can advance that requirement. Practice activity does not automatically become an official supervisor verification or competency sign-off.

### Career Record
The Log tab is the organized long-term record of what the user has done. It supports current-year and career views, search, activity filters, statistics, edit/delete controls, and Task Book-linked history.

### Growth
Growth turns the user's current goal and preserved career evidence into advancement preparation. It includes a prioritized Best Next Move, readiness dimensions, evidence gaps, competency development, promotion stories, and deeper professional-growth tools.

### Certifications
Certifications is the credential wallet. Current, expiring, and expired credentials are tracked in one place and matching credentials automatically satisfy applicable Career Task Book requirements.

## Data and privacy

Career data is stored locally on the user's device. FireOps Career Road is a personal professional-growth tool, not an ePCR, official department training record, official task book, exposure-reporting system, promotional eligibility determination, or required personnel record.

Do not enter patient names, addresses, dates of birth, medical record numbers, phone numbers, or other patient-identifying information.

## Backup

The portable Career Portfolio backup includes profile data, certifications, custom requirements, path overrides, Quick Log preferences, Career Records, Task Book task progress, and custom Task Book tasks. Current backups use portfolio schema version 4; older supported backups remain importable.

## Validation

GitHub Actions validates the production branch with:

- Flutter dependency resolution
- Flutter analyze
- automated tests
- web release compilation
- Android release compilation
- iOS release compilation without code signing

Store signing, provisioning, and final App Store / Google Play submission credentials remain deployment-time responsibilities and are not committed to this repository.
