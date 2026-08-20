import 'package:flutter/foundation.dart';

import 'package:firepath/models/resource.dart';
import 'package:firepath/services/catalog.dart';

/// Shared resource composition logic for Task Book flows.
///
/// Goal: never leave Get Started / Task Detail "Study" and "Find training"
/// sections empty when a certificationDefinitionId exists.
///
/// This stays fully offline-capable: resources are sourced from the local
/// catalog + deterministic FireOpsSim deep links.
@immutable
class TaskBookResourceComposer {
  const TaskBookResourceComposer._();

  static const String _fireOpsSimHost = 'fireopssim.com';

  static bool _isEmsCert(String? certId) {
    const emsCerts = {'emt', 'aemt', 'paramedic', 'bls', 'acls', 'pals'};
    final c = certId?.trim();
    if (c == null || c.isEmpty) return false;
    return emsCerts.contains(c);
  }

  static Uri fireOpsSimSchoolFinderUri({required String certId, required String? stateCode}) {
    final state = stateCode?.trim().toUpperCase();
    final q = <String, String>{
      'cert': certId,
      'path': _isEmsCert(certId) ? 'ems' : 'fire',
      if (state != null && state.isNotEmpty && state != FireOpsCatalog.otherStateCode) 'state': state,
    };
    return Uri.https(_fireOpsSimHost, '/school-finder.html', q);
  }

  static Uri fireOpsSimStudyGuidesUri({required String certId}) => Uri.https(_fireOpsSimHost, '/study-guides.html', {'cert': certId});

  static Uri fireOpsSimTaskbookResourcesUri({required String certId, required String taskId, required String? stateCode}) {
    final state = stateCode?.trim().toUpperCase();
    final q = <String, String>{
      'cert': certId,
      'task': taskId,
      'source': 'roadmap',
      if (state != null && state.isNotEmpty && state != FireOpsCatalog.otherStateCode) 'state': state,
    };
    return Uri.https(_fireOpsSimHost, '/taskbook-resources.html', q);
  }

  static Resource _link({
    required String id,
    required String title,
    required String description,
    required ResourceType type,
    required ResourceSourceType sourceType,
    required Uri url,
    required String certId,
  }) {
    final now = DateTime.now();
    return Resource(
      id: id,
      title: title,
      description: description,
      type: type,
      url: url.toString(),
      state: null,
      relatedCertificationDefinitionIds: <String>[certId],
      relatedCareerGoalIds: const <String>[],
      verified: true,
      lastVerifiedDate: now,
      sourceType: sourceType,
      createdAt: now,
      updatedAt: now,
    );
  }

  static List<Resource> _dedupe(List<Resource> input) {
    final seen = <String>{};
    final out = <Resource>[];
    for (final r in input) {
      final key = (r.url ?? r.id).trim();
      if (key.isEmpty) continue;
      if (seen.add(key)) out.add(r);
    }
    return out;
  }

  static _Sections buildGetStartedSections({
    required String certId,
    required String? stateCode,
    required List<Resource> catalogCombined,
  }) {
    final normalizedState = FireOpsCatalog.stateCodeFromLegacyValue(stateCode);

    List<Resource> pick(Set<ResourceType> types) {
      final state = normalizedState?.trim().toUpperCase();
      final filtered = catalogCombined
          .where((r) {
            if (!types.contains(r.type)) return false;
            // If the user hasn't selected a state yet, do NOT surface any
            // state-specific links (avoids silently defaulting to a random state
            // like CO).
            if (state == null || state.isEmpty) return r.state == null;
            return true;
          })
          .toList();
      filtered.sort((a, b) {
        int score(Resource r) {
          var s = 0;
          if (state != null && state.isNotEmpty && r.state == state) s += 120;
          if (r.verified) s += 50;
          s += switch (r.type) {
            ResourceType.officialStateAgency => 40,
            ResourceType.officialFederalAgency => 35,
            ResourceType.credentialingOrganization => 30,
            ResourceType.trainingProvider => 20,
            ResourceType.courseFinder => 18,
            ResourceType.collegeAcademy => 16,
            ResourceType.professionalOrganization => 12,
            ResourceType.studyResource => 10,
            ResourceType.practiceResource => 8,
            ResourceType.fireOpsTool => 6,
            ResourceType.departmentResource => 25,
          };
          return -s;
        }

        return score(a).compareTo(score(b));
      });
      return filtered;
    }

    final official = pick({
      ResourceType.officialStateAgency,
      ResourceType.officialFederalAgency,
      ResourceType.credentialingOrganization,
    });

    final training = pick({
      ResourceType.trainingProvider,
      ResourceType.courseFinder,
      ResourceType.collegeAcademy,
      ResourceType.officialFederalAgency,
    });

    final study = pick({ResourceType.studyResource, ResourceType.credentialingOrganization});
    final practice = pick({ResourceType.practiceResource, ResourceType.fireOpsTool});

    // --- Deterministic FireOpsSim fallbacks (always helpful) ---
    final fireOpsFinder = _link(
      id: 'fireopssim_school_finder_$certId',
      title: 'FireOpsSim School Finder',
      description: 'Find nearby and verified classes for this certification.',
      type: ResourceType.courseFinder,
      sourceType: ResourceSourceType.training,
      url: fireOpsSimSchoolFinderUri(certId: certId, stateCode: normalizedState),
      certId: certId,
    );

    final fireOpsStudy = _link(
      id: 'fireopssim_study_guides_$certId',
      title: 'FireOpsSim Study Guide',
      description: 'Study guide focused on the certification’s JPRs and testing topics.',
      type: ResourceType.studyResource,
      sourceType: ResourceSourceType.study,
      url: fireOpsSimStudyGuidesUri(certId: certId),
      certId: certId,
    );

    final trainingOut = _dedupe([fireOpsFinder, ...training]);
    final studyOut = _dedupe([fireOpsStudy, ...study]);
    final officialOut = _dedupe(official);
    final practiceOut = _dedupe(practice);

    return _Sections(
      official: officialOut,
      training: trainingOut,
      study: studyOut,
      practice: practiceOut,
    );
  }

  static List<Resource> buildTaskDetailReferences({
    required String? certId,
    required String taskId,
    required String? stateCode,
    required List<Resource> catalogCombined,
  }) {
    final c = certId?.trim();
    if (c == null || c.isEmpty) return const <Resource>[];

    final normalizedState = FireOpsCatalog.stateCodeFromLegacyValue(stateCode);

    // Start with the best "official/skill sheet" style resources.
    final officialDocs = catalogCombined
        .where(
          (r) => r.relatedCertificationDefinitionIds.contains(c) &&
              {
                ResourceType.officialStateAgency,
                ResourceType.officialFederalAgency,
                ResourceType.credentialingOrganization,
                ResourceType.studyResource,
              }.contains(r.type),
        )
        .where((r) {
          final st = normalizedState?.trim().toUpperCase();
          if (st == null || st.isEmpty) return r.state == null;
          return r.state == null || r.state == st;
        })
        .toList();

    final fireOpsTaskbook = _link(
      id: 'fireopssim_taskbook_resources_${c}_$taskId',
      title: 'FireOpsSim Task Book Resources',
      description: 'Skill sheets, JPR references, and tools mapped to this task.',
      type: ResourceType.studyResource,
      sourceType: ResourceSourceType.study,
      url: fireOpsSimTaskbookResourcesUri(certId: c, taskId: taskId, stateCode: normalizedState),
      certId: c,
    );

    return _dedupe([fireOpsTaskbook, ...officialDocs]);
  }
}

@immutable
class _Sections {
  final List<Resource> official;
  final List<Resource> training;
  final List<Resource> study;
  final List<Resource> practice;
  const _Sections({required this.official, required this.training, required this.study, required this.practice});
}
