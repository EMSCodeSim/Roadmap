import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firepath/pages/department/department_task_book_page.dart';
import 'package:firepath/services/department_link_store.dart';
import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/state/app_mode_controller.dart';
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

  DepartmentLink? _link;
  List<DepartmentTaskBookAssignment> _assignments = const [];
  bool _loading = true;
  bool _syncing = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _sync() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect department?'),
        content: const Text(
          'This removes the department login from this device. Your personal Career Road stays on this device and department records remain in ResponderRoadmap.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disconnect'),
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
                    'Connect ResponderRoadmap',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use the same account your department uses on responderroadmap.com.',
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
                      label: const Text('Connect Account'),
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
                'Your department can give you its ResponderRoadmap join code. Some departments require an administrator to approve the request.',
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
                  icon: const Icon(Icons.group_add_rounded),
                  label: const Text('Request to Join'),
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

  Future<void> _openAssignment(DepartmentTaskBookAssignment assignment) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DepartmentTaskBookPage(assignment: assignment),
      ),
    );
    await _sync();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskBooksOnly ? 'Department Task Books' : 'My Department'),
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
                      ),
                    ] else ...[
                      if (!widget.taskBooksOnly) Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: .55),
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(color: cs.primary.withValues(alpha: .14)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.apartment_rounded, color: cs.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _link!.departmentName,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                                const Icon(Icons.verified_rounded),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _link!.rank?.trim().isNotEmpty == true
                                  ? '${_link!.userName} · ${_link!.rank}'
                                  : _link!.userName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _link!.email,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _disconnect,
                                icon: const Icon(Icons.link_off_rounded),
                                label: const Text('Disconnect Department'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.taskBooksOnly) ...[
                        const SizedBox(height: 16),
                        _PrivacyBoundaryCard(),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Department Task Books',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Text(
                            '${_assignments.length}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Assignments here are official department records. Submissions go to ResponderRoadmap for evaluator review.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (_assignments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withValues(alpha: .35),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.assignment_outlined),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text('No department Task Books are assigned to you yet.'),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._assignments.map(
                          (assignment) => _AssignmentCard(
                            assignment: assignment,
                            onTap: () => _openAssignment(assignment),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _ConnectCard extends StatelessWidget {
  final bool busy;
  final String? error;
  final VoidCallback onConnect;

  const _ConnectCard({
    required this.busy,
    required this.error,
    required this.onConnect,
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
            'Connect to your department',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in with your ResponderRoadmap account to receive department Task Books and send work to your evaluator.',
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
              label: Text(busy ? 'Connecting…' : 'Connect ResponderRoadmap'),
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
              'Connected does not mean shared. Only department Task Book submissions you intentionally send are written to ResponderRoadmap. Personal career records remain separate.',
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
                  Text(
                    '${assignment.progress}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '${_humanize(assignment.status)} · Version ${assignment.version}',
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

String _humanize(String value) {
  return value
      .toLowerCase()
      .split('_')
      .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
