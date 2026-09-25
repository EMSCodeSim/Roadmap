import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:firepath/services/responder_roadmap_api.dart';

String? parseMemberQrToken(String raw) {
  final value = raw.trim();
  if (value.startsWith('rrmember:')) {
    final token = value.substring('rrmember:'.length);
    return RegExp(r'^[a-f0-9]{64}$').hasMatch(token) ? token : null;
  }
  return RegExp(r'^[a-f0-9]{64}$').hasMatch(value) ? value : null;
}

String? parseClassRegistrationToken(String raw) {
  final value = raw.trim();
  if (RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) return value;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.pathSegments.isEmpty) return null;
  final token = uri.pathSegments.last;
  return RegExp(r'^[a-f0-9]{64}$').hasMatch(token) ? token : null;
}

Future<String?> scanDepartmentQr(BuildContext context, {required String title}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => _QrScannerPage(title: title)),
  );
}

class MemberQrDialog extends StatefulWidget {
  const MemberQrDialog({super.key, required this.api});
  final ResponderRoadmapApi api;

  @override
  State<MemberQrDialog> createState() => _MemberQrDialogState();
}

class _MemberQrDialogState extends State<MemberQrDialog> {
  DepartmentMemberQr? _qr;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final qr = await widget.api.createMemberQr();
      if (mounted) setState(() => _qr = qr);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qr = _qr;
    return AlertDialog(
      title: const Text('My Department QR'),
      content: SizedBox(
        width: 300,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
                ? Text(_error!)
                : qr == null
                    ? const Text('QR unavailable.')
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          QrImageView(data: 'rrmember:${qr.token}', size: 230),
                          const SizedBox(height: 12),
                          Text(qr.member.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          if ((qr.member.rank ?? '').isNotEmpty) Text(qr.member.rank!),
                          const SizedBox(height: 8),
                          Text(
                            'Short-lived department identity code. It contains no name, email, or member number.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
      ),
      actions: [
        if (!_loading)
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('New Code'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage({required this.title});
  final String title;

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue?.trim();
                if (raw == null || raw.isEmpty) continue;
                _handled = true;
                Navigator.of(context).pop(raw);
                return;
              }
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
