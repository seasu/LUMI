import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh', 'TW'),
    Locale('zh', 'CN'),
    Locale('ja'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Lumi'**
  String get appName;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get error;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknownError;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get and;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Light up your wardrobe with AI'**
  String get authTitle;

  /// No description provided for @authSignInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get authSignInGoogle;

  /// No description provided for @authSignInApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get authSignInApple;

  /// No description provided for @authTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get authTermsPrefix;

  /// No description provided for @authTermsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authTermsLink;

  /// No description provided for @authPrivacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyLink;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'My Wardrobe'**
  String get homeTitle;

  /// No description provided for @homeAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get homeAddItem;

  /// No description provided for @homeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your wardrobe is empty'**
  String get homeEmpty;

  /// No description provided for @homeEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}! Tap the button below to start adding items'**
  String homeEmptyHint(String name);

  /// No description provided for @homeFab.
  ///
  /// In en, this message translates to:
  /// **'Lumi Snap'**
  String get homeFab;

  /// No description provided for @homeItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{count} item} other{{count} items}}'**
  String homeItemCount(int count);

  /// No description provided for @snapTitle.
  ///
  /// In en, this message translates to:
  /// **'New Item'**
  String get snapTitle;

  /// No description provided for @snapUploadAll.
  ///
  /// In en, this message translates to:
  /// **'Analyze All'**
  String get snapUploadAll;

  /// No description provided for @snapSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 item} other{Added {count} items}}'**
  String snapSuccessCount(int count);

  /// No description provided for @snapQuotaBanner.
  ///
  /// In en, this message translates to:
  /// **'AI analysis: {remaining} left · Upgrade →'**
  String snapQuotaBanner(int remaining);

  /// No description provided for @snapQuotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'AI analysis quota reached'**
  String get snapQuotaExceeded;

  /// No description provided for @snapAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get snapAnalyzing;

  /// No description provided for @snapUploadError.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get snapUploadError;

  /// No description provided for @snapTapToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap to add photos'**
  String get snapTapToAdd;

  /// No description provided for @snapAddMore.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get snapAddMore;

  /// No description provided for @snapDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get snapDone;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search items...'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get searchNoResults;

  /// No description provided for @searchDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get searchDeleteTitle;

  /// No description provided for @searchDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this item from your wardrobe?'**
  String get searchDeleteConfirm;

  /// No description provided for @searchFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchFilterAll;

  /// No description provided for @searchFilterFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get searchFilterFavorites;

  /// No description provided for @searchFilterUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get searchFilterUncategorized;

  /// Clothing category: 連身裙
  ///
  /// In en, this message translates to:
  /// **'Dress'**
  String get catDress;

  /// Clothing category: 上衣
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get catTop;

  /// Clothing category: 下身
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get catBottom;

  /// Clothing category: 鞋履/鞋子
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get catShoes;

  /// Clothing category: 包款
  ///
  /// In en, this message translates to:
  /// **'Bags'**
  String get catBag;

  /// Clothing category: 配件
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get catAccessory;

  /// Clothing category: 褲子
  ///
  /// In en, this message translates to:
  /// **'Pants'**
  String get catPants;

  /// Clothing category: 外套
  ///
  /// In en, this message translates to:
  /// **'Outerwear'**
  String get catOuterwear;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colorYellow;

  /// No description provided for @colorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colorGreen;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colorPurple;

  /// No description provided for @colorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colorBrown;

  /// No description provided for @colorBeige.
  ///
  /// In en, this message translates to:
  /// **'Beige'**
  String get colorBeige;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorGray.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get colorGray;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileMeasurements.
  ///
  /// In en, this message translates to:
  /// **'Body Measurements'**
  String get profileMeasurements;

  /// No description provided for @profileHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileHeight;

  /// No description provided for @profileWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get profileWeight;

  /// No description provided for @profileBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get profileBirthday;

  /// No description provided for @profileHead.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get profileHead;

  /// No description provided for @profileChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get profileChest;

  /// No description provided for @profileWaist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get profileWaist;

  /// No description provided for @profileHips.
  ///
  /// In en, this message translates to:
  /// **'Hips'**
  String get profileHips;

  /// No description provided for @profileInseam.
  ///
  /// In en, this message translates to:
  /// **'Inseam'**
  String get profileInseam;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get profileDeleteTitle;

  /// No description provided for @profileDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'All data will be permanently deleted and cannot be recovered. Are you sure?'**
  String get profileDeleteConfirm;

  /// No description provided for @profileDeletePermanent.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete'**
  String get profileDeletePermanent;

  /// No description provided for @profileDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting...'**
  String get profileDeleting;

  /// No description provided for @profileDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Deletion failed. Please try again.'**
  String get profileDeleteError;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @quotaTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis Quota'**
  String get quotaTitle;

  /// No description provided for @quotaUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} / {total}'**
  String quotaUsed(int used, int total);

  /// No description provided for @quotaRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining} remaining'**
  String quotaRemaining(int remaining);

  /// No description provided for @quotaUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited (Pro)'**
  String get quotaUnlimited;

  /// No description provided for @quotaUpgradeHint.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Pro or buy a top-up pack'**
  String get quotaUpgradeHint;

  /// No description provided for @quotaUpgradeButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get quotaUpgradeButton;

  /// No description provided for @quotaProActive.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI analysis, enjoy Pro membership'**
  String get quotaProActive;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Your digital wardrobe\nneeds more space'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the plan that suits you best'**
  String get paywallSubtitle;

  /// No description provided for @paywallProName.
  ///
  /// In en, this message translates to:
  /// **'Lumi Pro Annual'**
  String get paywallProName;

  /// No description provided for @paywallProPrice.
  ///
  /// In en, this message translates to:
  /// **'NT\$199 / year'**
  String get paywallProPrice;

  /// No description provided for @paywallProDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlimited AI analysis, enjoy year-round'**
  String get paywallProDesc;

  /// No description provided for @paywallProBadge.
  ///
  /// In en, this message translates to:
  /// **'Best Value'**
  String get paywallProBadge;

  /// No description provided for @paywallExtraName.
  ///
  /// In en, this message translates to:
  /// **'Top-up Pack'**
  String get paywallExtraName;

  /// No description provided for @paywallExtraPrice.
  ///
  /// In en, this message translates to:
  /// **'NT\$99'**
  String get paywallExtraPrice;

  /// No description provided for @paywallExtraDesc.
  ///
  /// In en, this message translates to:
  /// **'+100 AI analysis credits, one-time'**
  String get paywallExtraDesc;

  /// No description provided for @paywallFreeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue for free'**
  String get paywallFreeContinue;

  /// No description provided for @paywallRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get paywallRestorePurchases;

  /// No description provided for @paywallSuccessPro.
  ///
  /// In en, this message translates to:
  /// **'🎉 Upgraded to Pro! Enjoy unlimited AI analysis'**
  String get paywallSuccessPro;

  /// No description provided for @paywallSuccessExtra.
  ///
  /// In en, this message translates to:
  /// **'✅ Added 100 AI analysis credits'**
  String get paywallSuccessExtra;

  /// No description provided for @paywallErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get paywallErrorGeneric;

  /// No description provided for @outfitTitle.
  ///
  /// In en, this message translates to:
  /// **'Outfits'**
  String get outfitTitle;

  /// No description provided for @outfitCreate.
  ///
  /// In en, this message translates to:
  /// **'Create Outfit'**
  String get outfitCreate;

  /// No description provided for @outfitEmpty.
  ///
  /// In en, this message translates to:
  /// **'No outfits yet'**
  String get outfitEmpty;

  /// No description provided for @outfitEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first outfit'**
  String get outfitEmptyHint;

  /// No description provided for @outfitShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get outfitShare;

  /// No description provided for @outfitDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Outfit'**
  String get outfitDelete;

  /// No description provided for @outfitDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this outfit?'**
  String get outfitDeleteConfirm;

  /// No description provided for @outfitNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Outfit'**
  String get outfitNewTitle;

  /// No description provided for @outfitEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Outfit'**
  String get outfitEditTitle;

  /// No description provided for @outfitDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get outfitDate;

  /// No description provided for @outfitNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get outfitNote;

  /// No description provided for @checkTitle.
  ///
  /// In en, this message translates to:
  /// **'Lumi Check'**
  String get checkTitle;

  /// No description provided for @checkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan before you buy'**
  String get checkSubtitle;

  /// No description provided for @checkSimilarItems.
  ///
  /// In en, this message translates to:
  /// **'Similar items in your wardrobe'**
  String get checkSimilarItems;

  /// No description provided for @checkNoSimilar.
  ///
  /// In en, this message translates to:
  /// **'No similar items found'**
  String get checkNoSimilar;

  /// No description provided for @checkSimilarityLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% similar'**
  String checkSimilarityLabel(int percent);

  /// No description provided for @checkTapToScan.
  ///
  /// In en, this message translates to:
  /// **'Tap to scan'**
  String get checkTapToScan;

  /// No description provided for @checkScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get checkScanning;

  /// No description provided for @onboardingStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Zero-friction digital wardrobe'**
  String get onboardingStep1Title;

  /// No description provided for @onboardingStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'LUMI syncs with Google Photos automatically — no manual uploads needed.'**
  String get onboardingStep1Desc;

  /// No description provided for @onboardingStep2Title.
  ///
  /// In en, this message translates to:
  /// **'AI smart analysis'**
  String get onboardingStep2Title;

  /// No description provided for @onboardingStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Lumi uses Gemini AI to automatically identify colors, materials and styles, making search effortless.'**
  String get onboardingStep2Desc;

  /// No description provided for @onboardingStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Shop smarter, never duplicate'**
  String get onboardingStep3Title;

  /// No description provided for @onboardingStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'\'Lumi Check\' lets you compare against your wardrobe in real time while shopping.'**
  String get onboardingStep3Desc;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingStart;

  /// No description provided for @itemDetailEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {label}'**
  String itemDetailEditTitle(String label);

  /// No description provided for @itemDetailCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get itemDetailCategory;

  /// No description provided for @itemDetailColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get itemDetailColors;

  /// No description provided for @itemDetailMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get itemDetailMaterials;

  /// No description provided for @itemDetailBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get itemDetailBrand;

  /// No description provided for @itemDetailNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get itemDetailNote;

  /// No description provided for @itemDetailAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'AI Analyzed'**
  String get itemDetailAnalyzed;

  /// No description provided for @itemDetailNotAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'Not yet analyzed'**
  String get itemDetailNotAnalyzed;

  /// No description provided for @itemDetailDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Item'**
  String get itemDetailDeleteTitle;

  /// No description provided for @itemDetailDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this item from your wardrobe?'**
  String get itemDetailDeleteConfirm;

  /// No description provided for @errorQuotaExceeded.
  ///
  /// In en, this message translates to:
  /// **'AI analysis quota reached. Purchase a top-up or upgrade to Pro.'**
  String get errorQuotaExceeded;

  /// No description provided for @errorNetworkFailed.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get errorNetworkFailed;

  /// No description provided for @errorAuthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get errorAuthRequired;

  /// No description provided for @errorPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get errorPurchaseFailed;

  /// No description provided for @errorDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Deletion failed. Please try again.'**
  String get errorDeleteFailed;

  /// No description provided for @snapIdleTitle.
  ///
  /// In en, this message translates to:
  /// **'Select source'**
  String get snapIdleTitle;

  /// No description provided for @snapIdleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Up to 10 photos at once, AI will categorize in the background'**
  String get snapIdleSubtitle;

  /// No description provided for @snapCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get snapCamera;

  /// No description provided for @snapLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get snapLibrary;

  /// No description provided for @snapSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} / {max} selected'**
  String snapSelectedCount(int count, int max);

  /// No description provided for @snapAddToWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Add to Wardrobe'**
  String get snapAddToWardrobe;

  /// No description provided for @snapAddMoreTile.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get snapAddMoreTile;

  /// No description provided for @snapRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get snapRetry;

  /// No description provided for @snapAppBarAdding.
  ///
  /// In en, this message translates to:
  /// **'Adding to wardrobe...'**
  String get snapAppBarAdding;

  /// No description provided for @snapAppBarDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get snapAppBarDone;

  /// No description provided for @snapQuotaExhaustedBanner.
  ///
  /// In en, this message translates to:
  /// **'AI analysis quota used up — items added but not analyzed'**
  String get snapQuotaExhaustedBanner;

  /// No description provided for @snapUpgradeArrow.
  ///
  /// In en, this message translates to:
  /// **'Upgrade →'**
  String get snapUpgradeArrow;

  /// No description provided for @paywallBuyPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Now'**
  String get paywallBuyPro;

  /// No description provided for @paywallBuyExtra.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get paywallBuyExtra;

  /// No description provided for @paywallProPriceSub.
  ///
  /// In en, this message translates to:
  /// **'/ year'**
  String get paywallProPriceSub;

  /// No description provided for @paywallExtraPriceSub.
  ///
  /// In en, this message translates to:
  /// **'one-time'**
  String get paywallExtraPriceSub;

  /// No description provided for @profileVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get profileVersion;

  /// No description provided for @profileDebugHint.
  ///
  /// In en, this message translates to:
  /// **'{count} more taps to open Debug Log'**
  String profileDebugHint(int count);

  /// No description provided for @profileDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get profileDeleteConfirmTitle;

  /// No description provided for @profileDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Your account data will be permanently deleted. Photos and records on your device are not affected.'**
  String get profileDeleteConfirmBody;

  /// No description provided for @profileDeletePermanentButton.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete Account'**
  String get profileDeletePermanentButton;

  /// No description provided for @measureHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get measureHeight;

  /// No description provided for @measureWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get measureWeight;

  /// No description provided for @measureBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get measureBirthday;

  /// No description provided for @measureHead.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get measureHead;

  /// No description provided for @measureChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get measureChest;

  /// No description provided for @measureWaist.
  ///
  /// In en, this message translates to:
  /// **'Waist'**
  String get measureWaist;

  /// No description provided for @measureHips.
  ///
  /// In en, this message translates to:
  /// **'Hips'**
  String get measureHips;

  /// No description provided for @measureInseam.
  ///
  /// In en, this message translates to:
  /// **'Inseam'**
  String get measureInseam;

  /// No description provided for @searchEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to start adding clothes to your wardrobe'**
  String get searchEmptyHint;

  /// No description provided for @searchViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get searchViewAll;

  /// No description provided for @searchFavoritesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get searchFavoritesEmptyTitle;

  /// No description provided for @searchFavoritesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart icon on a clothing card to add it to favorites'**
  String get searchFavoritesEmptyHint;

  /// No description provided for @searchAiDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'AI analysis complete!'**
  String get searchAiDoneTitle;

  /// No description provided for @searchAiDoneHint.
  ///
  /// In en, this message translates to:
  /// **'Items have been categorized. Tap a category to view.'**
  String get searchAiDoneHint;

  /// No description provided for @searchFilterEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No items in this category'**
  String get searchFilterEmptyTitle;

  /// No description provided for @searchFilterEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try another category or clear your filters'**
  String get searchFilterEmptyHint;

  /// No description provided for @checkScanTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Comparing'**
  String get checkScanTitle;

  /// No description provided for @checkScanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Searching your wardrobe for similar styles...'**
  String get checkScanSubtitle;

  /// No description provided for @checkWantToBuy.
  ///
  /// In en, this message translates to:
  /// **'Item to Buy'**
  String get checkWantToBuy;

  /// No description provided for @checkClosestInWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Closest Match'**
  String get checkClosestInWardrobe;

  /// No description provided for @checkHighSimilarBanner.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe has {percent}% match — reconsider before buying!'**
  String checkHighSimilarBanner(String percent);

  /// No description provided for @checkMediumSimilarBanner.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe has {percent}% match — compare before deciding.'**
  String checkMediumSimilarBanner(String percent);

  /// No description provided for @checkAlreadyHave.
  ///
  /// In en, this message translates to:
  /// **'Already own it'**
  String get checkAlreadyHave;

  /// No description provided for @checkAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Added to wardrobe'**
  String get checkAddedSuccess;

  /// No description provided for @checkNoSimilarHint.
  ///
  /// In en, this message translates to:
  /// **'No similar items found — safe to buy!'**
  String get checkNoSimilarHint;

  /// No description provided for @checkBackToWardrobe.
  ///
  /// In en, this message translates to:
  /// **'Back to Wardrobe'**
  String get checkBackToWardrobe;

  /// No description provided for @checkAdding.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get checkAdding;

  /// No description provided for @itemDetailEditBadge.
  ///
  /// In en, this message translates to:
  /// **'Edit AI Result'**
  String get itemDetailEditBadge;

  /// No description provided for @itemDetailAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'AI analyzing…'**
  String get itemDetailAnalyzing;

  /// No description provided for @itemDetailAnalyzeFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed, pull down to retry'**
  String get itemDetailAnalyzeFailed;

  /// No description provided for @outfitNoCaption.
  ///
  /// In en, this message translates to:
  /// **'No caption'**
  String get outfitNoCaption;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @outfitShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Outfit'**
  String get outfitShareTitle;

  /// No description provided for @outfitShareCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Add a caption...'**
  String get outfitShareCaptionHint;

  /// No description provided for @outfitShareDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get outfitShareDone;

  /// No description provided for @outfitShareSuccess.
  ///
  /// In en, this message translates to:
  /// **'Outfit shared!'**
  String get outfitShareSuccess;

  /// No description provided for @outfitShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share failed. Please try again.'**
  String get outfitShareFailed;

  /// No description provided for @outfitShareSubject.
  ///
  /// In en, this message translates to:
  /// **'My Lumi Outfit'**
  String get outfitShareSubject;

  /// No description provided for @outfitShareBrandSlogan.
  ///
  /// In en, this message translates to:
  /// **'Record your daily style with AI'**
  String get outfitShareBrandSlogan;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh': {
  switch (locale.countryCode) {
    case 'CN': return AppLocalizationsZhCn();
case 'TW': return AppLocalizationsZhTw();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
