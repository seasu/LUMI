import 'package:cloud_firestore/cloud_firestore.dart';

class OotdItem {
  const OotdItem({
    required this.id,
    required this.imageBase64,
    required this.caption,
    required this.date,
    required this.createdAt,
  });

  final String id;

  /// Compressed JPEG stored as base64 (max 800px wide, quality 60).
  /// Kept in Firestore for the MVP; migrate to Storage in M5+.
  final String imageBase64;

  final String caption;
  final DateTime date;
  final DateTime createdAt;

  factory OotdItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return OotdItem(
      id: doc.id,
      imageBase64: d['imageBase64'] as String? ?? '',
      caption: d['caption'] as String? ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'imageBase64': imageBase64,
        'caption': caption,
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
