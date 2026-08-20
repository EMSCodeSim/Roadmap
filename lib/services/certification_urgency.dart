import 'package:flutter/foundation.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/models/certification_definition.dart';
import 'package:firepath/services/catalog.dart';

@immutable
class CertificationUrgencyItem {
  final Certification cert;
  final CertificationStatus status;
  final int? daysRemaining;
  const CertificationUrgencyItem({required this.cert, required this.status, required this.daysRemaining});

  bool get isExpired => status == CertificationStatus.expired;
  bool get isExpiringSoon => status == CertificationStatus.expiringSoon;
}

@immutable
class CertificationRenewalGuidance {
  final String headline;
  final String summary;
  final List<String> steps;
  final String? ceNotes;
  const CertificationRenewalGuidance({required this.headline, required this.summary, required this.steps, required this.ceNotes});
}

/// Helpers for making expiring/expired certifications impossible to miss.
class CertificationUrgency {
  static const List<int> dashboardBuckets = [30, 60, 90];

  static List<CertificationUrgencyItem> urgent(List<Certification> certs, {int withinDays = 90}) {
    final items = <CertificationUrgencyItem>[];
    for (final c in certs) {
      final s = c.status;
      if (s == CertificationStatus.current) continue;
      final days = c.daysRemaining;
      if (s == CertificationStatus.expiringSoon && (days == null || days > withinDays)) continue;
      items.add(CertificationUrgencyItem(cert: c, status: s, daysRemaining: days));
    }

    int rank(CertificationUrgencyItem i) => switch (i.status) {
          CertificationStatus.expired => 0,
          CertificationStatus.expiringSoon => 1,
          CertificationStatus.current => 2,
        };

    items.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      final ad = a.daysRemaining;
      final bd = b.daysRemaining;
      if (ad == null && bd != null) return 1;
      if (ad != null && bd == null) return -1;
      if (ad != null && bd != null) return ad.compareTo(bd);
      return 0;
    });
    return items;
  }

  static Map<int, List<CertificationUrgencyItem>> bucketedForDashboard(List<Certification> certs) {
    final items = urgent(certs, withinDays: 90);
    final out = <int, List<CertificationUrgencyItem>>{for (final b in dashboardBuckets) b: <CertificationUrgencyItem>[]};
    for (final item in items) {
      if (item.status == CertificationStatus.expired) {
        out[30]!.add(item);
        continue;
      }
      final d = item.daysRemaining;
      if (d == null) continue;
      for (final b in dashboardBuckets) {
        if (d <= b) {
          out[b]!.add(item);
          break;
        }
      }
    }
    return out;
  }

  static CertificationRenewalGuidance renewalGuidance(Certification cert) {
    final def = _definitionFor(cert);
    final displayName = def?.displayName ?? cert.name;
    final isExpired = cert.status == CertificationStatus.expired;

    final ceNotes = def?.continuingEducationNotes?.trim();
    final renewalDesc = def?.renewalDescription?.trim();

    final summaryParts = <String>[];
    if (renewalDesc != null && renewalDesc.isNotEmpty) summaryParts.add(renewalDesc);
    if (ceNotes != null && ceNotes.isNotEmpty) summaryParts.add(ceNotes);
    final summary = summaryParts.isEmpty
        ? 'Renew through your issuing authority and update your record in FirePath.'
        : summaryParts.join(' ');

    final steps = <String>[
      if (!isExpired) 'Confirm your renewal window and due date.',
      if (isExpired) 'Confirm reinstatement requirements (some agencies require a refresher if lapsed).',
      if (ceNotes != null && ceNotes.isNotEmpty) 'Complete required CE / continuing education (${_compactCe(ceNotes)}).',
      'Gather proof: completion certificates, CE transcripts, or signed documentation.',
      'Submit your renewal to the issuing organization (and pay any required fees).',
      'Update FirePath with the new expiration date and a renewal note.',
    ];

    return CertificationRenewalGuidance(
      headline: isExpired ? 'Renew now — credential is expired' : 'Renew soon — keep this credential current',
      summary: summary,
      steps: steps,
      ceNotes: (ceNotes != null && ceNotes.isNotEmpty) ? ceNotes : null,
    );
  }

  static CertificationDefinition? _definitionFor(Certification cert) {
    final id = cert.certificationDefinitionId;
    if (id == null || id.trim().isEmpty) return null;
    return FireOpsCatalog.certificationById()[id];
  }

  static String _compactCe(String v) {
    final s = v.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s.length <= 64 ? s : '${s.substring(0, 61)}...';
  }
}
