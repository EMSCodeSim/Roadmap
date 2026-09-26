import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:firepath/services/responder_roadmap_api.dart';

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

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Join this class roster?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(preview.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (preview.location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(preview.location),
              ],
              const SizedBox(height: 14),
              const Text('Responder information', style: TextStyle(fontWeight: FontWeight.w800)),
              Text(session.name),
              Text(session.email),
              if ((session.departmentName ?? '').isNotEmpty) Text(session.departmentName!),
              const SizedBox(height: 12),
              const Text(
                'Your signed-in department profile will be used. An instructor must still confirm attendance and any skill results.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: preview.open ? () => Navigator.pop(context, true) : null,
              child: Text(preview.open ? 'Join roster' : 'Registration closed'),
            ),
          ],
        ),
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
            ? 'You are already on the ' + result.title + ' roster.'
            : 'You are registered for ' + result.title + '.';
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Scan Class QR')),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(controller: _controller, onDetect: _onDetect),
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(20),
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
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Done'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
