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

    return Container(
      decoration: BoxDecoration(
        color: LumiColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _ThumbnailImage(url: thumbnailUrl)),
          Padding(
            padding: const EdgeInsets.all(LumiSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: LumiColors.text,
                  ),
                ),
                const SizedBox(height: LumiSpacing.xs),
                Row(
                  children: item.colors
                      .take(3)
                      .map((hex) => _ColorDot(hex: hex))
                      .toList(),
                ),
              ],
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
  // Auto-refresh in background if stale; return current URL immediately
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
      errorBuilder: (_, __, ___) => const ColoredBox(
        color: LumiColors.base,
        child: Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: LumiColors.subtext),
        ),
      ),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: LumiColors.base,
        );
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
    final color = value != null ? Color(value) : LumiColors.subtext;

    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(right: LumiSpacing.xs),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
