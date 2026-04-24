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
- `FIREBASE_TOKEN`
- `FIREBASE_ANDROID_APP_ID`（可選，例：`1:1234567890:android:abcdef123456`）
- `FIREBASE_ANDROID_GOOGLE_SERVICES_JSON_BASE64`（可選，`android/app/google-services.json` 的 base64）

> `app_id` 解析優先順序：
> 1. workflow 手動輸入 `app_id`
> 2. `FIREBASE_ANDROID_APP_ID`
> 3. `FIREBASE_ANDROID_GOOGLE_SERVICES_JSON_BASE64` 解碼後的 `google-services.json`
>
> 若要產生 `FIREBASE_ANDROID_GOOGLE_SERVICES_JSON_BASE64`：
>
> - macOS / Linux：
>   ```bash
>   base64 -w 0 android/app/google-services.json
>   ```
>   （若你是 macOS 且 `-w` 不支援，改用 `base64 < android/app/google-services.json | tr -d '\n'`）
>
> - Windows PowerShell：
>   ```powershell
>   [Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/google-services.json"))
>   ```

### Trigger

- GitHub Actions → Run workflow
  - `iOS Deploy to TestFlight`
  - `Android Deploy to Firebase App Distribution`

### Web Deploy

`Deploy to GitHub Pages` 已改為手動觸發（`workflow_dispatch`），避免持續自動部署 web。
