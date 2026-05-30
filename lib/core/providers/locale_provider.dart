import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _init();
    return const Locale('zh', 'TW');
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);
    if (saved != null) {
      state = _parseLocale(saved);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    final key = locale.countryCode != null && locale.countryCode!.isNotEmpty
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    await prefs.setString(_kLocaleKey, key);
  }

  static Locale _parseLocale(String code) {
    final parts = code.split('_');
    if (parts.length >= 2 && parts[1].isNotEmpty) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }
}

const kSupportedLocales = [
  Locale('en'),
  Locale('zh', 'TW'),
  Locale('zh', 'CN'),
  Locale('ja'),
];

const kLocaleDisplayNames = <String, String>{
  'en': 'English',
  'zh_TW': '繁體中文',
  'zh_CN': '简体中文',
  'ja': '日本語',
};

String localeToKey(Locale locale) {
  if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
    return '${locale.languageCode}_${locale.countryCode}';
  }
  return locale.languageCode;
}
