import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/lumi_colors.dart';
import '../../../../shared/constants/lumi_spacing.dart';
import '../../../wardrobe/data/wardrobe_item.dart';
import '../../../wardrobe/data/wardrobe_repository.dart';
import '../../../../core/providers/firebase_providers.dart';

class WardrobeCard extends ConsumerWidget {
  const WardrobeCard({super.key, required this.item});

  final WardrobeItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailUrl = ref.watch(_thumbnailUrlProvider(item));

    // Spring entrance: scale from 0.92 → 1.0 with easeOutBack
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.0),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (_, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        decoration: BoxDecoration(
          color: LumiColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed image
            _ThumbnailImage(url: thumbnailUrl),
            // Bottom gradient overlay with label (only when analyzed)
            if (item.analyzed)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    LumiSpacing.sm,
                    LumiSpacing.xl,
                    LumiSpacing.sm,
                    LumiSpacing.sm,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xCC000000), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          item.category,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      ...item.colors.take(3).map((hex) => _ColorDot(hex: hex)),
                    ],
                  ),
                ),
              ),
            // Pending / quota overlay
            if (!item.analyzed) _PendingOverlay(item: item),
          ],
        ),
      ),
    );
  }
}

// ── Pending overlay ───────────────────────────────────────────────────────────

class _PendingOverlay extends StatelessWidget {
  const _PendingOverlay({required this.item});

  final WardrobeItem item;

  @override
  Widget build(BuildContext context) {
    final isQuota = item.isQuotaExceeded;

    return Container(
      color: LumiColors.text.withOpacity(0.35),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isQuota)
            const Icon(Icons.lock_outline, color: Colors.white, size: 26)
          else
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LumiColors.glow.withOpacity(0.8),
              ),
            ),
          const SizedBox(height: 6),
          Text(
            isQuota ? '配額已用完' : 'AI 分析中',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Thumbnail with stale-check ────────────────────────────────────────────────

final _thumbnailUrlProvider =
    Provider.family<String, WardrobeItem>((ref, item) {
  if (item.isThumbnailStale) {
    _refreshInBackground(ref, item);
  }
  return item.thumbnailUrl;
});

void _refreshInBackground(Ref ref, WardrobeItem item) {
  final user = ref.read(firebaseAuthProvider).currentUser;
  if (user == null) return;

  Future(() async {
    try {
      final googleSignIn = ref.read(googleSignInProvider);
      final gUser =
          googleSignIn.currentUser ?? await googleSignIn.signInSilently();
      final accessToken = (await gUser?.authentication)?.accessToken;
      if (accessToken == null) return;

      await ref.read(wardrobeRepositoryProvider).refreshThumbnailUrl(
            userId: user.uid,
            mediaItemId: item.mediaItemId,
            accessToken: accessToken,
          );
    } catch (_) {
      // Silent fail — stale URL still works until ~60 min
    }
  });
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ThumbnailImage extends StatelessWidget {
  const _ThumbnailImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: LumiColors.base,
        child: Center(
          child: Icon(Icons.checkroom_outlined, color: LumiColors.subtext, size: 32),
        ),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(color: LumiColors.base);
      },
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.hex});

  final String hex;

  @override
  Widget build(BuildContext context) {
    final clean = hex.replaceAll('#', '');
    final value = int.tryParse('FF$clean', radix: 16);
    final color = value != null ? Color(value) : Colors.white;

    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(left: LumiSpacing.xs),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1),
      ),
    );
  }
}
