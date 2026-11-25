import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
    Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl')
  ];

  /// No description provided for @todaysProgress.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S PROGRESS'**
  String get todaysProgress;

  /// No description provided for @stepsDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String stepsDone(int done, int total);

  /// No description provided for @hifdthAssistant.
  ///
  /// In en, this message translates to:
  /// **'Hifdth assistant'**
  String get hifdthAssistant;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @mainNav.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get mainNav;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabPlayer.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get tabPlayer;

  /// No description provided for @tabMethod.
  ///
  /// In en, this message translates to:
  /// **'My Method'**
  String get tabMethod;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Hifdth is happy, you\'re on track'**
  String get moodHappy;

  /// No description provided for @moodWorried.
  ///
  /// In en, this message translates to:
  /// **'Hifdth is getting worried…'**
  String get moodWorried;

  /// No description provided for @moodSad.
  ///
  /// In en, this message translates to:
  /// **'Hifdth is sad, sessions missed'**
  String get moodSad;

  /// No description provided for @taskDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get taskDone;

  /// No description provided for @taskPending.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get taskPending;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal {pct} percent'**
  String dailyGoal(int pct);

  /// No description provided for @weekComplete.
  ///
  /// In en, this message translates to:
  /// **'This week: {done} of {total} days complete'**
  String weekComplete(int done, int total);

  /// No description provided for @openPlayerLabel.
  ///
  /// In en, this message translates to:
  /// **'Open player. {name}, {summary}'**
  String openPlayerLabel(String name, String summary);

  /// No description provided for @stopAndClose.
  ///
  /// In en, this message translates to:
  /// **'Stop and close {name}'**
  String stopAndClose(String name);

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @signInBubble.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your Quran progress'**
  String get signInBubble;

  /// No description provided for @quranProgressCaps.
  ///
  /// In en, this message translates to:
  /// **'QURAN PROGRESS'**
  String get quranProgressCaps;

  /// No description provided for @opensSignIn.
  ///
  /// In en, this message translates to:
  /// **'Opens sign-in'**
  String get opensSignIn;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @signedOutHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in, then tap a surah to mark its ayahs.'**
  String get signedOutHint;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @allAyahsMarked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ayah marked} other{All {count} ayahs marked}}'**
  String allAyahsMarked(int count);

  /// No description provided for @allAyahsCleared.
  ///
  /// In en, this message translates to:
  /// **'All ayahs cleared'**
  String get allAyahsCleared;

  /// No description provided for @savedLearned.
  ///
  /// In en, this message translates to:
  /// **'Saved · {name}, {learned} of {count, plural, =1{1 ayah} other{{count} ayahs}} learned'**
  String savedLearned(String name, int learned, int count);

  /// No description provided for @changesDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Changes discarded'**
  String get changesDiscarded;

  /// No description provided for @learnedNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started · {count, plural, =1{1 ayah} other{{count} ayahs}}'**
  String learnedNotStarted(int count);

  /// No description provided for @learnedAll.
  ///
  /// In en, this message translates to:
  /// **'Learned · all {count, plural, =1{1 ayah} other{{count} ayahs}}'**
  String learnedAll(int count);

  /// No description provided for @learnedSome.
  ///
  /// In en, this message translates to:
  /// **'{learned} of {count, plural, =1{1 ayah} other{{count} ayahs}} learned'**
  String learnedSome(int learned, int count);

  /// No description provided for @surahStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Surah {number}, {name}. {status}'**
  String surahStatusLabel(int number, String name, String status);

  /// No description provided for @learnedSheetHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an ayah to mark it, or slide across ayahs to mark several. The dashed one is next.'**
  String get learnedSheetHint;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @wholeSurahLearned.
  ///
  /// In en, this message translates to:
  /// **'Whole surah learned'**
  String get wholeSurahLearned;

  /// No description provided for @marksAll.
  ///
  /// In en, this message translates to:
  /// **'Marks all {count, plural, =1{1 ayah} other{{count} ayahs}} at once'**
  String marksAll(int count);

  /// No description provided for @ayahLearned.
  ///
  /// In en, this message translates to:
  /// **'Ayah {number}, learned'**
  String ayahLearned(int number);

  /// No description provided for @ayahNotLearned.
  ///
  /// In en, this message translates to:
  /// **'Ayah {number}, not learned'**
  String ayahNotLearned(int number);

  /// No description provided for @markedLearned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ayah} other{{count} ayahs}} marked learned'**
  String markedLearned(int count);

  /// No description provided for @unmarkedShort.
  ///
  /// In en, this message translates to:
  /// **'{count} unmarked'**
  String unmarkedShort(int count);

  /// No description provided for @unmarkedLong.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ayah} other{{count} ayahs}} unmarked'**
  String unmarkedLong(int count);

  /// No description provided for @willHaveLearned.
  ///
  /// In en, this message translates to:
  /// **'{changes}. You\'ll have {learned} of {count, plural, =1{1 ayah} other{{count} ayahs}} learned.'**
  String willHaveLearned(String changes, int learned, int count);

  /// No description provided for @saveChangesQ.
  ///
  /// In en, this message translates to:
  /// **'Save changes?'**
  String get saveChangesQ;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get discardChanges;

  /// No description provided for @surahNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started · {count, plural, =1{1 ayah} other{{count} ayahs}}'**
  String surahNotStarted(int count);

  /// No description provided for @surahMemorized.
  ///
  /// In en, this message translates to:
  /// **'Memorized · {count, plural, =1{1 ayah} other{{count} ayahs}}'**
  String surahMemorized(int count);

  /// No description provided for @surahPartial.
  ///
  /// In en, this message translates to:
  /// **'{memorized} of {count, plural, =1{1 ayah} other{{count} ayahs}} · {left} to go'**
  String surahPartial(int memorized, int count, int left);

  /// No description provided for @percentMemorized.
  ///
  /// In en, this message translates to:
  /// **'{pct} percent memorized'**
  String percentMemorized(int pct);

  /// No description provided for @surahsMemorized.
  ///
  /// In en, this message translates to:
  /// **'{memorized} of {total} surahs memorized'**
  String surahsMemorized(int memorized, int total);

  /// No description provided for @surahsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 surah} other{{count} surahs}}'**
  String surahsCount(int count);

  /// No description provided for @progressHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a surah. Press and hold, then slide, to browse.'**
  String get progressHint;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @working.
  ///
  /// In en, this message translates to:
  /// **'{label}, working'**
  String working(String label);

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @rule8chars.
  ///
  /// In en, this message translates to:
  /// **'8+ characters'**
  String get rule8chars;

  /// No description provided for @ruleNumber.
  ///
  /// In en, this message translates to:
  /// **'A number'**
  String get ruleNumber;

  /// No description provided for @termsSentence.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the {terms} and {privacy}.'**
  String termsSentence(String terms, String privacy);

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @emailIncomplete.
  ///
  /// In en, this message translates to:
  /// **'That email looks incomplete'**
  String get emailIncomplete;

  /// No description provided for @accountOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Turn on the internet to update your account.'**
  String get accountOffline;

  /// No description provided for @signedOutResync.
  ///
  /// In en, this message translates to:
  /// **'You were signed out. Sign in again to sync your progress.'**
  String get signedOutResync;

  /// No description provided for @yourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get yourAccount;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'We sent a reset link to {email}'**
  String resetLinkSent(String email);

  /// No description provided for @logOutQ.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutQ;

  /// No description provided for @logOutBody.
  ///
  /// In en, this message translates to:
  /// **'Your progress stays on this phone. Sign in again to sync it with your account.'**
  String get logOutBody;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @deleteAccountQ.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountQ;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your account and its synced progress are deleted for good. This can\'t be undone.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @accountSettingsCaps.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT SETTINGS'**
  String get accountSettingsCaps;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @addYourName.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get addYourName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterName;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @nameGreeting.
  ///
  /// In en, this message translates to:
  /// **'This is how Hifdth greets you.'**
  String get nameGreeting;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @passwordMin8.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get passwordMin8;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWrong;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @orWord.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orWord;

  /// No description provided for @continueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueApple;

  /// No description provided for @continueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueGoogle;

  /// No description provided for @createPassword.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get createPassword;

  /// No description provided for @yourPassword.
  ///
  /// In en, this message translates to:
  /// **'Your password'**
  String get yourPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @authEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in or sign up'**
  String get authEmailTitle;

  /// No description provided for @authEmailBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and Hifdth will take it from there.'**
  String get authEmailBody;

  /// No description provided for @authPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authPasswordTitle;

  /// No description provided for @authPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to pick up where you left off.'**
  String get authPasswordBody;

  /// No description provided for @authCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Nice to meet you'**
  String get authCreateTitle;

  /// No description provided for @authCreateBody.
  ///
  /// In en, this message translates to:
  /// **'Two more things and your progress is saved everywhere.'**
  String get authCreateBody;

  /// No description provided for @linesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line} other{{count} lines}}'**
  String linesCount(int count);

  /// No description provided for @pagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 page} other{{count} pages}}'**
  String pagesCount(int count);

  /// No description provided for @pagesHalf.
  ///
  /// In en, this message translates to:
  /// **'{n} pages'**
  String pagesHalf(String n);

  /// No description provided for @paceOnePage.
  ///
  /// In en, this message translates to:
  /// **'one full page'**
  String get paceOnePage;

  /// No description provided for @paceTwoPages.
  ///
  /// In en, this message translates to:
  /// **'two full pages'**
  String get paceTwoPages;

  /// No description provided for @paceHalfPage.
  ///
  /// In en, this message translates to:
  /// **'about half a page'**
  String get paceHalfPage;

  /// No description provided for @pacePagePlus.
  ///
  /// In en, this message translates to:
  /// **'a page and {count, plural, =1{1 line} other{{count} lines}}'**
  String pacePagePlus(int count);

  /// No description provided for @paceOfPage.
  ///
  /// In en, this message translates to:
  /// **'{count} of 15 lines on a page'**
  String paceOfPage(int count);

  /// No description provided for @weekdaysLong.
  ///
  /// In en, this message translates to:
  /// **'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday'**
  String get weekdaysLong;

  /// No description provided for @weekdaysShort.
  ///
  /// In en, this message translates to:
  /// **'Mon,Tue,Wed,Thu,Fri,Sat,Sun'**
  String get weekdaysShort;

  /// No description provided for @weekdayLetters.
  ///
  /// In en, this message translates to:
  /// **'M,T,W,T,F,S,S'**
  String get weekdayLetters;

  /// No description provided for @monthsLong.
  ///
  /// In en, this message translates to:
  /// **'January,February,March,April,May,June,July,August,September,October,November,December'**
  String get monthsLong;

  /// No description provided for @monthsShort.
  ///
  /// In en, this message translates to:
  /// **'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'**
  String get monthsShort;

  /// No description provided for @dateShort.
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {day} {month}'**
  String dateShort(String weekday, int day, String month);

  /// No description provided for @withYear.
  ///
  /// In en, this message translates to:
  /// **'{date} {year}'**
  String withYear(String date, int year);

  /// No description provided for @dateLong.
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {day} {month}'**
  String dateLong(String weekday, int day, String month);

  /// No description provided for @askTitle.
  ///
  /// In en, this message translates to:
  /// **'How much of the Quran have you memorised?'**
  String get askTitle;

  /// No description provided for @askBody.
  ///
  /// In en, this message translates to:
  /// **'Tap a surah to tell me.'**
  String get askBody;

  /// No description provided for @planDoneToast.
  ///
  /// In en, this message translates to:
  /// **'Today\'s plan is done. Well done!'**
  String get planDoneToast;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @todaysPlanCaps.
  ///
  /// In en, this message translates to:
  /// **'TODAY\'S PLAN'**
  String get todaysPlanCaps;

  /// No description provided for @tagRecite33.
  ///
  /// In en, this message translates to:
  /// **'Recite 33×'**
  String get tagRecite33;

  /// No description provided for @tagMemorize.
  ///
  /// In en, this message translates to:
  /// **'Memorize'**
  String get tagMemorize;

  /// No description provided for @tagBy22.
  ///
  /// In en, this message translates to:
  /// **'by 22:00'**
  String get tagBy22;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @taskRecite.
  ///
  /// In en, this message translates to:
  /// **'Recite {range}'**
  String taskRecite(String range);

  /// No description provided for @taskMemorize.
  ///
  /// In en, this message translates to:
  /// **'Memorize {range}'**
  String taskMemorize(String range);

  /// No description provided for @taskReciteSub.
  ///
  /// In en, this message translates to:
  /// **'{amount} · 33× from memory · last {count, plural, =1{lesson} other{{count} lessons}}'**
  String taskReciteSub(String amount, int count);

  /// No description provided for @taskMemorizeSub.
  ///
  /// In en, this message translates to:
  /// **'{amount} · about one hour, before 22:00'**
  String taskMemorizeSub(String amount);

  /// No description provided for @showsQuranProgress.
  ///
  /// In en, this message translates to:
  /// **'Shows your Quran progress'**
  String get showsQuranProgress;

  /// No description provided for @hifdth.
  ///
  /// In en, this message translates to:
  /// **'Hifdth'**
  String get hifdth;

  /// No description provided for @hideMessage.
  ///
  /// In en, this message translates to:
  /// **'Hide message'**
  String get hideMessage;

  /// No description provided for @talkToHifdth.
  ///
  /// In en, this message translates to:
  /// **'Talk to Hifdth'**
  String get talkToHifdth;

  /// No description provided for @offlineMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Changes are saved on this phone and sync when you\'re back online.'**
  String get offlineMessage;

  /// No description provided for @backOnlineMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re back online. Your changes are syncing.'**
  String get backOnlineMessage;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @backOnline.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get backOnline;

  /// No description provided for @dailyGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get dailyGoalTitle;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String daysCount(int count);

  /// No description provided for @nothingDue.
  ///
  /// In en, this message translates to:
  /// **'Nothing due today'**
  String get nothingDue;

  /// No description provided for @waitingForPlan.
  ///
  /// In en, this message translates to:
  /// **'Hifdth is waiting for your plan'**
  String get waitingForPlan;

  /// No description provided for @noPlanYet.
  ///
  /// In en, this message translates to:
  /// **'No plan yet'**
  String get noPlanYet;

  /// No description provided for @noPlanDetail.
  ///
  /// In en, this message translates to:
  /// **'Pick where to start; each day\'s lesson shows up here.'**
  String get noPlanDetail;

  /// No description provided for @setUpMyPlan.
  ///
  /// In en, this message translates to:
  /// **'Set up my plan'**
  String get setUpMyPlan;

  /// No description provided for @restDayStatus.
  ///
  /// In en, this message translates to:
  /// **'Rest day. Hifdth is resting too'**
  String get restDayStatus;

  /// No description provided for @restDay.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get restDay;

  /// No description provided for @restDayDetail.
  ///
  /// In en, this message translates to:
  /// **'Read this week\'s lessons once, if you like.'**
  String get restDayDetail;

  /// No description provided for @startsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String startsOn(String date);

  /// No description provided for @planComplete.
  ///
  /// In en, this message translates to:
  /// **'Plan complete'**
  String get planComplete;

  /// No description provided for @planCompleteDetail.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ayah} other{{count} ayahs}}, {from} → {to}. Keep revising them.'**
  String planCompleteDetail(int count, String from, String to);

  /// No description provided for @setNewRange.
  ///
  /// In en, this message translates to:
  /// **'Set a new range'**
  String get setNewRange;

  /// No description provided for @dayOf.
  ///
  /// In en, this message translates to:
  /// **'Day {day}/{total}'**
  String dayOf(int day, int total);

  /// No description provided for @allDoneToday.
  ///
  /// In en, this message translates to:
  /// **'All done today'**
  String get allDoneToday;

  /// No description provided for @leftToday.
  ///
  /// In en, this message translates to:
  /// **'{count} left today'**
  String leftToday(int count);

  /// No description provided for @yourPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get yourPlanTitle;

  /// No description provided for @changePlan.
  ///
  /// In en, this message translates to:
  /// **'Change plan'**
  String get changePlan;

  /// No description provided for @dayText.
  ///
  /// In en, this message translates to:
  /// **'Day {text}'**
  String dayText(String text);

  /// No description provided for @linesPerDayFact.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line} other{{count} lines}}/day'**
  String linesPerDayFact(int count);

  /// No description provided for @finishesOn.
  ///
  /// In en, this message translates to:
  /// **'Finishes {date}'**
  String finishesOn(String date);

  /// No description provided for @dayOff.
  ///
  /// In en, this message translates to:
  /// **'{day} off'**
  String dayOff(String day);

  /// No description provided for @methodName.
  ///
  /// In en, this message translates to:
  /// **'33 repetitions'**
  String get methodName;

  /// No description provided for @loopSelected.
  ///
  /// In en, this message translates to:
  /// **'Loop selected'**
  String get loopSelected;

  /// No description provided for @thenNextAyah.
  ///
  /// In en, this message translates to:
  /// **'Then next ayah'**
  String get thenNextAyah;

  /// No description provided for @nOfM.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total}'**
  String nOfM(int n, int total);

  /// No description provided for @finishedAyat.
  ///
  /// In en, this message translates to:
  /// **'Finished · {count} ayat'**
  String finishedAyat(int count);

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @playingOnce.
  ///
  /// In en, this message translates to:
  /// **'Playing once'**
  String get playingOnce;

  /// No description provided for @playsOnce.
  ///
  /// In en, this message translates to:
  /// **'Plays once'**
  String get playsOnce;

  /// No description provided for @repeating.
  ///
  /// In en, this message translates to:
  /// **'Repeating '**
  String get repeating;

  /// No description provided for @repeatWord.
  ///
  /// In en, this message translates to:
  /// **'Repeat '**
  String get repeatWord;

  /// No description provided for @ofCount.
  ///
  /// In en, this message translates to:
  /// **' of {count}'**
  String ofCount(int count);

  /// No description provided for @basmala.
  ///
  /// In en, this message translates to:
  /// **'Basmala'**
  String get basmala;

  /// No description provided for @ayahNOfM.
  ///
  /// In en, this message translates to:
  /// **'Ayah {n} of {total}'**
  String ayahNOfM(int n, int total);

  /// No description provided for @selectionHintSome.
  ///
  /// In en, this message translates to:
  /// **'{count} selected · each plays {how}, then the next selected one'**
  String selectionHintSome(int count, String how);

  /// No description provided for @onRepeat.
  ///
  /// In en, this message translates to:
  /// **'on repeat'**
  String get onRepeat;

  /// No description provided for @timesShort.
  ///
  /// In en, this message translates to:
  /// **'{count}×'**
  String timesShort(int count);

  /// No description provided for @selectionHintNone.
  ///
  /// In en, this message translates to:
  /// **'Tap the ayat you want to repeat'**
  String get selectionHintNone;

  /// No description provided for @couldntLoadAyah.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this ayah.'**
  String get couldntLoadAyah;

  /// No description provided for @couldntPlayAyah.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t play this ayah.'**
  String get couldntPlayAyah;

  /// No description provided for @ayahN.
  ///
  /// In en, this message translates to:
  /// **'Ayah {n}'**
  String ayahN(int n);

  /// No description provided for @surahName.
  ///
  /// In en, this message translates to:
  /// **'Surah {name}'**
  String surahName(String name);

  /// No description provided for @reciterLine.
  ///
  /// In en, this message translates to:
  /// **'{reciter} · Surah {surah} · {count, plural, =1{1 ayah} other{{count} ayahs}}'**
  String reciterLine(String reciter, int surah, int count);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selected;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @doneSelecting.
  ///
  /// In en, this message translates to:
  /// **'Done selecting'**
  String get doneSelecting;

  /// No description provided for @selectedAyatChange.
  ///
  /// In en, this message translates to:
  /// **'Selected, {count} ayat. Tap to change'**
  String selectedAyatChange(int count);

  /// No description provided for @selectAyat.
  ///
  /// In en, this message translates to:
  /// **'Select ayat'**
  String get selectAyat;

  /// No description provided for @basmalaTapToListen.
  ///
  /// In en, this message translates to:
  /// **'Basmala. Tap to listen'**
  String get basmalaTapToListen;

  /// No description provided for @tapToListenBasmala.
  ///
  /// In en, this message translates to:
  /// **'Tap to listen to the Basmala'**
  String get tapToListenBasmala;

  /// No description provided for @loadingName.
  ///
  /// In en, this message translates to:
  /// **'Loading {name}'**
  String loadingName(String name);

  /// No description provided for @couldntLoadName.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load {name}'**
  String couldntLoadName(String name);

  /// No description provided for @checkUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Check the app is up to date, then try again.'**
  String get checkUpToDate;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @ayahWithText.
  ///
  /// In en, this message translates to:
  /// **'Ayah {n}. {text}'**
  String ayahWithText(int n, String text);

  /// No description provided for @repeatEachAyahCaps.
  ///
  /// In en, this message translates to:
  /// **'REPEAT EACH AYAH'**
  String get repeatEachAyahCaps;

  /// No description provided for @audioComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Audio for {name} is coming soon'**
  String audioComingSoon(String name);

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @previousAyah.
  ///
  /// In en, this message translates to:
  /// **'Previous ayah'**
  String get previousAyah;

  /// No description provided for @nextAyah.
  ///
  /// In en, this message translates to:
  /// **'Next ayah'**
  String get nextAyah;

  /// No description provided for @repeatForever.
  ///
  /// In en, this message translates to:
  /// **'Repeat forever'**
  String get repeatForever;

  /// No description provided for @repeatTimes.
  ///
  /// In en, this message translates to:
  /// **'Repeat {count} times'**
  String repeatTimes(int count);

  /// No description provided for @noSurahMatches.
  ///
  /// In en, this message translates to:
  /// **'No surah matches “{query}”'**
  String noSurahMatches(String query);

  /// No description provided for @searchTryHint.
  ///
  /// In en, this message translates to:
  /// **'Try a number, a name like “Kahf”, or a meaning like “cave”.'**
  String get searchTryHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @juzMeaning.
  ///
  /// In en, this message translates to:
  /// **'Juz {juz} · {meaning}'**
  String juzMeaning(int juz, String meaning);

  /// No description provided for @surahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get surahs;

  /// No description provided for @juzSuffix.
  ///
  /// In en, this message translates to:
  /// **' juz'**
  String get juzSuffix;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Name, number or meaning'**
  String get searchHint;

  /// No description provided for @jumpToJuz.
  ///
  /// In en, this message translates to:
  /// **'Jump to juz'**
  String get jumpToJuz;

  /// No description provided for @juzN.
  ///
  /// In en, this message translates to:
  /// **'Juz {juz}'**
  String juzN(int juz);

  /// No description provided for @juzMemorized.
  ///
  /// In en, this message translates to:
  /// **'Juz {juz}, memorized'**
  String juzMemorized(int juz);

  /// No description provided for @meaningAyahs.
  ///
  /// In en, this message translates to:
  /// **'{meaning} · {count, plural, =1{1 ayah} other{{count} ayahs}}'**
  String meaningAyahs(String meaning, int count);

  /// No description provided for @ayahRange.
  ///
  /// In en, this message translates to:
  /// **'ayahs {from}–{to}'**
  String ayahRange(int from, int to);

  /// No description provided for @continuesAyahRange.
  ///
  /// In en, this message translates to:
  /// **'Continues · ayahs {from}–{to}'**
  String continuesAyahRange(int from, int to);

  /// No description provided for @memorizedSuffix.
  ///
  /// In en, this message translates to:
  /// **', memorized'**
  String get memorizedSuffix;

  /// No description provided for @ayahsMemorizedSuffix.
  ///
  /// In en, this message translates to:
  /// **', {learned} of {total} ayahs memorized'**
  String ayahsMemorizedSuffix(int learned, int total);

  /// No description provided for @methodOrigin.
  ///
  /// In en, this message translates to:
  /// **'Your Hifz plan'**
  String get methodOrigin;

  /// No description provided for @methodSummary.
  ///
  /// In en, this message translates to:
  /// **'Learn a new portion each evening and sleep on it. On the next three mornings, recite it 33 times from memory. That makes about 100 recitations of every lesson.'**
  String get methodSummary;

  /// No description provided for @step1.
  ///
  /// In en, this message translates to:
  /// **'Evening: memorize the new portion, about an hour, as the last thing you do.'**
  String get step1;

  /// No description provided for @step2.
  ///
  /// In en, this message translates to:
  /// **'Morning 1: recite it 33 times from memory.'**
  String get step2;

  /// No description provided for @step3.
  ///
  /// In en, this message translates to:
  /// **'Morning 2: another 33 times from memory.'**
  String get step3;

  /// No description provided for @step4.
  ///
  /// In en, this message translates to:
  /// **'Morning 3: 33 more. That\'s about 100 in three days.'**
  String get step4;

  /// No description provided for @tip1.
  ///
  /// In en, this message translates to:
  /// **'Finish the evening lesson before 22:00 so the mornings stay possible.'**
  String get tip1;

  /// No description provided for @tip2.
  ///
  /// In en, this message translates to:
  /// **'On your rest day, read the week\'s lessons once or twice.'**
  String get tip2;

  /// No description provided for @howItWorksCaps.
  ///
  /// In en, this message translates to:
  /// **'HOW IT WORKS'**
  String get howItWorksCaps;

  /// No description provided for @atAGlanceCaps.
  ///
  /// In en, this message translates to:
  /// **'AT A GLANCE'**
  String get atAGlanceCaps;

  /// No description provided for @tipsCaps.
  ///
  /// In en, this message translates to:
  /// **'TIPS'**
  String get tipsCaps;

  /// No description provided for @stepLabel.
  ///
  /// In en, this message translates to:
  /// **'{method}, step {n}: {text}'**
  String stepLabel(String method, int n, String text);

  /// No description provided for @previousStep.
  ///
  /// In en, this message translates to:
  /// **'Previous step'**
  String get previousStep;

  /// No description provided for @stepNOfM.
  ///
  /// In en, this message translates to:
  /// **'Step {n} of {total}'**
  String stepNOfM(int n, int total);

  /// No description provided for @pauseSteps.
  ///
  /// In en, this message translates to:
  /// **'Pause steps'**
  String get pauseSteps;

  /// No description provided for @playSteps.
  ///
  /// In en, this message translates to:
  /// **'Play steps'**
  String get playSteps;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStep;

  /// No description provided for @learnAboutHour.
  ///
  /// In en, this message translates to:
  /// **'learn · ~1 h'**
  String get learnAboutHour;

  /// No description provided for @morningN.
  ///
  /// In en, this message translates to:
  /// **'Morning {n}'**
  String morningN(int n);

  /// No description provided for @fromMemory.
  ///
  /// In en, this message translates to:
  /// **'from memory'**
  String get fromMemory;

  /// No description provided for @about100.
  ///
  /// In en, this message translates to:
  /// **'≈ 100 recitations'**
  String get about100;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @aDay.
  ///
  /// In en, this message translates to:
  /// **'a day'**
  String get aDay;

  /// No description provided for @demanding.
  ///
  /// In en, this message translates to:
  /// **'Demanding'**
  String get demanding;

  /// No description provided for @effort.
  ///
  /// In en, this message translates to:
  /// **'effort'**
  String get effort;

  /// No description provided for @solo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get solo;

  /// No description provided for @noTeacher.
  ///
  /// In en, this message translates to:
  /// **'no teacher'**
  String get noTeacher;

  /// No description provided for @startSurah.
  ///
  /// In en, this message translates to:
  /// **'Start surah'**
  String get startSurah;

  /// No description provided for @endSurah.
  ///
  /// In en, this message translates to:
  /// **'End surah'**
  String get endSurah;

  /// No description provided for @planUpdated.
  ///
  /// In en, this message translates to:
  /// **'Plan updated'**
  String get planUpdated;

  /// No description provided for @planCreated.
  ///
  /// In en, this message translates to:
  /// **'Plan created · day 1 of {count} is on Home'**
  String planCreated(int count);

  /// No description provided for @editMyPlan.
  ///
  /// In en, this message translates to:
  /// **'Edit my plan'**
  String get editMyPlan;

  /// No description provided for @updateMyPlan.
  ///
  /// In en, this message translates to:
  /// **'Update my plan'**
  String get updateMyPlan;

  /// No description provided for @createMyPlan.
  ///
  /// In en, this message translates to:
  /// **'Create my plan'**
  String get createMyPlan;

  /// No description provided for @setYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Set your plan'**
  String get setYourPlan;

  /// No description provided for @methodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{method} · each day\'s tasks appear on Home'**
  String methodSubtitle(String method);

  /// No description provided for @whatToMemorizeCaps.
  ///
  /// In en, this message translates to:
  /// **'WHAT TO MEMORIZE'**
  String get whatToMemorizeCaps;

  /// No description provided for @fromBeginning.
  ///
  /// In en, this message translates to:
  /// **'From the beginning'**
  String get fromBeginning;

  /// No description provided for @fatihahFirst.
  ///
  /// In en, this message translates to:
  /// **'Al-Fatihah first'**
  String get fatihahFirst;

  /// No description provided for @fromEnd.
  ///
  /// In en, this message translates to:
  /// **'From the end'**
  String get fromEnd;

  /// No description provided for @nasFirst.
  ///
  /// In en, this message translates to:
  /// **'An-Nas first, Juz ʿAmma'**
  String get nasFirst;

  /// No description provided for @rangeErrorFromEnd.
  ///
  /// In en, this message translates to:
  /// **'The end must come after the start when reading from the end. Change the end or the reading order.'**
  String get rangeErrorFromEnd;

  /// No description provided for @rangeErrorFromBeginning.
  ///
  /// In en, this message translates to:
  /// **'The end must come after the start when reading from the beginning. Change the end or the reading order.'**
  String get rangeErrorFromBeginning;

  /// No description provided for @dailyPaceCaps.
  ///
  /// In en, this message translates to:
  /// **'DAILY PACE'**
  String get dailyPaceCaps;

  /// No description provided for @lines.
  ///
  /// In en, this message translates to:
  /// **'Lines'**
  String get lines;

  /// No description provided for @presetHalfPage.
  ///
  /// In en, this message translates to:
  /// **'½ page'**
  String get presetHalfPage;

  /// No description provided for @countedInMushaf.
  ///
  /// In en, this message translates to:
  /// **'Counted in the 15-line Madani mushaf'**
  String get countedInMushaf;

  /// No description provided for @restDayCaps.
  ///
  /// In en, this message translates to:
  /// **'REST DAY'**
  String get restDayCaps;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @howItWorksLabel.
  ///
  /// In en, this message translates to:
  /// **'How it works, {method} in {count} steps'**
  String howItWorksLabel(String method, int count);

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @howItWorksSub.
  ///
  /// In en, this message translates to:
  /// **'{count} steps · about 100 recitations'**
  String howItWorksSub(int count);

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @startSurahLabel.
  ///
  /// In en, this message translates to:
  /// **'Start surah: {n}, {name}. Change'**
  String startSurahLabel(int n, String name);

  /// No description provided for @endSurahLabel.
  ///
  /// In en, this message translates to:
  /// **'End surah: {n}, {name}. Change'**
  String endSurahLabel(int n, String name);

  /// No description provided for @ayah.
  ///
  /// In en, this message translates to:
  /// **'Ayah'**
  String get ayah;

  /// No description provided for @decrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease'**
  String get decrease;

  /// No description provided for @increase.
  ///
  /// In en, this message translates to:
  /// **'Increase'**
  String get increase;

  /// No description provided for @rangeLabel.
  ///
  /// In en, this message translates to:
  /// **'{label}, {min} to {max}'**
  String rangeLabel(String label, int min, int max);

  /// No description provided for @dayWord.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String dayWord(int count);

  /// No description provided for @ayahsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ayah} other{{count} ayahs}}'**
  String ayahsCount(int count);

  /// No description provided for @day1.
  ///
  /// In en, this message translates to:
  /// **'Day 1'**
  String get day1;

  /// No description provided for @summaryHint.
  ///
  /// In en, this message translates to:
  /// **'Your plan shows here once the range is right.'**
  String get summaryHint;

  /// No description provided for @nameOrNumber.
  ///
  /// In en, this message translates to:
  /// **'Name or number'**
  String get nameOrNumber;

  /// No description provided for @noSurahMatchesDot.
  ///
  /// In en, this message translates to:
  /// **'No surah matches “{query}”.'**
  String noSurahMatchesDot(String query);

  /// No description provided for @languageCaps.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get languageCaps;

  /// No description provided for @languageNote.
  ///
  /// In en, this message translates to:
  /// **'Surah meanings and the English translation of the ayahs stay in English for now.'**
  String get languageNote;

  /// No description provided for @playbackCaps.
  ///
  /// In en, this message translates to:
  /// **'PLAYBACK'**
  String get playbackCaps;

  /// No description provided for @repeatEachAyah.
  ///
  /// In en, this message translates to:
  /// **'Repeat each ayah'**
  String get repeatEachAyah;

  /// No description provided for @repeatEachAyahNote.
  ///
  /// In en, this message translates to:
  /// **'How many times the player plays an ayah before moving on.'**
  String get repeatEachAyahNote;

  /// No description provided for @thenNextAyahNote.
  ///
  /// In en, this message translates to:
  /// **'Go on to the next ayah when the repeats finish.'**
  String get thenNextAyahNote;

  /// No description provided for @aboutCaps.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get aboutCaps;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @reciter.
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get reciter;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contactUs;

  /// No description provided for @soon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// No description provided for @madeWithCare.
  ///
  /// In en, this message translates to:
  /// **'Hifz · made for those who memorize the Quran'**
  String get madeWithCare;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langRussian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get langRussian;

  /// No description provided for @langUzbekLatin.
  ///
  /// In en, this message translates to:
  /// **'Uzbek (Latin)'**
  String get langUzbekLatin;

  /// No description provided for @langUzbekCyrillic.
  ///
  /// In en, this message translates to:
  /// **'Uzbek (Cyrillic)'**
  String get langUzbekCyrillic;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicyTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'uz':
      {
        switch (locale.scriptCode) {
          case 'Cyrl':
            return AppLocalizationsUzCyrl();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
