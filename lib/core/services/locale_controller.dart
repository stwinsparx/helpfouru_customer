import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The app's active language, persisted across restarts. English and Hindi
/// are the only supported locales; anything else falls back to English.
class LocaleController extends ChangeNotifier {
  static const _localeKey = 'app_locale';
  static const _storage = FlutterSecureStorage();

  static const supportedLocales = [Locale('en'), Locale('hi')];

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  Future<void> load() async {
    final saved = await _storage.read(key: _localeKey);
    if (saved != null && supportedLocales.any((l) => l.languageCode == saved)) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    await _storage.write(key: _localeKey, value: locale.languageCode);
  }
}
