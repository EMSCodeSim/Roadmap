import 'package:flutter/material.dart';

import 'package:firepath/pages/department/my_department_page.dart';
import 'package:firepath/pages/task_book/task_book_page.dart';
import 'package:firepath/services/task_book_focus_store.dart';

/// Entry page for the Task Book tab.
///
/// Users can choose whether the Task Book tab prioritizes their private
/// Personal Task Books or official Department Task Books. The choice is stored
/// locally on the device and becomes the default the next time this tab opens.
class TaskBookEntryPage extends StatefulWidget {
  const TaskBookEntryPage({super.key});

  @override
  State<TaskBookEntryPage> createState() => _TaskBookEntryPageState();
}

class _TaskBookEntryPageState extends State<TaskBookEntryPage> {
  final TaskBookFocusStore _focusStore = TaskBookFocusStore();

  TaskBookFocus _focus = TaskBookFocus.personal;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFocus();
  }

  Future<void> _loadFocus() async {
    final focus = await _focusStore.load();
    if (!mounted) return;
    setState(() {
      _focus = focus;
      _loading = false;
    });
  }

  Future<void> _setFocus(TaskBookFocus focus) async {
    if (_focus == focus) return;
    setState(() => _focus = focus);
    await _focusStore.save(focus);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _focus == TaskBookFocus.department
              ? const MyDepartmentPage()
              : const TaskBookPage(),
        ),
        _TaskBookFocusBar(
          focus: _focus,
          onChanged: _setFocus,
        ),
      ],
    );
  }
}

class _TaskBookFocusBar extends StatelessWidget {
  const _TaskBookFocusBar({
    required this.focus,
    required this.onChanged,
  });

  final TaskBookFocus focus;
  final ValueChanged<TaskBookFocus> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surface,
      elevation: 6,
      shadowColor: Colors.black26,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 9),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: .7)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                'TASK BOOK FOCUS · REMEMBERED ON THIS DEVICE',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .35,
                    ),
              ),
            ),
            SegmentedButton<TaskBookFocus>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<TaskBookFocus>(
                  value: TaskBookFocus.personal,
                  icon: Icon(Icons.person_outline_rounded),
                  label: Text('Personal'),
                ),
                ButtonSegment<TaskBookFocus>(
                  value: TaskBookFocus.department,
                  icon: Icon(Icons.apartment_rounded),
                  label: Text('Department'),
                ),
              ],
              selected: {focus},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) onChanged(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}
