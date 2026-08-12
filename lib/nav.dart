import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:firepath/pages/bootstrap_page.dart';
import 'package:firepath/pages/shell/app_shell_page.dart';
import 'package:firepath/pages/home/visual_home_page.dart';
import 'package:firepath/pages/onboarding/onboarding_flow_page.dart';
import 'package:firepath/pages/path/goal_picker_page.dart';
import 'package:firepath/pages/path/roadmap_entry_page.dart';
import 'package:firepath/pages/career/career_hub_page.dart';
import 'package:firepath/pages/career/career_vault_page.dart';
import 'package:firepath/pages/career/personal_log_page.dart';
import 'package:firepath/pages/certifications/certifications_page.dart';
import 'package:firepath/pages/resources/resources_page.dart';
import 'package:firepath/pages/requirement/requirement_detail_page.dart';
import 'package:firepath/pages/requirement/get_started_page.dart';
import 'package:firepath/pages/certifications/certification_detail_page.dart';
import 'package:firepath/pages/certifications/certification_picker_page.dart';

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
            const NoTransitionPage(child: OnboardingFlowPage()),
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
                    const NoTransitionPage(child: RoadmapEntryPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.personalLog,
                name: 'personal_log',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: PersonalLogPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.growth,
                name: 'growth',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: CareerHubPage()),
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

      // Legacy links retained so existing bookmarks/deep links do not break.
      GoRoute(path: '/career', redirect: (context, state) => AppRoutes.growth),
      GoRoute(
        path: '/career/vault',
        redirect: (context, state) => AppRoutes.personalLog,
      ),

      GoRoute(
        path: AppRoutes.goalSetup,
        name: 'goal_setup',
        pageBuilder: (context, state) =>
            const MaterialPage(child: GoalPickerPage()),
      ),
      GoRoute(
        path: AppRoutes.careerEvidence,
        name: 'career_evidence',
        pageBuilder: (context, state) =>
            const MaterialPage(child: CareerVaultPage()),
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
        pageBuilder: (context, state) =>
            MaterialPage(child: RequirementDetailPage(requirement: state.extra)),
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
}

class AppRoutes {
  static const String bootstrap = '/bootstrap';
  static const String onboarding = '/onboarding';

  static const String home = '/home';
  static const String myPath = '/path';
  static const String personalLog = '/log';
  static const String growth = '/growth';
  static const String certifications = '/certifications';

  // Compatibility aliases used throughout the existing app.
  static const String career = growth;
  static const String careerVault = personalLog;
  static const String careerEvidence = '/growth/evidence';
  static const String resources = '/resources';

  static const String goalSetup = '/goal-setup';
  static const String requirementDetail = '/requirement';
  static const String getStarted = '/get-started';
  static const String certificationDetail = '/certification';
  static const String certificationAdd = '/certifications/add';
}
