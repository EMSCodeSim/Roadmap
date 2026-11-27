import 'package:firepath/services/pdf_text_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes punctuation unsupported by standard PDF fonts', () {
    expect(
      pdfSafeText('Draft — “ready” • score ≥ 80% ✓'),
      'Draft - "ready" - score >= 80% PASS',
    );
  });

  test('removes unsupported symbols without joining words', () {
    expect(pdfSafeText('Alpha 🚒 Bravo'), 'Alpha Bravo');
  });
}
