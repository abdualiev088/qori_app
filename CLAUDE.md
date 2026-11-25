# Qori (Hifdth) — заметки для работы

Flutter-приложение-компаньон для заучивания Корана (хифз). Маскот — **Hifdth** (зелёный шар с глазами, настроение зависит от отставания по плану).
Репо: https://github.com/abdualiev088/qori_app (ветка `main`). Автор коммитов: azizabdualiyev.
Бэкенд — **отдельный Django-проект** («Backend Qori app», контракт API в его `docs/api.md`), в этом репо его нет. `docs/BACKEND.md` — исходный бриф (частично устарел: там «нет сети», а сеть уже есть — код главнее).

**Главный документ по правилам — `docs/BUSINESS_LOGIC.md`** (статусы live / placeholder / planned; при расхождении с кодом прав код, и файл чинится в том же изменении). Второй разработчик ведёт его вместе со своими коммитами — перед работой делать `git pull`.

Нарезка аудио по аятам: `tools/recitations/split_surah.py` + `asr.py` (venv, cache и out — в .gitignore). Границы аятов ищутся по распознанному тексту (Whisper `tarteel-ai/whisper-base-ar-quran`, на GPU), а не по длине: по длине Аль-Ахзаб был сдвинут на 1–7 аятов. В `report.json` у каждого аята `heard` и `sim` (0..1). Видеокарта ноутбука иногда падает на пачках: каждая сура идёт отдельным процессом с повторами, распознанное кэшируется в `cache/asr/`. Источник Алижона кори: mp3quran.net, reciter 21196, `cdn.mp3quran.net/audio/alijon-hamdan/r1/SSS.mp3`. Встроенный Al-Qalam (`assets/audio`) не трогать.

## Стек
- Flutter 3.50 / Dart 3.14 (локально; `google_fonts ^9` требует Dart 3.13+). Линты `flutter_lints`. С 3.47 `package:flutter/material.dart` помечен устаревшим (замена — `material_ui`): 27 info в analyze, не ошибки.
- `just_audio` + `audio_service` + `audio_session` — плеер с lock screen.
- `shared_preferences` — локальное состояние; `flutter_secure_storage` — токены.
- `http` — API; `google_sign_in` 7.x, `sign_in_with_apple`; `google_fonts` (Inter, Amiri Quran); `flutter_svg`.
- iOS bundle и Android applicationId — `com.abdualiev088.qori`, team `QQLG5SP5R2`. Подпись Android-релиза — `android/key.properties` (не в git).

## Структура `lib/`
| Файл | Что |
| --- | --- |
| `main.dart` | Инициализация: AudioService → prefs → PlayerController, LearnedStore, ApiClient, ProgressSync, AuthApi. Сначала `runApp`, потом sync/loadMe/аудиосессия в фоне. Sync на resume. |
| `app_shell.dart` | Градиентный фон, `IndexedStack` из 2 вкладок (Home, Player), `BottomGlow`, плавающий `LiquidGlassNav`. |
| `theme/tokens.dart` | `HColors`, `HRadii`, `HText.inter()/arabic()` (флаг `HText.useGoogleFonts=false` в тестах), `arabicDigits()`. |
| `data/surahs.dart` | Имена и число аятов 114 сур, `SurahProgress`, `sampleSurahProgress()` (только для превью/тестов). |
| `data/al_qalam.dart` | Сгенерировано (не править руками): текст суры 68 (ar/en), `basmala`, `ayahDurations` (индекс 0 = басмала). |
| `data/learned_store.dart` | `LearnedStore` (ChangeNotifier): выученные аяты, prefs `hifdth.learned.v1` = `{"68":[1,2,3]}`. `commit()` заменяет набор суры целиком, `applyServer(json, keep:)`. |
| `data/api_client.dart` | `ApiClient`: JSON, bearer, авто-refresh при 401 (кроме `/auth/*`), `ApiException {status, code, message, fields, body}`, status 0 = offline. URL: `--dart-define=QORI_API_URL`, иначе `http://127.0.0.1:8000/v1` (Android-эмулятор `10.0.2.2`). |
| `data/auth_api.dart` | `AuthApi`, `QoriUser{id,email,displayName,isGuest,hasPassword}`. Email-first: `/auth/email/check`, `/signin`, `/signup`, `/auth/password/reset`, `/auth/social`, `/auth/signout`, `GET/PATCH/DELETE /me`. |
| `data/progress_sync.dart` | `ProgressSync`: гостевой аккаунт `/auth/guest`, очередь `hifdth.sync.pending.v1`, `/progress/merge` (union) при смене аккаунта (`hifdth.sync.merged.v1`), `PUT /progress/{surah}` с `updated_at`, 409 → берём серверный набор, потом `GET /progress`. |
| `data/social_sign_in.dart` | Нативные Apple/Google. Google требует `--dart-define` `GOOGLE_IOS_CLIENT_ID` / `GOOGLE_SERVER_CLIENT_ID`. Отмена → `SignInCancelled`. |
| `player/player_controller.dart` | Плеер (порт из `Player.dc.html`): repeat (1,3,5,7,10,0=∞), autoNext, loopSelected, выделение-очередь; prefs `hifdth.qalam.*`. Аудио `assets/audio/068_NNN.mp3` (000 = басмала). |
| `player/playback_rules.dart` | Чистые `nextAfter` / `prevBefore`, `lastAyah = 52`. |
| `player/audio_handler.dart` | `HifdthAudioHandler` — мост к lock screen / уведомлению. |
| `screens/home_screen.dart` | Приветствие, `HifdthCard` (персонаж + статус), летающий Hifdth + пузырь-вопрос, `QuranProgressCard`, кнопка профиля → Auth/Account. |
| `screens/player_screen.dart` | Список аятов, панель плеера, сегментный seek bar, repeat chip, auto switch. |
| `screens/auth_screen.dart` | Шаги email → password / create. После успеха заменяется на `AccountScreen`. |
| `screens/account_screen.dart` | Имя, email, сброс пароля, выход, удаление аккаунта. |
| `widgets/` | `glass.dart` (LiquidGlass, nav c hold/swipe), `ribbed_glass.dart` (+shimmer), `hifdth_*` (painter, mood, card), `learned_sheet.dart` (сетка аятов со свайп-разметкой и диалогом сохранения), `quran_progress_card.dart` (сетка 114 сур с лупой), `progress_indicators.dart`, `auth_widgets.dart`, `toast.dart`, `star.dart`, `icons.dart`. |

## Что реально, а что заглушка
- Реально: выученные аяты + синк, аккаунты, плеер Al-Qalam (только сура 68, ~18 МБ mp3 в ассетах).
- Вкладки: Home, Player, My Method (план «33 повторения», `lib/data/plan.dart`, `plan_store.dart`, `screens/method_screen.dart`). Settings (шестерёнка, `screens/settings_screen.dart`): язык, воспроизведение, о приложении. План дня, цель и стрик на Home считаются по отметкам плана; настроение Hifdth — по просроченным задачам, пороги — `moodFor` в `widgets/hifdth_mood.dart`.
- Сетка прогресса на Home стартует с суры 68.

## Языки
- en (по умолчанию), ru, uz (латиница), uz-Cyrl. Строки — `lib/l10n/app_*.arb`, код генерируется (`flutter gen-l10n`, делается и при `flutter run`). В виджетах `context.l10n.x`; без делегатов (тесты) — английский. Даты, строки/страницы — `lib/l10n/plan_text.dart`. Выбор языка — `LocaleStore` (`hifdth.locale.v1`).

## Правила домена
- Суры 1–114, аяты 1..`surahAyahCounts[s-1]`; всё вне диапазона молча отбрасывается.
- Сура выучена = выучены все её аяты; отдельного флага нет и не надо.
- В плеере аят `0` = басмала.
- Офлайн обязателен: устройство — источник правды, изменения в очереди.

## Конвенции
- Doc-комментарии `///` на каждом классе: что и зачем, с размерами из дизайна (px).
- Уважать Reduce Motion (анимации стоят на месте).
- Коммиты: заголовок в повелительном наклонении («Add…», «Give…»), тело — проза о поведении для пользователя, трейлер `Co-Authored-By: Claude …`.
- Дизайн-решения фиксируются в `docs/DECISIONS.md` (с датой, выбранное/отвергнутое).
- Тесты: `test/` — widget + unit, `HText.useGoogleFonts = false`, `SharedPreferences.setMockInitialValues`, `test/fake_auth_api.dart` для авторизации, фиксированный `now:` в HomeScreen.

## Команды
```
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=QORI_API_URL=http://127.0.0.1:8000/v1
```
