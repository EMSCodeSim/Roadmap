import 'package:flutter/material.dart';

import 'package:firepath/models/requirement.dart';
import 'package:firepath/services/catalog.dart';

/// Consistent UI labels/colors for describing where a requirement comes from.
///
/// This intentionally uses cautious language: we only claim “Required in [State]”
/// when the requirement is explicitly tagged as [RequirementSource.stateRequirement]
/// AND the requirement carries a matching [Requirement.sourceStateCode].
class RequirementSourcePresenter {
  static String badgeText(Requirement r, {required String? profileStateCode}) {
    switch (r.requirementSource) {
      case RequirementSource.stateRequirement:
        final stateName = FireOpsCatalog.stateNameForCode(r.sourceStateCode ?? profileStateCode);
        if (stateName != null && stateName.trim().isNotEmpty) return 'Required in $stateName';
        return 'State requirement';
      case RequirementSource.departmentRequirement:
        return 'Department requirement';
      case RequirementSource.commonlyRequired:
        return 'Common requirement';
      case RequirementSource.recommended:
        return 'Common recommendation';
    }
  }

  static String shortLine(Requirement r, {required String? profileStateCode}) {
    switch (r.requirementSource) {
      case RequirementSource.stateRequirement:
        final stateName = FireOpsCatalog.stateNameForCode(r.sourceStateCode ?? profileStateCode);
        return stateName == null ? 'State requirement' : '$stateName requirement';
      case RequirementSource.departmentRequirement:
        return 'Department requirement';
      case RequirementSource.commonlyRequired:
        return r.stateDependent ? 'Common requirement • Verify locally' : 'Common requirement';
      case RequirementSource.recommended:
        return 'Common recommendation';
    }
  }

  static ({Color bg, Color fg}) badgeColors(BuildContext context, Requirement r) {
    final cs = Theme.of(context).colorScheme;
    return switch (r.requirementSource) {
      RequirementSource.stateRequirement => (bg: cs.tertiaryContainer.withValues(alpha: 0.85), fg: cs.onTertiaryContainer),
      RequirementSource.departmentRequirement => (bg: cs.secondaryContainer.withValues(alpha: 0.85), fg: cs.onSecondaryContainer),
      RequirementSource.commonlyRequired => (bg: cs.primaryContainer.withValues(alpha: 0.70), fg: cs.onPrimaryContainer),
      RequirementSource.recommended => (bg: cs.surfaceContainerHighest, fg: cs.onSurfaceVariant),
    };
  }

  static bool isVerifiedStateRequirement(Requirement r, {required String? profileStateCode}) {
    if (r.requirementSource != RequirementSource.stateRequirement) return false;
    final state = (r.sourceStateCode ?? profileStateCode)?.trim().toUpperCase();
    final src = r.sourceStateCode?.trim().toUpperCase();
    if (src == null || src.isEmpty) return false;
    if (state == null || state.isEmpty) return true;
    return src == state;
  }
}
