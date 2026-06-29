// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Lumi';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get retry => '再試行';

  @override
  String get close => '閉じる';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラーが発生しました';

  @override
  String get unknownError => '不明なエラーが発生しました';

  @override
  String get and => 'と';

  @override
  String get authTitle => 'AIでワードローブを輝かせよう';

  @override
  String get authSignInGoogle => 'Googleアカウントでログイン';

  @override
  String get authSignInApple => 'Appleアカウントでログイン';

  @override
  String get authTermsPrefix => '続けることで、';

  @override
  String get authTermsLink => '利用規約';

  @override
  String get authPrivacyLink => 'プライバシーポリシー';

  @override
  String get homeTitle => 'マイワードローブ';

  @override
  String get homeAddItem => 'アイテムを追加';

  @override
  String get homeEmpty => 'ワードローブは空です';

  @override
  String homeEmptyHint(String name) {
    return 'ようこそ $name！下のボタンをタップして服を追加しましょう';
  }

  @override
  String get homeFab => 'Lumi Snap';

  @override
  String homeItemCount(int count) {
    return '$count点';
  }

  @override
  String get snapTitle => '服を追加';

  @override
  String get snapUploadAll => 'すべて分析';

  @override
  String snapSuccessCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count点の服を追加しました',
      one: '1点の服を追加しました',
    );
    return '$_temp0';
  }

  @override
  String snapQuotaBanner(int remaining) {
    return 'AI分析残り$remaining点・間もなく上限 → アップグレード';
  }

  @override
  String get snapQuotaExceeded => 'AI分析の上限に達しました';

  @override
  String get snapAnalyzing => '分析中...';

  @override
  String get snapUploadError => 'アップロードに失敗しました。もう一度お試しください。';

  @override
  String get snapTapToAdd => 'タップして写真を追加';

  @override
  String get snapAddMore => 'さらに追加';

  @override
  String get snapDone => '完了';

  @override
  String get searchTitle => 'ワードローブ';

  @override
  String get searchHint => '服を検索...';

  @override
  String get searchNoResults => '服が見つかりません';

  @override
  String get searchDeleteTitle => '服を削除';

  @override
  String get searchDeleteConfirm => 'このアイテムをワードローブから削除してもよいですか？';

  @override
  String get searchFilterAll => 'すべて';

  @override
  String get searchFilterFavorites => 'お気に入り';

  @override
  String get searchFilterUncategorized => '未分類';

  @override
  String get catDress => 'ワンピース';

  @override
  String get catTop => 'トップス';

  @override
  String get catBottom => 'ボトムス';

  @override
  String get catShoes => 'シューズ';

  @override
  String get catBag => 'バッグ';

  @override
  String get catAccessory => 'アクセサリー';

  @override
  String get catPants => 'パンツ';

  @override
  String get catOuterwear => 'アウター';

  @override
  String get colorRed => '赤';

  @override
  String get colorOrange => 'オレンジ';

  @override
  String get colorYellow => '黄';

  @override
  String get colorGreen => '緑';

  @override
  String get colorBlue => '青';

  @override
  String get colorPurple => '紫';

  @override
  String get colorPink => 'ピンク';

  @override
  String get colorBrown => 'ブラウン';

  @override
  String get colorBeige => 'ベージュ';

  @override
  String get colorBlack => '黒';

  @override
  String get colorWhite => '白';

  @override
  String get colorGray => 'グレー';

  @override
  String get profileTitle => 'プロフィール';

  @override
  String get profileMeasurements => 'ボディサイズ';

  @override
  String get profileHeight => '身長';

  @override
  String get profileWeight => '体重';

  @override
  String get profileBirthday => '誕生日';

  @override
  String get profileHead => '頭囲';

  @override
  String get profileChest => 'バスト';

  @override
  String get profileWaist => 'ウエスト';

  @override
  String get profileHips => 'ヒップ';

  @override
  String get profileInseam => '股下';

  @override
  String get profileSignOut => 'ログアウト';

  @override
  String get profileSigningOut => 'アカウントデータが見つかりません。ログアウトします…';

  @override
  String get profileDeleteAccount => 'アカウントを削除';

  @override
  String get profileDeleteTitle => 'アカウントを削除';

  @override
  String get profileDeleteConfirm => 'すべてのデータが完全に削除され、復元できません。よろしいですか？';

  @override
  String get profileDeletePermanent => '完全に削除';

  @override
  String get profileDeleting => '削除中...';

  @override
  String get profileDeleteError => '削除に失敗しました。もう一度お試しください。';

  @override
  String get profileLanguage => '言語';

  @override
  String get quotaTitle => 'AI分析クォータ';

  @override
  String quotaUsed(int used, int total) {
    return '$used / $total';
  }

  @override
  String quotaRemaining(int remaining) {
    return '残り$remaining点';
  }

  @override
  String get quotaUnlimited => '無制限（Pro）';

  @override
  String get quotaUpgradeHint => 'Proにアップグレードまたは補充パックを購入';

  @override
  String get quotaUpgradeButton => 'アップグレード';

  @override
  String get quotaProActive => '無制限のAI分析、Proメンバーシップをお楽しみください';

  @override
  String get paywallTitle => 'デジタルワードローブに\nもっとスペースが必要です';

  @override
  String get paywallSubtitle => '最適なプランを選んでクローゼットを拡張しましょう';

  @override
  String get paywallProName => 'Lumi Pro 年間プラン';

  @override
  String get paywallProPrice => 'NT\$199 / 年';

  @override
  String get paywallProDesc => '無制限のAI分析、1年間お楽しみください';

  @override
  String get paywallProBadge => 'お得';

  @override
  String get paywallExtraName => '補充パック';

  @override
  String get paywallExtraPrice => 'NT\$99';

  @override
  String get paywallExtraDesc => '+100回のAI分析、買い切り';

  @override
  String get paywallFreeContinue => '無料のまま続ける';

  @override
  String get paywallRestorePurchases => '購入を復元';

  @override
  String get paywallRestoringPurchases => '購入を復元中…';

  @override
  String get paywallSuccessPro => '🎉 Proにアップグレード！無制限のAI分析をお楽しみください';

  @override
  String get paywallSuccessExtra => '✅ AI分析100回分を補充しました';

  @override
  String get paywallRestoreSuccess => '✅ 購入を正常に復元しました';

  @override
  String get paywallErrorGeneric => '購入に失敗しました。もう一度お試しください。';

  @override
  String get paywallVerifyFailed => '購入の確認に失敗しました。後ほど再試行するか、サポートにお問い合わせください。';

  @override
  String get paywallRestoreFailed => '購入の復元に失敗しました。後ほど再試行するか、サポートにお問い合わせください。';

  @override
  String get paywallSubscriptionExpired => 'サブスクリプションの有効期限が切れています。Pro機能を継続するには再登録してください。';

  @override
  String get paywallAutoRenewNotice => 'Lumi Proは自動更新サブスクリプションです。各期間終了の24時間前にApple IDに課金され、App Storeのアカウント設定からいつでも解約できます。';

  @override
  String get outfitTitle => 'コーディネート';

  @override
  String get outfitCreate => 'コーデを作成';

  @override
  String get outfitEmpty => 'コーディネートはまだありません';

  @override
  String get outfitEmptyHint => '+ をタップして最初のコーデを作成';

  @override
  String get outfitShare => 'シェア';

  @override
  String get outfitDelete => 'コーデを削除';

  @override
  String get outfitDeleteConfirm => 'このコーディネートを削除しますか？';

  @override
  String get outfitNewTitle => '新しいコーデ';

  @override
  String get outfitEditTitle => 'コーデを編集';

  @override
  String get outfitDate => '日付';

  @override
  String get outfitNote => 'メモ';

  @override
  String get checkTitle => 'Lumi Check';

  @override
  String get checkSubtitle => '買う前にスキャンして比較';

  @override
  String get checkSimilarItems => 'ワードローブの類似アイテム';

  @override
  String get checkNoSimilar => '類似アイテムは見つかりませんでした';

  @override
  String checkSimilarityLabel(int percent) {
    return '$percent% 類似';
  }

  @override
  String get checkTapToScan => 'タップしてスキャン';

  @override
  String get checkScanning => 'スキャン中...';

  @override
  String get onboardingStep1Title => 'ゼロ摩擦のデジタルワードローブ';

  @override
  String get onboardingStep1Desc => 'Lumiは Googleフォトと自動同期 — 手動アップロード不要。';

  @override
  String get onboardingStep2Title => 'AIスマート分析';

  @override
  String get onboardingStep2Desc => 'LumiはGemini AIで色・素材・スタイルを自動識別し、検索を簡単に。';

  @override
  String get onboardingStep3Title => '賢く買い物、重複なし';

  @override
  String get onboardingStep3Desc => '「Lumi Check」でショッピング中にワードローブとリアルタイム比較。';

  @override
  String get onboardingNext => '次へ';

  @override
  String get onboardingStart => 'はじめる';

  @override
  String itemDetailEditTitle(String label) {
    return '$labelを編集';
  }

  @override
  String get itemDetailCategory => 'カテゴリー';

  @override
  String get itemDetailColors => 'カラー';

  @override
  String get itemDetailMaterials => '素材';

  @override
  String get itemDetailBrand => 'ブランド';

  @override
  String get itemDetailNote => 'メモ';

  @override
  String get itemDetailAnalyzed => 'AI分析済み';

  @override
  String get itemDetailNotAnalyzed => '未分析';

  @override
  String get itemDetailDeleteTitle => '服を削除';

  @override
  String get itemDetailDeleteConfirm => 'このアイテムをワードローブから削除してもよいですか？';

  @override
  String get errorQuotaExceeded => 'AI分析の上限に達しました。補充パックを購入するかProにアップグレードしてください。';

  @override
  String get errorNetworkFailed => 'ネットワークエラー。接続を確認してください。';

  @override
  String get errorAuthRequired => '続けるにはログインしてください。';

  @override
  String get errorPurchaseFailed => '購入に失敗しました。もう一度お試しください。';

  @override
  String get errorDeleteFailed => '削除に失敗しました。もう一度お試しください。';

  @override
  String get snapIdleTitle => '追加方法を選択';

  @override
  String get snapIdleSubtitle => '一度に最大10枚、AIがバックグラウンドで自動分類';

  @override
  String get snapCamera => '写真を撮る';

  @override
  String get snapLibrary => 'ライブラリから選択';

  @override
  String snapSelectedCount(int count, int max) {
    return '$count / $max 枚選択中';
  }

  @override
  String get snapAddToWardrobe => 'ワードローブに追加';

  @override
  String get snapAddMoreTile => '追加';

  @override
  String get snapRetry => '再選択';

  @override
  String get snapAppBarAdding => '追加中...';

  @override
  String get snapAppBarDone => '追加完了';

  @override
  String get snapQuotaExhaustedBanner => 'AI分析の上限に達しました — 追加はできますが分析されません';

  @override
  String get snapUpgradeArrow => 'アップグレード →';

  @override
  String get paywallBuyPro => '今すぐアップグレード';

  @override
  String get paywallBuyExtra => '購入';

  @override
  String get paywallProPriceSub => '/ 年';

  @override
  String get paywallExtraPriceSub => '買い切り';

  @override
  String get profileVersion => 'バージョン';

  @override
  String profileDebugHint(int count) {
    return 'あと $count 回タップでデバッグログを開く';
  }

  @override
  String get profileDeleteConfirmTitle => 'アカウントを削除しますか？';

  @override
  String get profileDeleteConfirmBody => 'この操作は元に戻せません。アカウントデータは完全に削除されます。端末上の服の写真や記録は影響を受けません。';

  @override
  String get profileDeletePermanentButton => 'アカウントを完全に削除';

  @override
  String get measureHeight => '身長';

  @override
  String get measureWeight => '体重';

  @override
  String get measureBirthday => '誕生日';

  @override
  String get measureHead => '頭囲';

  @override
  String get measureChest => 'バスト';

  @override
  String get measureWaist => 'ウエスト';

  @override
  String get measureHips => 'ヒップ';

  @override
  String get measureInseam => '股下';

  @override
  String get searchEmptyHint => '右下の + ボタンをタップしてデジタルワードローブを始めましょう';

  @override
  String get searchViewAll => 'すべて表示';

  @override
  String get searchFavoritesEmptyTitle => 'お気に入りはまだありません';

  @override
  String get searchFavoritesEmptyHint => '衣物カードのハートアイコンをタップしてお気に入りに追加';

  @override
  String get searchAiDoneTitle => 'AI分析が完了しました！';

  @override
  String get searchAiDoneHint => '衣物が分類されました\n下のボタンから確認しましょう';

  @override
  String get searchFilterEmptyTitle => 'このカテゴリーに服はありません';

  @override
  String get searchFilterEmptyHint => '別のカテゴリーを選ぶか、フィルターをクリアしてください';

  @override
  String get checkScanTitle => 'AI比較中';

  @override
  String get checkScanSubtitle => 'ワードローブから似たスタイルを検索中...';

  @override
  String get checkWantToBuy => '購入予定';

  @override
  String get checkClosestInWardrobe => '最近似アイテム';

  @override
  String checkHighSimilarBanner(String percent) {
    return 'ワードローブに$percent%の類似品あり — 購入前に確認を！';
  }

  @override
  String checkMediumSimilarBanner(String percent) {
    return 'ワードローブに$percent%の類似品あり — じっくり比較してみて。';
  }

  @override
  String get checkAlreadyHave => 'すでに持っている';

  @override
  String get checkAddedSuccess => 'ワードローブに追加しました';

  @override
  String get checkNoSimilarHint => 'ワードローブに似た服はありませんでした。\n安心して購入できます！';

  @override
  String get checkBackToWardrobe => 'ワードローブに戻る';

  @override
  String get checkAdding => '追加中...';

  @override
  String get itemDetailEditBadge => 'AI結果を編集';

  @override
  String get itemDetailAnalyzing => 'AI分析中…';

  @override
  String get itemDetailAnalyzeFailed => '分析失敗、下にスワイプして再試行';

  @override
  String get outfitNoCaption => 'コメントなし';

  @override
  String get back => '戻る';

  @override
  String get done => '完了';

  @override
  String get outfitShareTitle => 'コーデをシェア';

  @override
  String get outfitShareCaptionHint => 'キャプションを追加...';

  @override
  String get outfitShareDone => '完了';

  @override
  String get outfitShareSuccess => 'コーデのシェアに成功しました！';

  @override
  String get outfitShareFailed => 'シェアに失敗しました。もう一度お試しください。';

  @override
  String get outfitShareSubject => '私のLumiコーデ';

  @override
  String get outfitShareBrandSlogan => 'AIで毎日のスタイルを記録';
}
