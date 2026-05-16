import 'package:cloud_firestore/cloud_firestore.dart';

class WardrobeItem {
  const WardrobeItem({
    required this.docId,
    required this.localFileName,
    required this.category,
    required this.colors,
    required this.materials,
    required this.embedding,
    required this.createdAt,
    this.analyzed = true,
    this.analyzeError,
  });

  /// Firestore document ID — UUID derived from the image file name.
  final String docId;

  /// Local image file name (e.g. `"abc123.jpg"`).
  final String localFileName;

  final String category;
  final List<String> colors;
  final List<String> materials;
  final List<double> embedding;
  final DateTime createdAt;

  final bool analyzed;
  final String? analyzeError;

  bool get isPending => !analyzed && analyzeError == null;
  bool get isQuotaExceeded => analyzeError == 'quota_exceeded';

  Map<String, dynamic> toJson() => {
        'docId': docId,
        'localFileName': localFileName,
        'category': category,
        'colors': colors,
        'materials': materials,
        'embedding': embedding,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'analyzed': analyzed,
        if (analyzeError != null) 'analyzeError': analyzeError,
      };

  factory WardrobeItem.fromJson(Map<String, dynamic> d) => WardrobeItem(
        docId: d['docId'] as String,
        localFileName: d['localFileName'] as String? ?? '',
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
        createdAt: DateTime.parse(d['createdAt'] as String),
        analyzed: d['analyzed'] as bool? ?? true,
        analyzeError: d['analyzeError'] as String?,
      );

  Map<String, dynamic> toFirestore() => {
        'localFileName': localFileName,
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
      localFileName: d['localFileName'] as String? ?? '',
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
    String? category,
    List<String>? colors,
    List<String>? materials,
    bool? analyzed,
    String? analyzeError,
    bool clearAnalyzeError = false,
  }) =>
      WardrobeItem(
        docId: docId,
        localFileName: localFileName,
        category: category ?? this.category,
        colors: colors ?? this.colors,
        materials: materials ?? this.materials,
        embedding: embedding,
        createdAt: createdAt,
        analyzed: analyzed ?? this.analyzed,
        analyzeError:
            clearAnalyzeError ? null : (analyzeError ?? this.analyzeError),
      );
}
