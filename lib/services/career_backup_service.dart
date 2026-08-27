import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'package:firepath/services/career_record_store.dart';
import 'package:firepath/services/storage/path_bytes.dart';

class CareerBackupExportResult {
  final bool success;
  final String message;
  final String? fileName;

  const CareerBackupExportResult({
    required this.success,
    required this.message,
    this.fileName,
  });
}

/// File-based Career Portfolio backup and restore.
///
/// The portable JSON envelope stays the interchange format. Sharing or saving
/// a `.json` file is the primary path; clipboard paste remains a fallback.
class CareerBackupService {
  CareerBackupService({CareerRecordStore? store})
      : _store = store ?? CareerRecordStore();

  final CareerRecordStore _store;

  static String fileNameFor(DateTime exportedAt) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'FireOps-Career-Portfolio-'
        '${exportedAt.year}-${two(exportedAt.month)}-${two(exportedAt.day)}.json';
  }

  Future<String> exportBackupJson() => _store.exportBackup();

  Future<CareerBackupExportResult> shareOrSaveBackup() async {
    try {
      final json = await exportBackupJson();
      final fileName = fileNameFor(DateTime.now());
      final bytes = Uint8List.fromList(utf8.encode(json));

      if (kIsWeb) {
        final saved = await FilePicker.platform.saveFile(
          dialogTitle: 'Save FireOps career backup',
          fileName: fileName,
          bytes: bytes,
          type: FileType.custom,
          allowedExtensions: const ['json'],
        );
        if (saved == null) {
          return const CareerBackupExportResult(
            success: false,
            message: 'Backup was not saved.',
          );
        }
        return CareerBackupExportResult(
          success: true,
          message: 'Backup saved as $fileName.',
          fileName: fileName,
        );
      }

      final result = await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            mimeType: 'application/json',
            name: fileName,
          ),
        ],
        subject: 'FireOps Career Portfolio backup',
        text:
            'FireOps Career Road backup. Keep this file somewhere safe; restoring it replaces the portfolio on a device.',
        fileNameOverrides: [fileName],
      );
      if (result.status == ShareResultStatus.dismissed) {
        return CareerBackupExportResult(
          success: false,
          message: 'Backup was not shared.',
          fileName: fileName,
        );
      }
      return CareerBackupExportResult(
        success: true,
        message: 'Backup file $fileName is ready to save or share.',
        fileName: fileName,
      );
    } catch (e) {
      debugPrint('CareerBackupService.shareOrSaveBackup failed: $e');
      return const CareerBackupExportResult(
        success: false,
        message: 'The backup file could not be created. Try again.',
      );
    }
  }

  Future<CareerRestoreResult> restoreFromPickedFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        dialogTitle: 'Choose a FireOps career backup',
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        return const CareerRestoreResult(
          success: false,
          count: 0,
          message: 'No backup file was selected.',
        );
      }
      final file = picked.files.single;
      var bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        bytes = await readBytesFromPath(file.path);
      }
      if (bytes == null || bytes.isEmpty) {
        return const CareerRestoreResult(
          success: false,
          count: 0,
          message:
              'The selected file could not be read. Choose a FireOps .json backup.',
        );
      }
      return await restoreFromBytes(bytes);
    } catch (e) {
      debugPrint('CareerBackupService.restoreFromPickedFile failed: $e');
      return const CareerRestoreResult(
        success: false,
        count: 0,
        message: 'The backup file could not be opened. Try another file.',
      );
    }
  }

  Future<CareerRestoreResult> restoreFromBytes(Uint8List bytes) async {
    String raw;
    try {
      raw = utf8.decode(bytes);
    } catch (e) {
      debugPrint('CareerBackupService.restoreFromBytes decode failed: $e');
      return const CareerRestoreResult(
        success: false,
        count: 0,
        message: 'The backup file is not valid UTF-8 text.',
      );
    }
    return _store.restoreBackup(raw);
  }

  Future<CareerRestoreResult> restoreFromPastedJson(String raw) =>
      _store.restoreBackup(raw);
}
