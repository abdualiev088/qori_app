import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// `context.l10n.someText`. Falls back to English where no localizations are
/// installed (plain test harnesses), so a missing delegate never crashes a screen.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this) ?? _en;
}

final AppLocalizations _en = lookupAppLocalizations(const Locale('en'));
