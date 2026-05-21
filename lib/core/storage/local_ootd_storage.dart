import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const _dirName = 'lumi_ootd';

/// Local storage for OOTD photos and metadata.
/// Images are stored as `{id}.jpg`; metadata as `{id}.json`.
/// iOS: covered by iCloud Backup. Android: covered by Auto Backup.
class LocalOotdStorage {
  static const _uuid = Uuid();

  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_dirName');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Saves image bytes and returns the generated [id] (filename without ext).
  /// Compresses to JPEG (quality 82, max 1920px) before writing.
  static Future<String> saveImage(List<int> bytes) async {
    final dir = await _dir();
    final id = _uuid.v4().replaceAll('-', '');
    final compressed = await FlutterImageCompress.compressWithList(
      Uint8List.fromList(bytes),
      minWidth: 1440,
      minHeight: 1920,
      quality: 82,
      format: CompressFormat.jpeg,
    );
    await File('${dir.path}/$id.jpg').writeAsBytes(compressed, flush: true);
    return id;
  }

  static Future<void> saveMetadata(
      String id, Map<String, dynamic> data) async {
    final dir = await _dir();
    await File('${dir.path}/$id.json')
        .writeAsString(jsonEncode(data), flush: true);
  }

  /// Returns the image [File] for [id], or `null` if not found.
  static Future<File?> getImageFile(String id) async {
    final dir = await _dir();
    final f = File('${dir.path}/$id.jpg');
    return f.existsSync() ? f : null;
  }

  /// Deletes both image and metadata files for [id].
  static Future<void> deleteItem(String id) async {
    final dir = await _dir();
    for (final ext in ['.jpg', '.json']) {
      try {
        final f = File('${dir.path}/$id$ext');
        if (f.existsSync()) await f.delete();
      } catch (_) {}
    }
  }

  /// Scans directory and returns all parseable JSON metadata maps.
  static Future<List<Map<String, dynamic>>> listAll() async {
    final dir = await _dir();
    if (!dir.existsSync()) return [];
    final result = <Map<String, dynamic>>[];
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      try {
        result
            .add(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
      } catch (_) {}
    }
    return result;
  }
}
