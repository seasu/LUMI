import '../../l10n/generated/app_localizations.dart';

// Maps Gemini-returned Chinese category strings → translated display strings.
// Covers both filter_bar values ('連身裙','下身','鞋履','包款') and
// Gemini analysis values ('上衣','褲子','外套','配件','鞋子').
String translateCategory(String rawKey, AppLocalizations l10n) {
  switch (rawKey) {
    case '連身裙':
      return l10n.catDress;
    case '上衣':
      return l10n.catTop;
    case '下身':
      return l10n.catBottom;
    case '鞋履':
    case '鞋子':
      return l10n.catShoes;
    case '包款':
      return l10n.catBag;
    case '配件':
      return l10n.catAccessory;
    case '褲子':
      return l10n.catPants;
    case '外套':
      return l10n.catOuterwear;
    default:
      return rawKey;
  }
}

String translateColor(String rawKey, AppLocalizations l10n) {
  switch (rawKey) {
    case '紅':
      return l10n.colorRed;
    case '橘':
      return l10n.colorOrange;
    case '黃':
      return l10n.colorYellow;
    case '綠':
      return l10n.colorGreen;
    case '藍':
      return l10n.colorBlue;
    case '紫':
      return l10n.colorPurple;
    case '粉':
      return l10n.colorPink;
    case '棕':
      return l10n.colorBrown;
    case '米':
      return l10n.colorBeige;
    case '黑':
      return l10n.colorBlack;
    case '白':
      return l10n.colorWhite;
    case '灰':
      return l10n.colorGray;
    default:
      return rawKey;
  }
}
