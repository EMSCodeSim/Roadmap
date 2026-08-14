# FireOps Career Road

FireOps Career Road is a private professional-growth and advancement app for firefighters and EMS professionals. It combines an actionable **Career Task Book**, a fast **Quick Log**, credential tracking, and a long-term **Career Record** so a user can plan advancement, do the work, preserve proof, and prepare for future promotions or job opportunities.

## Core experience

The product loop is:

**PLAN → WORK → RECORD → PROVE → ADVANCE**

### First run
New users answer three practical questions: where they are now, which certifications they already hold, and where they want to go next. FireOps Career Road then builds a starting Career Road and shows the result before asking for any optional department customization. Quick Log uses sensible defaults; users can personalize it later after they understand how they actually use the app.

### Home
The home screen is a career decision dashboard, not just a tracker. **Career Readiness** leads the experience with the user's active goal, mapped-requirement completion percentage, target date, timeline health, and a **Next Best Step** that points to the highest-priority incomplete requirement. Users can jump directly into the Task Book or log progress, with current level, certification health, and Quick Log still available below.

### Daily Focus
**Daily Focus** turns the current Next Best Step into a practical work session based on the time the user actually has: **15 minutes, 30 minutes, 1 hour, or a Crew Drill**. It selects the next unfinished preparation task when one exists, builds a Learn / Practice / Debrief / Record session around that work, and shows seven-day activity and documented-hour momentum.

A Daily Focus session can open directly into the relevant preparation task and ends with **Record What I Did**, pre-linked to the same career goal, requirement, and task. This closes the daily loop between planning, practice, and the long-term Career Record instead of making users organize the same activity twice.

### Contextual ecosystem recommendations
Career Road may show one understated **Recommended Tool** card when the user's current Next Best Step clearly matches another FireOps or EMSCodeSim product. Recommendations are contextual rather than generic advertising: fireground hydraulics can point to FireOps Calc, pump-operator work to FirePumpSim, EMS development to EMSCodeSim, and officer/instructor/HazMat development to FireOpsSim.

Recommendations appear below the user's actual career work, explain why the tool is useful at that moment, and open the relevant external product only when the user chooses to. If no strong match exists, no promotional card is shown. Career Road does not use rotating banners, forced interstitials, countdown promotions, or unrelated cross-promotion.

### Task Book
The active career goal becomes a Career Task Book. Major requirements such as certifications, experience, department requirements, task books, and promotion steps can open into progressively deeper preparation tasks. Built-in preparation tasks preserve FireOps-authored instructional order rather than being alphabetized. FireOps-created task content is preparation guidance and does not replace official department, state, or credentialing requirements.

Task Book detail pages use a consistent **Learn → Practice → Record** loop. FireOpsSim supplies free study material, task-specific practice/tools, school or course-finder help, and supporting references. Stable certification and task IDs are passed to FireOpsSim so Roadmap remains focused on planning and progress while FireOpsSim can continue expanding the learning content independently.

Task status distinguishes personal preparation from official verification. A user may mark a preparation task **Self-completed**, while future department workflows can separately support supervisor verification.

Task Book detail pages use **FireOpsSim** as the free companion resource layer. From a task, users can open study material, task-specific practice/tools, school or course-finder help, and supporting references. Stable certification and task IDs are passed to FireOpsSim so Roadmap remains focused on planning and progress while FireOpsSim can continue expanding the learning content independently.

### Quick Log
Quick Log is designed for fast capture after a call, drill, class, shift, or career milestone. Users can record calls, skill repetitions, training time, drive time, leadership, teaching, awards, achievements, projects, education, custom activity, and Task Book progress without navigating through the full career history.

When a Quick Log entry is linked to a measurable Task Book requirement, eligible hours or repetitions can advance that requirement. Practice activity does not automatically become an official supervisor verification or competency sign-off.

### Career Record
The Log tab is the organized long-term record of what the user has done. It supports current-year and career views, search, activity filters, statistics, edit/delete controls, and Task Book-linked history.

### Advance
Advance turns the user's current goal and preserved career evidence into advancement preparation. It uses the same **Next Best Step** language as Home and the Task Book, then adds readiness dimensions, evidence gaps, competency development, promotion stories, and deeper professional-growth tools.

### Career Intelligence
Career Intelligence is the long-term interpretation layer for users who have months or years of Career Record history. It summarizes total documented activity, years of history, hours, and marked highlights; identifies the user's strongest documented career area and a professional-development gap; and surfaces a chronological career-highlights timeline.

The **Annual Career Review** converts a selected year into a copyable summary of activity by area, documented hours, highlights, strengths, development opportunities, active-goal readiness, and the recommended next move for the following year.

The **Promotion Portfolio** combines long-term career totals with the advancement engine's credential status, readiness score, evidence gaps, competency map, and strongest promotion stories so years of logging become useful during interviews, annual evaluations, applications, and promotional preparation.

**Long-Term Career Tools** add multi-path readiness comparisons, retained past-goal / Task Book history, year-over-year activity trends, stale-skill refresh signals, STAR interview-story preparation, and resume source material.

### Career Export Center
The Career Export Center converts locally stored career data into professionally formatted PDF documents using US letter-sized layouts. Users can optionally save a local export identity (name, email, phone, and city/state) that is used only in generated documents.

Available exports include:

- **Professional Resume** — concise role, credential, accomplishment, leadership, teaching, project, and professional-development summary.
- **Promotion Packet** — advancement readiness, evidence gaps, competency support, credentials, and interview-story bank.
- **Career Portfolio** — fuller long-term career history with totals, highlights, credentials, readiness, and development priorities.

PDFs can be previewed/printed or shared using the platform print/share workflow. Users should review generated documents before submitting them for employment, promotion, or official use.

### Department Transfer
Department Transfer keeps a prospective agency comparison separate from the user's active Career Road. A user can name a target department, choose a typical career path as a starting point, import that path's typical requirements, and then add or edit local department-specific requirements.

Career Road compares those requirements against current credentials, retained Task Book/path progress, and Career Record evidence. It shows estimated overlap, likely transferable items, and gaps that should be verified with the receiving department. Users may manually mark a requirement as equivalent or accepted when they have confirmed that externally. A professional transfer-readiness PDF can also be generated and shared.

A match is a planning signal only. The receiving department, state authority, or credentialing body determines what actually transfers, what must be repeated, and which supporting documents are acceptable.

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
