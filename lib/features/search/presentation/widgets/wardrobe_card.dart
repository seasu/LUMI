import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/constants/lumi_colors.dart';
import '../../../wardrobe/data/wardrobe_item.dart';
import '../../../wardrobe/data/wardrobe_repository.dart';
import '../../../../core/providers/firebase_providers.dart';

class WardrobeCard extends ConsumerWidget {
  const WardrobeCard({super.key, required this.item});

  final WardrobeItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailUrl = ref.watch(_thumbnailUrlProvider(item));
    final colorText = item.colors.isNotEmpty ? item.colors.first : '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: LumiColors.surface,
              borderRadius: BorderRadius.circular(22),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ThumbnailImage(url: thumbnailUrl),
                if (!item.analyzed) _PendingOverlay(item: item),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.category.isEmpty ? '未分類' : item.category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: LumiColors.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          colorText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            color: LumiColors.subtext,
          ),
        ),
      ],
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
            const Icon(Icons.lock_outline, color: Colors.white, size: 24)
          else
            Container(
              width: 20,
              height: 20,
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
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
