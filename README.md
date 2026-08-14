# FireOps Career Road

FireOps Career Road is a private professional-growth and advancement app for firefighters and EMS professionals. It combines an actionable **Career Task Book**, a fast **Quick Log**, credential tracking, and a long-term **Career Record** so a user can plan advancement, do the work, preserve proof, and prepare for future promotions or job opportunities.

## Core experience

The product loop is:

**PLAN → WORK → RECORD → PROVE → ADVANCE**

### First run
New users answer three practical questions: where they are now, which certifications they already hold, and where they want to go next. FireOps Career Road then builds a starting Career Road and shows the result before asking for any optional department customization. Quick Log uses sensible defaults; users can personalize it later after they understand how they actually use the app.

### Home
The home screen is a career decision dashboard, not just a tracker. **Career Readiness** leads the experience with the user's active goal, mapped-requirement completion percentage, target date, timeline health, and a **Next Best Step** that points to the highest-priority incomplete requirement. Users can jump directly into the Task Book or log progress, with current level, certification health, and Quick Log still available below.

### Task Book
The active career goal becomes a Career Task Book. Major requirements such as certifications, experience, department requirements, task books, and promotion steps can open into progressively deeper preparation tasks. Built-in preparation tasks preserve FireOps-authored instructional order rather than being alphabetized. FireOps-created task content is preparation guidance and does not replace official department, state, or credentialing requirements.

Task Book detail pages use a consistent **Learn → Practice → Record** loop. FireOpsSim supplies free study material, task-specific practice/tools, school or course-finder help, and supporting references. Stable certification and task IDs are passed to FireOpsSim so Roadmap remains focused on planning and progress while FireOpsSim can continue expanding the learning content independently.

Task status distinguishes personal preparation from official verification. A user may mark a preparation task **Self-completed**, while future department workflows can separately support supervisor verification.

### Quick Log
Quick Log is designed for fast capture after a call, drill, class, shift, or career milestone. Users can record calls, skill repetitions, training time, drive time, leadership, teaching, awards, achievements, projects, education, custom activity, and Task Book progress without navigating through the full career history.

When a Quick Log entry is linked to a measurable Task Book requirement, eligible hours or repetitions can advance that requirement. Practice activity does not automatically become an official supervisor verification or competency sign-off.

### Career Record
The Log tab is the organized long-term record of what the user has done. It supports current-year and career views, search, activity filters, statistics, edit/delete controls, and Task Book-linked history.

### Advance
Advance turns the user's current goal and preserved career evidence into advancement preparation. It uses the same **Next Best Step** language as Home and the Task Book, then adds readiness dimensions, evidence gaps, competency development, promotion stories, and deeper professional-growth tools.

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
