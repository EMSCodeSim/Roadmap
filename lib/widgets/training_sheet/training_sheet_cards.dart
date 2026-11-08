import 'package:flutter/material.dart';

import 'package:firepath/services/theme.dart';
import 'package:firepath/services/training_time_calculator.dart';
import 'package:firepath/services/responder_roadmap_api.dart';

class TrainingSheetHeaderCard extends StatelessWidget {
  const TrainingSheetHeaderCard({super.key, required this.detail});
  final DepartmentClassDetail detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: AppCardTokens.padding,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppCardTokens.radius),
              color: FireOpsFeatureColors.training.withValues(alpha: 0.12),
            ),
            child: Icon(Icons.receipt_long_rounded, color: FireOpsFeatureColors.training),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(detail.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, height: 1.1)),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                _Pill(icon: Icons.event_outlined, label: _formatDate(detail.startsAt?.toLocal()), tone: scheme.surfaceVariant),
                if (detail.location.trim().isNotEmpty) _Pill(icon: Icons.place_outlined, label: detail.location, tone: scheme.surfaceVariant),
                _StatusPill(status: detail.status, rmsStatus: detail.rmsStatus, instructorApprovedAt: detail.instructorApprovedAt),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return 'Date: TBD';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}

class TrainingSheetTimeHoursCard extends StatelessWidget {
  const TrainingSheetTimeHoursCard({super.key, required this.detail, required this.onEditTimes});
  final DepartmentClassDetail detail;
  final VoidCallback onEditTimes;

  @override
  Widget build(BuildContext context) {
    final start = detail.startsAt?.toLocal();
    final end = detail.endsAt?.toLocal();
    final elapsed = (start == null) ? null : TrainingTimeCalculator.elapsedMinutes(start, end);
    final split = (elapsed == null || start == null || end == null)
        ? null
        : TrainingTimeCalculator.splitDayNight(startLocal: start, endLocal: end, definition: TrainingTimeCalculator.defaultDayNight);

    return Card(
      child: Padding(
        padding: AppCardTokens.padding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.schedule_rounded, color: FireOpsFeatureColors.training),
            const SizedBox(width: 8),
            Expanded(child: Text('Time & Hours', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
            TextButton.icon(
              onPressed: onEditTimes,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
          ]),
          const SizedBox(height: 10),
          _KeyValueRow(icon: Icons.play_arrow_rounded, label: 'Start', value: start == null ? '—' : _formatTime(start)),
          const SizedBox(height: 8),
          _KeyValueRow(icon: Icons.stop_rounded, label: 'End', value: end == null ? 'Pending' : _formatTime(end), valueTone: end == null ? FireOpsSemanticColors.amber : FireOpsSemanticColors.green),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppCardTokens.radius),
              color: FireOpsFeatureColors.training.withValues(alpha: 0.10),
              border: Border.all(color: FireOpsFeatureColors.training.withValues(alpha: AppCardTokens.subtleBorderAlpha)),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              _KeyValueRow(icon: Icons.timer_outlined, label: 'Total', value: elapsed == null ? 'Pending' : formatMinutesAsHoursMinutes(elapsed), valueStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              if (split != null) ...[
                const SizedBox(height: 8),
                _KeyValueRow(icon: Icons.wb_sunny_outlined, label: 'Day', value: formatMinutesAsHoursMinutes(split.dayMinutes), valueTone: FireOpsSemanticColors.green),
                const SizedBox(height: 6),
                _KeyValueRow(icon: Icons.nights_stay_outlined, label: 'Night', value: formatMinutesAsHoursMinutes(split.nightMinutes), valueTone: FireOpsSemanticColors.blue),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: Text(TrainingTimeCalculator.defaultDayNight.label, style: Theme.of(context).textTheme.bodySmall)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  static String _formatTime(DateTime local) {
    final h = local.hour;
    final use12 = true; // Visual formatting only; actual picker uses system setting.
    if (!use12) {
      final hh = h.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final period = h >= 12 ? 'PM' : 'AM';
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hour:$mm $period';
  }
}

class TrainingSheetNextActionCard extends StatelessWidget {
  const TrainingSheetNextActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primaryAction,
    required this.primaryLabel,
    required this.primaryIcon,
    this.secondaryActions = const <Widget>[],
    required this.statusTone,
  });

  final String title;
  final String subtitle;
  final VoidCallback? primaryAction;
  final String primaryLabel;
  final IconData primaryIcon;
  final List<Widget> secondaryActions;
  final Color statusTone;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppCardTokens.padding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: statusTone, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4)),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: primaryAction, icon: Icon(primaryIcon), label: Text(primaryLabel)),
          if (secondaryActions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: secondaryActions),
          ],
        ]),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.icon, required this.label, required this.value, this.valueTone, this.valueStyle});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueTone;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
    const SizedBox(width: 8),
    Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
    Text(value, style: valueStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, color: valueTone)),
  ]);
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.tone});
  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: tone,
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    ]),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.rmsStatus, required this.instructorApprovedAt});
  final String status;
  final String rmsStatus;
  final DateTime? instructorApprovedAt;

  @override
  Widget build(BuildContext context) {
    final tone = status == 'COMPLETE'
        ? (instructorApprovedAt != null ? FireOpsSemanticColors.green : FireOpsSemanticColors.amber)
        : FireOpsSemanticColors.blue;
    final label = status == 'COMPLETE'
        ? (instructorApprovedAt != null
            ? (rmsStatus == 'RMS_ENTERED' ? 'RMS Entered' : 'Approved')
            : 'Needs approval')
        : 'In progress';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tone.withValues(alpha: 0.14),
        border: Border.all(color: tone.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified_rounded, size: 16, color: tone),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800, color: tone)),
      ]),
    );
  }
}
