import 'package:flutter_test/flutter_test.dart';
import 'package:firepath/widgets/department_qr.dart';

void main() {
  test('member QR accepts only opaque 64-char token formats', () {
    const token = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    expect(parseMemberQrToken(token), token);
    expect(parseMemberQrToken('rrmember:$token'), token);
    expect(parseMemberQrToken('rrmember:abc'), isNull);
    expect(parseMemberQrToken('https://example.com/member/$token'), isNull);
  });

  test('class QR extracts the registration token from the canonical URL', () {
    const token = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    expect(parseClassRegistrationToken(token), token);
    expect(
      parseClassRegistrationToken('https://responderroadmap.com/class-register/$token'),
      token,
    );
    expect(parseClassRegistrationToken('https://example.com/no-token'), isNull);
  });
}
