import 'package:flutter/material.dart';

import 'package:firepath/services/department_link_store.dart';
import 'package:firepath/theme.dart';

class MyDepartmentPage extends StatefulWidget {
  const MyDepartmentPage({super.key});

  @override
  State<MyDepartmentPage> createState() => _MyDepartmentPageState();
}

class _MyDepartmentPageState extends State<MyDepartmentPage> {
  final DepartmentLinkStore _store = DepartmentLinkStore();

  DepartmentLink? _link;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final link = await _store.load();
      if (!mounted) return;
      setState(() {
        _link = link;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _promptForCode({required bool joinStyle}) async {
    final controller = TextEditingController();
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final viewInsets = MediaQuery.viewInsetsOf(context);
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                joinStyle ? 'Join Department' : 'Enter Department Code',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'For development, try DEMO-01.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Department code',
                  hintText: 'DEMO-01',
                ),
                onSubmitted: (v) => Navigator.of(context).pop(v),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(controller.text),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(joinStyle ? 'Join Department' : 'Continue'),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
    final normalized = (code ?? '').trim().toUpperCase();
    if (normalized.isEmpty) return;

    final resolvedName = _departmentNameForCode(normalized);
    if (resolvedName == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code. Try DEMO-01 for development.')),
      );
      return;
    }

    final link = DepartmentLink(code: normalized, departmentName: resolvedName, linkedAt: DateTime.now());
    await _store.save(link);
    if (!mounted) return;
    setState(() => _link = link);
  }

  String? _departmentNameForCode(String code) {
    if (code == 'DEMO-01') return 'Metro Fire & Rescue';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Department'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                children: [
                  if (_link == null) ...[
                    _ConnectCard(
                      onJoin: () => _promptForCode(joinStyle: true),
                      onEnterCode: () => _promptForCode(joinStyle: false),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: cs.onSurface.withValues(alpha: .08)),
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
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Connected via code ${_link!.code}.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.tonalIcon(
                              onPressed: () async {
                                await _store.clear();
                                if (!mounted) return;
                                setState(() => _link = null);
                              },
                              icon: const Icon(Icons.link_off_rounded),
                              label: const Text('Disconnect'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ConnectCard extends StatelessWidget {
  final VoidCallback onJoin;
  final VoidCallback onEnterCode;

  const _ConnectCard({
    required this.onJoin,
    required this.onEnterCode,
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
            'Connect ResponderRoadmap to your department',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Your career stays yours\nYour personal Career Road and career history remain separate from department-managed assignments.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Join Department'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.tonalIcon(
              onPressed: onEnterCode,
              icon: const Icon(Icons.key_rounded),
              label: const Text('Enter Department Code'),
            ),
          ),
        ],
      ),
    );
  }
}
