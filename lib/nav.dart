import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/bootstrap_page.dart';
import 'package:firepath/pages/shell/app_shell_page.dart';
import 'package:firepath/pages/home/visual_home_page.dart';
import 'package:firepath/pages/onboarding/onboarding_v2_page.dart';
import 'package:firepath/pages/path/goal_picker_page.dart';
import 'package:firepath/pages/path/roadmap_entry_page.dart';
import 'package:firepath/pages/task_book/task_book_entry_page.dart';
import 'package:firepath/pages/task_book/task_book_review_page.dart';
import 'package:firepath/pages/task_book/task_book_requirements_editor_page.dart';
import 'package:firepath/pages/task_book/custom_task_book_create_page.dart';
import 'package:firepath/pages/task_book/custom_task_book_builder_page.dart';
import 'package:firepath/pages/career/career_hub_page.dart';
import 'package:firepath/pages/career/career_vault_page.dart';
import 'package:firepath/pages/career/growth_overview_page.dart';
import 'package:firepath/pages/career/career_intelligence_page.dart';
import 'package:firepath/pages/career/career_longevity_page.dart';
import 'package:firepath/pages/career/daily_focus_page.dart';
import 'package:firepath/pages/career/needs_attention_page.dart';
import 'package:firepath/pages/career/career_export_page.dart';
import 'package:firepath/pages/career/career_inbox_page.dart';
import 'package:firepath/pages/career/promotion_portfolio_review_page.dart';
import 'package:firepath/pages/career/department_transfer_page.dart';
import 'package:firepath/pages/department/my_department_page.dart';
import 'package:firepath/pages/career/personal_log_page.dart';
import 'package:firepath/pages/career/career_record_v2_page.dart';
import 'package:firepath/pages/career/quick_log_setup_page.dart';
import 'package:firepath/pages/certifications/certifications_page.dart';
import 'package:firepath/pages/resources/resources_page.dart';
import 'package:firepath/pages/settings/settings_page.dart';
import 'package:firepath/pages/requirement/requirement_detail_page.dart';
import 'package:firepath/pages/requirement/get_started_page.dart';
import 'package:firepath/pages/certifications/certification_detail_page.dart';
import 'package:firepath/pages/certifications/certification_picker_page.dart';
import 'package:firepath/pages/task_book/qualification_task_book_checklist_shell.dart';
import 'package:firepath/pages/task_book/requirement_checklist_page.dart';
import 'package:firepath/pages/task_book/task_detail_page.dart';
import 'package:firepath/models/prefill.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/task_book_navigation.dart';

import 'package:firepath/portal/pages/portal_login_page.dart';
import 'package:firepath/portal/pages/portal_shell_page.dart';
import 'package:firepath/portal/pages/dashboard/portal_dashboard_page.dart';
import 'package:firepath/portal/pages/members/portal_members_page.dart';
import 'package:firepath/portal/pages/members/portal_member_profile_page.dart';
import 'package:firepath/portal/pages/task_books/portal_task_books_page.dart';
import 'package:firepath/portal/pages/task_books/portal_task_book_builder_page.dart';
import 'package:firepath/portal/pages/assignments/portal_assignments_page.dart';
import 'package:firepath/portal/pages/signoffs/portal_signoffs_page.dart';
import 'package:firepath/portal/pages/certifications/portal_certifications_page.dart';
import 'package:firepath/portal/pages/reports/portal_reports_page.dart';
import 'package:firepath/portal/pages/department/portal_department_page.dart';
import 'package:firepath/portal/pages/settings/portal_settings_page.dart';
import 'package:firepath/portal/state/portal_controller.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.bootstrap,
    routes: [
      GoRoute(
        path: AppRoutes.bootstrap,
        name: 'bootstrap',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: BootstrapPage()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: OnboardingV2Page()),
      ),

      // ---------------------------------------------------------------------
      // ResponderRoadmap Department Portal (desktop/web)
      // ---------------------------------------------------------------------
      GoRoute(
        path: AppRoutes.portalLogin,
        name: 'portal_login',
        pageBuilder: (context, state) => const MaterialPage(child: PortalLoginPage()),
      ),
      ShellRoute(
        builder: (context, state, child) => PortalShellPage(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.portal,
            redirect: (context, state) {
              final portal = context.read<PortalController>();
              if (!portal.bootstrapped) return null;
              if (portal.sessionUserId == null) return AppRoutes.portalLogin;
              return '${AppRoutes.portal}/dashboard';
            },
          ),
          GoRoute(
            path: '${AppRoutes.portal}/dashboard',
            name: 'portal_dashboard',
            redirect: (context, state) {
              final portal = context.read<PortalController>();
              if (!portal.bootstrapped) return null;
              if (portal.sessionUserId == null) return AppRoutes.portalLogin;
              return null;
            },
            pageBuilder: (context, state) => const NoTransitionPage(child: PortalDashboardPage()),
          ),
          GoRoute(
            path: '${AppRoutes.portal}/members',
            name: 'portal_members',
            redirect: (context, state) {
              final portal = context.read<PortalController>();
              if (!portal.bootstrapped) return null;
              if (portal.sessionUserId == null) return AppRoutes.portalLogin;
              return null;
            },
            pageBuilder: (context, state) => const NoTransitionPage(child: PortalMembersPage()),
            routes: [
              GoRoute(
                path: ':id',
                name: 'portal_member_profile',
                pageBuilder: (context, state) => MaterialPage(
                  child: PortalMemberProfilePage(memberId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '${AppRoutes.portal}/task-books',
            name: 'portal_task_books',
            redirect: (context, state) {
              final portal = context.read<PortalController>();
              if (!portal.bootstrapped) return null;
              if (portal.sessionUserId == null) return AppRoutes.portalLogin;
              return null;
            },
            pageBuilder: (context, state) => const NoTransitionPage(child: PortalTaskBooksPage()),
            routes: [
              GoRoute(
                path: ':id',
                name: 'portal_task_book_builder',
                pageBuilder: (context, state) => MaterialPage(
                  child: PortalTaskBookBuilderPage(templateId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '${AppRoutes.portal}/assignments',
            name: 'portal_assignments',
            redirect: (context, state) {
              final portal = context.read<PortalController>();
              if (!portal.bootstrapped) return null;
              if (portal.sessionUserId == null) return AppRoutes.portalLogin;
              return null;
            },
            pageBuilder: (context, state) => const NoTransitionPage(child: PortalAssignmentsPage()),
          ),
          GoRoute(
            path: '${AppRoutes.portal}/signoffs',
            name: 'portal_signoffs',
            redirect: (context, state) {
              final portal = context.read<PortalController>();
              if (!portal.bootstrapped) return null;
              if (portal.sessionUserId == null) return AppRoutes.portalLogin;
              return null;
            },
            pageBuilder: (context, state) => const NoTransitionPage(child: PortalSignoffsPage()),
          ),
          GoRoute(
            path: '${AppRoutes.portal}/certifications',
            name: 'portal_certifications',
            redirect: (context, state) {
              final portal = context.read<PortalController>();
              if (!portal.bootstrapped) return null;
              if (portal.sessionUserId == null) return AppRoutes.portalLogin;
              return null;
            },
            pageBuilder: (context, state) => const NoTransitionPage(child: PortalCertificationsPage()),
          ),
          GoRoute(
            path: '${AppRoutes.portal}/reports',
            name: 'portal_reports',
            redirect: (context, state) {
              final portal = context.read<PortalController>();
              if (!portal.bootstrapped) return null;
              if (portal.sessionUserId == null) return AppRoutes.portalLogin;
              return null;
            },
            pageBuilder: (context, state) => const NoTransitionPage(child: PortalReportsPage()),
          ),
          GoRoute(
            path: '${AppRoutes.portal}/department',
            name: 'portal_department',
            redirect: (context, state) {
              final portal = context.read<PortalController>();
              if (!portal.bootstrapped) return null;
              if (portal.sessionUserId == null) return AppRoutes.portalLogin;
              return null;
            },
            pageBuilder: (context, state) => const NoTransitionPage(child: PortalDepartmentPage()),
          ),
          GoRoute(
            path: '${AppRoutes.portal}/settings',
            name: 'portal_settings',
            redirect: (context, state) {
              final portal = context.read<PortalController>();
              if (!portal.bootstrapped) return null;
              if (portal.sessionUserId == null) return AppRoutes.portalLogin;
              return null;
            },
            pageBuilder: (context, state) => const NoTransitionPage(child: PortalSettingsPage()),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellPage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: VisualHomePage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.myPath,
                name: 'my_path',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TaskBookEntryPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.personalLog,
                name: 'personal_log',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CareerRecordV2Page()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.growth,
                name: 'growth',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: GrowthOverviewPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.certifications,
                name: 'certifications',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CertificationsPage()),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) =>
            const MaterialPage(child: SettingsPage()),
      ),

      GoRoute(
        path: AppRoutes.department,
        name: 'department',
        pageBuilder: (context, state) => const MaterialPage(child: MyDepartmentPage()),
      ),

      GoRoute(path: '/career', redirect: (context, state) => AppRoutes.growth),
      GoRoute(
        path: '/career/vault',
        redirect: (context, state) => AppRoutes.personalLog,
      ),

      GoRoute(
        path: AppRoutes.personalLogLegacy,
        redirect: (context, state) => AppRoutes.personalLogClassic,
      ),
      GoRoute(
        path: AppRoutes.personalLogClassic,
        name: 'personal_log_classic',
        pageBuilder: (context, state) => MaterialPage(
          child: PersonalLogPage(prefill: state.extra as LogPrefill?),
        ),
      ),
      GoRoute(
        path: AppRoutes.quickLogSetup,
        name: 'quick_log_setup',
        pageBuilder: (context, state) =>
            const MaterialPage(child: QuickLogSetupPage()),
      ),
      GoRoute(
        path: AppRoutes.taskBookReview,
        name: 'task_book_review',
        pageBuilder: (context, state) =>
            const MaterialPage(child: TaskBookReviewPage()),
      ),
      GoRoute(
        path: AppRoutes.taskBookRequirementsSetup,
        name: 'task_book_requirements_setup',
        pageBuilder: (context, state) =>
            const MaterialPage(child: TaskBookRequirementsEditorPage()),
      ),
      GoRoute(
        path: AppRoutes.customTaskBookCreate,
        name: 'custom_task_book_create',
        pageBuilder: (context, state) =>
            const MaterialPage(child: CustomTaskBookCreatePage()),
      ),
      GoRoute(
        path: AppRoutes.customTaskBookBuilder,
        name: 'custom_task_book_builder',
        pageBuilder: (context, state) =>
            MaterialPage(child: CustomTaskBookBuilderPage(extra: state.extra)),
      ),
      GoRoute(
        path: AppRoutes.goalSetup,
        name: 'goal_setup',
        pageBuilder: (context, state) =>
            const MaterialPage(child: GoalPickerPage()),
      ),
      GoRoute(
        path: AppRoutes.growthDetails,
        name: 'growth_details',
        pageBuilder: (context, state) =>
            const MaterialPage(child: CareerHubPage()),
      ),
      GoRoute(
        path: AppRoutes.careerIntelligence,
        name: 'career_intelligence',
        pageBuilder: (context, state) =>
            const MaterialPage(child: CareerIntelligencePage()),
      ),
      GoRoute(
        path: AppRoutes.careerLongevity,
        name: 'career_longevity',
        pageBuilder: (context, state) =>
            const MaterialPage(child: CareerLongevityPage()),
      ),
      GoRoute(
        path: AppRoutes.dailyFocus,
        name: 'daily_focus',
        pageBuilder: (context, state) =>
            const MaterialPage(child: DailyFocusPage()),
      ),
      GoRoute(
        path: AppRoutes.needsAttention,
        name: 'needs_attention',
        pageBuilder: (context, state) =>
            const MaterialPage(child: NeedsAttentionPage()),
      ),
      GoRoute(
        path: AppRoutes.careerInbox,
        name: 'career_inbox',
        pageBuilder: (context, state) =>
            const MaterialPage(child: CareerInboxPage()),
      ),
      GoRoute(
        path: AppRoutes.careerExport,
        name: 'career_export',
        pageBuilder: (context, state) =>
            const MaterialPage(child: CareerExportPage()),
      ),
      GoRoute(
        path: AppRoutes.promotionPortfolioReview,
        name: 'promotion_portfolio_review',
        pageBuilder: (context, state) =>
            const MaterialPage(child: PromotionPortfolioReviewPage()),
      ),
      GoRoute(
        path: AppRoutes.departmentTransfer,
        name: 'department_transfer',
        pageBuilder: (context, state) =>
            const MaterialPage(child: DepartmentTransferPage()),
      ),
      GoRoute(
        path: AppRoutes.careerEvidence,
        name: 'career_evidence',
        pageBuilder: (context, state) => MaterialPage(
          child: CareerVaultPage(prefill: state.extra as EvidencePrefill?),
        ),
      ),
      GoRoute(
        path: AppRoutes.qualificationTaskBook,
        name: 'qualification_task_book',
        pageBuilder: (context, state) => MaterialPage(
          child: QualificationTaskBookChecklistShell(
            requirement: (state.extra as Map?)?['requirement'] ?? state.extra,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.taskDetail,
        name: 'task_detail',
        pageBuilder: (context, state) =>
            MaterialPage(child: TaskDetailPage(extra: state.extra)),
      ),
      GoRoute(
        path: AppRoutes.requirementChecklist,
        name: 'requirement_checklist',
        pageBuilder: (context, state) {
          final args = TaskBookRouteArgs.fromExtra(state.extra);
          final requirement = args.requirement;
          if (requirement == null) {
            return const MaterialPage(
              child: Scaffold(
                body: Center(child: Text('Checklist not found.')),
              ),
            );
          }
          return MaterialPage(
            child: RequirementChecklistPage(
              requirement: requirement,
              goalId: args.goalId,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.myPathLegacy,
        name: 'task_book_customize',
        pageBuilder: (context, state) =>
            const MaterialPage(child: RoadmapEntryPage()),
      ),
      GoRoute(
        path: AppRoutes.resources,
        name: 'resources',
        pageBuilder: (context, state) =>
            MaterialPage(child: ResourcesPage(extra: state.extra)),
      ),
      GoRoute(
        path: AppRoutes.requirementDetail,
        name: 'requirement_detail',
        pageBuilder: (context, state) => MaterialPage(
          child: RequirementDetailPage(requirement: state.extra),
        ),
      ),
      GoRoute(
        path: AppRoutes.getStarted,
        name: 'get_started',
        pageBuilder: (context, state) =>
            MaterialPage(child: GetStartedPage(requirement: state.extra)),
      ),
      GoRoute(
        path: '${AppRoutes.certificationDetail}/:id',
        name: 'certification_detail',
        pageBuilder: (context, state) => MaterialPage(
          child: CertificationDetailPage(
            certId: state.pathParameters['id']!,
            extra: state.extra,
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.certificationAdd,
        name: 'certification_add',
        pageBuilder: (context, state) =>
            MaterialPage(child: CertificationPickerPage(extra: state.extra)),
      ),
    ],
  );

  /// Opens a Task Book requirement at the correct depth.
  ///
  /// Certifications go to the JPR/skills checklist. Preparation tasks remain
  /// a secondary screen when FireOps has authored that content.
  static void openRequirement(
    BuildContext context,
    Requirement requirement, {
    String? goalId,
  }) {
    switch (TaskBookNavigation.targetFor(requirement)) {
      case TaskBookOpenTarget.skillsChecklist:
        context.push(
          AppRoutes.requirementChecklist,
          extra: <String, dynamic>{
            'requirement': requirement,
            if (goalId != null) 'goalId': goalId,
          },
        );
      case TaskBookOpenTarget.preparationTasks:
        openPreparationTasks(context, requirement);
      case TaskBookOpenTarget.requirementDetail:
        context.push(
          AppRoutes.requirementDetail,
          extra: goalId == null
              ? requirement
              : <String, dynamic>{
                  'requirement': requirement,
                  'goalId': goalId,
                },
        );
    }
  }

  static void openPreparationTasks(
    BuildContext context,
    Requirement requirement,
  ) {
    context.push(
      AppRoutes.qualificationTaskBook,
      extra: <String, dynamic>{'requirement': requirement},
    );
  }
}

class AppRoutes {
  static const String bootstrap = '/bootstrap';
  static const String onboarding = '/onboarding';

  static const String home = '/home';
  static const String myPath = '/path';
  static const String myPathLegacy = '/task-book/customize';
  static const String personalLog = '/log';
  static const String personalLogLegacy = '/log/legacy';
  static const String personalLogClassic = '/log/classic';
  static const String quickLogSetup = '/log/setup';
  static const String growth = '/growth';
  static const String certifications = '/certifications';
  static const String settings = '/settings';

  static const String department = '/department';

  static const String career = growth;
  static const String careerVault = personalLog;
  static const String careerEvidence = '/growth/evidence';
  static const String resources = '/resources';

  static const String goalSetup = '/goal-setup';
  static const String growthDetails = '/growth-tools';
  static const String careerIntelligence = '/career-intelligence';
  static const String careerLongevity = '/career-intelligence/long-term';
  static const String dailyFocus = '/daily-focus';
  static const String needsAttention = '/needs-attention';
  static const String careerInbox = '/career-inbox';
  static const String careerExport = '/career-intelligence/export';
  static const String promotionPortfolioReview =
      '/career-intelligence/export/promotion-review';
  static const String departmentTransfer =
      '/career-intelligence/department-transfer';
  static const String requirementDetail = '/requirement';
  static const String getStarted = '/get-started';
  static const String certificationDetail = '/certification';
  static const String certificationAdd = '/certifications/add';

  static const String taskBookReview = '/task-book/review';
  static const String taskBookRequirementsSetup =
      '/task-book/requirements-setup';
  static const String customTaskBookCreate = '/task-book/custom/create';
  static const String customTaskBookBuilder = '/task-book/custom/builder';
  static const String qualificationTaskBook = '/task-book/qualification';
  static const String requirementChecklist = '/task-book/checklist';
  static const String taskDetail = '/task-book/task';

  // Department Portal (web/desktop)
  static const String portalLogin = '/portal/login';
  static const String portal = '/portal';
}