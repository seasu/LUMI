import 'dart:io';

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

  /// Saves [bytes] to the wardrobe directory.
  /// Returns the file name (e.g. `"abc123.jpg"`), which should be stored in Firestore.
  static Future<String> saveImage(
    List<int> bytes, {
    String extension = 'jpg',
  }) async {
    final dir = await _wardrobeDir();
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    final fileName = '${_uuid.v4()}.$ext';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
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
}
