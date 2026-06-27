// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Lumi';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Something went wrong';

  @override
  String get unknownError => 'An unknown error occurred';

  @override
  String get and => ' and ';

  @override
  String get authTitle => 'Light up your wardrobe with AI';

  @override
  String get authSignInGoogle => 'Sign in with Google';

  @override
  String get authSignInApple => 'Sign in with Apple';

  @override
  String get authTermsPrefix => 'By continuing, you agree to our ';

  @override
  String get authTermsLink => 'Terms of Service';

  @override
  String get authPrivacyLink => 'Privacy Policy';

  @override
  String get homeTitle => 'My Wardrobe';

  @override
  String get homeAddItem => 'Add Item';

  @override
  String get homeEmpty => 'Your wardrobe is empty';

  @override
  String homeEmptyHint(String name) {
    return 'Welcome, $name! Tap the button below to start adding items';
  }

  @override
  String get homeFab => 'Lumi Snap';

  @override
  String homeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get snapTitle => 'New Item';

  @override
  String get snapUploadAll => 'Analyze All';

  @override
  String snapSuccessCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count items',
      one: 'Added 1 item',
    );
    return '$_temp0';
  }

  @override
  String snapQuotaBanner(int remaining) {
    return 'AI analysis: $remaining left · Upgrade →';
  }

  @override
  String get snapQuotaExceeded => 'AI analysis quota reached';

  @override
  String get snapAnalyzing => 'Analyzing...';

  @override
  String get snapUploadError => 'Upload failed. Please try again.';

  @override
  String get snapTapToAdd => 'Tap to add photos';

  @override
  String get snapAddMore => 'Add More';

  @override
  String get snapDone => 'Done';

  @override
  String get searchTitle => 'Wardrobe';

  @override
  String get searchHint => 'Search items...';

  @override
  String get searchNoResults => 'No items found';

  @override
  String get searchDeleteTitle => 'Delete Item';

  @override
  String get searchDeleteConfirm => 'Are you sure you want to remove this item from your wardrobe?';

  @override
  String get searchFilterAll => 'All';

  @override
  String get searchFilterFavorites => 'Favorites';

  @override
  String get searchFilterUncategorized => 'Uncategorized';

  @override
  String get catDress => 'Dress';

  @override
  String get catTop => 'Top';

  @override
  String get catBottom => 'Bottom';

  @override
  String get catShoes => 'Shoes';

  @override
  String get catBag => 'Bags';

  @override
  String get catAccessory => 'Accessories';

  @override
  String get catPants => 'Pants';

  @override
  String get catOuterwear => 'Outerwear';

  @override
  String get colorRed => 'Red';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorYellow => 'Yellow';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorPurple => 'Purple';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorBrown => 'Brown';

  @override
  String get colorBeige => 'Beige';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorWhite => 'White';

  @override
  String get colorGray => 'Gray';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileMeasurements => 'Body Measurements';

  @override
  String get profileHeight => 'Height';

  @override
  String get profileWeight => 'Weight';

  @override
  String get profileBirthday => 'Birthday';

  @override
  String get profileHead => 'Head';

  @override
  String get profileChest => 'Chest';

  @override
  String get profileWaist => 'Waist';

  @override
  String get profileHips => 'Hips';

  @override
  String get profileInseam => 'Inseam';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String get profileSigningOut => 'Account data not found. Signing you out…';

  @override
  String get profileDeleteAccount => 'Delete Account';

  @override
  String get profileDeleteTitle => 'Delete Account';

  @override
  String get profileDeleteConfirm => 'All data will be permanently deleted and cannot be recovered. Are you sure?';

  @override
  String get profileDeletePermanent => 'Permanently Delete';

  @override
  String get profileDeleting => 'Deleting...';

  @override
  String get profileDeleteError => 'Deletion failed. Please try again.';

  @override
  String get profileLanguage => 'Language';

  @override
  String get quotaTitle => 'AI Analysis Quota';

  @override
  String quotaUsed(int used, int total) {
    return '$used / $total';
  }

  @override
  String quotaRemaining(int remaining) {
    return '$remaining remaining';
  }

  @override
  String get quotaUnlimited => 'Unlimited (Pro)';

  @override
  String get quotaUpgradeHint => 'Upgrade Pro or buy a top-up pack';

  @override
  String get quotaUpgradeButton => 'Upgrade';

  @override
  String get quotaProActive => 'Unlimited AI analysis, enjoy Pro membership';

  @override
  String get paywallTitle => 'Your digital wardrobe\nneeds more space';

  @override
  String get paywallSubtitle => 'Choose the plan that suits you best';

  @override
  String get paywallProName => 'Lumi Pro Annual';

  @override
  String get paywallProPrice => 'NT\$199 / year';

  @override
  String get paywallProDesc => 'Unlimited AI analysis, enjoy year-round';

  @override
  String get paywallProBadge => 'Best Value';

  @override
  String get paywallExtraName => 'Top-up Pack';

  @override
  String get paywallExtraPrice => 'NT\$99';

  @override
  String get paywallExtraDesc => '+100 AI analysis credits, one-time';

  @override
  String get paywallFreeContinue => 'Continue for free';

  @override
  String get paywallRestorePurchases => 'Restore Purchases';

  @override
  String get paywallRestoringPurchases => 'Restoring purchases…';

  @override
  String get paywallSuccessPro => '🎉 Upgraded to Pro! Enjoy unlimited AI analysis';

  @override
  String get paywallSuccessExtra => '✅ Added 100 AI analysis credits';

  @override
  String get paywallRestoreSuccess => '✅ Purchases restored successfully';

  @override
  String get paywallErrorGeneric => 'Purchase failed. Please try again.';

  @override
  String get paywallVerifyFailed => 'Purchase verification failed. Please try again later or contact support.';

  @override
  String get paywallRestoreFailed => 'Restore failed. Please try again later or contact support.';

  @override
  String get paywallSubscriptionExpired => 'Your subscription has expired. Please resubscribe to continue using Pro features.';

  @override
  String get outfitTitle => 'Outfits';

  @override
  String get outfitCreate => 'Create Outfit';

  @override
  String get outfitEmpty => 'No outfits yet';

  @override
  String get outfitEmptyHint => 'Tap + to create your first outfit';

  @override
  String get outfitShare => 'Share';

  @override
  String get outfitDelete => 'Delete Outfit';

  @override
  String get outfitDeleteConfirm => 'Delete this outfit?';

  @override
  String get outfitNewTitle => 'New Outfit';

  @override
  String get outfitEditTitle => 'Edit Outfit';

  @override
  String get outfitDate => 'Date';

  @override
  String get outfitNote => 'Note';

  @override
  String get checkTitle => 'Lumi Check';

  @override
  String get checkSubtitle => 'Scan before you buy';

  @override
  String get checkSimilarItems => 'Similar items in your wardrobe';

  @override
  String get checkNoSimilar => 'No similar items found';

  @override
  String checkSimilarityLabel(int percent) {
    return '$percent% similar';
  }

  @override
  String get checkTapToScan => 'Tap to scan';

  @override
  String get checkScanning => 'Scanning...';

  @override
  String get onboardingStep1Title => 'Zero-friction digital wardrobe';

  @override
  String get onboardingStep1Desc => 'Lumi syncs with Google Photos automatically — no manual uploads needed.';

  @override
  String get onboardingStep2Title => 'AI smart analysis';

  @override
  String get onboardingStep2Desc => 'Lumi uses Gemini AI to automatically identify colors, materials and styles, making search effortless.';

  @override
  String get onboardingStep3Title => 'Shop smarter, never duplicate';

  @override
  String get onboardingStep3Desc => '\'Lumi Check\' lets you compare against your wardrobe in real time while shopping.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Get Started';

  @override
  String itemDetailEditTitle(String label) {
    return 'Edit $label';
  }

  @override
  String get itemDetailCategory => 'Category';

  @override
  String get itemDetailColors => 'Colors';

  @override
  String get itemDetailMaterials => 'Materials';

  @override
  String get itemDetailBrand => 'Brand';

  @override
  String get itemDetailNote => 'Note';

  @override
  String get itemDetailAnalyzed => 'AI Analyzed';

  @override
  String get itemDetailNotAnalyzed => 'Not yet analyzed';

  @override
  String get itemDetailDeleteTitle => 'Delete Item';

  @override
  String get itemDetailDeleteConfirm => 'Are you sure you want to remove this item from your wardrobe?';

  @override
  String get errorQuotaExceeded => 'AI analysis quota reached. Purchase a top-up or upgrade to Pro.';

  @override
  String get errorNetworkFailed => 'Network error. Please check your connection.';

  @override
  String get errorAuthRequired => 'Please sign in to continue.';

  @override
  String get errorPurchaseFailed => 'Purchase failed. Please try again.';

  @override
  String get errorDeleteFailed => 'Deletion failed. Please try again.';

  @override
  String get snapIdleTitle => 'Select source';

  @override
  String get snapIdleSubtitle => 'Up to 10 photos at once, AI will categorize in the background';

  @override
  String get snapCamera => 'Take photo';

  @override
  String get snapLibrary => 'Choose from library';

  @override
  String snapSelectedCount(int count, int max) {
    return '$count / $max selected';
  }

  @override
  String get snapAddToWardrobe => 'Add to Wardrobe';

  @override
  String get snapAddMoreTile => 'Add';

  @override
  String get snapRetry => 'Try Again';

  @override
  String get snapAppBarAdding => 'Adding to wardrobe...';

  @override
  String get snapAppBarDone => 'Done';

  @override
  String get snapQuotaExhaustedBanner => 'AI analysis quota used up — items added but not analyzed';

  @override
  String get snapUpgradeArrow => 'Upgrade →';

  @override
  String get paywallBuyPro => 'Upgrade Now';

  @override
  String get paywallBuyExtra => 'Buy';

  @override
  String get paywallProPriceSub => '/ year';

  @override
  String get paywallExtraPriceSub => 'one-time';

  @override
  String get profileVersion => 'Version';

  @override
  String profileDebugHint(int count) {
    return '$count more taps to open Debug Log';
  }

  @override
  String get profileDeleteConfirmTitle => 'Delete Account?';

  @override
  String get profileDeleteConfirmBody => 'This cannot be undone. Your account data will be permanently deleted. Photos and records on your device are not affected.';

  @override
  String get profileDeletePermanentButton => 'Permanently Delete Account';

  @override
  String get measureHeight => 'Height';

  @override
  String get measureWeight => 'Weight';

  @override
  String get measureBirthday => 'Birthday';

  @override
  String get measureHead => 'Head';

  @override
  String get measureChest => 'Chest';

  @override
  String get measureWaist => 'Waist';

  @override
  String get measureHips => 'Hips';

  @override
  String get measureInseam => 'Inseam';

  @override
  String get searchEmptyHint => 'Tap + to start adding clothes to your wardrobe';

  @override
  String get searchViewAll => 'View all';

  @override
  String get searchFavoritesEmptyTitle => 'No favorites yet';

  @override
  String get searchFavoritesEmptyHint => 'Tap the heart icon on a clothing card to add it to favorites';

  @override
  String get searchAiDoneTitle => 'AI analysis complete!';

  @override
  String get searchAiDoneHint => 'Items have been categorized. Tap a category to view.';

  @override
  String get searchFilterEmptyTitle => 'No items in this category';

  @override
  String get searchFilterEmptyHint => 'Try another category or clear your filters';

  @override
  String get checkScanTitle => 'AI Comparing';

  @override
  String get checkScanSubtitle => 'Searching your wardrobe for similar styles...';

  @override
  String get checkWantToBuy => 'Item to Buy';

  @override
  String get checkClosestInWardrobe => 'Closest Match';

  @override
  String checkHighSimilarBanner(String percent) {
    return 'Wardrobe has $percent% match — reconsider before buying!';
  }

  @override
  String checkMediumSimilarBanner(String percent) {
    return 'Wardrobe has $percent% match — compare before deciding.';
  }

  @override
  String get checkAlreadyHave => 'Already own it';

  @override
  String get checkAddedSuccess => 'Added to wardrobe';

  @override
  String get checkNoSimilarHint => 'No similar items found — safe to buy!';

  @override
  String get checkBackToWardrobe => 'Back to Wardrobe';

  @override
  String get checkAdding => 'Adding...';

  @override
  String get itemDetailEditBadge => 'Edit AI Result';

  @override
  String get itemDetailAnalyzing => 'AI analyzing…';

  @override
  String get itemDetailAnalyzeFailed => 'Analysis failed, pull down to retry';

  @override
  String get outfitNoCaption => 'No caption';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get outfitShareTitle => 'Share Outfit';

  @override
  String get outfitShareCaptionHint => 'Add a caption...';

  @override
  String get outfitShareDone => 'Done';

  @override
  String get outfitShareSuccess => 'Outfit shared!';

  @override
  String get outfitShareFailed => 'Share failed. Please try again.';

  @override
  String get outfitShareSubject => 'My Lumi Outfit';

  @override
  String get outfitShareBrandSlogan => 'Record your daily style with AI';
}
