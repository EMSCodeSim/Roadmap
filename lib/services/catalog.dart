/// Compatibility re-export.
///
/// `lib/services/catalog.dart` was historically a large monolithic file.
/// It now re-exports the modularized catalog implementation in
/// `lib/services/catalog/catalog.dart` so existing imports/callers do not change.
export 'package:firepath/services/catalog/catalog.dart';
