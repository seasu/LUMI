# Lumi Code Style Skill

你是 Lumi App 的程式碼風格守門員。所有 Dart/Flutter 程式碼必須符合本規範。

---

## 目錄結構

```
lib/
  features/
    auth/
      data/          # Repository 實作、API 呼叫
      domain/        # Model、抽象介面
      presentation/  # Page、Widget、Provider
    wardrobe/
      data/
      domain/
      presentation/
    lumi_check/
      data/
      domain/
      presentation/
  shared/
    constants/       # LumiColors、LumiSpacing 等全域常數
    widgets/         # 跨功能共用 Widget
    utils/           # 工具函式
  app.dart           # MaterialApp 與 GoRouter 設定
  main.dart
```

## 命名規範

| 對象 | 規則 | 範例 |
|------|------|------|
| 檔案 / 資料夾 | `snake_case` | `wardrobe_card.dart` |
| Class / Enum | `PascalCase` | `WardrobeRepository` |
| 變數 / 函式 | `camelCase` | `fetchWardrobeItems()` |
| 常數 | `camelCase`（以 `k` 為前綴） | `kMaxEmbeddingSize` |
| Provider | 功能名稱 + `Provider` | `wardrobeListProvider` |
| Notifier | 功能名稱 + `Notifier` | `wardrobeNotifier` |
| Page Widget | 功能名稱 + `Page` | `WardrobePage` |
| 子 Widget | 描述性名稱 + `Widget` | `WardrobeCardWidget` |

## Import 排序

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:io';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. 第三方套件（字母排序）
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 4. 專案內部（相對路徑）
import '../../../shared/constants/lumi_colors.dart';
import '../domain/wardrobe_item.dart';
```

## Riverpod 使用模式

### 資料讀取（AsyncNotifierProvider）
```dart
// 非同步資料，有 loading / error / data 三態
@riverpod
class WardrobeList extends _$WardrobeList {
  @override
  Future<List<WardrobeItem>> build() async {
    return ref.watch(wardrobeRepositoryProvider).fetchAll();
  }
}
```

### UI 狀態（NotifierProvider）
```dart
// 純 UI 狀態，不涉及非同步
@riverpod
class SelectedCategory extends _$SelectedCategory {
  @override
  String? build() => null;

  void select(String category) => state = category;
  void clear() => state = null;
}
```

### 單純依賴注入（Provider）
```dart
// Repository、Service 等無狀態依賴
@riverpod
WardrobeRepository wardrobeRepository(Ref ref) {
  return WardrobeRepository(
    firestore: ref.watch(firestoreProvider),
  );
}
```

## Widget 撰寫規範

```dart
// 1. 優先使用 const constructor
const WardrobeCardWidget({super.key, required this.item});

// 2. build() 保持簡潔，複雜部分拆成 private method 或子 Widget
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      _buildThumbnail(),
      _buildInfo(),
    ],
  );
}

// 3. 單一 Widget 檔案不超過 200 行，超過就拆分
// 4. 禁止在 build() 內直接 new 非 const 物件（效能問題）
```

## Model 規範

```dart
// 使用 freezed 或手動實作 copyWith / equality
// 所有 Model 必須是 immutable
@freezed
class WardrobeItem with _$WardrobeItem {
  const factory WardrobeItem({
    required String mediaItemId,
    required String category,
    required List<String> colors,
    required List<String> materials,
    required DateTime createdAt,
    String? thumbnailUrl,
  }) = _WardrobeItem;

  factory WardrobeItem.fromFirestore(Map<String, dynamic> data) => ...;
}
```

## 禁止事項

- 禁止在 Widget 內直接呼叫 Firestore / HTTP（必須透過 Repository）
- 禁止在 `main.dart` 以外的地方初始化 Firebase
- 禁止使用 `dynamic` 型別（除非無法避免）
- 禁止 `print()`，一律用 `debugPrint()` 或 logger 套件
- 禁止 hardcode 字串常數，共用文字放 `lib/shared/constants/strings.dart`

## 任務

$ARGUMENTS
