import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/department/department_task_book_page.dart';
import 'package:firepath/pages/department/department_inbox_page.dart';
import 'package:firepath/pages/department/department_classes_page.dart';
import 'package:firepath/services/department_link_store.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/state/app_mode_controller.dart';
import 'package:firepath/state/department_inbox_controller.dart';
import 'package:firepath/widgets/app_mode_switcher.dart';

class MyDepartmentPage extends StatefulWidget {
  final bool taskBooksOnly;

  const MyDepartmentPage({super.key, this.taskBooksOnly = false});

  @override
  State<MyDepartmentPage> createState() => _MyDepartmentPageState();
}

class _MyDepartmentPageState extends State<MyDepartmentPage> {
  final DepartmentLinkStore _store = DepartmentLinkStore();
  final ResponderRoadmapApi _api = ResponderRoadmapApi();
  final GlobalKey _taskBooksSectionKey = GlobalKey();
  final GlobalKey _assignmentsSectionKey = GlobalKey();

  DepartmentLink? _link;
  List<DepartmentTaskBookAssignment> _assignments = const [];
  bool _loading = true;
  bool _syncing = false;
  String? _loadError;
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _link != null && !_syncing) {
        _sync(showErrors: false);
      }
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    DepartmentLink? stored;
    try {
      stored = await _store.load();
      if (await _api.hasStoredToken) {
        final session = await _api.currentSession();
        if (session.hasDepartment) {
          stored = DepartmentLink.fromSession(session);
          await _store.save(stored);
          if (!mounted) return;
          await context.read<AppModeController>().setDepartmentLink(stored);
          final assignments = await _api.listAssignments();
          if (!mounted) return;
          setState(() {
            _link = stored;
            _assignments = assignments;
            _loading = false;
            _loadError = null;
          });
          return;
        }
      }
      if (stored != null) await _store.clear();
    } on ResponderRoadmapApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _store.clear();
        await _api.disconnect();
        stored = null;
      } else {
        _loadError = e.message;
      }
    } catch (e) {
      _loadError = 'Could not load the department connection.';
    }
    if (!mounted) return;
    setState(() {
      _link = stored;
      _loading = false;
    });
  }

  Future<void> _connect() async {
    final credentials = await _showLoginSheet();
    if (credentials == null) return;
    setState(() => _syncing = true);
    try {
      var session = await _api.login(
        email: credentials.email,
        password: credentials.password,
      );

      if (!session.hasDepartment) {
        final joinCode = await _showJoinCodeSheet();
        if (joinCode == null || joinCode.trim().isEmpty) {
          await _api.disconnect();
          return;
        }
        final joined = await _api.joinDepartment(joinCode);
        if (!joined.isActive) {
          await _api.disconnect();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${joined.departmentName} requires approval. Your request was sent. Sign in again after a department administrator approves you.',
              ),
              duration: const Duration(seconds: 7),
            ),
          );
          return;
        }
        // The initial app token was issued before department membership existed.
        // Log in one more time to receive fresh department/membership claims.
        session = await _api.login(
          email: credentials.email,
          password: credentials.password,
        );
      }

      if (!session.hasDepartment) {
        throw const ResponderRoadmapApiException(
          'Your account does not have an active department membership yet.',
        );
      }

      final link = DepartmentLink.fromSession(session);
      await _store.save(link);
      await context.read<AppModeController>().setDepartmentLink(link);
      final assignments = await _api.listAssignments();
      await context.read<DepartmentInboxController>().refresh(silent: true);
      if (!mounted) return;
      setState(() {
        _link = link;
        _assignments = assignments;
        _loadError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${link.departmentName}.')),
      );
    } on ResponderRoadmapApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), duration: const Duration(seconds: 6)),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _createDepartmentAccount() async {
    final code = await _showJoinCodeSheet();
    if (code == null || code.trim().isEmpty) return;
    setState(() => _syncing = true);
    try {
      final department = await _api.validateDepartmentCode(code);
      if (!mounted) return;
      setState(() => _syncing = false);
      final registration = await _showRegistrationSheet(department);
      if (registration == null) return;
      setState(() => _syncing = true);
      final result = await _api.registerWithDepartmentCode(
        joinCode: department.joinCode,
        name: registration.name,
        email: registration.email,
        password: registration.password,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.hourglass_top_rounded),
          title: const Text('Account created'),
          content: Text(
            'Your request to join ${result.departmentName} was sent. A Training Officer must approve it before you can sign in to department mode.',
          ),
          actions: [FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done'))],
        ),
      );
    } on ResponderRoadmapApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), duration: const Duration(seconds: 7)));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _sync({bool showErrors = true}) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      final session = await _api.currentSession();
      if (!session.hasDepartment) {
        throw const ResponderRoadmapApiException(
          'Your ResponderRoadmap account is not connected to an active department.',
        );
      }
      final link = DepartmentLink.fromSession(session);
      final assignments = await _api.listAssignments();
      await _store.save(link);
      await context.read<AppModeController>().setDepartmentLink(link);
      await context.read<DepartmentInboxController>().refresh(silent: true);
      if (!mounted) return;
      setState(() {
        _link = link;
        _assignments = assignments;
        _loadError = null;
      });
    } on ResponderRoadmapApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401 || e.statusCode == 403) {
        await _api.disconnect();
        await _store.clear();
        await context.read<AppModeController>().setDepartmentLink(null);
        setState(() {
          _link = null;
          _assignments = const [];
        });
      }
      if (showErrors) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out of department?'),
        content: const Text(
          'This removes the department login from this device. Your personal roadmap stays on this device, and official department records remain safely stored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _api.disconnect();
    await _store.clear();
    await context.read<AppModeController>().setDepartmentLink(null);
    if (!mounted) return;
    setState(() {
      _link = null;
      _assignments = const [];
    });
  }

  Future<_Credentials?> _showLoginSheet() async {
    final email = TextEditingController();
    final password = TextEditingController();
    var obscure = true;
    final result = await showModalBottomSheet<_Credentials>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final viewInsets = MediaQuery.viewInsetsOf(context);
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 20 + viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sign in to your department',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use the email and password from your Responder Roadmap department account.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () => setSheetState(() => obscure = !obscure),
                        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    onSubmitted: (_) {
                      if (email.text.trim().isNotEmpty && password.text.isNotEmpty) {
                        Navigator.of(context).pop(
                          _Credentials(email: email.text.trim(), password: password.text),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (email.text.trim().isEmpty || password.text.isEmpty) return;
                        Navigator.of(context).pop(
                          _Credentials(email: email.text.trim(), password: password.text),
                        );
                      },
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Sign In'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    email.dispose();
    password.dispose();
    return result;
  }

  Future<String?> _showJoinCodeSheet() async {
    final code = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final viewInsets = MediaQuery.viewInsetsOf(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 6, 16, 20 + viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Join your department',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter the private ResponderRoadmap code provided by your department. Every join-code request requires Training Officer approval.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: code,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Department join code',
                  hintText: 'ABC-1234',
                ),
                onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(code.text.trim()),
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Check Department Code'),
                ),
              ),
            ],
          ),
        );
      },
    );
    code.dispose();
    return result;
  }

  Future<_RegistrationCredentials?> _showRegistrationSheet(DepartmentCodeValidation department) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final confirmPassword = TextEditingController();
    var obscure = true;
    String? validationError;
    final result = await showModalBottomSheet<_RegistrationCredentials>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final viewInsets = MediaQuery.viewInsetsOf(context);
          void submit() {
            if (name.text.trim().isEmpty || email.text.trim().isEmpty || password.text.length < 8) {
              setSheetState(() => validationError = 'Enter your name, email, and a password of at least 8 characters.');
              return;
            }
            if (password.text != confirmPassword.text) {
              setSheetState(() => validationError = 'The passwords do not match.');
              return;
            }
            Navigator.of(context).pop(_RegistrationCredentials(
              name: name.text.trim(),
              email: email.text.trim(),
              password: password.text,
            ));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 20 + viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Code accepted', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(department.departmentName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('Create your account. Department access begins only after a Training Officer approves your request.'),
                if (validationError != null) ...[
                  const SizedBox(height: 12),
                  Text(validationError!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 16),
                TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name'), textInputAction: TextInputAction.next),
                const SizedBox(height: 12),
                TextField(controller: email, keyboardType: TextInputType.emailAddress, autocorrect: false, decoration: const InputDecoration(labelText: 'Email'), textInputAction: TextInputAction.next),
                const SizedBox(height: 12),
                TextField(controller: password, obscureText: obscure, autocorrect: false, enableSuggestions: false, decoration: InputDecoration(labelText: 'Password (8+ characters)', suffixIcon: IconButton(onPressed: () => setSheetState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))), textInputAction: TextInputAction.next),
                const SizedBox(height: 12),
                TextField(controller: confirmPassword, obscureText: obscure, autocorrect: false, enableSuggestions: false, decoration: const InputDecoration(labelText: 'Confirm password'), onSubmitted: (_) => submit()),
                const SizedBox(height: 18),
                SizedBox(height: 54, child: FilledButton.icon(onPressed: submit, icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Create Account and Request Approval'))),
              ],
            ),
          );
        },
      ),
    );
    name.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    return result;
  }

  Future<void> _openAssignment(DepartmentTaskBookAssignment assignment) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DepartmentTaskBookPage(assignment: assignment),
      ),
    );
    await _sync();
  }

  Future<void> _openInbox() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DepartmentInboxPage()),
    );
    if (mounted) {
      await context.read<DepartmentInboxController>().refresh(silent: true);
    }
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final inbox = context.watch<DepartmentInboxController>();
    final taskBooks = _assignments
        .where((assignment) => !assignment.isSingleTask)
        .toList(growable: false);
    final trainingAssignments = _assignments
        .where((assignment) => assignment.isSingleTask)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.taskBooksOnly ? 'Department Task Books' : 'Department',
        ),
        actions: [
          if (_link != null)
            IconButton(
              tooltip: 'Sync department records',
              onPressed: _syncing ? null : _sync,
              icon: _syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _link == null ? () async {} : _sync,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  children: [
                    if (!widget.taskBooksOnly) ...[
                      const AppModeSwitcher(),
                      const SizedBox(height: 16),
                    ],
                    if (_link == null) ...[
                      _ConnectCard(
                        busy: _syncing,
                        error: _loadError,
                        onConnect: _connect,
                        onCreateAccount: _createDepartmentAccount,
                      ),
                      const SizedBox(height: 12),
                      const _DepartmentSetupGuide(),
                    ] else ...[
                      if (widget.taskBooksOnly)
                        _SyncStatusCard(controller: inbox)
                      else
                        _DepartmentConnectionCard(
                          link: _link!,
                          controller: inbox,
                          syncing: _syncing,
                          onSync: _sync,
                          onSignOut: _disconnect,
                        ),
                      if (!widget.taskBooksOnly) ...[
                        const SizedBox(height: 12),
                        _DepartmentOverview(
                          taskBookCount: taskBooks.length,
                          assignmentCount: trainingAssignments.length,
                          unreadCount: inbox.unreadCount,
                          actionCount: inbox.actionCount,
                          // Even when counts are 0, these tiles should still take
                          // members straight to the relevant section.
                          onTaskBooks: () => _scrollTo(_taskBooksSectionKey),
                          onAssignments: () => _scrollTo(_assignmentsSectionKey),
                          onMessages: _openInbox,
                          onNeedsAction: _openInbox,
                        ),
                        const SizedBox(height: 12),
                        _DepartmentNextAction(
                          assignments: _assignments,
                          unreadCount: inbox.unreadCount,
                          actionCount: inbox.actionCount,
                          onOpenInbox: _openInbox,
                          onOpenAssignment: _openAssignment,
                        ),
                        if (const ['EVALUATOR', 'TRAINING_OFFICER', 'DEPARTMENT_ADMINISTRATOR'].contains(_link!.role)) ...[
                          const SizedBox(height: 12),
                          Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: const Icon(Icons.fact_check_outlined),
                              title: const Text('Proctor class rosters', style: TextStyle(fontWeight: FontWeight.w800)),
                              subtitle: const Text('Check off skills for students assigned to your testing station.'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DepartmentClassesPage())),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 20),
                      _DepartmentAssignmentSection(
                        key: _taskBooksSectionKey,
                        title: 'Task Books',
                        description:
                            'Department-issued task books and approved progress.',
                        emptyMessage:
                            'No department Task Books are assigned to you yet.',
                        assignments: taskBooks,
                        onOpen: _openAssignment,
                      ),
                      if (!widget.taskBooksOnly) ...[
                        const SizedBox(height: 18),
                        _DepartmentAssignmentSection(
                          key: _assignmentsSectionKey,
                          title: 'Training Assignments',
                          description:
                              'Single tasks from your Training Captain that do not require a full Task Book.',
                          emptyMessage:
                              'No single training assignments are waiting for you.',
                          assignments: trainingAssignments,
                          onOpen: _openAssignment,
                        ),
                      ],
                      if (!widget.taskBooksOnly) ...[
                        const SizedBox(height: 14),
                        _PrivacyBoundaryCard(),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _DepartmentConnectionCard extends StatelessWidget {
  const _DepartmentConnectionCard({
    required this.link,
    required this.controller,
    required this.syncing,
    required this.onSync,
    required this.onSignOut,
  });

  final DepartmentLink link;
  final DepartmentInboxController controller;
  final bool syncing;
  final VoidCallback onSync;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final memberLabel = link.rank?.trim().isNotEmpty == true
        ? '${link.userName} · ${link.rank}'
        : link.userName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.primary.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.apartment_rounded, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected to ${link.departmentName}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900, height: 1.1),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      memberLabel,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${_humanize(link.role)} · ${link.email}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Same account',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Assignments, evaluation requests, returned work, approvals, and receipts here are the same official records your Training Captain sees on the department dashboard.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 12),
          _SyncStatusCard(controller: controller),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton.icon(
                onPressed: syncing ? null : onSync,
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: Text(syncing ? 'Refreshing…' : 'Refresh now'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepartmentNextAction extends StatelessWidget {
  const _DepartmentNextAction({
    required this.assignments,
    required this.unreadCount,
    required this.actionCount,
    required this.onOpenInbox,
    required this.onOpenAssignment,
  });

  final List<DepartmentTaskBookAssignment> assignments;
  final int unreadCount;
  final int actionCount;
  final VoidCallback onOpenInbox;
  final Future<void> Function(DepartmentTaskBookAssignment assignment)
      onOpenAssignment;

  @override
  Widget build(BuildContext context) {
    DepartmentTaskBookAssignment? next;
    for (final assignment in assignments) {
      if (assignment.status != 'COMPLETE' && assignment.progress < 100) {
        next = assignment;
        break;
      }
    }

    late final IconData icon;
    late final String title;
    late final String body;
    late final String actionLabel;
    late final VoidCallback onTap;
    var emphasize = false;

    if (actionCount > 0) {
      icon = Icons.pending_actions_rounded;
      title = actionCount == 1
          ? '1 item needs your action'
          : '$actionCount items need your action';
      body =
          'Open your queue to review a sign-off or correct returned work before it gets delayed.';
      actionLabel = 'Open action queue';
      onTap = onOpenInbox;
      emphasize = true;
    } else if (unreadCount > 0) {
      icon = Icons.mark_email_unread_outlined;
      title = unreadCount == 1
          ? '1 unread department update'
          : '$unreadCount unread department updates';
      body =
          'Read the latest assignment, return, approval, or department message.';
      actionLabel = 'Open inbox';
      onTap = onOpenInbox;
      emphasize = true;
    } else if (next != null) {
      final selected = next;
      icon = selected.isSingleTask
          ? Icons.assignment_outlined
          : Icons.menu_book_outlined;
      title = 'Continue ${selected.taskBookTitle}';
      body = selected.pendingApproval > 0
          ? '${selected.pendingApproval} requirement(s) are waiting for evaluation. You can still review the submission receipt and remaining work.'
          : '${selected.complete} of ${selected.totalRequired} requirements are approved. Open it to see the next required step.';
      actionLabel = selected.pendingApproval > 0
          ? 'View status'
          : 'Continue work';
      onTap = () {
        onOpenAssignment(selected);
      };
    } else {
      icon = Icons.task_alt_rounded;
      title = 'You are caught up';
      body =
          'There is no department action waiting right now. Pull down or tap Refresh now for the latest records.';
      actionLabel = 'Open inbox';
      onTap = onOpenInbox;
    }

    final cs = Theme.of(context).colorScheme;
    return Card(
      color: emphasize
          ? cs.tertiaryContainer.withValues(alpha: .55)
          : cs.surfaceContainerHighest.withValues(alpha: .32),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: emphasize ? cs.tertiary : cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT DEPARTMENT ACTION',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: Text(actionLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  final DepartmentInboxController controller;
  const _SyncStatusCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final waiting = controller.syncState == DepartmentSyncState.waitingToUpload;
    final failed = controller.syncState == DepartmentSyncState.failed;
    final syncing = controller.syncState == DepartmentSyncState.syncing;
    final label = waiting ? 'Waiting to upload' : failed ? 'Sync failed' : syncing ? 'Syncing' : 'Synced';
    final icon = waiting ? Icons.cloud_upload_outlined : failed ? Icons.sync_problem_rounded : syncing ? Icons.sync_rounded : Icons.cloud_done_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: (waiting || failed ? cs.errorContainer : cs.primaryContainer).withValues(alpha: .45),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(children: [
        Icon(icon, size: 20),
        const SizedBox(width: 9),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900))),
        if (controller.lastSyncedAt != null) Text(_syncTime(controller.lastSyncedAt!), style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class _DepartmentOverview extends StatelessWidget {
  const _DepartmentOverview({
    required this.taskBookCount,
    required this.assignmentCount,
    required this.unreadCount,
    required this.actionCount,
    required this.onTaskBooks,
    required this.onAssignments,
    required this.onMessages,
    required this.onNeedsAction,
  });

  final int taskBookCount;
  final int assignmentCount;
  final int unreadCount;
  final int actionCount;
  final VoidCallback onTaskBooks;
  final VoidCallback onAssignments;
  final VoidCallback onMessages;
  final VoidCallback onNeedsAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Department overview',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DepartmentOverviewTile(
                icon: Icons.menu_book_outlined,
                value: taskBookCount,
                label: 'Task Books',
                onTap: onTaskBooks,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DepartmentOverviewTile(
                icon: Icons.assignment_outlined,
                value: assignmentCount,
                label: 'Assignments',
                onTap: onAssignments,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DepartmentOverviewTile(
                icon: Icons.notifications_outlined,
                value: unreadCount,
                label: 'Unread messages',
                emphasize: unreadCount > 0,
                onTap: onMessages,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DepartmentOverviewTile(
                icon: Icons.pending_actions_outlined,
                value: actionCount,
                label: 'Needs my action',
                emphasize: actionCount > 0,
                onTap: onNeedsAction,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DepartmentOverviewTile extends StatelessWidget {
  const _DepartmentOverviewTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    this.emphasize = false,
  });

  final IconData icon;
  final int value;
  final String label;
  final VoidCallback onTap;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: emphasize
          ? cs.tertiaryContainer.withValues(alpha: .65)
          : cs.surfaceContainerHighest.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 98),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 21),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$value',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DepartmentAssignmentSection extends StatelessWidget {
  const _DepartmentAssignmentSection({
    super.key,
    required this.title,
    required this.description,
    required this.emptyMessage,
    required this.assignments,
    required this.onOpen,
  });

  final String title;
  final String description;
  final String emptyMessage;
  final List<DepartmentTaskBookAssignment> assignments;
  final Future<void> Function(DepartmentTaskBookAssignment assignment) onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '${assignments.length}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 10),
        if (assignments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: .35),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(emptyMessage),
          )
        else
          ...assignments.map(
            (assignment) => _AssignmentCard(
              assignment: assignment,
              onTap: () => onOpen(assignment),
            ),
          ),
      ],
    );
  }
}

String _syncTime(DateTime value) {
  final local = value.toLocal();
  return '${local.month}/${local.day} ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
}

class _ConnectCard extends StatelessWidget {
  final bool busy;
  final String? error;
  final VoidCallback onConnect;
  final VoidCallback onCreateAccount;

  const _ConnectCard({
    required this.busy,
    required this.error,
    required this.onConnect,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.primary.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your department workspace',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to receive Task Books and training assignments, read department messages, and send completed work to an approved evaluator.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: .6),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline_rounded, size: 20),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Your personal Career Road, Quick Log, career history, and private notes stay on this device. They are not uploaded to your department automatically.',
                  ),
                ),
              ],
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: TextStyle(color: cs.error, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: busy ? null : onConnect,
              icon: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.link_rounded),
              label: Text(busy ? 'Signing in…' : 'Sign in to department'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onCreateAccount,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Create account with department code'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentSetupGuide extends StatelessWidget {
  const _DepartmentSetupGuide();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How department access works',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const _SetupStep(
              number: '1',
              title: 'Your department enrolls',
              detail:
                  'A Training Captain or administrator creates the department dashboard at responderroadmap.com and receives its join code.',
            ),
            const _SetupStep(
              number: '2',
              title: 'You receive access',
              detail:
                  'Enter the private join code. After it is accepted, create your account in the app or website.',
            ),
            const _SetupStep(
              number: '3',
              title: 'Training Officer approval',
              detail:
                  'Every join-code account remains pending until a Training Officer approves it. Then sign in to receive assignments.',
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Text(
                'Need access? Ask your Training Captain or department administrator for an invitation or join code.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.title,
    required this.detail,
  });

  final String number;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: cs.primaryContainer,
            child: Text(
              number,
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyBoundaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Connected does not mean shared. Department Task Book submissions and only the certifications you choose to share from the Certs tab are written to ResponderRoadmap. Other personal career records remain separate.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final DepartmentTaskBookAssignment assignment;
  final VoidCallback onTap;

  const _AssignmentCard({required this.assignment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      assignment.taskBookTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: .7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      assignment.isSingleTask ? 'Single assignment' : 'Task Book',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${assignment.progress}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                assignment.isSingleTask
                    ? _humanize(assignment.status)
                    : '${_humanize(assignment.status)} · Version ${assignment.version}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (assignment.progress / 100)
                    .clamp(0.0, 1.0)
                    .toDouble(),
                minHeight: 7,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${assignment.complete}/${assignment.totalRequired} approved',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (assignment.pendingApproval > 0)
                    Text(
                      '${assignment.pendingApproval} awaiting review',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.tertiary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Credentials {
  final String email;
  final String password;

  const _Credentials({required this.email, required this.password});
}

class _RegistrationCredentials {
  final String name;
  final String email;
  final String password;

  const _RegistrationCredentials({required this.name, required this.email, required this.password});
}

String _humanize(String value) {
  return value
      .toLowerCase()
      .split('_')
      .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
