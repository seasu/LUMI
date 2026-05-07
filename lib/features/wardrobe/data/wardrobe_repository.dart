import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/debug/debug_log.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/storage/local_image_storage.dart';
import 'wardrobe_item.dart';

void _log(String msg) => DebugLogService.instance.log('[fs:wardrobe] $msg');

class WardrobeRepository {
  WardrobeRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _firestore.collection('users').doc(userId).collection('wardrobe');

  /// Creates a wardrobe doc for a locally saved image.
  /// [localFileName] is the file name returned by [LocalImageStorage.saveImage].
  /// The doc ID is the UUID portion of the file name (without extension).
  Future<String> addItemLocal(
    String userId, {
    required String localFileName,
    required DateTime createdAt,
  }) {
    final docId = localFileName.contains('.')
        ? localFileName.substring(0, localFileName.lastIndexOf('.'))
        : localFileName;
    _log('addItemLocal → uid=$userId docId=$docId');
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
    return _col(userId).doc(docId).set(item.toFirestore()).then((_) => docId);
  }

  /// Updates a wardrobe doc with Gemini analysis results.
  Future<void> updateAnalysis(
    String userId,
    String docId, {
    required String category,
    required List<String> colors,
    required List<String> materials,
    required List<double> embedding,
  }) {
    _log('updateAnalysis → uid=$userId docId=$docId category=$category');
    return _col(userId).doc(docId).update({
      'category': category,
      'colors': colors,
      'materials': materials,
      'embedding': embedding,
      'analyzed': true,
      'analyzeError': FieldValue.delete(),
    });
  }

  /// Marks a wardrobe doc as failed analysis.
  Future<void> markAnalyzeFailed(
    String userId,
    String docId,
    String error,
  ) {
    _log('markAnalyzeFailed → uid=$userId docId=$docId');
    return _col(userId).doc(docId).update({
      'analyzed': false,
      'analyzeError': error.length > 500 ? '${error.substring(0, 500)}…' : error,
    });
  }

  /// Deletes a wardrobe item and its local image file (if any).
  Future<void> deleteItem(
    String userId,
    String docId, {
    String? localFileName,
  }) async {
    _log('deleteItem → uid=$userId docId=$docId');
    await LocalImageStorage.deleteFile(localFileName);
    return _col(userId).doc(docId).delete();
  }

  Future<WardrobeItem?> getItem(String userId, String docId) async {
    _log('getItem → uid=$userId docId=$docId');
    final doc = await _col(userId).doc(docId).get();
    if (!doc.exists) return null;
    return WardrobeItem.fromFirestore(doc);
  }

  Stream<List<WardrobeItem>> watchWardrobe(String userId) =>
      _col(userId).orderBy('createdAt', descending: true).snapshots().map(
            (snap) => snap.docs.map(WardrobeItem.fromFirestore).toList(),
          );

  Future<void> prefetchWardrobeFromServer(String userId) async {
    _log('prefetchFromServer → uid=$userId');
    final sw = Stopwatch()..start();
    try {
      final snap = await _col(userId)
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.server));
      _log('prefetchFromServer ← ok ${sw.elapsedMilliseconds}ms'
          ' count=${snap.docs.length}');
    } catch (e) {
      _log('prefetchFromServer ✗ ${sw.elapsedMilliseconds}ms $e');
      rethrow;
    }
  }
}

final wardrobeRepositoryProvider = Provider<WardrobeRepository>((ref) {
  return WardrobeRepository(ref.watch(firestoreProvider));
});
