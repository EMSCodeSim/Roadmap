import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Reads a picked backup when the file picker supplies a path but no bytes
/// (typical on desktop, and a fallback on iOS/Android).
Future<Uint8List?> readBytesFromPath(String? path) async {
  if (path == null || path.isEmpty) return null;
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  } catch (e) {
    debugPrint('readBytesFromPath failed: $e');
    return null;
  }
}
