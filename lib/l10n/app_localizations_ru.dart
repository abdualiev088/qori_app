// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get todaysProgress => 'ПРОГРЕСС ЗА ДЕНЬ';

  @override
  String stepsDone(int done, int total) {
    return 'Готово $done из $total';
  }

  @override
  String get hifdthAssistant => 'Помощник Hifdth';

  @override
  String get profile => 'Профиль';

  @override
  String get mainNav => 'Главное меню';

  @override
  String get tabHome => 'Главная';

  @override
  String get tabPlayer => 'Плеер';

  @override
  String get tabMethod => 'Мой метод';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get moodHappy => 'Hifdth доволен, вы идёте по плану';

  @override
  String get moodWorried => 'Hifdth начинает волноваться…';

  @override
  String get moodSad => 'Hifdth грустит: занятия пропущены';

  @override
  String get taskDone => 'выполнено';

  @override
  String get taskPending => 'не выполнено';

  @override
  String dailyGoal(int pct) {
    return 'Цель дня: $pct процентов';
  }

  @override
  String weekComplete(int done, int total) {
    return 'Эта неделя: выполнено дней — $done из $total';
  }

  @override
  String openPlayerLabel(String name, String summary) {
    return 'Открыть плеер. $name, $summary';
  }

  @override
  String stopAndClose(String name) {
    return 'Остановить и закрыть $name';
  }

  @override
  String get pause => 'Пауза';

  @override
  String get play => 'Воспроизвести';

  @override
  String get signInBubble => 'Войдите, чтобы сохранять прогресс по Корану';

  @override
  String get quranProgressCaps => 'ПРОГРЕСС ПО КОРАНУ';

  @override
  String get opensSignIn => 'Открывает вход';

  @override
  String get signIn => 'Войти';

  @override
  String get register => 'Регистрация';

  @override
  String get signedOutHint =>
      'Войдите, затем нажмите на суру, чтобы отметить аяты.';

  @override
  String get undo => 'Отменить';

  @override
  String allAyahsMarked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Отмечены все $count аята',
      many: 'Отмечены все $count аятов',
      few: 'Отмечены все $count аята',
      one: 'Отмечен $count аят',
    );
    return '$_temp0';
  }

  @override
  String get allAyahsCleared => 'Все отметки сняты';

  @override
  String savedLearned(String name, int learned, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return 'Сохранено · $name: выучено $learned из $_temp0';
  }

  @override
  String get changesDiscarded => 'Изменения отменены';

  @override
  String learnedNotStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return 'Не начата · $_temp0';
  }

  @override
  String learnedAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return 'Выучена · все $_temp0';
  }

  @override
  String learnedSome(int learned, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return 'Выучено $learned из $_temp0';
  }

  @override
  String surahStatusLabel(int number, String name, String status) {
    return 'Сура $number, $name. $status';
  }

  @override
  String get learnedSheetHint =>
      'Нажмите на аят, чтобы отметить его, или проведите по нескольким аятам. Пунктиром обведён следующий.';

  @override
  String get done => 'Готово';

  @override
  String get wholeSurahLearned => 'Сура выучена целиком';

  @override
  String marksAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return 'Отмечает сразу $_temp0';
  }

  @override
  String ayahLearned(int number) {
    return 'Аят $number, выучен';
  }

  @override
  String ayahNotLearned(int number) {
    return 'Аят $number, не выучен';
  }

  @override
  String markedLearned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return 'Отмечено выученными: $_temp0';
  }

  @override
  String unmarkedShort(int count) {
    return 'снято: $count';
  }

  @override
  String unmarkedLong(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return 'Снята отметка: $_temp0';
  }

  @override
  String willHaveLearned(String changes, int learned, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return '$changes. Будет выучено $learned из $_temp0.';
  }

  @override
  String get saveChangesQ => 'Сохранить изменения?';

  @override
  String get saveChanges => 'Сохранить';

  @override
  String get keepEditing => 'Продолжить';

  @override
  String get discardChanges => 'Не сохранять';

  @override
  String surahNotStarted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return 'Не начата · $_temp0';
  }

  @override
  String surahMemorized(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return 'Выучена · $_temp0';
  }

  @override
  String surahPartial(int memorized, int count, int left) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return '$memorized из $_temp0 · осталось $left';
  }

  @override
  String percentMemorized(int pct) {
    return 'Выучено $pct процентов';
  }

  @override
  String surahsMemorized(int memorized, int total) {
    return 'Выучено сур: $memorized из $total';
  }

  @override
  String surahsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count суры',
      many: '$count сур',
      few: '$count суры',
      one: '$count сура',
    );
    return '$_temp0';
  }

  @override
  String get progressHint =>
      'Нажмите на суру. Чтобы листать, нажмите, удерживайте и ведите пальцем.';

  @override
  String get back => 'Назад';

  @override
  String working(String label) {
    return '$label, выполняется';
  }

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get rule8chars => 'Не меньше 8 символов';

  @override
  String get ruleNumber => 'Есть цифра';

  @override
  String termsSentence(String terms, String privacy) {
    return 'Продолжая, вы принимаете $terms и $privacy.';
  }

  @override
  String get terms => 'Условия';

  @override
  String get privacyPolicy => 'Политику конфиденциальности';

  @override
  String get enterEmail => 'Введите email';

  @override
  String get emailIncomplete => 'Похоже, email введён не полностью';

  @override
  String get accountOffline =>
      'Нет подключения к интернету. Включите его, чтобы изменить аккаунт.';

  @override
  String get signedOutResync =>
      'Вы вышли из аккаунта. Войдите снова, чтобы синхронизировать прогресс.';

  @override
  String get yourAccount => 'Ваш аккаунт';

  @override
  String resetLinkSent(String email) {
    return 'Мы отправили ссылку для сброса на $email';
  }

  @override
  String get logOutQ => 'Выйти?';

  @override
  String get logOutBody =>
      'Ваш прогресс останется на этом телефоне. Войдите снова, чтобы синхронизировать его с аккаунтом.';

  @override
  String get logOut => 'Выйти';

  @override
  String get deleteAccountQ => 'Удалить аккаунт?';

  @override
  String get deleteAccountBody =>
      'Аккаунт и синхронизированный прогресс будут удалены навсегда. Это нельзя отменить.';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get accountSettingsCaps => 'НАСТРОЙКИ АККАУНТА';

  @override
  String get name => 'Имя';

  @override
  String get addYourName => 'Добавьте имя';

  @override
  String get email => 'Email';

  @override
  String get notSet => 'Не указан';

  @override
  String get password => 'Пароль';

  @override
  String get sendResetLink => 'Отправить ссылку для сброса';

  @override
  String get enterName => 'Введите имя';

  @override
  String get yourName => 'Ваше имя';

  @override
  String get nameGreeting => 'Так Hifdth будет к вам обращаться.';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get passwordMin8 => 'Минимум 8 символов';

  @override
  String get somethingWrong => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get change => 'Изменить';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get continueLabel => 'Продолжить';

  @override
  String get orWord => 'или';

  @override
  String get continueApple => 'Продолжить с Apple';

  @override
  String get continueGoogle => 'Продолжить с Google';

  @override
  String get createPassword => 'Придумайте пароль';

  @override
  String get yourPassword => 'Ваш пароль';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get authEmailTitle => 'Вход или регистрация';

  @override
  String get authEmailBody => 'Введите email, а остальное Hifdth сделает сам.';

  @override
  String get authPasswordTitle => 'С возвращением';

  @override
  String get authPasswordBody =>
      'Введите пароль, чтобы продолжить с того же места.';

  @override
  String get authCreateTitle => 'Приятно познакомиться';

  @override
  String get authCreateBody =>
      'Ещё два шага, и ваш прогресс будет сохранён на всех устройствах.';

  @override
  String linesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count строки',
      many: '$count строк',
      few: '$count строки',
      one: '$count строка',
    );
    return '$_temp0';
  }

  @override
  String pagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count страницы',
      many: '$count страниц',
      few: '$count страницы',
      one: '$count страница',
    );
    return '$_temp0';
  }

  @override
  String pagesHalf(String n) {
    return '$n страницы';
  }

  @override
  String get paceOnePage => 'целая страница';

  @override
  String get paceTwoPages => 'две целые страницы';

  @override
  String get paceHalfPage => 'примерно полстраницы';

  @override
  String pacePagePlus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count строки',
      many: '$count строк',
      few: '$count строки',
      one: '$count строка',
    );
    return 'страница и $_temp0';
  }

  @override
  String paceOfPage(int count) {
    return '$count из 15 строк страницы';
  }

  @override
  String get weekdaysLong =>
      'понедельник,вторник,среда,четверг,пятница,суббота,воскресенье';

  @override
  String get weekdaysShort => 'Пн,Вт,Ср,Чт,Пт,Сб,Вс';

  @override
  String get weekdayLetters => 'П,В,С,Ч,П,С,В';

  @override
  String get monthsLong =>
      'января,февраля,марта,апреля,мая,июня,июля,августа,сентября,октября,ноября,декабря';

  @override
  String get monthsShort => 'янв,фев,мар,апр,мая,июн,июл,авг,сен,окт,ноя,дек';

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
  String get askTitle => 'Сколько Корана вы уже выучили?';

  @override
  String get askBody => 'Нажмите на суру и расскажите мне.';

  @override
  String get planDoneToast => 'План на сегодня выполнен. Отлично!';

  @override
  String get goodMorning => 'Доброе утро';

  @override
  String get goodAfternoon => 'Добрый день';

  @override
  String get goodEvening => 'Добрый вечер';

  @override
  String get todaysPlanCaps => 'ПЛАН НА СЕГОДНЯ';

  @override
  String get tagRecite33 => 'Прочесть 33×';

  @override
  String get tagMemorize => 'Выучить';

  @override
  String get tagBy22 => 'до 22:00';

  @override
  String get morning => 'Утро';

  @override
  String get evening => 'Вечер';

  @override
  String taskRecite(String range) {
    return 'Прочесть $range';
  }

  @override
  String taskMemorize(String range) {
    return 'Выучить $range';
  }

  @override
  String taskReciteSub(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'последние $count урока',
      many: 'последние $count уроков',
      few: 'последние $count урока',
      one: 'последний урок',
    );
    return '$amount · 33× по памяти · $_temp0';
  }

  @override
  String taskMemorizeSub(String amount) {
    return '$amount · около часа, до 22:00';
  }

  @override
  String get showsQuranProgress => 'Показывает прогресс по Корану';

  @override
  String get hifdth => 'Hifdth';

  @override
  String get hideMessage => 'Скрыть сообщение';

  @override
  String get talkToHifdth => 'Поговорить с Hifdth';

  @override
  String get offlineMessage =>
      'Нет подключения. Изменения сохраняются на телефоне и синхронизируются, когда интернет вернётся.';

  @override
  String get backOnlineMessage =>
      'Подключение восстановлено. Изменения синхронизируются.';

  @override
  String get offline => 'Нет сети';

  @override
  String get backOnline => 'Снова в сети';

  @override
  String get dailyGoalTitle => 'Цель дня';

  @override
  String get streak => 'Серия';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String get nothingDue => 'Сегодня ничего не запланировано';

  @override
  String get waitingForPlan => 'Hifdth ждёт ваш план';

  @override
  String get noPlanYet => 'Плана пока нет';

  @override
  String get noPlanDetail =>
      'Выберите, с чего начать, и урок каждого дня появится здесь.';

  @override
  String get setUpMyPlan => 'Составить план';

  @override
  String get restDayStatus => 'День отдыха. Hifdth тоже отдыхает';

  @override
  String get restDay => 'День отдыха';

  @override
  String get restDayDetail =>
      'Если хотите, повторите уроки этой недели один раз.';

  @override
  String startsOn(String date) {
    return 'Начало: $date';
  }

  @override
  String get planComplete => 'План выполнен';

  @override
  String planCompleteDetail(int count, String from, String to) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return '$_temp0, $from → $to. Продолжайте их повторять.';
  }

  @override
  String get setNewRange => 'Выбрать новый отрезок';

  @override
  String dayOf(int day, int total) {
    return 'День $day/$total';
  }

  @override
  String get allDoneToday => 'На сегодня всё';

  @override
  String leftToday(int count) {
    return 'Осталось сегодня: $count';
  }

  @override
  String get yourPlanTitle => 'Ваш план';

  @override
  String get changePlan => 'Изменить план';

  @override
  String dayText(String text) {
    return 'День $text';
  }

  @override
  String linesPerDayFact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count строки',
      many: '$count строк',
      few: '$count строки',
      one: '$count строка',
    );
    return '$_temp0/день';
  }

  @override
  String finishesOn(String date) {
    return 'Завершение: $date';
  }

  @override
  String dayOff(String day) {
    return '$day — выходной';
  }

  @override
  String get methodName => '33 повторения';

  @override
  String get loopSelected => 'Повторять выбранные';

  @override
  String get thenNextAyah => 'Затем следующий аят';

  @override
  String nOfM(int n, int total) {
    return '$n из $total';
  }

  @override
  String finishedAyat(int count) {
    return 'Готово · аятов: $count';
  }

  @override
  String get finished => 'Готово';

  @override
  String get playingOnce => 'Играет один раз';

  @override
  String get playsOnce => 'Один раз';

  @override
  String get repeating => 'Повтор ';

  @override
  String get repeatWord => 'Повтор ';

  @override
  String ofCount(int count) {
    return ' из $count';
  }

  @override
  String get basmala => 'Басмала';

  @override
  String ayahNOfM(int n, int total) {
    return 'Аят $n из $total';
  }

  @override
  String selectionHintSome(int count, String how) {
    return 'Выбрано: $count · каждый звучит $how, затем следующий выбранный';
  }

  @override
  String get onRepeat => 'без конца';

  @override
  String timesShort(int count) {
    return '$count×';
  }

  @override
  String get selectionHintNone => 'Нажмите на аяты, которые хотите повторять';

  @override
  String get couldntLoadAyah => 'Не удалось загрузить этот аят.';

  @override
  String get couldntPlayAyah => 'Не удалось воспроизвести этот аят.';

  @override
  String ayahN(int n) {
    return 'Аят $n';
  }

  @override
  String surahName(String name) {
    return 'Сура $name';
  }

  @override
  String reciterLine(String reciter, int surah, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return '$reciter · Сура $surah · $_temp0';
  }

  @override
  String get all => 'Все';

  @override
  String get clear => 'Сбросить';

  @override
  String get selected => 'Выбрано';

  @override
  String get select => 'Выбрать';

  @override
  String get doneSelecting => 'Закончить выбор';

  @override
  String selectedAyatChange(int count) {
    return 'Выбрано аятов: $count. Нажмите, чтобы изменить';
  }

  @override
  String get selectAyat => 'Выбрать аяты';

  @override
  String get basmalaTapToListen => 'Басмала. Нажмите, чтобы послушать';

  @override
  String get tapToListenBasmala => 'Нажмите, чтобы послушать басмалу';

  @override
  String loadingName(String name) {
    return 'Загрузка: $name';
  }

  @override
  String couldntLoadName(String name) {
    return 'Не удалось загрузить: $name';
  }

  @override
  String get checkUpToDate =>
      'Проверьте, что приложение обновлено, и попробуйте ещё раз.';

  @override
  String get tryAgain => 'Попробовать снова';

  @override
  String ayahWithText(int n, String text) {
    return 'Аят $n. $text';
  }

  @override
  String get repeatEachAyahCaps => 'ПОВТОР КАЖДОГО АЯТА';

  @override
  String audioComingSoon(String name) {
    return 'Аудио для суры $name скоро появится';
  }

  @override
  String get position => 'Позиция';

  @override
  String get previousAyah => 'Предыдущий аят';

  @override
  String get nextAyah => 'Следующий аят';

  @override
  String get repeatForever => 'Повторять без конца';

  @override
  String repeatTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Повторить $count раза',
      many: 'Повторить $count раз',
      few: 'Повторить $count раза',
      one: 'Повторить $count раз',
    );
    return '$_temp0';
  }

  @override
  String noSurahMatches(String query) {
    return 'Нет суры по запросу «$query»';
  }

  @override
  String get searchTryHint =>
      'Попробуйте номер, название, например «Кахф», или значение, например «cave».';

  @override
  String get clearSearch => 'Очистить поиск';

  @override
  String juzMeaning(int juz, String meaning) {
    return 'Джуз $juz · $meaning';
  }

  @override
  String get surahs => 'Суры';

  @override
  String get juzSuffix => ' джузов';

  @override
  String get searchHint => 'Название, номер или значение';

  @override
  String get jumpToJuz => 'Перейти к джузу';

  @override
  String juzN(int juz) {
    return 'Джуз $juz';
  }

  @override
  String juzMemorized(int juz) {
    return 'Джуз $juz, выучен';
  }

  @override
  String meaningAyahs(String meaning, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return '$meaning · $_temp0';
  }

  @override
  String ayahRange(int from, int to) {
    return 'аяты $from–$to';
  }

  @override
  String continuesAyahRange(int from, int to) {
    return 'Продолжение · аяты $from–$to';
  }

  @override
  String get memorizedSuffix => ', выучена';

  @override
  String ayahsMemorizedSuffix(int learned, int total) {
    return ', выучено $learned из $total аятов';
  }

  @override
  String get methodOrigin => 'Ваш план хифза';

  @override
  String get methodSummary =>
      'Каждый вечер учите новую часть и ложитесь спать. Следующие три утра читайте её по памяти 33 раза. Так каждый урок прозвучит около 100 раз.';

  @override
  String get step1 =>
      'Вечер: выучите новую часть, примерно за час, и пусть это будет последнее дело дня.';

  @override
  String get step2 => 'Утро 1: прочтите её 33 раза по памяти.';

  @override
  String get step3 => 'Утро 2: ещё 33 раза по памяти.';

  @override
  String get step4 => 'Утро 3: ещё 33. Это около 100 раз за три дня.';

  @override
  String get tip1 =>
      'Заканчивайте вечерний урок до 22:00, чтобы хватило сил на утро.';

  @override
  String get tip2 => 'В день отдыха прочтите уроки недели один-два раза.';

  @override
  String get howItWorksCaps => 'КАК ЭТО РАБОТАЕТ';

  @override
  String get atAGlanceCaps => 'КОРОТКО';

  @override
  String get tipsCaps => 'СОВЕТЫ';

  @override
  String stepLabel(String method, int n, String text) {
    return '$method, шаг $n: $text';
  }

  @override
  String get previousStep => 'Предыдущий шаг';

  @override
  String stepNOfM(int n, int total) {
    return 'Шаг $n из $total';
  }

  @override
  String get pauseSteps => 'Остановить шаги';

  @override
  String get playSteps => 'Запустить шаги';

  @override
  String get nextStep => 'Следующий шаг';

  @override
  String get learnAboutHour => 'учить · ~1 ч';

  @override
  String morningN(int n) {
    return 'Утро $n';
  }

  @override
  String get fromMemory => 'по памяти';

  @override
  String get about100 => '≈ 100 повторений';

  @override
  String minutesShort(int count) {
    return '$count мин';
  }

  @override
  String get aDay => 'в день';

  @override
  String get demanding => 'Непросто';

  @override
  String get effort => 'нагрузка';

  @override
  String get solo => 'Сам';

  @override
  String get noTeacher => 'без учителя';

  @override
  String get startSurah => 'Начальная сура';

  @override
  String get endSurah => 'Конечная сура';

  @override
  String get planUpdated => 'План обновлён';

  @override
  String planCreated(int count) {
    return 'План составлен · день 1 из $count — на главной';
  }

  @override
  String get editMyPlan => 'Изменить план';

  @override
  String get updateMyPlan => 'Обновить план';

  @override
  String get createMyPlan => 'Составить план';

  @override
  String get setYourPlan => 'Составьте план';

  @override
  String methodSubtitle(String method) {
    return '$method · задачи на каждый день — на главной';
  }

  @override
  String get whatToMemorizeCaps => 'ЧТО УЧИТЬ';

  @override
  String get fromBeginning => 'С начала';

  @override
  String get fatihahFirst => 'Сначала Аль-Фатиха';

  @override
  String get fromEnd => 'С конца';

  @override
  String get nasFirst => 'Сначала Ан-Нас, джуз Амма';

  @override
  String get rangeErrorFromEnd =>
      'При чтении с конца конец должен идти после начала. Измените конец или порядок чтения.';

  @override
  String get rangeErrorFromBeginning =>
      'При чтении с начала конец должен идти после начала. Измените конец или порядок чтения.';

  @override
  String get dailyPaceCaps => 'ТЕМП В ДЕНЬ';

  @override
  String get lines => 'Строки';

  @override
  String get presetHalfPage => '½ стр.';

  @override
  String get countedInMushaf => 'По 15-строчному мединскому мусхафу';

  @override
  String get restDayCaps => 'ДЕНЬ ОТДЫХА';

  @override
  String get none => 'Нет';

  @override
  String howItWorksLabel(String method, int count) {
    return 'Как это работает: $method за $count шага';
  }

  @override
  String get howItWorks => 'Как это работает';

  @override
  String howItWorksSub(int count) {
    return '$count шага · около 100 повторений';
  }

  @override
  String get start => 'Начало';

  @override
  String get end => 'Конец';

  @override
  String startSurahLabel(int n, String name) {
    return 'Начальная сура: $n, $name. Изменить';
  }

  @override
  String endSurahLabel(int n, String name) {
    return 'Конечная сура: $n, $name. Изменить';
  }

  @override
  String get ayah => 'Аят';

  @override
  String get decrease => 'Уменьшить';

  @override
  String get increase => 'Увеличить';

  @override
  String rangeLabel(String label, int min, int max) {
    return '$label, от $min до $max';
  }

  @override
  String dayWord(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'дня',
      many: 'дней',
      few: 'дня',
      one: 'день',
    );
    return '$_temp0';
  }

  @override
  String ayahsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аята',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return '$_temp0';
  }

  @override
  String get day1 => 'День 1';

  @override
  String get summaryHint =>
      'План появится здесь, когда отрезок будет выбран верно.';

  @override
  String get nameOrNumber => 'Название или номер';

  @override
  String noSurahMatchesDot(String query) {
    return 'Нет суры по запросу «$query».';
  }

  @override
  String get languageCaps => 'ЯЗЫК';

  @override
  String get languageNote =>
      'Значения названий сур и перевод аятов пока на английском.';

  @override
  String get playbackCaps => 'ВОСПРОИЗВЕДЕНИЕ';

  @override
  String get repeatEachAyah => 'Повтор каждого аята';

  @override
  String get repeatEachAyahNote =>
      'Сколько раз плеер читает аят, прежде чем перейти дальше.';

  @override
  String get thenNextAyahNote => 'Переходить к следующему аяту после повторов.';

  @override
  String get aboutCaps => 'О ПРИЛОЖЕНИИ';

  @override
  String get version => 'Версия';

  @override
  String get reciter => 'Чтец';

  @override
  String get contactUs => 'Связаться с нами';

  @override
  String get soon => 'Скоро';

  @override
  String get madeWithCare => 'Qori · для тех, кто учит Коран наизусть';

  @override
  String get langEnglish => 'Английский';

  @override
  String get langRussian => 'Русский';

  @override
  String get langUzbekLatin => 'Узбекский (латиница)';

  @override
  String get langUzbekCyrillic => 'Узбекский (кириллица)';

  @override
  String get privacyPolicyTitle => 'Политика конфиденциальности';
}
