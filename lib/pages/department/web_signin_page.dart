import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:firepath/services/responder_roadmap_api.dart';

class WebSignInPage extends StatefulWidget {
  final String? requestId;
  final String? approvalToken;

  const WebSignInPage({
    super.key,
    this.requestId,
    this.approvalToken,
  });

  @override
  State<WebSignInPage> createState() => _WebSignInPageState();
}

class _WebSignInPageState extends State<WebSignInPage> {
  final _api = ResponderRoadmapApi();
  final _scanner = MobileScannerController();
  bool _busy = false;
  bool _done = false;
  String? _error;
  String? _requestId;
  String? _approvalToken;

  @override
  void initState() {
    super.initState();
    _requestId = widget.requestId;
    _approvalToken = widget.approvalToken;
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  bool _parsePayload(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null) return false;

    final recognized =
        uri.scheme == 'responderroadmap' ||
        (uri.scheme == 'https' &&
            uri.host == 'responderroadmap.com' &&
            uri.path == '/app-signin');
    if (!recognized) return false;

    final id = uri.queryParameters['id']?.trim() ?? '';
    final token = uri.queryParameters['token']?.trim() ?? '';
    if (id.isEmpty || token.isEmpty) return false;

    setState(() {
      _requestId = id;
      _approvalToken = token;
      _error = null;
    });
    _scanner.stop();
    return true;
  }

  Future<void> _approve() async {
    final requestId = _requestId;
    final approvalToken = _approvalToken;
    if (requestId == null || approvalToken == null) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.approveWebSignIn(
        requestId: requestId,
        approvalToken: approvalToken,
      );
      if (!mounted) return;
      setState(() => _done = true);
    } on ResponderRoadmapApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to approve this web sign-in request.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRequest = _requestId != null && _approvalToken != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in on web')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _done
              ? _Success(onDone: () => Navigator.of(context).maybePop())
              : hasRequest
                  ? _Confirm(
                      busy: _busy,
                      error: _error,
                      onApprove: _approve,
                      onCancel: () {
                        setState(() {
                          _requestId = null;
                          _approvalToken = null;
                          _error = null;
                        });
                        _scanner.start();
                      },
                    )
                  : _Scanner(
                      controller: _scanner,
                      error: _error,
                      onCode: (value) {
                        if (!_parsePayload(value)) {
                          setState(() {
                            _error = 'That QR code is not a Responder Roadmap web sign-in request.';
                          });
                        }
                      },
                    ),
        ),
      ),
    );
  }
}

class _Scanner extends StatelessWidget {
  final MobileScannerController controller;
  final String? error;
  final ValueChanged<String> onCode;

  const _Scanner({
    required this.controller,
    required this.error,
    required this.onCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Scan the QR code shown on responderroadmap.com/login.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        const Text(
          'No password is shared with the browser. You will confirm the sign-in in this app.',
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  final value = barcode.rawValue;
                  if (value != null && value.isNotEmpty) {
                    onCode(value);
                    break;
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Only approve a sign-in request you started on a browser you recognize.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Confirm extends StatelessWidget {
  final bool busy;
  final String? error;
  final VoidCallback onApprove;
  final VoidCallback onCancel;

  const _Confirm({
    required this.busy,
    required this.error,
    required this.onApprove,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.laptop_mac_rounded, size: 44),
                const SizedBox(height: 14),
                Text(
                  'Sign in this browser?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Approve only if you just opened the Responder Roadmap sign-in page on that computer or phone.',
                  textAlign: TextAlign.center,
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: busy ? null : onApprove,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: Text(busy ? 'Approving…' : 'Approve web sign-in'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: busy ? null : onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Success extends StatelessWidget {
  final VoidCallback onDone;

  const _Success({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  'Browser signed in',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You can return to the browser. This QR request cannot be used again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onDone,
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
