import 'package:firepath/models/roadmap_models.dart';

/// Backward-compatible hierarchy for Task Book checklist items.
///
/// RequirementPlanStep is the parent checklist level. RequirementSubTask is
/// the deeper checklist level. To avoid a storage migration, the parent step
/// id is stored in a small metadata prefix inside the subtask notes field.
/// User-visible notes are returned without the prefix.
class TaskBookChecklistHierarchy {
  TaskBookChecklistHierarchy._();

  static const String _prefix = '@parent:';

  static String? parentStepId(RequirementSubTask item) {
    final notes = item.notes ?? '';
    if (!notes.startsWith(_prefix)) return null;
    final end = notes.indexOf('\n');
    final raw = end < 0
        ? notes.substring(_prefix.length)
        : notes.substring(_prefix.length, end);
    final id = raw.trim();
    return id.isEmpty ? null : id;
  }

  static String? visibleNotes(RequirementSubTask item) {
    final notes = item.notes ?? '';
    if (!notes.startsWith(_prefix)) {
      final clean = notes.trim();
      return clean.isEmpty ? null : clean;
    }
    final end = notes.indexOf('\n');
    if (end < 0) return null;
    final clean = notes.substring(end + 1).trim();
    return clean.isEmpty ? null : clean;
  }

  static RequirementSubTask attachToStep(
    RequirementSubTask item,
    String stepId, {
    String? visibleNotes,
  }) {
    final cleanStep = stepId.trim();
    final cleanNotes = visibleNotes?.trim();
    final encoded = cleanNotes == null || cleanNotes.isEmpty
        ? '$_prefix$cleanStep'
        : '$_prefix$cleanStep\n$cleanNotes';
    return item.copyWith(notes: encoded);
  }

  static List<RequirementSubTask> childrenFor(
    String stepId,
    Iterable<RequirementSubTask> items,
  ) => items.where((item) => parentStepId(item) == stepId).toList();

  static List<RequirementSubTask> unassigned(
    Iterable<RequirementSubTask> items,
  ) => items.where((item) => parentStepId(item) == null).toList();

  static bool stepCompleteFromChildren(
    String stepId,
    Iterable<RequirementSubTask> items,
  ) {
    final children = childrenFor(stepId, items);
    return children.isNotEmpty && children.every((item) => item.isDone);
  }
}
