// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get todaysProgress => 'BUGUNGI NATIJA';

  @override
  String stepsDone(int done, int total) {
    return '$total tadan $done tasi bajarildi';
  }

  @override
  String get hifdthAssistant => 'Hifdth yordamchisi';

  @override
  String get mainNav => 'Asosiy menyu';

  @override
  String get tabHome => 'Bosh sahifa';

  @override
  String get tabPlayer => 'Pleyer';

  @override
  String get tabMethod => 'Usulim';

  @override
  String get tabSettings => 'Sozlamalar';

  @override
  String get moodHappy => 'Hifdth xursand, reja boʻyicha ketyapsiz';

  @override
  String get moodWorried => 'Hifdth xavotirlana boshladi…';

  @override
  String get moodSad => 'Hifdth xafa: mashgʻulotlar oʻtkazib yuborildi';

  @override
  String get taskDone => 'bajarildi';

  @override
  String get taskPending => 'bajarilmagan';

  @override
  String dailyGoal(int pct) {
    return 'Kunlik maqsad: $pct foiz';
  }

  @override
  String weekComplete(int done, int total) {
    return 'Bu hafta: $total kundan $done kun bajarildi';
  }

  @override
  String openPlayerLabel(String name, String summary) {
    return 'Pleyerni ochish. $name, $summary';
  }

  @override
  String stopAndClose(String name) {
    return '${name}ni toʻxtatish va yopish';
  }

  @override
  String get pause => 'Pauza';

  @override
  String get play => 'Ijro etish';

  @override
  String get signInBubble =>
      'Qurʼon boʻyicha natijangizni saqlash uchun kiring';

  @override
  String get quranProgressCaps => 'QURʼON BOʻYICHA NATIJA';

  @override
  String get opensSignIn => 'Kirish oynasini ochadi';

  @override
  String get signIn => 'Kirish';

  @override
  String get register => 'Roʻyxatdan oʻtish';

  @override
  String get signedOutHint =>
      'Kiring, soʻng oyatlarni belgilash uchun surani bosing.';

  @override
  String get undo => 'Bekor qilish';

  @override
  String allAyahsMarked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Barcha $count oyat belgilandi',
      one: 'Oyat belgilandi',
    );
    return '$_temp0';
  }

  @override
  String get allAyahsCleared => 'Barcha belgilar olib tashlandi';

  @override
  String savedLearned(String name, int learned, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return 'Saqlandi · $name: ${_temp0}dan $learned tasi yodlandi';
  }

  @override
  String get changesDiscarded => 'Oʻzgarishlar bekor qilindi';

  @override
  String learnedNotStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return 'Boshlanmagan · $_temp0';
  }

  @override
  String learnedAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return 'Yodlandi · barcha $_temp0';
  }

  @override
  String learnedSome(int learned, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return '${_temp0}dan $learned tasi yodlandi';
  }

  @override
  String surahStatusLabel(int number, String name, String status) {
    return '$number-sura, $name. $status';
  }

  @override
  String get learnedSheetHint =>
      'Oyatni belgilash uchun bosing yoki bir nechtasini belgilash uchun ustidan suring. Punktirli oyat — navbatdagisi.';

  @override
  String get done => 'Tayyor';

  @override
  String get wholeSurahLearned => 'Sura toʻliq yodlandi';

  @override
  String marksAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return 'Birdaniga ${_temp0}ni belgilaydi';
  }

  @override
  String ayahLearned(int number) {
    return '$number-oyat, yodlangan';
  }

  @override
  String ayahNotLearned(int number) {
    return '$number-oyat, yodlanmagan';
  }

  @override
  String markedLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return '$_temp0 yodlangan deb belgilandi';
  }

  @override
  String unmarkedShort(int count) {
    return '$count tasi olib tashlandi';
  }

  @override
  String unmarkedLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return '${_temp0}dan belgi olib tashlandi';
  }

  @override
  String willHaveLearned(String changes, int learned, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return '$changes. ${_temp0}dan $learned tasi yodlangan boʻladi.';
  }

  @override
  String get saveChangesQ => 'Oʻzgarishlar saqlansinmi?';

  @override
  String get saveChanges => 'Saqlash';

  @override
  String get keepEditing => 'Tahrirlashda davom etish';

  @override
  String get discardChanges => 'Saqlamaslik';

  @override
  String surahNotStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return 'Boshlanmagan · $_temp0';
  }

  @override
  String surahMemorized(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return 'Yodlandi · $_temp0';
  }

  @override
  String surahPartial(int memorized, int count, int left) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return '${_temp0}dan $memorized tasi · $left ta qoldi';
  }

  @override
  String percentMemorized(int pct) {
    return '$pct foiz yodlandi';
  }

  @override
  String surahsMemorized(int memorized, int total) {
    return '$total ta suradan $memorized tasi yodlandi';
  }

  @override
  String surahsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sura',
      one: '1 sura',
    );
    return '$_temp0';
  }

  @override
  String get progressHint =>
      'Surani bosing. Varaqlash uchun bosib turing va suring.';

  @override
  String get back => 'Orqaga';

  @override
  String working(String label) {
    return '$label, bajarilmoqda';
  }

  @override
  String get showPassword => 'Parolni koʻrsatish';

  @override
  String get hidePassword => 'Parolni yashirish';

  @override
  String get rule8chars => 'Kamida 8 ta belgi';

  @override
  String get ruleNumber => 'Raqam bor';

  @override
  String termsSentence(String terms, String privacy) {
    return 'Davom etish orqali $terms va ${privacy}ga rozilik bildirasiz.';
  }

  @override
  String get terms => 'Foydalanish shartlari';

  @override
  String get privacyPolicy => 'Maxfiylik siyosati';

  @override
  String get enterEmail => 'Emailingizni kiriting';

  @override
  String get emailIncomplete => 'Email toʻliq kiritilmaganga oʻxshaydi';

  @override
  String get accountOffline =>
      'Internet yoʻq. Akkauntni yangilash uchun internetni yoqing.';

  @override
  String get signedOutResync =>
      'Akkauntdan chiqdingiz. Natijani sinxronlash uchun qayta kiring.';

  @override
  String get yourAccount => 'Akkauntingiz';

  @override
  String resetLinkSent(String email) {
    return 'Tiklash havolasini $email manziliga yubordik';
  }

  @override
  String get logOutQ => 'Chiqasizmi?';

  @override
  String get logOutBody =>
      'Natijangiz shu telefonda qoladi. Uni akkaunt bilan sinxronlash uchun qayta kiring.';

  @override
  String get logOut => 'Chiqish';

  @override
  String get deleteAccountQ => 'Akkaunt oʻchirilsinmi?';

  @override
  String get deleteAccountBody =>
      'Akkaunt va sinxronlangan natija butunlay oʻchiriladi. Buni qaytarib boʻlmaydi.';

  @override
  String get deleteAccount => 'Akkauntni oʻchirish';

  @override
  String get accountSettingsCaps => 'AKKAUNT SOZLAMALARI';

  @override
  String get name => 'Ism';

  @override
  String get addYourName => 'Ismingizni qoʻshing';

  @override
  String get email => 'Email';

  @override
  String get notSet => 'Kiritilmagan';

  @override
  String get password => 'Parol';

  @override
  String get sendResetLink => 'Tiklash havolasini yuborish';

  @override
  String get enterName => 'Ismingizni kiriting';

  @override
  String get yourName => 'Ismingiz';

  @override
  String get nameGreeting => 'Hifdth sizga shu ism bilan murojaat qiladi.';

  @override
  String get save => 'Saqlash';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get enterPassword => 'Parolni kiriting';

  @override
  String get passwordMin8 => 'Kamida 8 ta belgi ishlating';

  @override
  String get somethingWrong => 'Nimadir xato ketdi. Qayta urinib koʻring.';

  @override
  String get change => 'Oʻzgartirish';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get continueLabel => 'Davom etish';

  @override
  String get orWord => 'yoki';

  @override
  String get continueApple => 'Apple orqali davom etish';

  @override
  String get continueGoogle => 'Google orqali davom etish';

  @override
  String get createPassword => 'Parol oʻylab toping';

  @override
  String get yourPassword => 'Parolingiz';

  @override
  String get forgotPassword => 'Parolni unutdingizmi?';

  @override
  String get createAccount => 'Akkaunt yaratish';

  @override
  String get authEmailTitle => 'Kirish yoki roʻyxatdan oʻtish';

  @override
  String get authEmailBody =>
      'Emailingizni kiriting, qolganini Hifdth oʻzi bajaradi.';

  @override
  String get authPasswordTitle => 'Xush kelibsiz';

  @override
  String get authPasswordBody =>
      'Toʻxtagan joyingizdan davom etish uchun parolni kiriting.';

  @override
  String get authCreateTitle => 'Tanishganimdan xursandman';

  @override
  String get authCreateBody =>
      'Yana ikki qadam — va natijangiz hamma joyda saqlanadi.';

  @override
  String linesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count qator',
      one: '1 qator',
    );
    return '$_temp0';
  }

  @override
  String pagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sahifa',
      one: '1 sahifa',
    );
    return '$_temp0';
  }

  @override
  String pagesHalf(String n) {
    return '$n sahifa';
  }

  @override
  String get paceOnePage => 'toʻliq bir sahifa';

  @override
  String get paceTwoPages => 'toʻliq ikki sahifa';

  @override
  String get paceHalfPage => 'taxminan yarim sahifa';

  @override
  String pacePagePlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count qator',
      one: '1 qator',
    );
    return 'bir sahifa va $_temp0';
  }

  @override
  String paceOfPage(int count) {
    return 'sahifadagi 15 qatordan $count tasi';
  }

  @override
  String get weekdaysLong =>
      'dushanba,seshanba,chorshanba,payshanba,juma,shanba,yakshanba';

  @override
  String get weekdaysShort => 'Du,Se,Ch,Pa,Ju,Sh,Ya';

  @override
  String get weekdayLetters => 'D,S,C,P,J,Sh,Y';

  @override
  String get monthsLong =>
      'yanvar,fevral,mart,aprel,may,iyun,iyul,avgust,sentabr,oktabr,noyabr,dekabr';

  @override
  String get monthsShort => 'yan,fev,mar,apr,may,iyun,iyul,avg,sen,okt,noy,dek';

  @override
  String dateShort(String weekday, int day, String month) {
    return '$weekday, $day-$month';
  }

  @override
  String withYear(String date, int year) {
    return '$year-yil, $date';
  }

  @override
  String dateLong(String weekday, int day, String month) {
    return '$weekday, $day-$month';
  }

  @override
  String get askTitle => 'Qurʼonning qancha qismini yodlagansiz?';

  @override
  String get askBody => 'Menga aytish uchun surani bosing.';

  @override
  String get planDoneToast => 'Bugungi reja bajarildi. Barakalla!';

  @override
  String get todaysPlanCaps => 'BUGUNGI REJA';

  @override
  String get tagRecite33 => '33× oʻqish';

  @override
  String get tagMemorize => 'Yodlash';

  @override
  String get tagBy22 => '22:00 gacha';

  @override
  String get morning => 'Ertalab';

  @override
  String get evening => 'Kechqurun';

  @override
  String taskRecite(String range) {
    return '${range}ni oʻqish';
  }

  @override
  String taskMemorize(String range) {
    return '${range}ni yodlash';
  }

  @override
  String taskReciteSub(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'oxirgi $count dars',
      one: 'oxirgi dars',
    );
    return '$amount · 33× yoddan · $_temp0';
  }

  @override
  String taskMemorizeSub(String amount) {
    return '$amount · taxminan bir soat, 22:00 gacha';
  }

  @override
  String get showsQuranProgress => 'Qurʼon boʻyicha natijani koʻrsatadi';

  @override
  String get hifdth => 'Hifdth';

  @override
  String get hideMessage => 'Xabarni yashirish';

  @override
  String get talkToHifdth => 'Hifdth bilan gaplashish';

  @override
  String get offlineMessage =>
      'Internet yoʻq. Oʻzgarishlar telefonda saqlanadi va internet qaytganda sinxronlanadi.';

  @override
  String get backOnlineMessage =>
      'Internet qaytdi. Oʻzgarishlar sinxronlanmoqda.';

  @override
  String get offline => 'Internet yoʻq';

  @override
  String get backOnline => 'Internet qaytdi';

  @override
  String get dailyGoalTitle => 'Kunlik maqsad';

  @override
  String get streak => 'Ketma-ketlik';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kun',
      one: '1 kun',
    );
    return '$_temp0';
  }

  @override
  String get nothingDue => 'Bugun reja yoʻq';

  @override
  String get waitingForPlan => 'Hifdth rejangizni kutyapti';

  @override
  String get noPlanYet => 'Hozircha reja yoʻq';

  @override
  String get noPlanDetail =>
      'Qayerdan boshlashni tanlang — har kungi dars shu yerda chiqadi.';

  @override
  String get setUpMyPlan => 'Reja tuzish';

  @override
  String get restDayStatus => 'Dam olish kuni. Hifdth ham dam olyapti';

  @override
  String get restDay => 'Dam olish kuni';

  @override
  String get restDayDetail =>
      'Xohlasangiz, shu haftaning darslarini bir marta takrorlang.';

  @override
  String startsOn(String date) {
    return 'Boshlanishi: $date';
  }

  @override
  String get planComplete => 'Reja bajarildi';

  @override
  String planCompleteDetail(int count, String from, String to) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return '$_temp0, $from → $to. Ularni takrorlashda davom eting.';
  }

  @override
  String get setNewRange => 'Yangi oraliq tanlash';

  @override
  String dayOf(int day, int total) {
    return '$day/$total-kun';
  }

  @override
  String get allDoneToday => 'Bugungi hammasi bajarildi';

  @override
  String leftToday(int count) {
    return 'Bugun $count ta qoldi';
  }

  @override
  String get yourPlanTitle => 'Rejangiz';

  @override
  String get changePlan => 'Rejani oʻzgartirish';

  @override
  String dayText(String text) {
    return '$text-kun';
  }

  @override
  String linesPerDayFact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count qator',
      one: '1 qator',
    );
    return '$_temp0/kun';
  }

  @override
  String finishesOn(String date) {
    return 'Tugashi: $date';
  }

  @override
  String dayOff(String day) {
    return '$day — dam olish';
  }

  @override
  String get methodName => '33 takror';

  @override
  String get loopSelected => 'Tanlanganlarni takrorlash';

  @override
  String get thenNextAyah => 'Keyin keyingi oyat';

  @override
  String nOfM(int n, int total) {
    return '$total tadan $n';
  }

  @override
  String finishedAyat(int count) {
    return 'Tugadi · $count oyat';
  }

  @override
  String get finished => 'Tugadi';

  @override
  String get playingOnce => 'Bir marta ijro etilmoqda';

  @override
  String get playsOnce => 'Bir marta';

  @override
  String get repeating => 'Takror ';

  @override
  String get repeatWord => 'Takror ';

  @override
  String ofCount(int count) {
    return ' / $count';
  }

  @override
  String get basmala => 'Basmala';

  @override
  String ayahNOfM(int n, int total) {
    return '$n/$total-oyat';
  }

  @override
  String selectionHintSome(int count, String how) {
    return '$count ta tanlandi · har biri $how ijro etiladi, soʻng keyingi tanlangani';
  }

  @override
  String get onRepeat => 'toʻxtovsiz';

  @override
  String timesShort(int count) {
    return '$count×';
  }

  @override
  String get selectionHintNone => 'Takrorlamoqchi boʻlgan oyatlarni bosing';

  @override
  String get couldntLoadAyah => 'Bu oyatni yuklab boʻlmadi.';

  @override
  String get couldntPlayAyah => 'Bu oyatni ijro etib boʻlmadi.';

  @override
  String ayahN(int n) {
    return '$n-oyat';
  }

  @override
  String surahName(String name) {
    return '$name surasi';
  }

  @override
  String reciterLine(String reciter, int surah, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return '$reciter · $surah-sura · $_temp0';
  }

  @override
  String get all => 'Hammasi';

  @override
  String get clear => 'Tozalash';

  @override
  String get selected => 'Tanlangan';

  @override
  String get select => 'Tanlash';

  @override
  String get doneSelecting => 'Tanlashni tugatish';

  @override
  String selectedAyatChange(int count) {
    return '$count ta oyat tanlangan. Oʻzgartirish uchun bosing';
  }

  @override
  String get selectAyat => 'Oyatlarni tanlash';

  @override
  String get basmalaTapToListen => 'Basmala. Tinglash uchun bosing';

  @override
  String get tapToListenBasmala => 'Basmalani tinglash uchun bosing';

  @override
  String loadingName(String name) {
    return '$name yuklanmoqda';
  }

  @override
  String couldntLoadName(String name) {
    return '${name}ni yuklab boʻlmadi';
  }

  @override
  String get checkUpToDate =>
      'Ilova yangilanganini tekshiring va qayta urinib koʻring.';

  @override
  String get tryAgain => 'Qayta urinish';

  @override
  String ayahWithText(int n, String text) {
    return '$n-oyat. $text';
  }

  @override
  String get repeatEachAyahCaps => 'HAR OYATNI TAKRORLASH';

  @override
  String audioComingSoon(String name) {
    return '$name uchun audio tez orada qoʻshiladi';
  }

  @override
  String get position => 'Joylashuv';

  @override
  String get previousAyah => 'Oldingi oyat';

  @override
  String get nextAyah => 'Keyingi oyat';

  @override
  String get repeatForever => 'Toʻxtovsiz takrorlash';

  @override
  String repeatTimes(int count) {
    return '$count marta takrorlash';
  }

  @override
  String noSurahMatches(String query) {
    return '“$query” boʻyicha sura topilmadi';
  }

  @override
  String get searchTryHint =>
      'Raqam, “Kahf” kabi nom yoki “cave” kabi maʼnoni sinab koʻring.';

  @override
  String get clearSearch => 'Qidiruvni tozalash';

  @override
  String juzMeaning(int juz, String meaning) {
    return '$juz-pora · $meaning';
  }

  @override
  String get surahs => 'Suralar';

  @override
  String get juzSuffix => ' pora';

  @override
  String get searchHint => 'Nomi, raqami yoki maʼnosi';

  @override
  String get jumpToJuz => 'Poraga oʻtish';

  @override
  String juzN(int juz) {
    return '$juz-pora';
  }

  @override
  String juzMemorized(int juz) {
    return '$juz-pora, yodlangan';
  }

  @override
  String meaningAyahs(String meaning, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return '$meaning · $_temp0';
  }

  @override
  String ayahRange(int from, int to) {
    return '$from–$to-oyatlar';
  }

  @override
  String continuesAyahRange(int from, int to) {
    return 'Davomi · $from–$to-oyatlar';
  }

  @override
  String get memorizedSuffix => ', yodlangan';

  @override
  String ayahsMemorizedSuffix(int learned, int total) {
    return ', $total oyatdan $learned tasi yodlangan';
  }

  @override
  String get methodOrigin => 'Hifz rejangiz';

  @override
  String get methodSummary =>
      'Har kecha yangi qismni yodlang va uxlang. Keyingi uch tong uni yoddan 33 martadan oʻqing. Shunda har bir dars taxminan 100 marta takrorlanadi.';

  @override
  String get step1 =>
      'Kechqurun: yangi qismni taxminan bir soatda yodlang va bu kunning soʻnggi ishi boʻlsin.';

  @override
  String get step2 => '1-tong: uni yoddan 33 marta oʻqing.';

  @override
  String get step3 => '2-tong: yana 33 marta yoddan.';

  @override
  String get step4 => '3-tong: yana 33 marta. Uch kunda taxminan 100 marta.';

  @override
  String get tip1 =>
      'Ertalabki takror uchun kuch qolishi uchun kechki darsni 22:00 gacha tugating.';

  @override
  String get tip2 =>
      'Dam olish kuni haftaning darslarini bir-ikki marta oʻqing.';

  @override
  String get howItWorksCaps => 'QANDAY ISHLAYDI';

  @override
  String get atAGlanceCaps => 'QISQACHA';

  @override
  String get tipsCaps => 'MASLAHATLAR';

  @override
  String stepLabel(String method, int n, String text) {
    return '$method, $n-qadam: $text';
  }

  @override
  String get previousStep => 'Oldingi qadam';

  @override
  String stepNOfM(int n, int total) {
    return '$total qadamdan $n-qadam';
  }

  @override
  String get pauseSteps => 'Qadamlarni toʻxtatish';

  @override
  String get playSteps => 'Qadamlarni ijro etish';

  @override
  String get nextStep => 'Keyingi qadam';

  @override
  String get learnAboutHour => 'yodlash · ~1 soat';

  @override
  String morningN(int n) {
    return '$n-tong';
  }

  @override
  String get fromMemory => 'yoddan';

  @override
  String get about100 => '≈ 100 takror';

  @override
  String minutesShort(int count) {
    return '$count daqiqa';
  }

  @override
  String get aDay => 'kuniga';

  @override
  String get demanding => 'Mashaqqatli';

  @override
  String get effort => 'yuklama';

  @override
  String get solo => 'Mustaqil';

  @override
  String get noTeacher => 'ustozsiz';

  @override
  String get startSurah => 'Boshlanish surasi';

  @override
  String get endSurah => 'Tugash surasi';

  @override
  String get planUpdated => 'Reja yangilandi';

  @override
  String planCreated(int count) {
    return 'Reja tuzildi · $count kundan 1-kuni bosh sahifada';
  }

  @override
  String get editMyPlan => 'Rejani tahrirlash';

  @override
  String get updateMyPlan => 'Rejani yangilash';

  @override
  String get createMyPlan => 'Reja tuzish';

  @override
  String get setYourPlan => 'Rejangizni tuzing';

  @override
  String methodSubtitle(String method) {
    return '$method · har kungi vazifalar bosh sahifada';
  }

  @override
  String get whatToMemorizeCaps => 'NIMANI YODLASH';

  @override
  String get fromBeginning => 'Boshidan';

  @override
  String get fatihahFirst => 'Avval Al-Fotiha';

  @override
  String get fromEnd => 'Oxiridan';

  @override
  String get nasFirst => 'Avval An-Nos, Amma porasi';

  @override
  String get rangeErrorFromEnd =>
      'Oxiridan oʻqiganda tugash nuqtasi boshlanishdan keyin boʻlishi kerak. Tugashni yoki oʻqish tartibini oʻzgartiring.';

  @override
  String get rangeErrorFromBeginning =>
      'Boshidan oʻqiganda tugash nuqtasi boshlanishdan keyin boʻlishi kerak. Tugashni yoki oʻqish tartibini oʻzgartiring.';

  @override
  String get dailyPaceCaps => 'KUNLIK SURʼAT';

  @override
  String get lines => 'Qatorlar';

  @override
  String get presetHalfPage => '½ sahifa';

  @override
  String get countedInMushaf => '15 qatorli Madina mushafi boʻyicha';

  @override
  String get restDayCaps => 'DAM OLISH KUNI';

  @override
  String get none => 'Yoʻq';

  @override
  String howItWorksLabel(String method, int count) {
    return 'Qanday ishlaydi: $method, $count qadam';
  }

  @override
  String get howItWorks => 'Qanday ishlaydi';

  @override
  String howItWorksSub(int count) {
    return '$count qadam · taxminan 100 takror';
  }

  @override
  String get start => 'Boshlanish';

  @override
  String get end => 'Tugash';

  @override
  String startSurahLabel(int n, String name) {
    return 'Boshlanish surasi: $n, $name. Oʻzgartirish';
  }

  @override
  String endSurahLabel(int n, String name) {
    return 'Tugash surasi: $n, $name. Oʻzgartirish';
  }

  @override
  String get ayah => 'Oyat';

  @override
  String get decrease => 'Kamaytirish';

  @override
  String get increase => 'Koʻpaytirish';

  @override
  String rangeLabel(String label, int min, int max) {
    return '$label, $min dan $max gacha';
  }

  @override
  String dayWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kun',
    );
    return '$_temp0';
  }

  @override
  String ayahsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oyat',
      one: '1 oyat',
    );
    return '$_temp0';
  }

  @override
  String get day1 => '1-kun';

  @override
  String get summaryHint =>
      'Oraliq toʻgʻri tanlangach, rejangiz shu yerda chiqadi.';

  @override
  String get nameOrNumber => 'Nomi yoki raqami';

  @override
  String noSurahMatchesDot(String query) {
    return '“$query” boʻyicha sura topilmadi.';
  }

  @override
  String get languageCaps => 'TIL';

  @override
  String get playbackCaps => 'IJRO';

  @override
  String get repeatEachAyah => 'Har oyatni takrorlash';

  @override
  String get repeatEachAyahNote =>
      'Pleyer keyingisiga oʻtishdan oldin oyatni necha marta oʻqiydi.';

  @override
  String get thenNextAyahNote => 'Takrorlar tugagach, keyingi oyatga oʻtish.';

  @override
  String get aboutCaps => 'ILOVA HAQIDA';

  @override
  String get version => 'Versiya';

  @override
  String get reciter => 'Qori';

  @override
  String get contactUs => 'Biz bilan bogʻlanish';

  @override
  String get soon => 'Tez orada';

  @override
  String get madeWithCare => 'Qori · Qurʼonni yod oladiganlar uchun';

  @override
  String get privacyPolicyTitle => 'Maxfiylik siyosati';

  @override
  String get today => 'Bugun';

  @override
  String get yesterday => 'Kecha';

  @override
  String get tomorrow => 'Ertaga';

  @override
  String get monthsStandalone =>
      'Yanvar,Fevral,Mart,Aprel,May,Iyun,Iyul,Avgust,Sentabr,Oktabr,Noyabr,Dekabr';

  @override
  String monthYear(String month, int year) {
    return '$year-yil, $month';
  }

  @override
  String get calendarTitle => 'Taqvim';

  @override
  String get legendDone => 'Bajarildi';

  @override
  String get legendPartial => 'Qisman';

  @override
  String get legendMissed => 'Oʻtkazib yuborildi';

  @override
  String get legendUpcoming => 'Oldinda';

  @override
  String get previousDay => 'Oldingi kun';

  @override
  String get nextDay => 'Keyingi kun';

  @override
  String get openCalendar => 'Taqvimni ochish';

  @override
  String get previousMonth => 'Oldingi oy';

  @override
  String get nextMonth => 'Keyingi oy';

  @override
  String get backToToday => 'Bugunga qaytish';

  @override
  String get dayDoneStatus => 'Bu kun hammasi bajarilgan';

  @override
  String dayPartialStatus(int done, int total) {
    return '$total tadan $done tasi bajarilgan';
  }

  @override
  String get dayMissedStatus => 'Bu kun oʻtkazib yuborilgan';

  @override
  String get dayUpcomingStatus => 'Oldinda';

  @override
  String dayTodayLabel(String date) {
    return '$date, bugun';
  }

  @override
  String longestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kun',
    );
    return 'Rekord: $_temp0';
  }

  @override
  String streakThisWeek(int done, int total) {
    return 'Bu hafta $total tadan $done';
  }

  @override
  String skippedStatus(int count, String date) {
    return '$count kun oʻtkazib yuborildi · tugash $date ga surildi';
  }

  @override
  String get signInSubtitle => 'Natijangizni barcha qurilmalarda saqlang';

  @override
  String get editProfile => 'Tahrirlash';

  @override
  String get quranWord => 'Qurʼon';

  @override
  String get statSurahs => 'Suralar';

  @override
  String get statLessons => 'Darslar';

  @override
  String get statBestStreak => 'Rekord';

  @override
  String ayahsOfQuran(int count, int total) {
    return '$total oyatdan $count tasi yodlangan';
  }
}

/// The translations for Uzbek, using the Cyrillic script (`uz_Cyrl`).
class AppLocalizationsUzCyrl extends AppLocalizationsUz {
  AppLocalizationsUzCyrl() : super('uz_Cyrl');

  @override
  String get todaysProgress => 'БУГУНГИ НАТИЖА';

  @override
  String stepsDone(int done, int total) {
    return '$total тадан $done таси бажарилди';
  }

  @override
  String get hifdthAssistant => 'Hifdth ёрдамчиси';

  @override
  String get mainNav => 'Асосий меню';

  @override
  String get tabHome => 'Бош саҳифа';

  @override
  String get tabPlayer => 'Плеер';

  @override
  String get tabMethod => 'Усулим';

  @override
  String get tabSettings => 'Созламалар';

  @override
  String get moodHappy => 'Hifdth хурсанд, режа бўйича кетяпсиз';

  @override
  String get moodWorried => 'Hifdth хавотирлана бошлади…';

  @override
  String get moodSad => 'Hifdth хафа: машғулотлар ўтказиб юборилди';

  @override
  String get taskDone => 'бажарилди';

  @override
  String get taskPending => 'бажарилмаган';

  @override
  String dailyGoal(int pct) {
    return 'Кунлик мақсад: $pct фоиз';
  }

  @override
  String weekComplete(int done, int total) {
    return 'Бу ҳафта: $total кундан $done кун бажарилди';
  }

  @override
  String openPlayerLabel(String name, String summary) {
    return 'Плеерни очиш. $name, $summary';
  }

  @override
  String stopAndClose(String name) {
    return '$nameни тўхтатиш ва ёпиш';
  }

  @override
  String get pause => 'Пауза';

  @override
  String get play => 'Ижро этиш';

  @override
  String get signInBubble => 'Қуръон бўйича натижангизни сақлаш учун киринг';

  @override
  String get quranProgressCaps => 'ҚУРЪОН БЎЙИЧА НАТИЖА';

  @override
  String get opensSignIn => 'Кириш ойнасини очади';

  @override
  String get signIn => 'Кириш';

  @override
  String get register => 'Рўйхатдан ўтиш';

  @override
  String get signedOutHint =>
      'Киринг, сўнг оятларни белгилаш учун сурани босинг.';

  @override
  String get undo => 'Бекор қилиш';

  @override
  String allAyahsMarked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Барча $count оят белгиланди',
      one: 'Оят белгиланди',
    );
    return '$_temp0';
  }

  @override
  String get allAyahsCleared => 'Барча белгилар олиб ташланди';

  @override
  String savedLearned(String name, int learned, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return 'Сақланди · $name: $_temp0дан $learned таси ёдланди';
  }

  @override
  String get changesDiscarded => 'Ўзгаришлар бекор қилинди';

  @override
  String learnedNotStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return 'Бошланмаган · $_temp0';
  }

  @override
  String learnedAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return 'Ёдланди · барча $_temp0';
  }

  @override
  String learnedSome(int learned, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return '$_temp0дан $learned таси ёдланди';
  }

  @override
  String surahStatusLabel(int number, String name, String status) {
    return '$number-сура, $name. $status';
  }

  @override
  String get learnedSheetHint =>
      'Оятни белгилаш учун босинг ёки бир нечтасини белгилаш учун устидан суринг. Пунктирли оят — навбатдагиси.';

  @override
  String get done => 'Тайёр';

  @override
  String get wholeSurahLearned => 'Сура тўлиқ ёдланди';

  @override
  String marksAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return 'Бирданига $_temp0ни белгилайди';
  }

  @override
  String ayahLearned(int number) {
    return '$number-оят, ёдланган';
  }

  @override
  String ayahNotLearned(int number) {
    return '$number-оят, ёдланмаган';
  }

  @override
  String markedLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return '$_temp0 ёдланган деб белгиланди';
  }

  @override
  String unmarkedShort(int count) {
    return '$count таси олиб ташланди';
  }

  @override
  String unmarkedLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return '$_temp0дан белги олиб ташланди';
  }

  @override
  String willHaveLearned(String changes, int learned, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return '$changes. $_temp0дан $learned таси ёдланган бўлади.';
  }

  @override
  String get saveChangesQ => 'Ўзгаришлар сақлансинми?';

  @override
  String get saveChanges => 'Сақлаш';

  @override
  String get keepEditing => 'Таҳрирлашда давом этиш';

  @override
  String get discardChanges => 'Сақламаслик';

  @override
  String surahNotStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return 'Бошланмаган · $_temp0';
  }

  @override
  String surahMemorized(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return 'Ёдланди · $_temp0';
  }

  @override
  String surahPartial(int memorized, int count, int left) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return '$_temp0дан $memorized таси · $left та қолди';
  }

  @override
  String percentMemorized(int pct) {
    return '$pct фоиз ёдланди';
  }

  @override
  String surahsMemorized(int memorized, int total) {
    return '$total та сурадан $memorized таси ёдланди';
  }

  @override
  String surahsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сура',
      one: '1 сура',
    );
    return '$_temp0';
  }

  @override
  String get progressHint =>
      'Сурани босинг. Варақлаш учун босиб туринг ва суринг.';

  @override
  String get back => 'Орқага';

  @override
  String working(String label) {
    return '$label, бажарилмоқда';
  }

  @override
  String get showPassword => 'Паролни кўрсатиш';

  @override
  String get hidePassword => 'Паролни яшириш';

  @override
  String get rule8chars => 'Камида 8 та белги';

  @override
  String get ruleNumber => 'Рақам бор';

  @override
  String termsSentence(String terms, String privacy) {
    return 'Давом этиш орқали $terms ва $privacyга розилик билдирасиз.';
  }

  @override
  String get terms => 'Фойдаланиш шартлари';

  @override
  String get privacyPolicy => 'Махфийлик сиёсати';

  @override
  String get enterEmail => 'Электрон почтангизни киритинг';

  @override
  String get emailIncomplete => 'Электрон почта тўлиқ киритилмаганга ўхшайди';

  @override
  String get accountOffline =>
      'Интернет йўқ. Аккаунтни янгилаш учун интернетни ёқинг.';

  @override
  String get signedOutResync =>
      'Аккаунтдан чиқдингиз. Натижани синхронлаш учун қайта киринг.';

  @override
  String get yourAccount => 'Аккаунтингиз';

  @override
  String resetLinkSent(String email) {
    return 'Тиклаш ҳаволасини $email манзилига юбордик';
  }

  @override
  String get logOutQ => 'Чиқасизми?';

  @override
  String get logOutBody =>
      'Натижангиз шу телефонда қолади. Уни аккаунт билан синхронлаш учун қайта киринг.';

  @override
  String get logOut => 'Чиқиш';

  @override
  String get deleteAccountQ => 'Аккаунт ўчирилсинми?';

  @override
  String get deleteAccountBody =>
      'Аккаунт ва синхронланган натижа бутунлай ўчирилади. Буни қайтариб бўлмайди.';

  @override
  String get deleteAccount => 'Аккаунтни ўчириш';

  @override
  String get accountSettingsCaps => 'АККАУНТ СОЗЛАМАЛАРИ';

  @override
  String get name => 'Исм';

  @override
  String get addYourName => 'Исмингизни қўшинг';

  @override
  String get email => 'Электрон почта';

  @override
  String get notSet => 'Киритилмаган';

  @override
  String get password => 'Парол';

  @override
  String get sendResetLink => 'Тиклаш ҳаволасини юбориш';

  @override
  String get enterName => 'Исмингизни киритинг';

  @override
  String get yourName => 'Исмингиз';

  @override
  String get nameGreeting => 'Hifdth сизга шу исм билан мурожаат қилади.';

  @override
  String get save => 'Сақлаш';

  @override
  String get cancel => 'Бекор қилиш';

  @override
  String get enterPassword => 'Паролни киритинг';

  @override
  String get passwordMin8 => 'Камида 8 та белги ишлатинг';

  @override
  String get somethingWrong => 'Нимадир хато кетди. Қайта уриниб кўринг.';

  @override
  String get change => 'Ўзгартириш';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get continueLabel => 'Давом этиш';

  @override
  String get orWord => 'ёки';

  @override
  String get continueApple => 'Apple орқали давом этиш';

  @override
  String get continueGoogle => 'Google орқали давом этиш';

  @override
  String get createPassword => 'Парол ўйлаб топинг';

  @override
  String get yourPassword => 'Паролингиз';

  @override
  String get forgotPassword => 'Паролни унутдингизми?';

  @override
  String get createAccount => 'Аккаунт яратиш';

  @override
  String get authEmailTitle => 'Кириш ёки рўйхатдан ўтиш';

  @override
  String get authEmailBody =>
      'Электрон почтангизни киритинг, қолганини Hifdth ўзи бажаради.';

  @override
  String get authPasswordTitle => 'Хуш келибсиз';

  @override
  String get authPasswordBody =>
      'Тўхтаган жойингиздан давом этиш учун паролни киритинг.';

  @override
  String get authCreateTitle => 'Танишганимдан хурсандман';

  @override
  String get authCreateBody =>
      'Яна икки қадам — ва натижангиз ҳамма жойда сақланади.';

  @override
  String linesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count қатор',
      one: '1 қатор',
    );
    return '$_temp0';
  }

  @override
  String pagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count саҳифа',
      one: '1 саҳифа',
    );
    return '$_temp0';
  }

  @override
  String pagesHalf(String n) {
    return '$n саҳифа';
  }

  @override
  String get paceOnePage => 'тўлиқ бир саҳифа';

  @override
  String get paceTwoPages => 'тўлиқ икки саҳифа';

  @override
  String get paceHalfPage => 'тахминан ярим саҳифа';

  @override
  String pacePagePlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count қатор',
      one: '1 қатор',
    );
    return 'бир саҳифа ва $_temp0';
  }

  @override
  String paceOfPage(int count) {
    return 'саҳифадаги 15 қатордан $count таси';
  }

  @override
  String get weekdaysLong =>
      'душанба,сешанба,чоршанба,пайшанба,жума,шанба,якшанба';

  @override
  String get weekdaysShort => 'Ду,Се,Чо,Па,Жу,Ша,Як';

  @override
  String get weekdayLetters => 'Д,С,Ч,П,Ж,Ш,Я';

  @override
  String get monthsLong =>
      'январ,феврал,март,апрел,май,июн,июл,август,сентябр,октябр,ноябр,декабр';

  @override
  String get monthsShort => 'янв,фев,мар,апр,май,июн,июл,авг,сен,окт,ноя,дек';

  @override
  String dateShort(String weekday, int day, String month) {
    return '$weekday, $day-$month';
  }

  @override
  String withYear(String date, int year) {
    return '$year-йил, $date';
  }

  @override
  String dateLong(String weekday, int day, String month) {
    return '$weekday, $day-$month';
  }

  @override
  String get askTitle => 'Қуръоннинг қанча қисмини ёдлагансиз?';

  @override
  String get askBody => 'Менга айтиш учун сурани босинг.';

  @override
  String get planDoneToast => 'Бугунги режа бажарилди. Баракалла!';

  @override
  String get todaysPlanCaps => 'БУГУНГИ РЕЖА';

  @override
  String get tagRecite33 => '33× ўқиш';

  @override
  String get tagMemorize => 'Ёдлаш';

  @override
  String get tagBy22 => '22:00 гача';

  @override
  String get morning => 'Эрталаб';

  @override
  String get evening => 'Кечқурун';

  @override
  String taskRecite(String range) {
    return '$rangeни ўқиш';
  }

  @override
  String taskMemorize(String range) {
    return '$rangeни ёдлаш';
  }

  @override
  String taskReciteSub(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'охирги $count дарс',
      one: 'охирги дарс',
    );
    return '$amount · 33× ёддан · $_temp0';
  }

  @override
  String taskMemorizeSub(String amount) {
    return '$amount · тахминан бир соат, 22:00 гача';
  }

  @override
  String get showsQuranProgress => 'Қуръон бўйича натижани кўрсатади';

  @override
  String get hifdth => 'Hifdth';

  @override
  String get hideMessage => 'Хабарни яшириш';

  @override
  String get talkToHifdth => 'Hifdth билан гаплашиш';

  @override
  String get offlineMessage =>
      'Интернет йўқ. Ўзгаришлар телефонда сақланади ва интернет қайтганда синхронланади.';

  @override
  String get backOnlineMessage =>
      'Интернет қайтди. Ўзгаришлар синхронланмоқда.';

  @override
  String get offline => 'Интернет йўқ';

  @override
  String get backOnline => 'Интернет қайтди';

  @override
  String get dailyGoalTitle => 'Кунлик мақсад';

  @override
  String get streak => 'Кетма-кетлик';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count кун',
      one: '1 кун',
    );
    return '$_temp0';
  }

  @override
  String get nothingDue => 'Бугун режа йўқ';

  @override
  String get waitingForPlan => 'Hifdth режангизни кутяпти';

  @override
  String get noPlanYet => 'Ҳозирча режа йўқ';

  @override
  String get noPlanDetail =>
      'Қаердан бошлашни танланг — ҳар кунги дарс шу ерда чиқади.';

  @override
  String get setUpMyPlan => 'Режа тузиш';

  @override
  String get restDayStatus => 'Дам олиш куни. Hifdth ҳам дам оляпти';

  @override
  String get restDay => 'Дам олиш куни';

  @override
  String get restDayDetail =>
      'Хоҳласангиз, шу ҳафтанинг дарсларини бир марта такрорланг.';

  @override
  String startsOn(String date) {
    return 'Бошланиши: $date';
  }

  @override
  String get planComplete => 'Режа бажарилди';

  @override
  String planCompleteDetail(int count, String from, String to) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return '$_temp0, $from → $to. Уларни такрорлашда давом этинг.';
  }

  @override
  String get setNewRange => 'Янги оралиқ танлаш';

  @override
  String dayOf(int day, int total) {
    return '$day/$total-кун';
  }

  @override
  String get allDoneToday => 'Бугунги ҳаммаси бажарилди';

  @override
  String leftToday(int count) {
    return 'Бугун $count та қолди';
  }

  @override
  String get yourPlanTitle => 'Режангиз';

  @override
  String get changePlan => 'Режани ўзгартириш';

  @override
  String dayText(String text) {
    return '$text-кун';
  }

  @override
  String linesPerDayFact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count қатор',
      one: '1 қатор',
    );
    return '$_temp0/кун';
  }

  @override
  String finishesOn(String date) {
    return 'Тугаши: $date';
  }

  @override
  String dayOff(String day) {
    return '$day — дам олиш';
  }

  @override
  String get methodName => '33 такрор';

  @override
  String get loopSelected => 'Танланганларни такрорлаш';

  @override
  String get thenNextAyah => 'Кейин кейинги оят';

  @override
  String nOfM(int n, int total) {
    return '$total тадан $n';
  }

  @override
  String finishedAyat(int count) {
    return 'Тугади · $count оят';
  }

  @override
  String get finished => 'Тугади';

  @override
  String get playingOnce => 'Бир марта ижро этилмоқда';

  @override
  String get playsOnce => 'Бир марта';

  @override
  String get repeating => 'Такрор ';

  @override
  String get repeatWord => 'Такрор ';

  @override
  String ofCount(int count) {
    return ' / $count';
  }

  @override
  String get basmala => 'Басмала';

  @override
  String ayahNOfM(int n, int total) {
    return '$n/$total-оят';
  }

  @override
  String selectionHintSome(int count, String how) {
    return '$count та танланди · ҳар бири $how ижро этилади, сўнг кейинги танлангани';
  }

  @override
  String get onRepeat => 'тўхтовсиз';

  @override
  String timesShort(int count) {
    return '$count×';
  }

  @override
  String get selectionHintNone => 'Такрорламоқчи бўлган оятларни босинг';

  @override
  String get couldntLoadAyah => 'Бу оятни юклаб бўлмади.';

  @override
  String get couldntPlayAyah => 'Бу оятни ижро этиб бўлмади.';

  @override
  String ayahN(int n) {
    return '$n-оят';
  }

  @override
  String surahName(String name) {
    return '$name сураси';
  }

  @override
  String reciterLine(String reciter, int surah, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return '$reciter · $surah-сура · $_temp0';
  }

  @override
  String get all => 'Ҳаммаси';

  @override
  String get clear => 'Тозалаш';

  @override
  String get selected => 'Танланган';

  @override
  String get select => 'Танлаш';

  @override
  String get doneSelecting => 'Танлашни тугатиш';

  @override
  String selectedAyatChange(int count) {
    return '$count та оят танланган. Ўзгартириш учун босинг';
  }

  @override
  String get selectAyat => 'Оятларни танлаш';

  @override
  String get basmalaTapToListen => 'Басмала. Тинглаш учун босинг';

  @override
  String get tapToListenBasmala => 'Басмалани тинглаш учун босинг';

  @override
  String loadingName(String name) {
    return '$name юкланмоқда';
  }

  @override
  String couldntLoadName(String name) {
    return '$nameни юклаб бўлмади';
  }

  @override
  String get checkUpToDate =>
      'Илова янгиланганини текширинг ва қайта уриниб кўринг.';

  @override
  String get tryAgain => 'Қайта уриниш';

  @override
  String ayahWithText(int n, String text) {
    return '$n-оят. $text';
  }

  @override
  String get repeatEachAyahCaps => 'ҲАР ОЯТНИ ТАКРОРЛАШ';

  @override
  String audioComingSoon(String name) {
    return '$name учун аудио тез орада қўшилади';
  }

  @override
  String get position => 'Жойлашув';

  @override
  String get previousAyah => 'Олдинги оят';

  @override
  String get nextAyah => 'Кейинги оят';

  @override
  String get repeatForever => 'Тўхтовсиз такрорлаш';

  @override
  String repeatTimes(int count) {
    return '$count марта такрорлаш';
  }

  @override
  String noSurahMatches(String query) {
    return '“$query” бўйича сура топилмади';
  }

  @override
  String get searchTryHint =>
      'Рақам, “Каҳф” каби ном ёки “cave” каби маънони синаб кўринг.';

  @override
  String get clearSearch => 'Қидирувни тозалаш';

  @override
  String juzMeaning(int juz, String meaning) {
    return '$juz-пора · $meaning';
  }

  @override
  String get surahs => 'Суралар';

  @override
  String get juzSuffix => ' пора';

  @override
  String get searchHint => 'Номи, рақами ёки маъноси';

  @override
  String get jumpToJuz => 'Порага ўтиш';

  @override
  String juzN(int juz) {
    return '$juz-пора';
  }

  @override
  String juzMemorized(int juz) {
    return '$juz-пора, ёдланган';
  }

  @override
  String meaningAyahs(String meaning, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return '$meaning · $_temp0';
  }

  @override
  String ayahRange(int from, int to) {
    return '$from–$to-оятлар';
  }

  @override
  String continuesAyahRange(int from, int to) {
    return 'Давоми · $from–$to-оятлар';
  }

  @override
  String get memorizedSuffix => ', ёдланган';

  @override
  String ayahsMemorizedSuffix(int learned, int total) {
    return ', $total оятдан $learned таси ёдланган';
  }

  @override
  String get methodOrigin => 'Ҳифз режангиз';

  @override
  String get methodSummary =>
      'Ҳар кеча янги қисмни ёдланг ва ухланг. Кейинги уч тонг уни ёддан 33 мартадан ўқинг. Шунда ҳар бир дарс тахминан 100 марта такрорланади.';

  @override
  String get step1 =>
      'Кечқурун: янги қисмни тахминан бир соатда ёдланг ва бу куннинг сўнгги иши бўлсин.';

  @override
  String get step2 => '1-тонг: уни ёддан 33 марта ўқинг.';

  @override
  String get step3 => '2-тонг: яна 33 марта ёддан.';

  @override
  String get step4 => '3-тонг: яна 33 марта. Уч кунда тахминан 100 марта.';

  @override
  String get tip1 =>
      'Эрталабки такрор учун куч қолиши учун кечки дарсни 22:00 гача тугатинг.';

  @override
  String get tip2 => 'Дам олиш куни ҳафтанинг дарсларини бир-икки марта ўқинг.';

  @override
  String get howItWorksCaps => 'ҚАНДАЙ ИШЛАЙДИ';

  @override
  String get atAGlanceCaps => 'ҚИСҚАЧА';

  @override
  String get tipsCaps => 'МАСЛАҲАТЛАР';

  @override
  String stepLabel(String method, int n, String text) {
    return '$method, $n-қадам: $text';
  }

  @override
  String get previousStep => 'Олдинги қадам';

  @override
  String stepNOfM(int n, int total) {
    return '$total қадамдан $n-қадам';
  }

  @override
  String get pauseSteps => 'Қадамларни тўхтатиш';

  @override
  String get playSteps => 'Қадамларни ижро этиш';

  @override
  String get nextStep => 'Кейинги қадам';

  @override
  String get learnAboutHour => 'ёдлаш · ~1 соат';

  @override
  String morningN(int n) {
    return '$n-тонг';
  }

  @override
  String get fromMemory => 'ёддан';

  @override
  String get about100 => '≈ 100 такрор';

  @override
  String minutesShort(int count) {
    return '$count дақиқа';
  }

  @override
  String get aDay => 'кунига';

  @override
  String get demanding => 'Машаққатли';

  @override
  String get effort => 'юклама';

  @override
  String get solo => 'Мустақил';

  @override
  String get noTeacher => 'устозсиз';

  @override
  String get startSurah => 'Бошланиш сураси';

  @override
  String get endSurah => 'Тугаш сураси';

  @override
  String get planUpdated => 'Режа янгиланди';

  @override
  String planCreated(int count) {
    return 'Режа тузилди · $count кундан 1-куни бош саҳифада';
  }

  @override
  String get editMyPlan => 'Режани таҳрирлаш';

  @override
  String get updateMyPlan => 'Режани янгилаш';

  @override
  String get createMyPlan => 'Режа тузиш';

  @override
  String get setYourPlan => 'Режангизни тузинг';

  @override
  String methodSubtitle(String method) {
    return '$method · ҳар кунги вазифалар бош саҳифада';
  }

  @override
  String get whatToMemorizeCaps => 'НИМАНИ ЁДЛАШ';

  @override
  String get fromBeginning => 'Бошидан';

  @override
  String get fatihahFirst => 'Аввал Ал-Фотиҳа';

  @override
  String get fromEnd => 'Охиридан';

  @override
  String get nasFirst => 'Аввал Ан-Нос, Амма пораси';

  @override
  String get rangeErrorFromEnd =>
      'Охиридан ўқиганда тугаш нуқтаси бошланишдан кейин бўлиши керак. Тугашни ёки ўқиш тартибини ўзгартиринг.';

  @override
  String get rangeErrorFromBeginning =>
      'Бошидан ўқиганда тугаш нуқтаси бошланишдан кейин бўлиши керак. Тугашни ёки ўқиш тартибини ўзгартиринг.';

  @override
  String get dailyPaceCaps => 'КУНЛИК СУРЪАТ';

  @override
  String get lines => 'Қаторлар';

  @override
  String get presetHalfPage => '½ саҳифа';

  @override
  String get countedInMushaf => '15 қаторли Мадина мушафи бўйича';

  @override
  String get restDayCaps => 'ДАМ ОЛИШ КУНИ';

  @override
  String get none => 'Йўқ';

  @override
  String howItWorksLabel(String method, int count) {
    return 'Қандай ишлайди: $method, $count қадам';
  }

  @override
  String get howItWorks => 'Қандай ишлайди';

  @override
  String howItWorksSub(int count) {
    return '$count қадам · тахминан 100 такрор';
  }

  @override
  String get start => 'Бошланиш';

  @override
  String get end => 'Тугаш';

  @override
  String startSurahLabel(int n, String name) {
    return 'Бошланиш сураси: $n, $name. Ўзгартириш';
  }

  @override
  String endSurahLabel(int n, String name) {
    return 'Тугаш сураси: $n, $name. Ўзгартириш';
  }

  @override
  String get ayah => 'Оят';

  @override
  String get decrease => 'Камайтириш';

  @override
  String get increase => 'Кўпайтириш';

  @override
  String rangeLabel(String label, int min, int max) {
    return '$label, $min дан $max гача';
  }

  @override
  String dayWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'кун',
    );
    return '$_temp0';
  }

  @override
  String ayahsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count оят',
      one: '1 оят',
    );
    return '$_temp0';
  }

  @override
  String get day1 => '1-кун';

  @override
  String get summaryHint => 'Оралиқ тўғри танлангач, режангиз шу ерда чиқади.';

  @override
  String get nameOrNumber => 'Номи ёки рақами';

  @override
  String noSurahMatchesDot(String query) {
    return '“$query” бўйича сура топилмади.';
  }

  @override
  String get languageCaps => 'ТИЛ';

  @override
  String get playbackCaps => 'ИЖРО';

  @override
  String get repeatEachAyah => 'Ҳар оятни такрорлаш';

  @override
  String get repeatEachAyahNote =>
      'Плеер кейингисига ўтишдан олдин оятни неча марта ўқийди.';

  @override
  String get thenNextAyahNote => 'Такрорлар тугагач, кейинги оятга ўтиш.';

  @override
  String get aboutCaps => 'ИЛОВА ҲАҚИДА';

  @override
  String get version => 'Версия';

  @override
  String get reciter => 'Қори';

  @override
  String get contactUs => 'Биз билан боғланиш';

  @override
  String get soon => 'Тез орада';

  @override
  String get madeWithCare => 'Qori · Қуръонни ёд оладиганлар учун';

  @override
  String get privacyPolicyTitle => 'Махфийлик сиёсати';

  @override
  String get today => 'Бугун';

  @override
  String get yesterday => 'Кеча';

  @override
  String get tomorrow => 'Эртага';

  @override
  String get monthsStandalone =>
      'Январ,Феврал,Март,Апрел,Май,Июн,Июл,Август,Сентябр,Октябр,Ноябр,Декабр';

  @override
  String monthYear(String month, int year) {
    return '$year-йил, $month';
  }

  @override
  String get calendarTitle => 'Тақвим';

  @override
  String get legendDone => 'Бажарилди';

  @override
  String get legendPartial => 'Қисман';

  @override
  String get legendMissed => 'Ўтказиб юборилди';

  @override
  String get legendUpcoming => 'Олдинда';

  @override
  String get previousDay => 'Олдинги кун';

  @override
  String get nextDay => 'Кейинги кун';

  @override
  String get openCalendar => 'Тақвимни очиш';

  @override
  String get previousMonth => 'Олдинги ой';

  @override
  String get nextMonth => 'Кейинги ой';

  @override
  String get backToToday => 'Бугунга қайтиш';

  @override
  String get dayDoneStatus => 'Бу кун ҳаммаси бажарилган';

  @override
  String dayPartialStatus(int done, int total) {
    return '$total тадан $done таси бажарилган';
  }

  @override
  String get dayMissedStatus => 'Бу кун ўтказиб юборилган';

  @override
  String get dayUpcomingStatus => 'Олдинда';

  @override
  String dayTodayLabel(String date) {
    return '$date, бугун';
  }

  @override
  String longestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count кун',
    );
    return 'Рекорд: $_temp0';
  }

  @override
  String streakThisWeek(int done, int total) {
    return 'Бу ҳафта $total тадан $done';
  }

  @override
  String skippedStatus(int count, String date) {
    return '$count кун ўтказиб юборилди · тугаш $date га сурилди';
  }

  @override
  String get signInSubtitle => 'Натижангизни барча қурилмаларда сақланг';

  @override
  String get editProfile => 'Таҳрирлаш';

  @override
  String get quranWord => 'Қуръон';

  @override
  String get statSurahs => 'Суралар';

  @override
  String get statLessons => 'Дарслар';

  @override
  String get statBestStreak => 'Рекорд';

  @override
  String ayahsOfQuran(int count, int total) {
    return '$total оятдан $count таси ёдланган';
  }
}
