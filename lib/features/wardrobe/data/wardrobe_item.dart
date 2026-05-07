import 'package:cloud_firestore/cloud_firestore.dart';

class WardrobeItem {
  const WardrobeItem({
    required this.docId,
    required this.category,
    required this.colors,
    required this.materials,
    required this.embedding,
    required this.createdAt,
    this.localFileName,
    this.mediaItemId,
    this.analyzed = true,
    this.analyzeError,
  });

  /// Firestore document ID. For new (local) items this is a UUID; for items
  /// imported from Google Photos it equals the old mediaItemId.
  final String docId;

  /// Local image file name (e.g. `"abc123.jpg"`). Null for items imported
  /// from Google Photos before the local-storage migration.
  final String? localFileName;

  /// Google Photos media item ID. Kept for backward compatibility with items
  /// created before the local-storage migration; null for new local items.
  final String? mediaItemId;

  final String category;
  final List<String> colors;
  final List<String> materials;
  final List<double> embedding;
  final DateTime createdAt;

  final bool analyzed;
  final String? analyzeError;

  bool get isPending => !analyzed && analyzeError == null;
  bool get isQuotaExceeded => analyzeError == 'quota_exceeded';

  /// True when the item was stored locally (new architecture).
  bool get isLocal => localFileName != null;

  Map<String, dynamic> toFirestore() => {
        if (localFileName != null) 'localFileName': localFileName,
        if (mediaItemId != null) 'mediaItemId': mediaItemId,
        'category': category,
        'colors': colors,
        'materials': materials,
        'embedding': embedding,
        'createdAt': Timestamp.fromDate(createdAt),
        'analyzed': analyzed,
        if (analyzeError != null) 'analyzeError': analyzeError,
      };

  factory WardrobeItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return WardrobeItem(
      docId: doc.id,
      localFileName: d['localFileName'] as String?,
      mediaItemId: d['mediaItemId'] as String?,
      category: d['category'] as String? ?? '',
      colors: d['colors'] != null
          ? List<String>.from(d['colors'] as List)
          : const [],
      materials: d['materials'] != null
          ? List<String>.from(d['materials'] as List)
          : const [],
      embedding: d['embedding'] != null
          ? List<double>.from(
              (d['embedding'] as List).map((e) => (e as num).toDouble()),
            )
          : const [],
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      analyzed: d['analyzed'] as bool? ?? true,
      analyzeError: d['analyzeError'] as String?,
    );
  }

  WardrobeItem copyWith({
    bool? analyzed,
    String? analyzeError,
    bool clearAnalyzeError = false,
  }) =>
      WardrobeItem(
        docId: docId,
        localFileName: localFileName,
        mediaItemId: mediaItemId,
        category: category,
        colors: colors,
        materials: materials,
        embedding: embedding,
        createdAt: createdAt,
        analyzed: analyzed ?? this.analyzed,
        analyzeError:
            clearAnalyzeError ? null : (analyzeError ?? this.analyzeError),
      );
}
