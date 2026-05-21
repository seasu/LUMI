import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const _wardrobeDirName = 'lumi_wardrobe';

/// Manages wardrobe images stored in the app's local documents directory.
///
/// iOS: automatically included in iCloud Backup.
/// Android: included in Google Auto Backup (see backup_rules.xml).
class LocalImageStorage {
  static const _uuid = Uuid();

  static Future<Directory> _wardrobeDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_wardrobeDirName');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Saves [bytes] to the wardrobe directory, compressing to JPEG first.
  /// Returns the file name (e.g. `"abc123.jpg"`).
  static Future<String> saveImage(
    List<int> bytes, {
    String extension = 'jpg',
  }) async {
    final dir = await _wardrobeDir();
    final compressed = await FlutterImageCompress.compressWithList(
      Uint8List.fromList(bytes),
      minWidth: 1920,
      minHeight: 1920,
      quality: 82,
      format: CompressFormat.jpeg,
    );
    final fileName = '${_uuid.v4()}.jpg';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(compressed, flush: true);
    return fileName;
  }

  /// Returns the [File] for [fileName], or `null` if the file does not exist.
  static Future<File?> getFile(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return null;
    final dir = await _wardrobeDir();
    final file = File('${dir.path}/$fileName');
    return file.existsSync() ? file : null;
  }

  /// Deletes [fileName] from local storage. Silently ignores missing files.
  static Future<void> deleteFile(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return;
    try {
      final dir = await _wardrobeDir();
      final file = File('${dir.path}/$fileName');
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  /// Writes [data] as JSON to `{wardrobeDir}/{docId}.json`.
  static Future<void> saveMetadata(
    String docId,
    Map<String, dynamic> data,
  ) async {
    final dir = await _wardrobeDir();
    final file = File('${dir.path}/$docId.json');
    await file.writeAsString(jsonEncode(data), flush: true);
  }

  /// Reads and parses `{wardrobeDir}/{docId}.json`. Returns `null` if missing
  /// or corrupt.
  static Future<Map<String, dynamic>?> loadMetadata(String docId) async {
    final dir = await _wardrobeDir();
    final file = File('${dir.path}/$docId.json');
    if (!file.existsSync()) return null;
    try {
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Deletes `{wardrobeDir}/{docId}.json`. Silently ignores missing files.
  static Future<void> deleteMetadata(String docId) async {
    try {
      final dir = await _wardrobeDir();
      final file = File('${dir.path}/$docId.json');
      if (file.existsSync()) await file.delete();
    } catch (_) {}
  }

  /// Scans the wardrobe directory and returns all parseable JSON metadata maps.
  static Future<List<Map<String, dynamic>>> listAllMetadata() async {
    final dir = await _wardrobeDir();
    if (!dir.existsSync()) return const [];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList();
    final result = <Map<String, dynamic>>[];
    for (final file in files) {
      try {
        result.add(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    return result;
  }
}
