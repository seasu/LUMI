import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart'
    show firebaseAuthProvider;
import '../../../../core/storage/local_image_storage.dart';
import '../../../../shared/constants/lumi_colors.dart';
import '../../../wardrobe/data/wardrobe_item.dart';
import '../../../wardrobe/data/wardrobe_repository.dart';

class WardrobeCard extends ConsumerWidget {
  const WardrobeCard({super.key, required this.item});

  final WardrobeItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = _displayTitle(item);
    final subtitle = _displaySubtitle(item);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onLongPress: () => _showDeleteConfirmation(context, ref),
      child: Column(
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
                  _ThumbnailImage(localFileName: item.localFileName),
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
                  color: LumiColors.subtext.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除衣物'),
        content: const Text('確定要從衣櫥中刪除這件衣物嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '刪除',
              style: TextStyle(color: LumiColors.warning),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;

    try {
      await ref
          .read(wardrobeRepositoryProvider)
          .deleteItem(user.uid, item.docId, localFileName: item.localFileName);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('刪除失敗，請再試一次')),
        );
      }
    }
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
  final id = item.docId;
  final code = id.length > 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase();
  return '$category | $code';
}

// ── Thumbnail display ─────────────────────────────────────────────────────────

class _ThumbnailImage extends StatelessWidget {
  const _ThumbnailImage({required this.localFileName});

  final String? localFileName;

  @override
  Widget build(BuildContext context) {
    if (localFileName == null || localFileName!.isEmpty) {
      return const _ImagePlaceholder();
    }
    return FutureBuilder<File?>(
      future: LocalImageStorage.getFile(localFileName),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) return const _ImagePlaceholder();
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: LumiColors.base,
      child: Center(
        child: Icon(Icons.checkroom_outlined, color: LumiColors.subtext, size: 32),
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
      color: LumiColors.text.withValues(alpha: 0.35),
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
                color: LumiColors.glow.withValues(alpha: 0.8),
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
                        color: LumiColors.onPrimary.withValues(alpha: 0.88),
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

/// Maps analyzeError codes to short UI copy.
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
