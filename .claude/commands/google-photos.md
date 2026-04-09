# Google Photos API Skill

你是 Google Photos Library API 的專家顧問。協助 Lumi 正確使用這個 API，避開已知限制與陷阱。

## 最重要的限制（必讀）

**App 只能讀取自己上傳的相片。**
Google Photos Library API 自 2021 年 3 月起，不再允許第三方 App 讀取使用者的完整相簿。Lumi 只能存取透過 Lumi App 本身上傳的 `mediaItem`。這是硬限制，無法繞過。

## OAuth Scope

| Scope | 說明 | Lumi 是否使用 |
|-------|------|-------------|
| `photoslibrary.appendonly` | 只能上傳，不能讀取 | 上傳衣物照片 |
| `photoslibrary.readonly` | 讀取 App 自己上傳的內容 | 讀取 Lumi_Wardrobe |
| `photoslibrary` | 完整讀寫（已限制，新 App 無法申請） | 禁止使用 |

## 常用端點

### 建立相簿
```
POST https://photoslibrary.googleapis.com/v1/albums
Body: { "album": { "title": "Lumi_Wardrobe" } }
```

### 上傳相片（兩步驟）
```
# Step 1：上傳 bytes，取得 uploadToken
POST https://photoslibrary.googleapis.com/v1/uploads
Header: X-Goog-Upload-Protocol: raw
        X-Goog-Upload-File-Name: photo.jpg

# Step 2：建立 mediaItem
POST https://photoslibrary.googleapis.com/v1/mediaItems:batchCreate
Body: {
  "albumId": "xxx",
  "newMediaItems": [{
    "simpleMediaItem": { "uploadToken": "xxx" }
  }]
}
```

### 列出相簿內的相片
```
POST https://photoslibrary.googleapis.com/v1/mediaItems:search
Body: { "albumId": "xxx", "pageSize": 50 }
```

### 取得單一 mediaItem
```
GET https://photoslibrary.googleapis.com/v1/mediaItems/{mediaItemId}
```

## 已知陷阱

### thumbnailUrl 有效期只有 60 分鐘
`baseUrl` 回傳的 URL 會在約 60 分鐘後失效。
- **不可**持久化至 Firestore 或本機快取超過 55 分鐘
- 需要顯示圖片時，呼叫 `GET /v1/mediaItems/{id}` 取得新的 `baseUrl`
- 建議在 Riverpod Provider 層做自動刷新邏輯

### description 欄位為唯讀
App 無法透過 API 更新 `mediaItem` 的 `description`。所有 metadata 必須存 Firestore。

### 相簿 ID 不穩定
`albumId` 可能在使用者操作後改變，建議在 Firestore 存一份 `albumId`，並在 App 啟動時驗證其有效性，失效則重新搜尋。

### 分頁處理
所有列表 API 都有 `pageToken`，必須實作分頁迴圈才能取得完整資料。

## Flutter 套件

```yaml
# pubspec.yaml
dependencies:
  google_sign_in: ^6.x        # OAuth 認證
  http: ^1.x                  # 直接呼叫 Photos REST API
  # 注意：目前無官方 Google Photos Flutter SDK，需手動封裝 HTTP 呼叫
```

## 任務

$ARGUMENTS
