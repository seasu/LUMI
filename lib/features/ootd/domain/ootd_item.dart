class OotdItem {
  const OotdItem({
    required this.id,
    required this.caption,
    required this.date,
    required this.createdAt,
  });

  /// UUID (without extension); also serves as image filename base (`$id.jpg`).
  final String id;
  final String caption;
  final DateTime date;
  final DateTime createdAt;

  factory OotdItem.fromJson(Map<String, dynamic> d) => OotdItem(
        id: d['id'] as String,
        caption: d['caption'] as String? ?? '',
        date: DateTime.parse(d['date'] as String),
        createdAt: DateTime.parse(d['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'caption': caption,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}
