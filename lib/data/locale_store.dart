import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One of the app's languages. Uzbek comes in both scripts.
enum AppLanguage {
  en(Locale('en'), 'English'),
  ru(Locale('ru'), 'Русский'),
  uzLatn(Locale.fromSubtags(languageCode: 'uz'), 'Oʻzbekcha (lotin)'),
  uzCyrl(Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'), 'Ўзбекча (кирилл)');

  const AppLanguage(this.locale, this.nativeName);

  final Locale locale;

  /// The name in its own language and script, as the picker shows it; Uzbek
  /// names say which script they are in.
  final String nativeName;
}

/// The chosen language, saved on the device. English until the user picks another.
class LocaleStore extends ChangeNotifier {
  LocaleStore._(this._prefs, this._language);

  factory LocaleStore.load(SharedPreferences prefs) {
    final name = prefs.getString(key);
    final lang = AppLanguage.values.where((l) => l.name == name).firstOrNull ?? AppLanguage.en;
    return LocaleStore._(prefs, lang);
  }

  static const key = 'hifdth.locale.v1';

  final SharedPreferences _prefs;
  AppLanguage _language;

  AppLanguage get language => _language;
  Locale get locale => _language.locale;

  Future<void> set(AppLanguage l) async {
    if (l == _language) return;
    _language = l;
    notifyListeners();
    await _prefs.setString(key, l.name);
  }
}
