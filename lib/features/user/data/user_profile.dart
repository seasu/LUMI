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
    required this.onboardingCompleted,
    // Body measurements
    this.heightCm,
    this.weightKg,
    this.birthday,
    this.headCircumferenceCm,
    this.chestCm,
    this.waistCm,
    this.hipCm,
    this.legLengthCm,
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

  /// True once the user has completed the 3-step onboarding flow.
  final bool onboardingCompleted;

  // ── Body measurements ──────────────────────────────────────────────────────
  final double? heightCm;
  final double? weightKg;
  final String? birthday;          // "YYYY-MM-DD"
  final double? headCircumferenceCm;
  final double? chestCm;
  final double? waistCm;
  final double? hipCm;
  final double? legLengthCm;

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
      onboardingCompleted: (d['onboardingCompleted'] as bool?) ?? false,
      heightCm: (d['heightCm'] as num?)?.toDouble(),
      weightKg: (d['weightKg'] as num?)?.toDouble(),
      birthday: d['birthday'] as String?,
      headCircumferenceCm: (d['headCircumferenceCm'] as num?)?.toDouble(),
      chestCm: (d['chestCm'] as num?)?.toDouble(),
      waistCm: (d['waistCm'] as num?)?.toDouble(),
      hipCm: (d['hipCm'] as num?)?.toDouble(),
      legLengthCm: (d['legLengthCm'] as num?)?.toDouble(),
    );
  }
}
