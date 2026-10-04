import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

import 'package:firepath/services/responder_roadmap_api.dart';
import 'package:firepath/services/theme.dart';
import 'package:firepath/widgets/firefighter_roadmap_app_bar.dart';
import 'package:firepath/widgets/status_pill.dart';

class DepartmentClassQrScannerPage extends StatefulWidget {
  const DepartmentClassQrScannerPage({super.key});

  @override
  State<DepartmentClassQrScannerPage> createState() => _DepartmentClassQrScannerPageState();
}

class _DepartmentClassQrScannerPageState extends State<DepartmentClassQrScannerPage> {
  final _api = ResponderRoadmapApi();
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);

  ResponderRoadmapSession? _session;
  bool _handling = false;
  bool _registered = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final session = await _api.currentSession();
      if (mounted) setState(() => _session = session);
    } on ResponderRoadmapApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    }
  }

  String? _tokenFromValue(String value) {
    final trimmed = value.trim();
    final direct = RegExp(r'^[a-f0-9]{64}$');
    if (direct.hasMatch(trimmed)) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !{'responderroadmap.com', 'www.responderroadmap.com'}.contains(uri.host.toLowerCase())) {
      return null;
    }
    final segments = uri.pathSegments;
    if (segments.length != 2 ||
        !{'class-join', 'class-register'}.contains(segments.first)) {
      return null;
    }
    return direct.hasMatch(segments.last) ? segments.last : null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling || _registered) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    if (value == null) return;

    final token = _tokenFromValue(value);
    if (token == null) {
      setState(() {
        _handling = true;
        _message = 'That is not a Responder Roadmap class QR code.';
      });
      await _controller.stop();
      return;
    }

    setState(() {
      _handling = true;
      _message = null;
    });
    await _controller.stop();

    try {
      final preview = await _api.previewClassRegistration(token);
      if (!mounted) return;
      final session = _session ?? await _api.currentSession();
      if (!mounted) return;

      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) {
          final cs = Theme.of(sheetContext).colorScheme;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Join class roster', style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: AppCardTokens.padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(preview.title, style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        if (preview.location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(preview.location, style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text('You will be registered as:', style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                Card(
                  child: Padding(
                    padding: AppCardTokens.padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.name, style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        Text(session.email, style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        if ((session.departmentName ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: StatusPill(
                              text: session.departmentName!,
                              icon: Icons.apartment_rounded,
                              maxWidth: double.infinity,
                              backgroundColor: cs.surfaceContainerHighest,
                              foregroundColor: cs.onSurface,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'An instructor still confirms attendance and any evaluation results.',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, height: 1.35),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => sheetContext.pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: preview.open ? () => sheetContext.pop(true) : null,
                        child: Text(preview.open ? 'Join roster' : 'Registration closed'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      if (confirmed != true) {
        await _retry();
        return;
      }

      final result = await _api.registerForClass(token);
      if (!mounted) return;
      setState(() {
        _registered = true;
        _message = result.alreadyRegistered
            ? 'You are already on the ${result.title} roster.'
            : 'You are registered for ${result.title}.';
      });
    } on ResponderRoadmapApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    }
  }

  Future<void> _retry() async {
    if (!mounted) return;
    setState(() {
      _handling = false;
      _registered = false;
      _message = null;
    });
    await _controller.start();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
        appBar: const FirefighterRoadmapAppBar(subtitle: 'Scan Class QR'),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(controller: _controller, onDetect: _onDetect),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          cs.surface.withValues(alpha: 0.00),
                          cs.surface.withValues(alpha: 0.12),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withValues(alpha: 0.92), width: 2.5),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _registered
                          ? (_message ?? 'Registration complete.')
                          : _message ?? 'Point the camera at a Responder Roadmap class QR code.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (_message != null && !_registered) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Scan again'),
                      ),
                    ],
                    if (_registered) ...[
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context.pop(true),
                        child: const Text('Done'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
