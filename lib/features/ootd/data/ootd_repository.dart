import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_ootd_storage.dart';
import '../domain/ootd_item.dart';

/// Manages the in-memory OOTD list backed by [LocalOotdStorage].
class OotdLocalNotifier extends AsyncNotifier<List<OotdItem>> {
  @override
  Future<List<OotdItem>> build() => _loadFromDisk();

  Future<List<OotdItem>> _loadFromDisk() async {
    final maps = await LocalOotdStorage.listAll();
    final items = <OotdItem>[];
    for (final m in maps) {
      try {
        items.add(OotdItem.fromJson(m));
      } catch (_) {}
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Saves the image + metadata to disk and prepends the new item to state.
  Future<OotdItem> save({
    required String caption,
    required DateTime date,
    required Uint8List imageBytes,
  }) async {
    final id = await LocalOotdStorage.saveImage(imageBytes);
    final item = OotdItem(
      id: id,
      caption: caption,
      date: date,
      createdAt: DateTime.now(),
    );
    await LocalOotdStorage.saveMetadata(id, item.toJson());
    state = AsyncData([item, ...state.valueOrNull ?? []]);
    return item;
  }

  /// Deletes the item files and removes it from state.
  Future<void> delete(String id) async {
    await LocalOotdStorage.deleteItem(id);
    state = AsyncData(
      state.valueOrNull?.where((i) => i.id != id).toList() ?? [],
    );
  }
}

final ootdLocalProvider =
    AsyncNotifierProvider<OotdLocalNotifier, List<OotdItem>>(
  OotdLocalNotifier.new,
);
