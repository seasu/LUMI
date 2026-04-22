# LUMI
Lumi (源自 Luminous) 旨在透過科技照亮衣櫥中被遺忘的角落。透過「相簿即資料庫」的創新概念，讓數位衣櫥的維護成本降至零，並利用 AI 協助使用者進行理性消費與高效管理。
https://seasu.github.io/LUMI/

## Design Source of Truth

- UI/UX implementation must follow `DESIGN.md`.
- `DESIGN.md` is the only design guideline file in this repository.
- If Figma and `DESIGN.md` are inconsistent, list the differences first and confirm with the product owner before implementing.

## Security

- API key and credential hardening checklist: see `SECURITY.md`.

## Mobile CI/CD (iOS / Android)

目前已新增 GitHub Actions workflow：

- iOS → TestFlight: `.github/workflows/mobile-testflight.yml`
- Android → Firebase App Distribution: `.github/workflows/mobile-firebase-app-distribution.yml`

> 注意：此 repo 目前未包含 `ios/`、`android/` 目錄。請先在本機執行：
>
> `flutter create . --platforms=ios,android`
>
> 若你沒有電腦，可直接在 GitHub Actions 手動執行
> `Bootstrap iOS/Android Folders` workflow，自動產生並 commit `ios/`、`android/` 目錄。

### Required GitHub Secrets

#### iOS / TestFlight

- `IOS_DISTRIBUTION_CERT_BASE64`
- `IOS_DISTRIBUTION_CERT_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

#### Android / Firebase App Distribution

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `FIREBASE_TOKEN`

### Trigger

- GitHub Actions → Run workflow
  - `iOS Deploy to TestFlight`
  - `Android Deploy to Firebase App Distribution`

### Web Deploy

`Deploy to GitHub Pages` 已改為手動觸發（`workflow_dispatch`），避免持續自動部署 web。


### Android Build Baseline

- CI 會自動將 `android/app/build.gradle.kts` 對齊為：
  - `minSdk >= 23`（Firebase Auth 23.x 需要）
  - `ndkVersion = "27.0.12077973"`（對齊目前 Firebase/Google plugin 需求）

若你在本機第一次建立 `android/` 後直接 build，請確認這兩項設定已存在。

### iOS TestFlight Troubleshooting

若 `flutter build ipa --release` 出現 `No valid code signing certificates were found`，代表目前憑證鏈仍無法用於簽章，請優先檢查：

1. `IOS_DISTRIBUTION_CERT_BASE64` 對應的是 **Apple Distribution** 憑證匯出的 `.p12`，且包含 private key。
2. `IOS_DISTRIBUTION_CERT_PASSWORD` 與匯出 `.p12` 時的密碼一致。
3. `IOS_PROVISIONING_PROFILE_BASE64` 是 **App Store** 類型 profile，且 Bundle ID/Team 與專案一致。

目前 iOS workflow 會從 `IOS_PROVISIONING_PROFILE_BASE64` 自動解析 `Team ID`、`Bundle ID`、`Profile Name`，並改用 `xcodebuild archive/export` 的手動簽章流程，降低 Flutter 預設簽章模式造成的證書辨識失敗。 
