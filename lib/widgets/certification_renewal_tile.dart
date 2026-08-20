import 'package:flutter/material.dart';

import 'package:firepath/models/certification.dart';
import 'package:firepath/services/certification_urgency.dart';
import 'package:firepath/theme.dart';
import 'package:firepath/widgets/status_pill.dart';

/// High-contrast, mobile-first tile for expiring/expired certifications.
class CertificationRenewalTile extends StatelessWidget {
  final String title;
  final String? issuingOrganization;
  final CertificationStatus status;
  final int? daysRemaining;
  final String? expirationLabel;
  final String? renewalSummary;
  final VoidCallback onOpen;
  final VoidCallback? onRenew;

  const CertificationRenewalTile({
    super.key,
    required this.title,
    required this.issuingOrganization,
    required this.status,
    required this.daysRemaining,
    required this.expirationLabel,
    required this.renewalSummary,
    required this.onOpen,
    required this.onRenew,
  });

  factory CertificationRenewalTile.fromCert({
    Key? key,
    required Certification cert,
    required String displayName,
    required VoidCallback onOpen,
    required VoidCallback? onRenew,
  }) {
    final guidance = CertificationUrgency.renewalGuidance(cert);
    final status = cert.status;

    String expirationLabel;
    if (cert.doesNotExpire) {
      expirationLabel = 'Does not expire';
    } else if (cert.expirationDate == null) {
      expirationLabel = 'No expiration date';
    } else {
      final d = cert.daysRemaining;
      if (d == null) {
        expirationLabel = 'Expires ${_formatDate(cert.expirationDate!)}';
      } else if (d < 0) {
        expirationLabel = 'Expired ${_formatDate(cert.expirationDate!)}';
      } else {
        expirationLabel = 'Expires in $d ${d == 1 ? 'day' : 'days'} • ${_formatDate(cert.expirationDate!)}';
      }
    }

    return CertificationRenewalTile(
      key: key,
      title: displayName,
      issuingOrganization: cert.issuingOrganization,
      status: status,
      daysRemaining: cert.daysRemaining,
      expirationLabel: expirationLabel,
      renewalSummary: guidance.summary,
      onOpen: onOpen,
      onRenew: onRenew,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final (toneColor, bg, icon, label) = switch (status) {
      CertificationStatus.expired => (
          FireOpsSemanticColors.expired,
          cs.errorContainer,
          Icons.cancel,
          'Expired'
        ),
      CertificationStatus.expiringSoon => (
          FireOpsSemanticColors.expiring,
          cs.secondaryContainer,
          Icons.warning_amber_rounded,
          'Expiring'
        ),
      CertificationStatus.current => (
          FireOpsSemanticColors.current,
          cs.surfaceContainerHighest,
          Icons.check_circle,
          'Current'
        ),
    };

    final org = (issuingOrganization ?? '').trim();

    return Material(
      color: bg.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(AppCardTokens.radius),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppCardTokens.radius),
        child: Container(
          padding: AppCardTokens.padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppCardTokens.radius),
            border: Border.all(color: toneColor.withValues(alpha: AppCardTokens.toneBorderAlpha)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: toneColor.withValues(alpha: AppCardTokens.toneBorderAlpha)),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: toneColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StatusPill(
                          text: label,
                          icon: icon,
                          backgroundColor: cs.surface,
                          foregroundColor: toneColor,
                          maxWidth: 120,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [if (org.isNotEmpty) org, if (expirationLabel != null) expirationLabel].join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                    ),
                    if ((renewalSummary ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        renewalSummary!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface, height: 1.35, fontWeight: FontWeight.w700),
                      ),
                    ],
                    if (onRenew != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.tonalIcon(
                            onPressed: onRenew,
                            icon: const Icon(Icons.autorenew),
                            label: const Text('Renew / Update'),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppCardTokens.radius)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}
