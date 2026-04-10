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
  });

  final String mediaItemId;
  final String category;
  final List<String> colors;
  final List<String> materials;
  final List<double> embedding;
  final String thumbnailUrl;
  final DateTime createdAt;
  final DateTime thumbnailRefreshedAt;

  bool get isThumbnailStale =>
      DateTime.now().difference(thumbnailRefreshedAt).inMinutes >= 55;

  Map<String, dynamic> toFirestore() => {
        'mediaItemId': mediaItemId,
        'category': category,
        'colors': colors,
        'materials': materials,
        'embedding': embedding,
        'thumbnailUrl': thumbnailUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'thumbnailRefreshedAt': Timestamp.fromDate(thumbnailRefreshedAt),
      };

  factory WardrobeItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return WardrobeItem(
      mediaItemId: d['mediaItemId'] as String,
      category: d['category'] as String,
      colors: List<String>.from(d['colors'] as List),
      materials: List<String>.from(d['materials'] as List),
      embedding: List<double>.from(
        (d['embedding'] as List).map((e) => (e as num).toDouble()),
      ),
      thumbnailUrl: d['thumbnailUrl'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      thumbnailRefreshedAt:
          (d['thumbnailRefreshedAt'] as Timestamp).toDate(),
    );
  }

  WardrobeItem copyWith({
    String? thumbnailUrl,
    DateTime? thumbnailRefreshedAt,
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
      );
}
