// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get todaysProgress => 'TODAY\'S PROGRESS';

  @override
  String stepsDone(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get hifdthAssistant => 'Hifdth assistant';

  @override
  String get profile => 'Profile';

  @override
  String get mainNav => 'Main';

  @override
  String get tabHome => 'Home';

  @override
  String get tabPlayer => 'Player';

  @override
  String get tabMethod => 'My Method';

  @override
  String get tabSettings => 'Settings';

  @override
  String get moodHappy => 'Hifdth is happy, you\'re on track';

  @override
  String get moodWorried => 'Hifdth is getting worried…';

  @override
  String get moodSad => 'Hifdth is sad, sessions missed';

  @override
  String get taskDone => 'done';

  @override
  String get taskPending => 'pending';

  @override
  String dailyGoal(int pct) {
    return 'Daily goal $pct percent';
  }

  @override
  String weekComplete(int done, int total) {
    return 'This week: $done of $total days complete';
  }

  @override
  String openPlayerLabel(String name, String summary) {
    return 'Open player. $name, $summary';
  }

  @override
  String stopAndClose(String name) {
    return 'Stop and close $name';
  }

  @override
  String get pause => 'Pause';

  @override
  String get play => 'Play';

  @override
  String get signInBubble => 'Sign in to save your Quran progress';

  @override
  String get quranProgressCaps => 'QURAN PROGRESS';

  @override
  String get opensSignIn => 'Opens sign-in';

  @override
  String get signIn => 'Sign in';

  @override
  String get register => 'Register';

  @override
  String get signedOutHint => 'Sign in, then tap a surah to mark its ayahs.';

  @override
  String get undo => 'Undo';

  @override
  String allAyahsMarked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count ayahs marked',
      one: '1 ayah marked',
    );
    return '$_temp0';
  }

  @override
  String get allAyahsCleared => 'All ayahs cleared';

  @override
  String savedLearned(String name, int learned, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return 'Saved · $name, $learned of $_temp0 learned';
  }

  @override
  String get changesDiscarded => 'Changes discarded';

  @override
  String learnedNotStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return 'Not started · $_temp0';
  }

  @override
  String learnedAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return 'Learned · all $_temp0';
  }

  @override
  String learnedSome(int learned, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$learned of $_temp0 learned';
  }

  @override
  String surahStatusLabel(int number, String name, String status) {
    return 'Surah $number, $name. $status';
  }

  @override
  String get learnedSheetHint =>
      'Tap an ayah to mark it, or slide across ayahs to mark several. The dashed one is next.';

  @override
  String get done => 'Done';

  @override
  String get wholeSurahLearned => 'Whole surah learned';

  @override
  String marksAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return 'Marks all $_temp0 at once';
  }

  @override
  String ayahLearned(int number) {
    return 'Ayah $number, learned';
  }

  @override
  String ayahNotLearned(int number) {
    return 'Ayah $number, not learned';
  }

  @override
  String markedLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$_temp0 marked learned';
  }

  @override
  String unmarkedShort(int count) {
    return '$count unmarked';
  }

  @override
  String unmarkedLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$_temp0 unmarked';
  }

  @override
  String willHaveLearned(String changes, int learned, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$changes. You\'ll have $learned of $_temp0 learned.';
  }

  @override
  String get saveChangesQ => 'Save changes?';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String surahNotStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return 'Not started · $_temp0';
  }

  @override
  String surahMemorized(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return 'Memorized · $_temp0';
  }

  @override
  String surahPartial(int memorized, int count, int left) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$memorized of $_temp0 · $left to go';
  }

  @override
  String percentMemorized(int pct) {
    return '$pct percent memorized';
  }

  @override
  String surahsMemorized(int memorized, int total) {
    return '$memorized of $total surahs memorized';
  }

  @override
  String surahsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count surahs',
      one: '1 surah',
    );
    return '$_temp0';
  }

  @override
  String get progressHint =>
      'Tap a surah. Press and hold, then slide, to browse.';

  @override
  String get back => 'Back';

  @override
  String working(String label) {
    return '$label, working';
  }

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get rule8chars => '8+ characters';

  @override
  String get ruleNumber => 'A number';

  @override
  String termsSentence(String terms, String privacy) {
    return 'By continuing you agree to the $terms and $privacy.';
  }

  @override
  String get terms => 'Terms';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get emailIncomplete => 'That email looks incomplete';

  @override
  String get accountOffline =>
      'You\'re offline. Turn on the internet to update your account.';

  @override
  String get signedOutResync =>
      'You were signed out. Sign in again to sync your progress.';

  @override
  String get yourAccount => 'Your account';

  @override
  String resetLinkSent(String email) {
    return 'We sent a reset link to $email';
  }

  @override
  String get logOutQ => 'Log out?';

  @override
  String get logOutBody =>
      'Your progress stays on this phone. Sign in again to sync it with your account.';

  @override
  String get logOut => 'Log out';

  @override
  String get deleteAccountQ => 'Delete your account?';

  @override
  String get deleteAccountBody =>
      'Your account and its synced progress are deleted for good. This can\'t be undone.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get accountSettingsCaps => 'ACCOUNT SETTINGS';

  @override
  String get name => 'Name';

  @override
  String get addYourName => 'Add your name';

  @override
  String get email => 'Email';

  @override
  String get notSet => 'Not set';

  @override
  String get password => 'Password';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get enterName => 'Enter your name';

  @override
  String get yourName => 'Your name';

  @override
  String get nameGreeting => 'This is how Hifdth greets you.';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get passwordMin8 => 'Use at least 8 characters';

  @override
  String get somethingWrong => 'Something went wrong. Please try again.';

  @override
  String get change => 'Change';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get continueLabel => 'Continue';

  @override
  String get orWord => 'or';

  @override
  String get continueApple => 'Continue with Apple';

  @override
  String get continueGoogle => 'Continue with Google';

  @override
  String get createPassword => 'Create a password';

  @override
  String get yourPassword => 'Your password';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get createAccount => 'Create account';

  @override
  String get authEmailTitle => 'Sign in or sign up';

  @override
  String get authEmailBody =>
      'Enter your email and Hifdth will take it from there.';

  @override
  String get authPasswordTitle => 'Welcome back';

  @override
  String get authPasswordBody =>
      'Enter your password to pick up where you left off.';

  @override
  String get authCreateTitle => 'Nice to meet you';

  @override
  String get authCreateBody =>
      'Two more things and your progress is saved everywhere.';

  @override
  String linesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '1 line',
    );
    return '$_temp0';
  }

  @override
  String pagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String pagesHalf(String n) {
    return '$n pages';
  }

  @override
  String get paceOnePage => 'one full page';

  @override
  String get paceTwoPages => 'two full pages';

  @override
  String get paceHalfPage => 'about half a page';

  @override
  String pacePagePlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '1 line',
    );
    return 'a page and $_temp0';
  }

  @override
  String paceOfPage(int count) {
    return '$count of 15 lines on a page';
  }

  @override
  String get weekdaysLong =>
      'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';

  @override
  String get weekdaysShort => 'Mon,Tue,Wed,Thu,Fri,Sat,Sun';

  @override
  String get weekdayLetters => 'M,T,W,T,F,S,S';

  @override
  String get monthsLong =>
      'January,February,March,April,May,June,July,August,September,October,November,December';

  @override
  String get monthsShort => 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec';

  @override
  String dateShort(String weekday, int day, String month) {
    return '$weekday, $day $month';
  }

  @override
  String withYear(String date, int year) {
    return '$date $year';
  }

  @override
  String dateLong(String weekday, int day, String month) {
    return '$weekday, $day $month';
  }

  @override
  String get askTitle => 'How much of the Quran have you memorised?';

  @override
  String get askBody => 'Tap a surah to tell me.';

  @override
  String get planDoneToast => 'Today\'s plan is done. Well done!';

  @override
  String get todaysPlanCaps => 'TODAY\'S PLAN';

  @override
  String get tagRecite33 => 'Recite 33×';

  @override
  String get tagMemorize => 'Memorize';

  @override
  String get tagBy22 => 'by 22:00';

  @override
  String get morning => 'Morning';

  @override
  String get evening => 'Evening';

  @override
  String taskRecite(String range) {
    return 'Recite $range';
  }

  @override
  String taskMemorize(String range) {
    return 'Memorize $range';
  }

  @override
  String taskReciteSub(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lessons',
      one: 'lesson',
    );
    return '$amount · 33× from memory · last $_temp0';
  }

  @override
  String taskMemorizeSub(String amount) {
    return '$amount · about one hour, before 22:00';
  }

  @override
  String get showsQuranProgress => 'Shows your Quran progress';

  @override
  String get hifdth => 'Hifdth';

  @override
  String get hideMessage => 'Hide message';

  @override
  String get talkToHifdth => 'Talk to Hifdth';

  @override
  String get offlineMessage =>
      'You\'re offline. Changes are saved on this phone and sync when you\'re back online.';

  @override
  String get backOnlineMessage =>
      'You\'re back online. Your changes are syncing.';

  @override
  String get offline => 'Offline';

  @override
  String get backOnline => 'Back online';

  @override
  String get dailyGoalTitle => 'Daily goal';

  @override
  String get streak => 'Streak';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get nothingDue => 'Nothing due today';

  @override
  String get waitingForPlan => 'Hifdth is waiting for your plan';

  @override
  String get noPlanYet => 'No plan yet';

  @override
  String get noPlanDetail =>
      'Pick where to start; each day\'s lesson shows up here.';

  @override
  String get setUpMyPlan => 'Set up my plan';

  @override
  String get restDayStatus => 'Rest day. Hifdth is resting too';

  @override
  String get restDay => 'Rest day';

  @override
  String get restDayDetail => 'Read this week\'s lessons once, if you like.';

  @override
  String startsOn(String date) {
    return 'Starts $date';
  }

  @override
  String get planComplete => 'Plan complete';

  @override
  String planCompleteDetail(int count, String from, String to) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$_temp0, $from → $to. Keep revising them.';
  }

  @override
  String get setNewRange => 'Set a new range';

  @override
  String dayOf(int day, int total) {
    return 'Day $day/$total';
  }

  @override
  String get allDoneToday => 'All done today';

  @override
  String leftToday(int count) {
    return '$count left today';
  }

  @override
  String get yourPlanTitle => 'Your plan';

  @override
  String get changePlan => 'Change plan';

  @override
  String dayText(String text) {
    return 'Day $text';
  }

  @override
  String linesPerDayFact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '1 line',
    );
    return '$_temp0/day';
  }

  @override
  String finishesOn(String date) {
    return 'Finishes $date';
  }

  @override
  String dayOff(String day) {
    return '$day off';
  }

  @override
  String get methodName => '33 repetitions';

  @override
  String get loopSelected => 'Loop selected';

  @override
  String get thenNextAyah => 'Then next ayah';

  @override
  String nOfM(int n, int total) {
    return '$n of $total';
  }

  @override
  String finishedAyat(int count) {
    return 'Finished · $count ayat';
  }

  @override
  String get finished => 'Finished';

  @override
  String get playingOnce => 'Playing once';

  @override
  String get playsOnce => 'Plays once';

  @override
  String get repeating => 'Repeating ';

  @override
  String get repeatWord => 'Repeat ';

  @override
  String ofCount(int count) {
    return ' of $count';
  }

  @override
  String get basmala => 'Basmala';

  @override
  String ayahNOfM(int n, int total) {
    return 'Ayah $n of $total';
  }

  @override
  String selectionHintSome(int count, String how) {
    return '$count selected · each plays $how, then the next selected one';
  }

  @override
  String get onRepeat => 'on repeat';

  @override
  String timesShort(int count) {
    return '$count×';
  }

  @override
  String get selectionHintNone => 'Tap the ayat you want to repeat';

  @override
  String get couldntLoadAyah => 'Couldn\'t load this ayah.';

  @override
  String get couldntPlayAyah => 'Couldn\'t play this ayah.';

  @override
  String ayahN(int n) {
    return 'Ayah $n';
  }

  @override
  String surahName(String name) {
    return 'Surah $name';
  }

  @override
  String reciterLine(String reciter, int surah, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$reciter · Surah $surah · $_temp0';
  }

  @override
  String get all => 'All';

  @override
  String get clear => 'Clear';

  @override
  String get selected => 'Selected';

  @override
  String get select => 'Select';

  @override
  String get doneSelecting => 'Done selecting';

  @override
  String selectedAyatChange(int count) {
    return 'Selected, $count ayat. Tap to change';
  }

  @override
  String get selectAyat => 'Select ayat';

  @override
  String get basmalaTapToListen => 'Basmala. Tap to listen';

  @override
  String get tapToListenBasmala => 'Tap to listen to the Basmala';

  @override
  String loadingName(String name) {
    return 'Loading $name';
  }

  @override
  String couldntLoadName(String name) {
    return 'Couldn\'t load $name';
  }

  @override
  String get checkUpToDate => 'Check the app is up to date, then try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String ayahWithText(int n, String text) {
    return 'Ayah $n. $text';
  }

  @override
  String get repeatEachAyahCaps => 'REPEAT EACH AYAH';

  @override
  String audioComingSoon(String name) {
    return 'Audio for $name is coming soon';
  }

  @override
  String get position => 'Position';

  @override
  String get previousAyah => 'Previous ayah';

  @override
  String get nextAyah => 'Next ayah';

  @override
  String get repeatForever => 'Repeat forever';

  @override
  String repeatTimes(int count) {
    return 'Repeat $count times';
  }

  @override
  String noSurahMatches(String query) {
    return 'No surah matches “$query”';
  }

  @override
  String get searchTryHint =>
      'Try a number, a name like “Kahf”, or a meaning like “cave”.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String juzMeaning(int juz, String meaning) {
    return 'Juz $juz · $meaning';
  }

  @override
  String get surahs => 'Surahs';

  @override
  String get juzSuffix => ' juz';

  @override
  String get searchHint => 'Name, number or meaning';

  @override
  String get jumpToJuz => 'Jump to juz';

  @override
  String juzN(int juz) {
    return 'Juz $juz';
  }

  @override
  String juzMemorized(int juz) {
    return 'Juz $juz, memorized';
  }

  @override
  String meaningAyahs(String meaning, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$meaning · $_temp0';
  }

  @override
  String ayahRange(int from, int to) {
    return 'ayahs $from–$to';
  }

  @override
  String continuesAyahRange(int from, int to) {
    return 'Continues · ayahs $from–$to';
  }

  @override
  String get memorizedSuffix => ', memorized';

  @override
  String ayahsMemorizedSuffix(int learned, int total) {
    return ', $learned of $total ayahs memorized';
  }

  @override
  String get methodOrigin => 'Your Hifz plan';

  @override
  String get methodSummary =>
      'Learn a new portion each evening and sleep on it. On the next three mornings, recite it 33 times from memory. That makes about 100 recitations of every lesson.';

  @override
  String get step1 =>
      'Evening: memorize the new portion, about an hour, as the last thing you do.';

  @override
  String get step2 => 'Morning 1: recite it 33 times from memory.';

  @override
  String get step3 => 'Morning 2: another 33 times from memory.';

  @override
  String get step4 => 'Morning 3: 33 more. That\'s about 100 in three days.';

  @override
  String get tip1 =>
      'Finish the evening lesson before 22:00 so the mornings stay possible.';

  @override
  String get tip2 =>
      'On your rest day, read the week\'s lessons once or twice.';

  @override
  String get howItWorksCaps => 'HOW IT WORKS';

  @override
  String get atAGlanceCaps => 'AT A GLANCE';

  @override
  String get tipsCaps => 'TIPS';

  @override
  String stepLabel(String method, int n, String text) {
    return '$method, step $n: $text';
  }

  @override
  String get previousStep => 'Previous step';

  @override
  String stepNOfM(int n, int total) {
    return 'Step $n of $total';
  }

  @override
  String get pauseSteps => 'Pause steps';

  @override
  String get playSteps => 'Play steps';

  @override
  String get nextStep => 'Next step';

  @override
  String get learnAboutHour => 'learn · ~1 h';

  @override
  String morningN(int n) {
    return 'Morning $n';
  }

  @override
  String get fromMemory => 'from memory';

  @override
  String get about100 => '≈ 100 recitations';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get aDay => 'a day';

  @override
  String get demanding => 'Demanding';

  @override
  String get effort => 'effort';

  @override
  String get solo => 'Solo';

  @override
  String get noTeacher => 'no teacher';

  @override
  String get startSurah => 'Start surah';

  @override
  String get endSurah => 'End surah';

  @override
  String get planUpdated => 'Plan updated';

  @override
  String planCreated(int count) {
    return 'Plan created · day 1 of $count is on Home';
  }

  @override
  String get editMyPlan => 'Edit my plan';

  @override
  String get updateMyPlan => 'Update my plan';

  @override
  String get createMyPlan => 'Create my plan';

  @override
  String get setYourPlan => 'Set your plan';

  @override
  String methodSubtitle(String method) {
    return '$method · each day\'s tasks appear on Home';
  }

  @override
  String get whatToMemorizeCaps => 'WHAT TO MEMORIZE';

  @override
  String get fromBeginning => 'From the beginning';

  @override
  String get fatihahFirst => 'Al-Fatihah first';

  @override
  String get fromEnd => 'From the end';

  @override
  String get nasFirst => 'An-Nas first, Juz ʿAmma';

  @override
  String get rangeErrorFromEnd =>
      'The end must come after the start when reading from the end. Change the end or the reading order.';

  @override
  String get rangeErrorFromBeginning =>
      'The end must come after the start when reading from the beginning. Change the end or the reading order.';

  @override
  String get dailyPaceCaps => 'DAILY PACE';

  @override
  String get lines => 'Lines';

  @override
  String get presetHalfPage => '½ page';

  @override
  String get countedInMushaf => 'Counted in the 15-line Madani mushaf';

  @override
  String get restDayCaps => 'REST DAY';

  @override
  String get none => 'None';

  @override
  String howItWorksLabel(String method, int count) {
    return 'How it works, $method in $count steps';
  }

  @override
  String get howItWorks => 'How it works';

  @override
  String howItWorksSub(int count) {
    return '$count steps · about 100 recitations';
  }

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String startSurahLabel(int n, String name) {
    return 'Start surah: $n, $name. Change';
  }

  @override
  String endSurahLabel(int n, String name) {
    return 'End surah: $n, $name. Change';
  }

  @override
  String get ayah => 'Ayah';

  @override
  String get decrease => 'Decrease';

  @override
  String get increase => 'Increase';

  @override
  String rangeLabel(String label, int min, int max) {
    return '$label, $min to $max';
  }

  @override
  String dayWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String ayahsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$_temp0';
  }

  @override
  String get day1 => 'Day 1';

  @override
  String get summaryHint => 'Your plan shows here once the range is right.';

  @override
  String get nameOrNumber => 'Name or number';

  @override
  String noSurahMatchesDot(String query) {
    return 'No surah matches “$query”.';
  }

  @override
  String get languageCaps => 'LANGUAGE';

  @override
  String get languageNote =>
      'Surah meanings and the English translation of the ayahs stay in English for now.';

  @override
  String get playbackCaps => 'PLAYBACK';

  @override
  String get repeatEachAyah => 'Repeat each ayah';

  @override
  String get repeatEachAyahNote =>
      'How many times the player plays an ayah before moving on.';

  @override
  String get thenNextAyahNote =>
      'Go on to the next ayah when the repeats finish.';

  @override
  String get aboutCaps => 'ABOUT';

  @override
  String get version => 'Version';

  @override
  String get reciter => 'Reciter';

  @override
  String get contactUs => 'Contact us';

  @override
  String get soon => 'Soon';

  @override
  String get madeWithCare => 'Qori · made for those who memorize the Quran';

  @override
  String get langEnglish => 'English';

  @override
  String get langRussian => 'Russian';

  @override
  String get langUzbekLatin => 'Uzbek (Latin)';

  @override
  String get langUzbekCyrillic => 'Uzbek (Cyrillic)';

  @override
  String get privacyPolicyTitle => 'Privacy policy';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get monthsStandalone =>
      'January,February,March,April,May,June,July,August,September,October,November,December';

  @override
  String monthYear(String month, int year) {
    return '$month $year';
  }

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get legendDone => 'Done';

  @override
  String get legendPartial => 'Partly done';

  @override
  String get legendMissed => 'Missed';

  @override
  String get legendUpcoming => 'Coming up';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get openCalendar => 'Open the calendar';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get backToToday => 'Back to today';

  @override
  String get dayDoneStatus => 'All done that day';

  @override
  String dayPartialStatus(int done, int total) {
    return '$done of $total done that day';
  }

  @override
  String get dayMissedStatus => 'Missed that day';

  @override
  String get dayUpcomingStatus => 'Coming up';

  @override
  String dayTodayLabel(String date) {
    return '$date, today';
  }

  @override
  String longestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return 'Longest $_temp0';
  }

  @override
  String streakThisWeek(int done, int total) {
    return '$done of $total this week';
  }

  @override
  String skippedStatus(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Skipped $count days',
      one: 'Skipped 1 day',
    );
    return '$_temp0 · finish moved to $date';
  }
}
