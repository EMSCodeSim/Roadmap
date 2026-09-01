import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:firepath/services/ecosystem_recommendations.dart';
import 'package:firepath/services/theme.dart';

class EcosystemRecommendationCard extends StatelessWidget {
  final EcosystemRecommendation recommendation;
  final bool compact;

  const EcosystemRecommendationCard({
    super.key,
    required this.recommendation,
    this.compact = false,
  });

  Future<void> _open() async {
    final uri = Uri.tryParse(recommendation.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'RECOMMENDED TOOL',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                recommendation.product,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            recommendation.reason,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _open,
              icon: const Icon(Icons.open_in_new, size: 17),
              label: Text(recommendation.actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}
