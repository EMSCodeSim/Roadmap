import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:firepath/services/responder_roadmap_api.dart';

class DepartmentQrScannerPage extends StatefulWidget {
  const DepartmentQrScannerPage({super.key});

  @override
  State<DepartmentQrScannerPage> createState() => _DepartmentQrScannerPageState();
}

class _DepartmentQrScannerPageState extends State<DepartmentQrScannerPage> {
  final _api = ResponderRoadmapApi();
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _submitting = false;
  String? _error;

  Future<void> _detected(BarcodeCapture capture) async {
    if (_submitting) return;
    String? value;
    for (final barcode in capture.barcodes) {
      final candidate = barcode.rawValue?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        value = candidate;
        break;
      }
    }
    if (value == null) return;
    setState(() { _submitting = true; _error = null; });
    await _controller.stop();
    try {
      await _api.registerCurrentMemberForClassQr(value);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Checked in'),
          content: const Text('Your Responder Roadmap profile was added to the training roster.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on ResponderRoadmapApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _submitting = false; });
      await _controller.start();
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'Unable to check in. Confirm the class QR is open and try again.'; _submitting = false; });
      await _controller.start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan Training QR')),
    body: Column(children: [
      Expanded(
        child: Stack(fit: StackFit.expand, children: [
          MobileScanner(controller: _controller, onDetect: _detected),
          Center(child: Container(width: 250, height: 250, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3), borderRadius: BorderRadius.circular(18)))),
          if (_submitting) const ColoredBox(color: Color(0x66000000), child: Center(child: CircularProgressIndicator())),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Scan a Responder Roadmap class QR code. Your signed-in department profile will fill your name, email, and department automatically.', textAlign: TextAlign.center),
          if (_error != null) ...[const SizedBox(height: 10), Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w700))],
        ]),
      ),
    ]),
  );
}
