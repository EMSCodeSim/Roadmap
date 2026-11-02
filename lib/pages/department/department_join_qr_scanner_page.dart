import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans the join link printed by the department Enrollment page.
/// Never joins automatically: the caller validates the code and requests approval.
class DepartmentJoinQrScannerPage extends StatefulWidget {
  const DepartmentJoinQrScannerPage({super.key});

  @override
  State<DepartmentJoinQrScannerPage> createState() => _DepartmentJoinQrScannerPageState();
}

class _DepartmentJoinQrScannerPageState extends State<DepartmentJoinQrScannerPage> {
  final MobileScannerController _scanner = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _handled = false;
  String? _error;

  String? _joinCode(String value) {
    final raw = value.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' ||
        !{'responderroadmap.com', 'www.responderroadmap.com'}.contains(uri.host.toLowerCase()) ||
        uri.path != '/join') return null;
    final codes = uri.queryParametersAll['code'];
    if (codes == null || codes.length != 1) return null;
    final code = codes.single.trim();
    return RegExp(r'^[A-Za-z0-9-]{4,64}$').hasMatch(code) ? code : null;
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled || !mounted) return;
    final values = capture.barcodes.map((barcode) => barcode.rawValue).whereType<String>();
    for (final value in values) {
      final code = _joinCode(value);
      if (code != null) {
        _handled = true;
        Navigator.of(context).pop(code);
        return;
      }
    }
    setState(() => _error = 'Scan a department join QR from Responder Roadmap, not a class roster QR.');
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan department QR')),
    body: SafeArea(child: Column(children: [
      const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Scan the QR code shown on your department Enrollment page. Joining still requires department approval.'),
      ),
      Expanded(child: MobileScanner(controller: _scanner, onDetect: _onDetect)),
      if (_error != null) Padding(
        padding: const EdgeInsets.all(12),
        child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ),
      const Padding(
        padding: EdgeInsets.all(12),
        child: Text('You can also go back and enter the join code manually.'),
      ),
    ])),
  );
}
