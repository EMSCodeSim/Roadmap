import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:firepath/pages/bootstrap_page.dart';
import 'package:firepath/pages/shell/app_shell_page.dart';
import 'package:firepath/pages/home/home_page.dart';
import 'package:firepath/pages/onboarding/onboarding_flow_page.dart';
import 'package:firepath/pages/path/my_path_page.dart';
import 'package:firepath/pages/career/career_vault_page.dart';
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
        pageBuilder: (context, state) => const NoTransitionPage(child: BootstrapPage()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => const NoTransitionPage(child: OnboardingFlowPage()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShellPage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(child: HomePage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.myPath,
                name: 'my_path',
                pageBuilder: (context, state) => const NoTransitionPage(child: MyPathPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.careerVault,
                name: 'career_vault',
                pageBuilder: (context, state) => const NoTransitionPage(child: CareerVaultPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.certifications,
                name: 'certifications',
                pageBuilder: (context, state) => const NoTransitionPage(child: CertificationsPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.resources,
                name: 'resources',
                pageBuilder: (context, state) => NoTransitionPage(child: ResourcesPage(extra: state.extra)),
              ),
            ],
          ),
        ],
      ),

      // Details (outside the shell so they slide over any tab)
      GoRoute(
        path: AppRoutes.requirementDetail,
        name: 'requirement_detail',
        pageBuilder: (context, state) => MaterialPage(child: RequirementDetailPage(requirement: state.extra)),
      ),
      GoRoute(
        path: AppRoutes.getStarted,
        name: 'get_started',
        pageBuilder: (context, state) => MaterialPage(child: GetStartedPage(requirement: state.extra)),
      ),
      GoRoute(
        path: '${AppRoutes.certificationDetail}/:id',
        name: 'certification_detail',
        pageBuilder: (context, state) => MaterialPage(child: CertificationDetailPage(certId: state.pathParameters['id']!, extra: state.extra)),
      ),
      GoRoute(
        path: AppRoutes.certificationAdd,
        name: 'certification_add',
        pageBuilder: (context, state) => MaterialPage(child: CertificationPickerPage(extra: state.extra)),
      ),
    ],
  );
}

class AppRoutes {
  static const String bootstrap = '/bootstrap';
  static const String onboarding = '/onboarding';

  static const String home = '/home';
  static const String myPath = '/path';
  static const String careerVault = '/career';
  static const String certifications = '/certifications';
  static const String resources = '/resources';

  static const String requirementDetail = '/requirement';
  static const String getStarted = '/get-started';
  static const String certificationDetail = '/certification';
  static const String certificationAdd = '/certifications/add';
}
