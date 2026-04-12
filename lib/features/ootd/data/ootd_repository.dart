import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../domain/ootd_item.dart';

class OotdRepository {
  OotdRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String userId) =>
      _firestore.collection('users').doc(userId).collection('ootd');

  Stream<List<OotdItem>> watchItems(String userId) =>
      _col(userId)
          .orderBy('date', descending: true)
          .snapshots()
          .map((s) => s.docs.map(OotdItem.fromFirestore).toList());

  Future<OotdItem> addItem(String userId, OotdItem item) async {
    final ref = await _col(userId).add(item.toFirestore());
    return OotdItem(
      id: ref.id,
      imageBase64: item.imageBase64,
      caption: item.caption,
      date: item.date,
      createdAt: item.createdAt,
    );
  }

  Future<void> deleteItem(String userId, String itemId) =>
      _col(userId).doc(itemId).delete();
}

final ootdRepositoryProvider = Provider<OotdRepository>((ref) {
  return OotdRepository(ref.watch(firestoreProvider));
});

final ootdItemsProvider = StreamProvider.family<List<OotdItem>, String>(
  (ref, userId) => ref.watch(ootdRepositoryProvider).watchItems(userId),
);
