import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../debug/debug_log.dart';
import '../../features/wardrobe/data/wardrobe_item.dart';
import 'local_image_storage.dart';

void _log(String msg) => DebugLogService.instance.log('[store] $msg');

Future<List<WardrobeItem>> _loadAllFromDisk() async {
  final maps = await LocalImageStorage.listAllMetadata();
  final items = <WardrobeItem>[];
  for (final m in maps) {
    try {
      items.add(WardrobeItem.fromJson(m));
    } catch (e) {
      _log('loadAll: skip corrupt entry $e');
    }
  }
  items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return items;
}

class LocalWardrobeNotifier extends AsyncNotifier<List<WardrobeItem>> {
  @override
  Future<List<WardrobeItem>> build() => _loadAllFromDisk();

  /// Persists a new pending item and prepends it to the current list.
  /// Returns the `docId` (UUID derived from [localFileName]).
  Future<String> addItem({
    required String localFileName,
    required DateTime createdAt,
  }) async {
    final docId = localFileName.contains('.')
        ? localFileName.substring(0, localFileName.lastIndexOf('.'))
        : localFileName;
    final item = WardrobeItem(
      docId: docId,
      localFileName: localFileName,
      category: '',
      colors: const [],
      materials: const [],
      embedding: const [],
      createdAt: createdAt,
      analyzed: false,
    );
    await LocalImageStorage.saveMetadata(docId, item.toJson());
    final current = state.valueOrNull ?? [];
    state = AsyncData([item, ...current]);
    _log('addItem docId=$docId');
    return docId;
  }

  /// Writes AI analysis results and marks the item as analyzed.
  Future<void> updateAnalysis(
    String docId, {
    required String category,
    required List<String> colors,
    required List<String> materials,
    required List<double> embedding,
  }) async {
    final current = state.valueOrNull ?? [];
    final idx = current.indexWhere((i) => i.docId == docId);
    if (idx == -1) return;
    final old = current[idx];
    final item = WardrobeItem(
      docId: old.docId,
      localFileName: old.localFileName,
      category: category,
      colors: colors,
      materials: materials,
      embedding: embedding,
      createdAt: old.createdAt,
      analyzed: true,
    );
    await LocalImageStorage.saveMetadata(docId, item.toJson());
    final newList = List<WardrobeItem>.from(current)..[idx] = item;
    state = AsyncData(newList);
    _log('updateAnalysis docId=$docId category=$category');
  }

  /// Records an analysis failure on the item.
  Future<void> markAnalyzeFailed(String docId, String error) async {
    await _patch(
      docId,
      (item) => item.copyWith(
        analyzeError:
            error.length > 500 ? '${error.substring(0, 500)}…' : error,
      ),
    );
    _log('markAnalyzeFailed docId=$docId');
  }

  /// Clears [analyzeError], resetting the item to pending state for retry.
  Future<void> resetAnalyzeError(String docId) async {
    await _patch(docId, (item) => item.copyWith(clearAnalyzeError: true));
    _log('resetAnalyzeError docId=$docId');
  }

  /// Deletes both the image file and the JSON sidecar, then removes from state.
  Future<void> deleteItem(
    String docId, {
    required String localFileName,
  }) async {
    await LocalImageStorage.deleteFile(localFileName);
    await LocalImageStorage.deleteMetadata(docId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((i) => i.docId != docId).toList());
    _log('deleteItem docId=$docId');
  }

  /// Overwrites user-edited category, colors, and materials (keeps embedding).
  Future<void> updateUserEdit(
    String docId, {
    required String category,
    required List<String> colors,
    required List<String> materials,
  }) async {
    await _patch(
      docId,
      (item) => item.copyWith(
        category: category,
        colors: colors,
        materials: materials,
      ),
    );
    _log('updateUserEdit docId=$docId category=$category');
  }

  /// Rescans the wardrobe directory from disk (useful after OS backup restore).
  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadAllFromDisk());
    _log('reload done');
  }

  Future<void> _patch(
    String docId,
    WardrobeItem Function(WardrobeItem) transform,
  ) async {
    final current = state.valueOrNull ?? [];
    final idx = current.indexWhere((i) => i.docId == docId);
    if (idx == -1) return;
    final updated = transform(current[idx]);
    await LocalImageStorage.saveMetadata(docId, updated.toJson());
    final newList = List<WardrobeItem>.from(current)..[idx] = updated;
    state = AsyncData(newList);
  }
}

final localWardrobeProvider =
    AsyncNotifierProvider<LocalWardrobeNotifier, List<WardrobeItem>>(
  LocalWardrobeNotifier.new,
);
