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
    final title = _displayTitle(item);
    final subtitle = _displaySubtitle(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: LumiColors.surface,
              borderRadius: BorderRadius.circular(20),
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
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: LumiColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines:
                        item.analyzeError != null &&
                                item.analyzeError!.isNotEmpty &&
                                !item.isQuotaExceeded
                            ? 3
                            : 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      color: LumiColors.subtext,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                Icons.favorite_border,
                size: 13,
                color: LumiColors.subtext.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _displayTitle(WardrobeItem item) {
  if (item.isPending) return '分析中';
  if (item.analyzeError != null && item.analyzeError!.isNotEmpty) {
    return _analyzeErrorTitle(item.analyzeError!);
  }
  if (item.materials.isNotEmpty) {
    return item.materials.first;
  }
  if (item.category.isNotEmpty) {
    return item.category;
  }
  return '未分類';
}

String _displaySubtitle(WardrobeItem item) {
  if (item.isPending) {
    return '未分類 · AI 分類處理中';
  }
  final err = item.analyzeError;
  if (err != null && err.isNotEmpty && !item.isQuotaExceeded) {
    final hint = _analyzeErrorHintForUser(err);
    if (hint.isNotEmpty) return hint;
    return '請至 Firebase 後台查看紀錄';
  }
  final category = item.category.isEmpty ? '未分類' : item.category;
  final code = item.mediaItemId.length > 6
      ? item.mediaItemId.substring(0, 6).toUpperCase()
      : item.mediaItemId.toUpperCase();
  return '$category | $code';
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
    final err = item.analyzeError;

    final String title;
    if (isQuota) {
      title = '配額已用完';
    } else if (err != null && err.isNotEmpty) {
      title = _analyzeErrorTitle(err);
    } else {
      title = 'AI 分析中';
    }

    return Container(
      color: LumiColors.text.withOpacity(0.35),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isQuota)
            const Icon(Icons.lock_outline,
                color: LumiColors.onPrimary, size: 24)
          else if (err != null && err.isNotEmpty)
            const Icon(Icons.error_outline,
                color: LumiColors.onPrimary, size: 22)
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: LumiColors.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                if (err != null &&
                    err.isNotEmpty &&
                    err.startsWith('analysis_failed:'))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _analyzeErrorTechnicalTail(err),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: LumiColors.onPrimary.withOpacity(0.88),
                        fontSize: 8,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Maps [analyzeWardrobeItem] error codes to short UI copy (full value stays in Firestore).
String _analyzeErrorTitle(String analyzeError) {
  if (analyzeError == 'missing_url') return '缺少預覽連結';
  if (analyzeError == 'quota_exceeded') return '配額已用完';
  if (analyzeError.startsWith('download_failed:')) {
    return '無法載入相片';
  }
  if (analyzeError.startsWith('analysis_failed:')) {
    return 'AI 分析失敗';
  }
  if (analyzeError.startsWith('trigger_failed:')) {
    return '分析管線錯誤';
  }
  return '分析未完成';
}

/// Short multi-line hint for subtitle (prefix stripped, truncated).
String _analyzeErrorHintForUser(String analyzeError) {
  return _sanitizeErrorBlob(analyzeError).trim();
}

/// One compressed line from [analysis_failed:...] for overlay (max ~180 chars).
String _analyzeErrorTechnicalTail(String analyzeError) {
  return _sanitizeErrorBlob(analyzeError);
}

/// Maps stored `analyzeError` fields to readable, truncated copy for the UI.
String _sanitizeErrorBlob(String raw) {
  var s = raw.trim();
  const prefixes = [
    'analysis_failed:',
    'download_failed:',
    'trigger_failed:',
  ];
  for (final p in prefixes) {
    if (s.startsWith(p)) {
      s = s.substring(p.length).trim();
      break;
    }
  }
  // Drop redundant internal prefixes from Gemini SDK / Functions
  const noise = [
    'Gemini vision API error: ',
    'Gemini embedding API error: ',
    'INTERNAL: ',
  ];
  for (final n in noise) {
    if (s.contains(n)) {
      s = s.split(n).last.trim();
    }
  }
  if (s.length > 180) {
    s = '${s.substring(0, 177)}…';
  }
  if (s.isEmpty) {
    return '';
  }
  // Common operator-facing hints (Chinese)
  final lower = s.toLowerCase();
  if (lower.contains('404') && lower.contains('model')) {
    return '模型名稱或 API 版本可能過期，請開發者更新 Cloud Functions 的 Gemini 模型設定。';
  }
  if (lower.contains('api key') ||
      lower.contains('permission denied') ||
      lower.contains('permission_denied')) {
    return 'Gemini API 金鑰或權限有誤：請確認 Firebase 已設定 GEMINI_API_KEY，且 Generative Language API 已啟用。';
  }
  if (lower.contains('quota') || lower.contains('resource_exhausted')) {
    return 'Gemini API 配額或請求過於頻繁，請稍後再試或檢查 Google Cloud 配額。';
  }
  if (lower.contains('failed to parse gemini')) {
    return 'AI 回傳格式異常；請重試或換一張較清楚的衣物照片。';
  }
  return s;
}
