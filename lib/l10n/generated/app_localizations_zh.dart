// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Lumi';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確認';

  @override
  String get save => '儲存';

  @override
  String get delete => '刪除';

  @override
  String get retry => '重試';

  @override
  String get close => '關閉';

  @override
  String get loading => '載入中...';

  @override
  String get error => '發生錯誤';

  @override
  String get unknownError => '發生未知錯誤';

  @override
  String get and => '及';

  @override
  String get authTitle => '用 AI 點亮妳的衣櫥';

  @override
  String get authSignInGoogle => '使用 Google 帳號登入';

  @override
  String get authSignInApple => '使用 Apple 帳號登入';

  @override
  String get authTermsPrefix => '繼續即表示您同意我們的';

  @override
  String get authTermsLink => '使用條款';

  @override
  String get authPrivacyLink => '隱私政策';

  @override
  String get homeTitle => '我的衣櫥';

  @override
  String get homeAddItem => '加入新品';

  @override
  String get homeEmpty => '衣櫥是空的';

  @override
  String homeEmptyHint(String name) {
    return '歡迎 $name，點下方按鈕開始拍照入庫';
  }

  @override
  String get homeFab => 'Lumi Snap';

  @override
  String homeItemCount(int count) {
    return '$count 件';
  }

  @override
  String get snapTitle => '新增衣物';

  @override
  String get snapUploadAll => '全部分析';

  @override
  String snapSuccessCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已成功加入 $count 件衣物',
      one: '已成功加入 1 件衣物',
    );
    return '$_temp0';
  }

  @override
  String snapQuotaBanner(int remaining) {
    return 'AI 分析剩餘 $remaining 件，即將用完 · 升級 →';
  }

  @override
  String get snapQuotaExceeded => 'AI 分析配額已用完';

  @override
  String get snapAnalyzing => '分析中...';

  @override
  String get snapUploadError => '上傳失敗，請再試一次。';

  @override
  String get snapTapToAdd => '點擊新增照片';

  @override
  String get snapAddMore => '繼續新增';

  @override
  String get snapDone => '完成';

  @override
  String get searchTitle => '衣櫥';

  @override
  String get searchHint => '搜尋衣物...';

  @override
  String get searchNoResults => '找不到衣物';

  @override
  String get searchDeleteTitle => '刪除衣物';

  @override
  String get searchDeleteConfirm => '確定要從衣櫥中刪除這件衣物嗎？';

  @override
  String get searchFilterAll => '全部';

  @override
  String get searchFilterFavorites => '我的最愛';

  @override
  String get searchFilterUncategorized => '未分類';

  @override
  String get catDress => '連身裙';

  @override
  String get catTop => '上衣';

  @override
  String get catBottom => '下身';

  @override
  String get catShoes => '鞋履';

  @override
  String get catBag => '包款';

  @override
  String get catAccessory => '配件';

  @override
  String get catPants => '褲子';

  @override
  String get catOuterwear => '外套';

  @override
  String get colorRed => '紅';

  @override
  String get colorOrange => '橘';

  @override
  String get colorYellow => '黃';

  @override
  String get colorGreen => '綠';

  @override
  String get colorBlue => '藍';

  @override
  String get colorPurple => '紫';

  @override
  String get colorPink => '粉';

  @override
  String get colorBrown => '棕';

  @override
  String get colorBeige => '米';

  @override
  String get colorBlack => '黑';

  @override
  String get colorWhite => '白';

  @override
  String get colorGray => '灰';

  @override
  String get profileTitle => '個人檔案';

  @override
  String get profileMeasurements => '個人身材數據';

  @override
  String get profileHeight => '身高';

  @override
  String get profileWeight => '體重';

  @override
  String get profileBirthday => '生日';

  @override
  String get profileHead => '頭圍';

  @override
  String get profileChest => '胸圍';

  @override
  String get profileWaist => '腰圍';

  @override
  String get profileHips => '臀圍';

  @override
  String get profileInseam => '腿長';

  @override
  String get profileSignOut => '登出';

  @override
  String get profileDeleteAccount => '刪除帳號';

  @override
  String get profileDeleteTitle => '刪除帳號';

  @override
  String get profileDeleteConfirm => '所有資料將永久刪除且無法恢復，確定要繼續嗎？';

  @override
  String get profileDeletePermanent => '永久刪除';

  @override
  String get profileDeleting => '刪除中...';

  @override
  String get profileDeleteError => '刪除失敗，請再試一次。';

  @override
  String get profileLanguage => '語言';

  @override
  String get quotaTitle => 'AI 分析配額';

  @override
  String quotaUsed(int used, int total) {
    return '$used / $total';
  }

  @override
  String quotaRemaining(int remaining) {
    return '剩餘 $remaining 件';
  }

  @override
  String get quotaUnlimited => '無限次（Pro）';

  @override
  String get quotaUpgradeHint => '升級 Pro 或購買補充包';

  @override
  String get quotaUpgradeButton => '升級';

  @override
  String get quotaProActive => '無限 AI 分析，享受 Pro 會員';

  @override
  String get paywallTitle => '你的數位衣物庫\n需要更多空間';

  @override
  String get paywallSubtitle => '選擇最適合你的方案，繼續擴充衣物庫';

  @override
  String get paywallProName => 'Lumi Pro 年費方案';

  @override
  String get paywallProPrice => 'NT\$199 / 年';

  @override
  String get paywallProDesc => '無限 AI 分析配額，一年暢用';

  @override
  String get paywallProBadge => '最划算';

  @override
  String get paywallExtraName => '補充包';

  @override
  String get paywallExtraPrice => 'NT\$99';

  @override
  String get paywallExtraDesc => '+100 次 AI 分析，一次性';

  @override
  String get paywallFreeContinue => '繼續免費使用';

  @override
  String get paywallRestorePurchases => '還原購買';

  @override
  String get paywallSuccessPro => '🎉 已升級為 Pro！享受無限 AI 分析';

  @override
  String get paywallSuccessExtra => '✅ 已補充 100 次 AI 分析配額';

  @override
  String get paywallErrorGeneric => '購買失敗，請再試一次。';

  @override
  String get outfitTitle => '我的穿搭';

  @override
  String get outfitCreate => '新增穿搭';

  @override
  String get outfitEmpty => '還沒有穿搭紀錄';

  @override
  String get outfitEmptyHint => '點擊 + 建立第一套穿搭';

  @override
  String get outfitShare => '分享';

  @override
  String get outfitDelete => '刪除穿搭';

  @override
  String get outfitDeleteConfirm => '確定要刪除這套穿搭嗎？';

  @override
  String get outfitNewTitle => '新增穿搭';

  @override
  String get outfitEditTitle => '編輯穿搭';

  @override
  String get outfitDate => '日期';

  @override
  String get outfitNote => '備註';

  @override
  String get checkTitle => 'Lumi Check';

  @override
  String get checkSubtitle => '購物前先掃描比對';

  @override
  String get checkSimilarItems => '衣櫥中的相似單品';

  @override
  String get checkNoSimilar => '找不到相似單品';

  @override
  String checkSimilarityLabel(int percent) {
    return '$percent% 相似';
  }

  @override
  String get checkTapToScan => '點擊掃描';

  @override
  String get checkScanning => '掃描中...';

  @override
  String get onboardingStep1Title => '零摩擦數位化衣櫥';

  @override
  String get onboardingStep1Desc => 'LUMI 與 Google 相片自動同步，妳無需手動上傳任何內容。';

  @override
  String get onboardingStep2Title => 'AI 智慧分析';

  @override
  String get onboardingStep2Desc => 'Lumi 透過 Gemini AI 自動辨識顏色、材質與款式，讓搜尋變得毫不費力。';

  @override
  String get onboardingStep3Title => '聰明消費不重複';

  @override
  String get onboardingStep3Desc => '「似曾相識」讓妳在購物現場即時比對衣櫥，避免買到重複款式。';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingStart => '開始使用';

  @override
  String itemDetailEditTitle(String label) {
    return '修改$label';
  }

  @override
  String get itemDetailCategory => '分類';

  @override
  String get itemDetailColors => '顏色';

  @override
  String get itemDetailMaterials => '材質';

  @override
  String get itemDetailBrand => '品牌';

  @override
  String get itemDetailNote => '備註';

  @override
  String get itemDetailAnalyzed => 'AI 已分析';

  @override
  String get itemDetailNotAnalyzed => '尚未分析';

  @override
  String get itemDetailDeleteTitle => '刪除衣物';

  @override
  String get itemDetailDeleteConfirm => '確定要從衣櫥中刪除這件衣物嗎？';

  @override
  String get errorQuotaExceeded => 'AI 分析配額已用完，請購買補充包或升級 Pro。';

  @override
  String get errorNetworkFailed => '網路連線失敗，請檢查網路狀態。';

  @override
  String get errorAuthRequired => '請先登入後再繼續。';

  @override
  String get errorPurchaseFailed => '購買失敗，請再試一次。';

  @override
  String get errorDeleteFailed => '刪除失敗，請再試一次。';

  @override
  String get snapIdleTitle => '選擇加入方式';

  @override
  String get snapIdleSubtitle => '一次最多 10 張，AI 會在背景自動分類';

  @override
  String get snapCamera => '拍照';

  @override
  String get snapLibrary => '從相簿選取';

  @override
  String snapSelectedCount(int count, int max) {
    return '已選取 $count / $max 張';
  }

  @override
  String get snapAddToWardrobe => '加入衣櫥';

  @override
  String get snapAddMoreTile => '新增';

  @override
  String get snapRetry => '重新選取';

  @override
  String get snapAppBarAdding => '加入衣櫥中';

  @override
  String get snapAppBarDone => '加入完成';

  @override
  String get snapQuotaExhaustedBanner => 'AI 分析配額已用完，加入後無法分析';

  @override
  String get snapUpgradeArrow => '升級 →';

  @override
  String get paywallBuyPro => '立即升級';

  @override
  String get paywallBuyExtra => '購買';

  @override
  String get paywallProPriceSub => '/ 年';

  @override
  String get paywallExtraPriceSub => '一次性';

  @override
  String get profileVersion => '版本';

  @override
  String profileDebugHint(int count) {
    return '再點 $count 次開啟 Debug Log';
  }

  @override
  String get profileDeleteConfirmTitle => '確定要刪除帳號嗎？';

  @override
  String get profileDeleteConfirmBody => '此操作無法復原。您的帳號資料將永久刪除，裝置上的衣物照片與記錄不受影響。';

  @override
  String get profileDeletePermanentButton => '永久刪除帳號';

  @override
  String get measureHeight => '身高';

  @override
  String get measureWeight => '體重';

  @override
  String get measureBirthday => '生日';

  @override
  String get measureHead => '頭圍';

  @override
  String get measureChest => '胸圍';

  @override
  String get measureWaist => '腰圍';

  @override
  String get measureHips => '臀圍';

  @override
  String get measureInseam => '腿長';

  @override
  String get searchEmptyHint => '點擊右下角的 + 按鈕開始建立妳的數位衣櫥';

  @override
  String get searchViewAll => '查看全部衣物';

  @override
  String get searchFavoritesEmptyTitle => '還沒有收藏的衣物';

  @override
  String get searchFavoritesEmptyHint => '點擊衣物卡片右下角的愛心，將喜歡的單品加入最愛';

  @override
  String get searchAiDoneTitle => 'AI 辨識完成！';

  @override
  String get searchAiDoneHint => '衣物已歸類到對應分類\n快點擊下方按鈕去看看吧';

  @override
  String get searchFilterEmptyTitle => '這個分類目前沒有衣物';

  @override
  String get searchFilterEmptyHint => '換個分類看看，或清除篩選條件';

  @override
  String get checkScanTitle => 'AI 比對中';

  @override
  String get checkScanSubtitle => '正在從衣櫥中尋找相似款式...';

  @override
  String get checkWantToBuy => '想買的';

  @override
  String get checkClosestInWardrobe => '衣櫥最相似';

  @override
  String checkHighSimilarBanner(String percent) {
    return '衣櫥已有 $percent% 相似款，確認再入手！';
  }

  @override
  String checkMediumSimilarBanner(String percent) {
    return '衣櫥有 $percent% 相似款，可以再比較看看。';
  }

  @override
  String get checkAlreadyHave => '已經有了';

  @override
  String get checkAddedSuccess => '已成功加入衣櫥';

  @override
  String get checkNoSimilarHint => '這件衣物在妳的衣櫥裡找不到相似款，\n可以安心入手！';

  @override
  String get checkBackToWardrobe => '返回衣櫥';

  @override
  String get checkAdding => '加入中...';

  @override
  String get itemDetailEditBadge => '編輯辨識結果';

  @override
  String get itemDetailAnalyzing => 'AI 分析中…';

  @override
  String get itemDetailAnalyzeFailed => '分析失敗，可下拉重試';

  @override
  String get outfitNoCaption => '無備註';

  @override
  String get back => '返回';

  @override
  String get done => '完成';

  @override
  String get outfitShareTitle => '分享穿搭';

  @override
  String get outfitShareCaptionHint => '新增說明文字...';

  @override
  String get outfitShareDone => '完成';

  @override
  String get outfitShareSuccess => '穿搭已成功分享！';

  @override
  String get outfitShareFailed => '分享失敗，請再試一次。';

  @override
  String get outfitShareSubject => '我的 Lumi 穿搭';

  @override
  String get outfitShareBrandSlogan => '用AI記錄每日穿搭風格';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn(): super('zh_CN');

  @override
  String get appName => 'Lumi';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get retry => '重试';

  @override
  String get close => '关闭';

  @override
  String get loading => '加载中...';

  @override
  String get error => '发生错误';

  @override
  String get unknownError => '发生未知错误';

  @override
  String get and => '及';

  @override
  String get authTitle => '用 AI 点亮你的衣橱';

  @override
  String get authSignInGoogle => '使用 Google 账号登录';

  @override
  String get authSignInApple => '使用 Apple 账号登录';

  @override
  String get authTermsPrefix => '继续即表示您同意我们的';

  @override
  String get authTermsLink => '使用条款';

  @override
  String get authPrivacyLink => '隐私政策';

  @override
  String get homeTitle => '我的衣橱';

  @override
  String get homeAddItem => '添加新品';

  @override
  String get homeEmpty => '衣橱是空的';

  @override
  String homeEmptyHint(String name) {
    return '欢迎 $name，点击下方按钮开始拍照入库';
  }

  @override
  String get homeFab => 'Lumi Snap';

  @override
  String homeItemCount(int count) {
    return '$count 件';
  }

  @override
  String get snapTitle => '添加服装';

  @override
  String get snapUploadAll => '全部分析';

  @override
  String snapSuccessCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已成功添加 $count 件服装',
      one: '已成功添加 1 件服装',
    );
    return '$_temp0';
  }

  @override
  String snapQuotaBanner(int remaining) {
    return 'AI 分析剩余 $remaining 件，即将用完 · 升级 →';
  }

  @override
  String get snapQuotaExceeded => 'AI 分析配额已用完';

  @override
  String get snapAnalyzing => '分析中...';

  @override
  String get snapUploadError => '上传失败，请再试一次。';

  @override
  String get snapTapToAdd => '点击添加照片';

  @override
  String get snapAddMore => '继续添加';

  @override
  String get snapDone => '完成';

  @override
  String get searchTitle => '衣橱';

  @override
  String get searchHint => '搜索服装...';

  @override
  String get searchNoResults => '找不到服装';

  @override
  String get searchDeleteTitle => '删除服装';

  @override
  String get searchDeleteConfirm => '确定要从衣橱中删除这件服装吗？';

  @override
  String get searchFilterAll => '全部';

  @override
  String get searchFilterFavorites => '我的收藏';

  @override
  String get searchFilterUncategorized => '未分类';

  @override
  String get catDress => '连衣裙';

  @override
  String get catTop => '上衣';

  @override
  String get catBottom => '下装';

  @override
  String get catShoes => '鞋履';

  @override
  String get catBag => '包袋';

  @override
  String get catAccessory => '配饰';

  @override
  String get catPants => '裤子';

  @override
  String get catOuterwear => '外套';

  @override
  String get colorRed => '红';

  @override
  String get colorOrange => '橙';

  @override
  String get colorYellow => '黄';

  @override
  String get colorGreen => '绿';

  @override
  String get colorBlue => '蓝';

  @override
  String get colorPurple => '紫';

  @override
  String get colorPink => '粉';

  @override
  String get colorBrown => '棕';

  @override
  String get colorBeige => '米';

  @override
  String get colorBlack => '黑';

  @override
  String get colorWhite => '白';

  @override
  String get colorGray => '灰';

  @override
  String get profileTitle => '个人档案';

  @override
  String get profileMeasurements => '个人身材数据';

  @override
  String get profileHeight => '身高';

  @override
  String get profileWeight => '体重';

  @override
  String get profileBirthday => '生日';

  @override
  String get profileHead => '头围';

  @override
  String get profileChest => '胸围';

  @override
  String get profileWaist => '腰围';

  @override
  String get profileHips => '臀围';

  @override
  String get profileInseam => '腿长';

  @override
  String get profileSignOut => '退出登录';

  @override
  String get profileDeleteAccount => '删除账号';

  @override
  String get profileDeleteTitle => '删除账号';

  @override
  String get profileDeleteConfirm => '所有数据将永久删除且无法恢复，确定要继续吗？';

  @override
  String get profileDeletePermanent => '永久删除';

  @override
  String get profileDeleting => '删除中...';

  @override
  String get profileDeleteError => '删除失败，请再试一次。';

  @override
  String get profileLanguage => '语言';

  @override
  String get quotaTitle => 'AI 分析配额';

  @override
  String quotaUsed(int used, int total) {
    return '$used / $total';
  }

  @override
  String quotaRemaining(int remaining) {
    return '剩余 $remaining 件';
  }

  @override
  String get quotaUnlimited => '无限次（Pro）';

  @override
  String get quotaUpgradeHint => '升级 Pro 或购买补充包';

  @override
  String get quotaUpgradeButton => '升级';

  @override
  String get quotaProActive => '无限 AI 分析，享受 Pro 会员';

  @override
  String get paywallTitle => '你的数字衣橱\n需要更多空间';

  @override
  String get paywallSubtitle => '选择最适合你的方案，继续扩充衣橱';

  @override
  String get paywallProName => 'Lumi Pro 年费方案';

  @override
  String get paywallProPrice => 'NT\$199 / 年';

  @override
  String get paywallProDesc => '无限 AI 分析配额，一年畅用';

  @override
  String get paywallProBadge => '最划算';

  @override
  String get paywallExtraName => '补充包';

  @override
  String get paywallExtraPrice => 'NT\$99';

  @override
  String get paywallExtraDesc => '+100 次 AI 分析，一次性';

  @override
  String get paywallFreeContinue => '继续免费使用';

  @override
  String get paywallRestorePurchases => '恢复购买';

  @override
  String get paywallSuccessPro => '🎉 已升级为 Pro！享受无限 AI 分析';

  @override
  String get paywallSuccessExtra => '✅ 已补充 100 次 AI 分析配额';

  @override
  String get paywallErrorGeneric => '购买失败，请再试一次。';

  @override
  String get outfitTitle => '我的穿搭';

  @override
  String get outfitCreate => '新增穿搭';

  @override
  String get outfitEmpty => '还没有穿搭记录';

  @override
  String get outfitEmptyHint => '点击 + 创建第一套穿搭';

  @override
  String get outfitShare => '分享';

  @override
  String get outfitDelete => '删除穿搭';

  @override
  String get outfitDeleteConfirm => '确定要删除这套穿搭吗？';

  @override
  String get outfitNewTitle => '新增穿搭';

  @override
  String get outfitEditTitle => '编辑穿搭';

  @override
  String get outfitDate => '日期';

  @override
  String get outfitNote => '备注';

  @override
  String get checkTitle => 'Lumi Check';

  @override
  String get checkSubtitle => '购物前先扫描比对';

  @override
  String get checkSimilarItems => '衣橱中的相似单品';

  @override
  String get checkNoSimilar => '找不到相似单品';

  @override
  String checkSimilarityLabel(int percent) {
    return '$percent% 相似';
  }

  @override
  String get checkTapToScan => '点击扫描';

  @override
  String get checkScanning => '扫描中...';

  @override
  String get onboardingStep1Title => '零摩擦数字化衣橱';

  @override
  String get onboardingStep1Desc => 'LUMI 与 Google 相册自动同步，你无需手动上传任何内容。';

  @override
  String get onboardingStep2Title => 'AI 智能分析';

  @override
  String get onboardingStep2Desc => 'Lumi 通过 Gemini AI 自动识别颜色、材质与款式，让搜索变得毫不费力。';

  @override
  String get onboardingStep3Title => '聪明消费不重复';

  @override
  String get onboardingStep3Desc => '「似曾相识」让你在购物现场即时比对衣橱，避免买到重复款式。';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingStart => '开始使用';

  @override
  String itemDetailEditTitle(String label) {
    return '修改$label';
  }

  @override
  String get itemDetailCategory => '分类';

  @override
  String get itemDetailColors => '颜色';

  @override
  String get itemDetailMaterials => '材质';

  @override
  String get itemDetailBrand => '品牌';

  @override
  String get itemDetailNote => '备注';

  @override
  String get itemDetailAnalyzed => 'AI 已分析';

  @override
  String get itemDetailNotAnalyzed => '尚未分析';

  @override
  String get itemDetailDeleteTitle => '删除服装';

  @override
  String get itemDetailDeleteConfirm => '确定要从衣橱中删除这件服装吗？';

  @override
  String get errorQuotaExceeded => 'AI 分析配额已用完，请购买补充包或升级 Pro。';

  @override
  String get errorNetworkFailed => '网络连接失败，请检查网络状态。';

  @override
  String get errorAuthRequired => '请先登录后再继续。';

  @override
  String get errorPurchaseFailed => '购买失败，请再试一次。';

  @override
  String get errorDeleteFailed => '删除失败，请再试一次。';

  @override
  String get snapIdleTitle => '选择添加方式';

  @override
  String get snapIdleSubtitle => '一次最多 10 张，AI 会在后台自动分类';

  @override
  String get snapCamera => '拍照';

  @override
  String get snapLibrary => '从相册选取';

  @override
  String snapSelectedCount(int count, int max) {
    return '已选取 $count / $max 张';
  }

  @override
  String get snapAddToWardrobe => '添加到衣橱';

  @override
  String get snapAddMoreTile => '添加';

  @override
  String get snapRetry => '重新选取';

  @override
  String get snapAppBarAdding => '添加到衣橱中';

  @override
  String get snapAppBarDone => '添加完成';

  @override
  String get snapQuotaExhaustedBanner => 'AI 分析配额已用完，添加后无法分析';

  @override
  String get snapUpgradeArrow => '升级 →';

  @override
  String get paywallBuyPro => '立即升级';

  @override
  String get paywallBuyExtra => '购买';

  @override
  String get paywallProPriceSub => '/ 年';

  @override
  String get paywallExtraPriceSub => '一次性';

  @override
  String get profileVersion => '版本';

  @override
  String profileDebugHint(int count) {
    return '再点 $count 次开启 Debug Log';
  }

  @override
  String get profileDeleteConfirmTitle => '确定要删除账号吗？';

  @override
  String get profileDeleteConfirmBody => '此操作无法撤销。您的账号数据将永久删除，设备上的服装照片与记录不受影响。';

  @override
  String get profileDeletePermanentButton => '永久删除账号';

  @override
  String get measureHeight => '身高';

  @override
  String get measureWeight => '体重';

  @override
  String get measureBirthday => '生日';

  @override
  String get measureHead => '头围';

  @override
  String get measureChest => '胸围';

  @override
  String get measureWaist => '腰围';

  @override
  String get measureHips => '臀围';

  @override
  String get measureInseam => '腿长';

  @override
  String get searchEmptyHint => '点击右下角的 + 按钮开始建立你的数字衣橱';

  @override
  String get searchViewAll => '查看全部服装';

  @override
  String get searchFavoritesEmptyTitle => '还没有收藏的服装';

  @override
  String get searchFavoritesEmptyHint => '点击服装卡片右下角的爱心，将喜欢的单品加入收藏';

  @override
  String get searchAiDoneTitle => 'AI 识别完成！';

  @override
  String get searchAiDoneHint => '服装已归类到对应分类\n快点击下方按钮去看看吧';

  @override
  String get searchFilterEmptyTitle => '这个分类目前没有服装';

  @override
  String get searchFilterEmptyHint => '换个分类看看，或清除筛选条件';

  @override
  String get checkScanTitle => 'AI 比对中';

  @override
  String get checkScanSubtitle => '正在从衣橱中寻找相似款式...';

  @override
  String get checkWantToBuy => '想买的';

  @override
  String get checkClosestInWardrobe => '衣橱最相似';

  @override
  String checkHighSimilarBanner(String percent) {
    return '衣橱已有 $percent% 相似款，确认再入手！';
  }

  @override
  String checkMediumSimilarBanner(String percent) {
    return '衣橱有 $percent% 相似款，可以再比较看看。';
  }

  @override
  String get checkAlreadyHave => '已经有了';

  @override
  String get checkAddedSuccess => '已成功加入衣橱';

  @override
  String get checkNoSimilarHint => '这件服装在你的衣橱里找不到相似款，\n可以放心入手！';

  @override
  String get checkBackToWardrobe => '返回衣橱';

  @override
  String get checkAdding => '加入中...';

  @override
  String get itemDetailEditBadge => '编辑识别结果';

  @override
  String get itemDetailAnalyzing => 'AI 分析中…';

  @override
  String get itemDetailAnalyzeFailed => '分析失败，可下拉重试';

  @override
  String get outfitNoCaption => '无备注';

  @override
  String get back => '返回';

  @override
  String get done => '完成';

  @override
  String get outfitShareTitle => '分享穿搭';

  @override
  String get outfitShareCaptionHint => '添加说明文字...';

  @override
  String get outfitShareDone => '完成';

  @override
  String get outfitShareSuccess => '穿搭已成功分享！';

  @override
  String get outfitShareFailed => '分享失败，请再试一次。';

  @override
  String get outfitShareSubject => '我的 Lumi 穿搭';

  @override
  String get outfitShareBrandSlogan => '用AI记录每日穿搭风格';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw(): super('zh_TW');

  @override
  String get appName => 'Lumi';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確認';

  @override
  String get save => '儲存';

  @override
  String get delete => '刪除';

  @override
  String get retry => '重試';

  @override
  String get close => '關閉';

  @override
  String get loading => '載入中...';

  @override
  String get error => '發生錯誤';

  @override
  String get unknownError => '發生未知錯誤';

  @override
  String get and => '及';

  @override
  String get authTitle => '用 AI 點亮妳的衣櫥';

  @override
  String get authSignInGoogle => '使用 Google 帳號登入';

  @override
  String get authSignInApple => '使用 Apple 帳號登入';

  @override
  String get authTermsPrefix => '繼續即表示您同意我們的';

  @override
  String get authTermsLink => '使用條款';

  @override
  String get authPrivacyLink => '隱私政策';

  @override
  String get homeTitle => '我的衣櫥';

  @override
  String get homeAddItem => '加入新品';

  @override
  String get homeEmpty => '衣櫥是空的';

  @override
  String homeEmptyHint(String name) {
    return '歡迎 $name，點下方按鈕開始拍照入庫';
  }

  @override
  String get homeFab => 'Lumi Snap';

  @override
  String homeItemCount(int count) {
    return '$count 件';
  }

  @override
  String get snapTitle => '新增衣物';

  @override
  String get snapUploadAll => '全部分析';

  @override
  String snapSuccessCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已成功加入 $count 件衣物',
      one: '已成功加入 1 件衣物',
    );
    return '$_temp0';
  }

  @override
  String snapQuotaBanner(int remaining) {
    return 'AI 分析剩餘 $remaining 件，即將用完 · 升級 →';
  }

  @override
  String get snapQuotaExceeded => 'AI 分析配額已用完';

  @override
  String get snapAnalyzing => '分析中...';

  @override
  String get snapUploadError => '上傳失敗，請再試一次。';

  @override
  String get snapTapToAdd => '點擊新增照片';

  @override
  String get snapAddMore => '繼續新增';

  @override
  String get snapDone => '完成';

  @override
  String get searchTitle => '衣櫥';

  @override
  String get searchHint => '搜尋衣物...';

  @override
  String get searchNoResults => '找不到衣物';

  @override
  String get searchDeleteTitle => '刪除衣物';

  @override
  String get searchDeleteConfirm => '確定要從衣櫥中刪除這件衣物嗎？';

  @override
  String get searchFilterAll => '全部';

  @override
  String get searchFilterFavorites => '我的最愛';

  @override
  String get searchFilterUncategorized => '未分類';

  @override
  String get catDress => '連身裙';

  @override
  String get catTop => '上衣';

  @override
  String get catBottom => '下身';

  @override
  String get catShoes => '鞋履';

  @override
  String get catBag => '包款';

  @override
  String get catAccessory => '配件';

  @override
  String get catPants => '褲子';

  @override
  String get catOuterwear => '外套';

  @override
  String get colorRed => '紅';

  @override
  String get colorOrange => '橘';

  @override
  String get colorYellow => '黃';

  @override
  String get colorGreen => '綠';

  @override
  String get colorBlue => '藍';

  @override
  String get colorPurple => '紫';

  @override
  String get colorPink => '粉';

  @override
  String get colorBrown => '棕';

  @override
  String get colorBeige => '米';

  @override
  String get colorBlack => '黑';

  @override
  String get colorWhite => '白';

  @override
  String get colorGray => '灰';

  @override
  String get profileTitle => '個人檔案';

  @override
  String get profileMeasurements => '個人身材數據';

  @override
  String get profileHeight => '身高';

  @override
  String get profileWeight => '體重';

  @override
  String get profileBirthday => '生日';

  @override
  String get profileHead => '頭圍';

  @override
  String get profileChest => '胸圍';

  @override
  String get profileWaist => '腰圍';

  @override
  String get profileHips => '臀圍';

  @override
  String get profileInseam => '腿長';

  @override
  String get profileSignOut => '登出';

  @override
  String get profileDeleteAccount => '刪除帳號';

  @override
  String get profileDeleteTitle => '刪除帳號';

  @override
  String get profileDeleteConfirm => '所有資料將永久刪除且無法恢復，確定要繼續嗎？';

  @override
  String get profileDeletePermanent => '永久刪除';

  @override
  String get profileDeleting => '刪除中...';

  @override
  String get profileDeleteError => '刪除失敗，請再試一次。';

  @override
  String get profileLanguage => '語言';

  @override
  String get quotaTitle => 'AI 分析配額';

  @override
  String quotaUsed(int used, int total) {
    return '$used / $total';
  }

  @override
  String quotaRemaining(int remaining) {
    return '剩餘 $remaining 件';
  }

  @override
  String get quotaUnlimited => '無限次（Pro）';

  @override
  String get quotaUpgradeHint => '升級 Pro 或購買補充包';

  @override
  String get quotaUpgradeButton => '升級';

  @override
  String get quotaProActive => '無限 AI 分析，享受 Pro 會員';

  @override
  String get paywallTitle => '你的數位衣物庫\n需要更多空間';

  @override
  String get paywallSubtitle => '選擇最適合你的方案，繼續擴充衣物庫';

  @override
  String get paywallProName => 'Lumi Pro 年費方案';

  @override
  String get paywallProPrice => 'NT\$199 / 年';

  @override
  String get paywallProDesc => '無限 AI 分析配額，一年暢用';

  @override
  String get paywallProBadge => '最划算';

  @override
  String get paywallExtraName => '補充包';

  @override
  String get paywallExtraPrice => 'NT\$99';

  @override
  String get paywallExtraDesc => '+100 次 AI 分析，一次性';

  @override
  String get paywallFreeContinue => '繼續免費使用';

  @override
  String get paywallRestorePurchases => '還原購買';

  @override
  String get paywallSuccessPro => '🎉 已升級為 Pro！享受無限 AI 分析';

  @override
  String get paywallSuccessExtra => '✅ 已補充 100 次 AI 分析配額';

  @override
  String get paywallErrorGeneric => '購買失敗，請再試一次。';

  @override
  String get outfitTitle => '我的穿搭';

  @override
  String get outfitCreate => '新增穿搭';

  @override
  String get outfitEmpty => '還沒有穿搭紀錄';

  @override
  String get outfitEmptyHint => '點擊 + 建立第一套穿搭';

  @override
  String get outfitShare => '分享';

  @override
  String get outfitDelete => '刪除穿搭';

  @override
  String get outfitDeleteConfirm => '確定要刪除這套穿搭嗎？';

  @override
  String get outfitNewTitle => '新增穿搭';

  @override
  String get outfitEditTitle => '編輯穿搭';

  @override
  String get outfitDate => '日期';

  @override
  String get outfitNote => '備註';

  @override
  String get checkTitle => 'Lumi Check';

  @override
  String get checkSubtitle => '購物前先掃描比對';

  @override
  String get checkSimilarItems => '衣櫥中的相似單品';

  @override
  String get checkNoSimilar => '找不到相似單品';

  @override
  String checkSimilarityLabel(int percent) {
    return '$percent% 相似';
  }

  @override
  String get checkTapToScan => '點擊掃描';

  @override
  String get checkScanning => '掃描中...';

  @override
  String get onboardingStep1Title => '零摩擦數位化衣櫥';

  @override
  String get onboardingStep1Desc => 'LUMI 與 Google 相片自動同步，妳無需手動上傳任何內容。';

  @override
  String get onboardingStep2Title => 'AI 智慧分析';

  @override
  String get onboardingStep2Desc => 'Lumi 透過 Gemini AI 自動辨識顏色、材質與款式，讓搜尋變得毫不費力。';

  @override
  String get onboardingStep3Title => '聰明消費不重複';

  @override
  String get onboardingStep3Desc => '「似曾相識」讓妳在購物現場即時比對衣櫥，避免買到重複款式。';

  @override
  String get onboardingNext => '下一步';

  @override
  String get onboardingStart => '開始使用';

  @override
  String itemDetailEditTitle(String label) {
    return '修改$label';
  }

  @override
  String get itemDetailCategory => '分類';

  @override
  String get itemDetailColors => '顏色';

  @override
  String get itemDetailMaterials => '材質';

  @override
  String get itemDetailBrand => '品牌';

  @override
  String get itemDetailNote => '備註';

  @override
  String get itemDetailAnalyzed => 'AI 已分析';

  @override
  String get itemDetailNotAnalyzed => '尚未分析';

  @override
  String get itemDetailDeleteTitle => '刪除衣物';

  @override
  String get itemDetailDeleteConfirm => '確定要從衣櫥中刪除這件衣物嗎？';

  @override
  String get errorQuotaExceeded => 'AI 分析配額已用完，請購買補充包或升級 Pro。';

  @override
  String get errorNetworkFailed => '網路連線失敗，請檢查網路狀態。';

  @override
  String get errorAuthRequired => '請先登入後再繼續。';

  @override
  String get errorPurchaseFailed => '購買失敗，請再試一次。';

  @override
  String get errorDeleteFailed => '刪除失敗，請再試一次。';

  @override
  String get snapIdleTitle => '選擇加入方式';

  @override
  String get snapIdleSubtitle => '一次最多 10 張，AI 會在背景自動分類';

  @override
  String get snapCamera => '拍照';

  @override
  String get snapLibrary => '從相簿選取';

  @override
  String snapSelectedCount(int count, int max) {
    return '已選取 $count / $max 張';
  }

  @override
  String get snapAddToWardrobe => '加入衣櫥';

  @override
  String get snapAddMoreTile => '新增';

  @override
  String get snapRetry => '重新選取';

  @override
  String get snapAppBarAdding => '加入衣櫥中';

  @override
  String get snapAppBarDone => '加入完成';

  @override
  String get snapQuotaExhaustedBanner => 'AI 分析配額已用完，加入後無法分析';

  @override
  String get snapUpgradeArrow => '升級 →';

  @override
  String get paywallBuyPro => '立即升級';

  @override
  String get paywallBuyExtra => '購買';

  @override
  String get paywallProPriceSub => '/ 年';

  @override
  String get paywallExtraPriceSub => '一次性';

  @override
  String get profileVersion => '版本';

  @override
  String profileDebugHint(int count) {
    return '再點 $count 次開啟 Debug Log';
  }

  @override
  String get profileDeleteConfirmTitle => '確定要刪除帳號嗎？';

  @override
  String get profileDeleteConfirmBody => '此操作無法復原。您的帳號資料將永久刪除，裝置上的衣物照片與記錄不受影響。';

  @override
  String get profileDeletePermanentButton => '永久刪除帳號';

  @override
  String get measureHeight => '身高';

  @override
  String get measureWeight => '體重';

  @override
  String get measureBirthday => '生日';

  @override
  String get measureHead => '頭圍';

  @override
  String get measureChest => '胸圍';

  @override
  String get measureWaist => '腰圍';

  @override
  String get measureHips => '臀圍';

  @override
  String get measureInseam => '腿長';

  @override
  String get searchEmptyHint => '點擊右下角的 + 按鈕開始建立妳的數位衣櫥';

  @override
  String get searchViewAll => '查看全部衣物';

  @override
  String get searchFavoritesEmptyTitle => '還沒有收藏的衣物';

  @override
  String get searchFavoritesEmptyHint => '點擊衣物卡片右下角的愛心，將喜歡的單品加入最愛';

  @override
  String get searchAiDoneTitle => 'AI 辨識完成！';

  @override
  String get searchAiDoneHint => '衣物已歸類到對應分類\n快點擊下方按鈕去看看吧';

  @override
  String get searchFilterEmptyTitle => '這個分類目前沒有衣物';

  @override
  String get searchFilterEmptyHint => '換個分類看看，或清除篩選條件';

  @override
  String get checkScanTitle => 'AI 比對中';

  @override
  String get checkScanSubtitle => '正在從衣櫥中尋找相似款式...';

  @override
  String get checkWantToBuy => '想買的';

  @override
  String get checkClosestInWardrobe => '衣櫥最相似';

  @override
  String checkHighSimilarBanner(String percent) {
    return '衣櫥已有 $percent% 相似款，確認再入手！';
  }

  @override
  String checkMediumSimilarBanner(String percent) {
    return '衣櫥有 $percent% 相似款，可以再比較看看。';
  }

  @override
  String get checkAlreadyHave => '已經有了';

  @override
  String get checkAddedSuccess => '已成功加入衣櫥';

  @override
  String get checkNoSimilarHint => '這件衣物在妳的衣櫥裡找不到相似款，\n可以安心入手！';

  @override
  String get checkBackToWardrobe => '返回衣櫥';

  @override
  String get checkAdding => '加入中...';

  @override
  String get itemDetailEditBadge => '編輯辨識結果';

  @override
  String get itemDetailAnalyzing => 'AI 分析中…';

  @override
  String get itemDetailAnalyzeFailed => '分析失敗，可下拉重試';

  @override
  String get outfitNoCaption => '無備註';

  @override
  String get back => '返回';

  @override
  String get done => '完成';

  @override
  String get outfitShareTitle => '分享穿搭';

  @override
  String get outfitShareCaptionHint => '新增說明文字...';

  @override
  String get outfitShareDone => '完成';

  @override
  String get outfitShareSuccess => '穿搭已成功分享！';

  @override
  String get outfitShareFailed => '分享失敗，請再試一次。';

  @override
  String get outfitShareSubject => '我的 Lumi 穿搭';

  @override
  String get outfitShareBrandSlogan => '用AI記錄每日穿搭風格';
}
