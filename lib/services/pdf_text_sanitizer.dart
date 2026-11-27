/// Converts text to the character set supported by the standard PDF fonts.
///
/// The PDF package's built-in Helvetica font does not contain many common
/// Unicode punctuation glyphs. Without normalization, those characters can
/// print as empty squares or other unexpected symbols.
String pdfSafeText(String value) {
  return value
      .replaceAll('\u00a0', ' ')
      .replaceAll(RegExp(r'[\u2010-\u2015]'), '-')
      .replaceAll(RegExp(r'[\u2018\u2019]'), "'")
      .replaceAll(RegExp(r'[\u201c\u201d]'), '"')
      .replaceAll('\u2026', '...')
      .replaceAll(RegExp(r'[\u2022\u00b7\u203a\u2192]'), ' - ')
      .replaceAll('\u2265', '>=')
      .replaceAll('\u2264', '<=')
      .replaceAll('\u2713', 'PASS')
      .replaceAll(RegExp(r'[^\x09\x0a\x0d\x20-\x7e\xa0-\xff]'), ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .trim();
}
