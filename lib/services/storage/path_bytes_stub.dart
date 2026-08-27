import 'dart:typed_data';

/// Web has no local file path to read; [PlatformFile.bytes] is the source.
Future<Uint8List?> readBytesFromPath(String? path) async => null;
