import 'package:flutter_test/flutter_test.dart';

import 'package:firepath/models/roadmap_models.dart';
import 'package:firepath/services/task_book_checklist_hierarchy.dart';

void main() {
  RequirementSubTask item(String id, {bool done = false}) => RequirementSubTask(
        id: id,
        title: id,
        isDone: done,
        notes: null,
      );

  test('attaches deeper checklist item to parent without exposing metadata', () {
    final attached = TaskBookChecklistHierarchy.attachToStep(
      item('child-1'),
      'pump-ops',
      visibleNotes: 'Evaluator initials required',
    );

    expect(TaskBookChecklistHierarchy.parentStepId(attached), 'pump-ops');
    expect(
      TaskBookChecklistHierarchy.visibleNotes(attached),
      'Evaluator initials required',
    );
  });

  test('groups substeps under the correct checklist item', () {
    final a = TaskBookChecklistHierarchy.attachToStep(item('a'), 'parent-a');
    final b = TaskBookChecklistHierarchy.attachToStep(item('b'), 'parent-b');
    final c = TaskBookChecklistHierarchy.attachToStep(item('c'), 'parent-a');

    expect(
      TaskBookChecklistHierarchy.childrenFor('parent-a', [a, b, c])
          .map((e) => e.id),
      ['a', 'c'],
    );
  });

  test('parent is complete only when it has children and every child is done', () {
    final a = TaskBookChecklistHierarchy.attachToStep(
      item('a', done: true),
      'parent',
    );
    final b = TaskBookChecklistHierarchy.attachToStep(
      item('b', done: true),
      'parent',
    );
    final incomplete = TaskBookChecklistHierarchy.attachToStep(
      item('c'),
      'parent',
    );

    expect(
      TaskBookChecklistHierarchy.stepCompleteFromChildren('parent', [a, b]),
      isTrue,
    );
    expect(
      TaskBookChecklistHierarchy.stepCompleteFromChildren(
        'parent',
        [a, incomplete],
      ),
      isFalse,
    );
    expect(
      TaskBookChecklistHierarchy.stepCompleteFromChildren('missing', [a, b]),
      isFalse,
    );
  });
}
