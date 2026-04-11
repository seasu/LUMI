import 'package:cloud_firestore/cloud_firestore.dart';

class WardrobeItem {
  const WardrobeItem({
    required this.mediaItemId,
    required this.category,
    required this.colors,
    required this.materials,
    required this.embedding,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.thumbnailRefreshedAt,
    this.analyzed = true,
    this.analyzeError,
  });

  final String mediaItemId;
  final String category;
  final List<String> colors;
  final List<String> materials;
  final List<double> embedding;
  final String thumbnailUrl;
  final DateTime createdAt;
  final DateTime thumbnailRefreshedAt;

  /// false = Firestore trigger has not yet written analysis results.
  final bool analyzed;

  /// Non-null when the trigger failed: 'quota_exceeded', 'download_failed:…', etc.
  final String? analyzeError;

  bool get isThumbnailStale =>
      DateTime.now().difference(thumbnailRefreshedAt).inMinutes >= 55;

  bool get isPending => !analyzed && analyzeError == null;
  bool get isQuotaExceeded => analyzeError == 'quota_exceeded';

  Map<String, dynamic> toFirestore() => {
        'mediaItemId': mediaItemId,
        'category': category,
        'colors': colors,
        'materials': materials,
        'embedding': embedding,
        'thumbnailUrl': thumbnailUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'thumbnailRefreshedAt': Timestamp.fromDate(thumbnailRefreshedAt),
        'analyzed': analyzed,
        if (analyzeError != null) 'analyzeError': analyzeError,
      };

  factory WardrobeItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return WardrobeItem(
      mediaItemId: d['mediaItemId'] as String,
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
      thumbnailUrl: d['thumbnailUrl'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      thumbnailRefreshedAt:
          (d['thumbnailRefreshedAt'] as Timestamp).toDate(),
      analyzed: d['analyzed'] as bool? ?? true,
      analyzeError: d['analyzeError'] as String?,
    );
  }

  WardrobeItem copyWith({
    String? thumbnailUrl,
    DateTime? thumbnailRefreshedAt,
    bool? analyzed,
    String? analyzeError,
  }) =>
      WardrobeItem(
        mediaItemId: mediaItemId,
        category: category,
        colors: colors,
        materials: materials,
        embedding: embedding,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        createdAt: createdAt,
        thumbnailRefreshedAt:
            thumbnailRefreshedAt ?? this.thumbnailRefreshedAt,
        analyzed: analyzed ?? this.analyzed,
        analyzeError: analyzeError ?? this.analyzeError,
      );
}
