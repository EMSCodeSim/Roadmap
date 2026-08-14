import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:firepath/models/career_goal.dart';
import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/department_transfer.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/catalog.dart';
import 'package:firepath/state/app_state.dart';

class DepartmentTransferStore {
  static const _key = 'department_transfer_plan_v1';

  Future<DepartmentTransferPlan> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.trim().isEmpty) return DepartmentTransferPlan.empty();
    try {
      return DepartmentTransferPlan.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return DepartmentTransferPlan.empty();
    }
  }

  Future<void> save(DepartmentTransferPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(plan.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class DepartmentTransferService {
  const DepartmentTransferService._();

  static List<DepartmentTransferRequirement> requirementsFromGoal(CareerGoal goal) {
    return goal.requirements
        .where((r) => r.defaultRequired)
        .map((r) => DepartmentTransferRequirement(
              id: 'goal:${goal.id}:${r.id}',
              title: r.name,
              kind: _kindForRequirement(r.type),
              certificationDefinitionId: r.certificationDefinitionId,
              keywords: <String>{
                r.name,
                r.category,
                if (r.certificationReference != null) r.certificationReference!,
              }.where((e) => e.trim().isNotEmpty).toList(),
              manuallySatisfied: false,
              notes: r.description,
            ))
        .toList();
  }

  static DepartmentTransferEvaluation evaluate({
    required AppState app,
    required List<CareerRecord> records,
    required DepartmentTransferPlan plan,
  }) {
    final items = plan.requirements.map((requirement) {
      if (requirement.manuallySatisfied) {
        return TransferRequirementEvaluation(
          requirement: requirement,
          satisfied: true,
          reason: 'Marked satisfied by the user.',
          matchingRecords: 0,
        );
      }

      if (requirement.kind == TransferRequirementKind.certification) {
        final wantedId = requirement.certificationDefinitionId;
        final matchingCerts = app.certifications.where((cert) {
          if (cert.status.name == 'expired') return false;
          if (wantedId != null && cert.certificationDefinitionId == wantedId) return true;
          final haystack = <String>[
            cert.name,
            app.certificationDisplayName(cert),
          ].map(_normalize).join(' ');
          return _candidateTerms(requirement).any((term) => haystack.contains(term));
        }).toList();
        if (matchingCerts.isNotEmpty) {
          return TransferRequirementEvaluation(
            requirement: requirement,
            satisfied: true,
            reason: 'Matched current credential: ${app.certificationDisplayName(matchingCerts.first)}.',
            matchingRecords: 0,
          );
        }
      }

      final matchedRecords = records.where((record) {
        final haystack = <String>[
          record.title,
          record.category,
          record.summary ?? '',
          record.impact ?? '',
          record.roleOrAssignment ?? '',
          record.trackingKey ?? '',
          ...record.tags,
        ].map(_normalize).join(' ');
        return _candidateTerms(requirement).any((term) => haystack.contains(term));
      }).toList();

      if (matchedRecords.isNotEmpty) {
        return TransferRequirementEvaluation(
          requirement: requirement,
          satisfied: true,
          reason: 'Found ${matchedRecords.length} matching career record${matchedRecords.length == 1 ? '' : 's'} that may support this requirement.',
          matchingRecords: matchedRecords.length,
        );
      }

      final progressMatch = app.pathOverrides.any((override) {
        final haystack = _normalize(override.requirementId);
        return _candidateTerms(requirement).any((term) => haystack.contains(term));
      });
      if (progressMatch) {
        return TransferRequirementEvaluation(
          requirement: requirement,
          satisfied: true,
          reason: 'Found retained Task Book / path progress that may support this requirement.',
          matchingRecords: 0,
        );
      }

      return TransferRequirementEvaluation(
        requirement: requirement,
        satisfied: false,
        reason: 'No current credential or clearly matching career evidence was found. Verify this item with the target department.',
        matchingRecords: 0,
      );
    }).toList();

    return DepartmentTransferEvaluation(plan: plan, items: items);
  }

  static String buildComparisonText(DepartmentTransferEvaluation evaluation) {
    final buffer = StringBuffer();
    final plan = evaluation.plan;
    buffer.writeln('DEPARTMENT TRANSFER READINESS');
    buffer.writeln(plan.departmentName.trim().isEmpty ? 'Target department not named' : plan.departmentName.trim());
    if ((plan.targetRole ?? '').trim().isNotEmpty) buffer.writeln('Target role: ${plan.targetRole}');
    buffer.writeln('Estimated overlap: ${evaluation.satisfiedCount}/${evaluation.totalCount} requirements (${(evaluation.percent * 100).round()}%)');
    buffer.writeln();
    buffer.writeln('LIKELY TRANSFERABLE');
    final satisfied = evaluation.items.where((e) => e.satisfied).toList();
    if (satisfied.isEmpty) {
      buffer.writeln('- No matches identified yet.');
    } else {
      for (final item in satisfied) {
        buffer.writeln('- ${item.requirement.title} — ${item.reason}');
      }
    }
    buffer.writeln();
    buffer.writeln('GAPS / VERIFY');
    if (evaluation.gaps.isEmpty) {
      buffer.writeln('- No obvious gaps identified from the information entered.');
    } else {
      for (final item in evaluation.gaps) {
        buffer.writeln('- ${item.requirement.title} — ${item.reason}');
      }
    }
    buffer.writeln();
    buffer.writeln('This comparison is a personal planning aid. The receiving department or certifying authority determines what transfers, what must be repeated, and whether supporting documentation is acceptable.');
    return buffer.toString().trim();
  }

  static TransferRequirementKind _kindForRequirement(RequirementType type) => switch (type) {
        RequirementType.certification => TransferRequirementKind.certification,
        RequirementType.experience || RequirementType.numericProgress => TransferRequirementKind.experience,
        RequirementType.taskBook => TransferRequirementKind.taskBook,
        RequirementType.education || RequirementType.trainingCourse || RequirementType.course => TransferRequirementKind.education,
        RequirementType.practical || RequirementType.promotionalTest || RequirementType.interview => TransferRequirementKind.practical,
        RequirementType.custom => TransferRequirementKind.other,
      };

  static Iterable<String> _candidateTerms(DepartmentTransferRequirement requirement) {
    final values = <String>{requirement.title, ...requirement.keywords};
    final defId = requirement.certificationDefinitionId;
    if (defId != null) {
      final def = FireOpsCatalog.certificationById()[defId];
      if (def != null) values.addAll([def.displayName, if (def.shortName != null) def.shortName!, ...def.aliases]);
    }
    return values.map(_normalize).where((e) => e.length >= 3);
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}
