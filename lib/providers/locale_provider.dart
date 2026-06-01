import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../l10n/app_translations.dart';

class LocaleProvider extends ChangeNotifier {
  static const _storageKey = 'app_locale';
  final _storage = const FlutterSecureStorage();

  Locale _locale = const Locale('fr', 'FR');
  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isFrench => _locale.languageCode == 'fr';

  Future<void> init() async {
    final saved = await _storage.read(key: _storageKey);
    if (saved == 'en') {
      _locale = const Locale('en', 'US');
    }
  }

  Future<void> setLocale(String langCode) async {
    if (langCode == 'fr') {
      _locale = const Locale('fr', 'FR');
    } else {
      _locale = const Locale('en', 'US');
    }
    await _storage.write(key: _storageKey, value: langCode);
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    await setLocale(isFrench ? 'en' : 'fr');
  }

  String tr(String key) => AppTranslations.translate(key, languageCode);
}
