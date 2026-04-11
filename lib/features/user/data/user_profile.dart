import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.plan,
    required this.analyzedCount,
    required this.freeQuota,
    required this.createdAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  /// 'free' | 'pro' — reserved for future paid plans.
  final String plan;

  /// Lifetime total of photos analysed by the AI trigger.
  final int analyzedCount;

  /// Maximum photos allowed under the current plan.
  final int freeQuota;

  final DateTime createdAt;

  bool get isOverQuota => analyzedCount >= freeQuota;
  int get remainingQuota => (freeQuota - analyzedCount).clamp(0, freeQuota);

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return UserProfile(
      uid: d['uid'] as String? ?? doc.id,
      email: d['email'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      photoUrl: d['photoUrl'] as String?,
      plan: d['plan'] as String? ?? 'free',
      analyzedCount: (d['analyzedCount'] as num?)?.toInt() ?? 0,
      freeQuota: (d['freeQuota'] as num?)?.toInt() ?? 100,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
