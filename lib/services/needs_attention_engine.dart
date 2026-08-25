import 'package:firepath/models/career_record.dart';
import 'package:firepath/models/certification.dart';
import 'package:firepath/models/requirement.dart';
import 'package:firepath/state/app_state.dart';

enum NeedsAttentionUrgency { now, soon, later }

enum NeedsAttentionKind {
  certificationExpired,
  certificationExpiring,
  certificationMatch,
  missingRequiredCertification,
  stalledTaskBook,
}

class NeedsAttentionItem {
  final String id;
  final NeedsAttentionKind kind;
  final NeedsAttentionUrgency urgency;
  final String title;
  final String detail;
  final String actionLabel;
  final String? certificationId;
  final String? requirementId;

  const NeedsAttentionItem({
    required this.id,
    required this.kind,
    required this.urgency,
    required this.title,
    required this.detail,
    required this.actionLabel,
    this.certificationId,
    this.requirementId,
  });
}

class NeedsAttentionEngine {
  static List<NeedsAttentionItem> analyze({
    required AppState app,
    required List<CareerRecord> records,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final items = <NeedsAttentionItem>[];

    for (final cert in app.certifications) {
      if (cert.doesNotExpire || cert.expirationDate == null) continue;
      final days = cert.expirationDate!
          .difference(DateTime(today.year, today.month, today.day))
          .inDays;
      final name = app.certificationDisplayName(cert);

      if (days < 0) {
        items.add(NeedsAttentionItem(
          id: 'cert-expired:${cert.id}',
          kind: NeedsAttentionKind.certificationExpired,
          urgency: NeedsAttentionUrgency.now,
          title: '$name is expired',
          detail: 'Expired ${days.abs()} day${days.abs() == 1 ? '' : 's'} ago. Renew or update the credential record.',
          actionLabel: 'Review cert',
          certificationId: cert.id,
        ));
      } else if (days <= 14) {
        items.add(NeedsAttentionItem(
          id: 'cert-expiring:${cert.id}',
          kind: NeedsAttentionKind.certificationExpiring,
          urgency: NeedsAttentionUrgency.now,
          title: '$name expires in $days days',
          detail: 'This credential is close to expiration and may affect Task Book readiness.',
          actionLabel: 'Plan renewal',
          certificationId: cert.id,
        ));
      } else if (days <= 60) {
        items.add(NeedsAttentionItem(
          id: 'cert-expiring:${cert.id}',
          kind: NeedsAttentionKind.certificationExpiring,
          urgency: NeedsAttentionUrgency.soon,
          title: '$name expires in $days days',
          detail: 'Start planning renewal before it becomes urgent.',
          actionLabel: 'Review cert',
          certificationId: cert.id,
        ));
      } else if (days <= 90) {
        items.add(NeedsAttentionItem(
          id: 'cert-expiring:${cert.id}',
          kind: NeedsAttentionKind.certificationExpiring,
          urgency: NeedsAttentionUrgency.later,
          title: '$name expires in $days days',
          detail: 'No immediate action is required, but renewal is approaching.',
          actionLabel: 'Review cert',
          certificationId: cert.id,
        ));
      }
    }

    if (app.pendingCertMatches.isNotEmpty) {
      final count = app.pendingCertMatches.length;
      items.add(NeedsAttentionItem(
        id: 'cert-matches',
        kind: NeedsAttentionKind.certificationMatch,
        urgency: NeedsAttentionUrgency.now,
        title: '$count certification match${count == 1 ? '' : 'es'} need review',
        detail: 'Confirm matches so credentials count correctly toward Career Road requirements.',
        actionLabel: 'Review matches',
      ));
    }

    final roadmap = app.roadmap;
    if (roadmap != null) {
      final heldDefinitionIds = app.certifications
          .where((c) => c.status != CertificationStatus.expired)
          .map((c) => c.certificationDefinitionId)
          .whereType<String>()
          .toSet();

      for (final item in roadmap.all) {
        final requirement = item.requirement;
        if (item.isComplete || item.isExcluded) continue;
        if (requirement.type != RequirementType.certification) continue;
        final definitionId = requirement.certificationDefinitionId;
        if (definitionId == null || definitionId.isEmpty) continue;
        if (heldDefinitionIds.contains(definitionId)) continue;

        items.add(NeedsAttentionItem(
          id: 'missing-cert:${requirement.id}',
          kind: NeedsAttentionKind.missingRequiredCertification,
          urgency: NeedsAttentionUrgency.soon,
          title: '${requirement.name} is still needed',
          detail: 'This certification is part of your active ${roadmap.goal.title} Career Road.',
          actionLabel: 'Open requirement',
          requirementId: requirement.id,
        ));
      }

      if (roadmap.incompleteCount > 0) {
        final linked = records
            .where((record) =>
                record.relatedGoalId == roadmap.goal.id ||
                roadmap.all.any((rr) => rr.requirement.id == record.relatedRequirementId))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
        final latest = linked.isEmpty ? null : linked.first.date;
        final daysSince = latest == null ? null : today.difference(latest).inDays;

        if (daysSince != null && daysSince >= 30) {
          items.add(NeedsAttentionItem(
            id: 'stalled-roadmap:${roadmap.goal.id}',
            kind: NeedsAttentionKind.stalledTaskBook,
            urgency: daysSince >= 60
                ? NeedsAttentionUrgency.now
                : NeedsAttentionUrgency.soon,
            title: '${roadmap.goal.title} has been quiet for $daysSince days',
            detail: 'No linked Task Book progress has been recorded recently. A short Daily Focus session can restart momentum.',
            actionLabel: 'Open Task Book',
          ));
        }
      }
    }

    int rank(NeedsAttentionUrgency urgency) => switch (urgency) {
          NeedsAttentionUrgency.now => 0,
          NeedsAttentionUrgency.soon => 1,
          NeedsAttentionUrgency.later => 2,
        };
    items.sort((a, b) {
      final urgency = rank(a.urgency).compareTo(rank(b.urgency));
      if (urgency != 0) return urgency;
      return a.title.compareTo(b.title);
    });
    return items;
  }
}
