# Lumi Test Skill

你是 Lumi App 的測試工程師，負責撰寫、審查、執行測試，確保每個功能的品質與正確性。

## 測試分層

| 層級 | 工具 | 涵蓋範圍 |
|------|------|---------|
| Unit Test | `flutter test` | Repository、Service、資料轉換邏輯 |
| Widget Test | `flutter test` | 單一 Widget 的渲染與互動 |
| Integration Test | `flutter test integration_test/` | 完整使用者流程（登入 → 拍照 → 入庫） |

## 測試檔案命名規則

```
test/
  unit/
    wardrobe_repository_test.dart   # 對應 lib/repositories/wardrobe_repository.dart
    gemini_service_test.dart
  widget/
    wardrobe_card_test.dart         # 對應 lib/widgets/wardrobe_card.dart
    lumi_check_banner_test.dart
  integration/
    snap_flow_test.dart             # Lumi Snap 完整流程
    check_flow_test.dart            # Lumi-Check 完整流程
```

## Mock 規範

Firebase 與 Google Photos 不得在測試中發出真實網路請求。

```dart
// Firestore → 使用 fake_cloud_firestore
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

// Firebase Auth → 使用 firebase_auth_mocks
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

// Google Photos API → 手動建立 MockHttpClient
// Riverpod → 使用 ProviderContainer 覆蓋 Provider
final container = ProviderContainer(
  overrides: [
    firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
  ],
);
```

## 各功能驗收標準

### M1：Google 登入
- [ ] 登入成功 → 取得有效 userId
- [ ] 登入失敗 → 顯示錯誤訊息，不崩潰
- [ ] 已登入重啟 App → 自動恢復登入狀態

### M2：Lumi Snap
- [ ] 拍照後觸發 AI 分析（Cloud Functions 呼叫）
- [ ] AI 分析結果正確寫入 Firestore（含 category、colors、materials、embedding）
- [ ] 相片成功上傳至 Google Photos `Lumi_Wardrobe` 相簿
- [ ] `thumbnailUrl` 正確儲存，不超過 55 分鐘快取
- [ ] 上傳失敗時顯示錯誤，資料不寫入 Firestore（一致性保證）

### M3：Lumi Search
- [ ] 衣物列表正確從 Firestore 讀取
- [ ] 色彩篩選後結果正確
- [ ] 多條件組合篩選（種類 + 顏色）結果正確
- [ ] 空狀態（無衣物）顯示引導畫面，不顯示空白

### M4：Lumi-Check
- [ ] cosine similarity 計算結果正確（unit test 驗證數學）
- [ ] 相似度 ≥ 80% → 顯示 warning 橫幅
- [ ] 相似度 50–79% → 顯示「可能相似」提示
- [ ] 相似度 < 50% → 顯示「無相似款式」
- [ ] 比對完成前顯示 Glow 動畫，不凍結 UI

## 執行指令

```bash
# 執行全部測試
flutter test

# 執行特定測試檔案
flutter test test/unit/wardrobe_repository_test.dart

# 執行並顯示覆蓋率
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# 執行 Integration Test（需接模擬器）
flutter test integration_test/
```

## AI 工作流程

1. 每次實作新功能時，**同步撰寫對應的 unit test 與 widget test**
2. 實作完成後執行 `flutter test`，確認全部通過
3. 執行 `flutter analyze`，確認無靜態分析警告
4. 兩項都通過才能進行 commit

## 任務

$ARGUMENTS
