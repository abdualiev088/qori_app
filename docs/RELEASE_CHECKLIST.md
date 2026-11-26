# Выпуск на тест: TestFlight и Google Play internal testing

Цель — рабочая версия для тестировщиков: вход, прогресс с синхронизацией, плеер со всеми 114 сурами Алижона кори. План «33 повторения» (My Method, план дня, цель, стрик) вернулся 2026-11-25; Settings с языками (en/ru/uz/uz-Cyrl) вернулась тогда же.

Отметка: [x] сделано, [ ] осталось. В скобках — кто может сделать.

## 1. Приложение (код)

- [x] Убраны заглушки: вкладки My Method и Settings, план дня, цель, стрик. (Claude)
- [x] Android applicationId `com.abdualiev088.qori`, как bundle id на iOS. Название на экране телефона — «Qori». (Claude)
- [x] Подпись Android-релиза читается из `android/key.properties` (не в git). (Claude)
- [x] Flutter обновлён до 3.50.1; `flutter analyze` без ошибок и предупреждений, `flutter test` — 102 из 102. (Claude)
- [ ] Ссылки Privacy Policy и Terms на экране входа сейчас просто текст: сделать их ссылками на страницы из п. 4. (Claude, когда будут адреса)
- [ ] Иконка приложения и экран запуска (сейчас стандартные Flutter). (дизайн → Claude)
- [ ] Встроенный Al-Qalam (18 МБ в `assets/audio`): когда аудио будет на сервере, решить, оставлять ли его в сборке.

## 2. Аудио всех сур

- [x] Нарезка 114 сур, 6236 файлов, проверка распознаванием. (Claude)
- [ ] Прослушать аяты из `tools/recitations/out/CHECK_AYAHS.md` (27 штук, начать с первых 5). (вы)
- [x] Басмала одна на всех: запись 1-го аята Фатихи, она же `00. Bismillah.mp3`; в сурах 2–114 (кроме 9) играет как аят 0. (Claude)
- [x] Перекодировать в MP3 96 кбит/с моно (1,32 ГБ). (Claude)
- [x] Имена файлов по sha256, список по каждой суре (ayah, url, size, sha256, duration_ms) и `manifests/recitations.json` — лежат в бакете, приложение читает их оттуда. (Claude)
- [x] Бакет Cloudflare R2 `qori-audio`, ключ только на этот бакет. (вы)
- [ ] Свой домен в Cloudflare, `audio.<домен>` к бакету вместо r2.dev; пересобрать списки с `--base` и поменять `defaultAudioUrl()`. (вы + Claude)
- [x] Загрузить файлы и списки в R2 (`publish.py upload alijon`), бэкенду импорт не нужен. (Claude)

## 3. Бэкенд

- [ ] Хостинг (VPS или PaaS) + управляемый PostgreSQL с бэкапами. Уточнить требование Узбекистана о хранении персональных данных в стране.
- [ ] Домен и HTTPS, например `api.<домен>/v1`.
- [ ] `DEBUG=False`, `ALLOWED_HOSTS`, секреты в переменных окружения, rate limit на `/auth/*`.
- [ ] Отправка писем для сброса пароля (SMTP или сервис рассылки) и обратный адрес.
- [ ] Google/Apple: серверная проверка токенов с боевыми client ID.
- [ ] Sentry или другой мониторинг ошибок.

## 4. Юридическое и аккаунты разработчика

- [ ] Apple Developer Program ($99 в год) — team `QQLG5SP5R2` уже есть, проверить, что подписка активна.
- [ ] Google Play Console (разовые $25). Для личного аккаунта, созданного после ноября 2023, Google требует закрытое тестирование: 12 тестировщиков в течение 14 дней до выхода в продакшен. Internal testing (до 100 человек) доступен сразу.
- [ ] Страница политики конфиденциальности (что собираем: email, имя, прогресс; как удалить аккаунт) и условия использования, по публичным адресам.
- [ ] Разрешение чтеца (или правообладателя mp3quran) на использование записей в приложении.

## 5. iOS → TestFlight

- [ ] В App Store Connect создать приложение с bundle id `com.abdualiev088.qori`.
- [ ] Sign in with Apple: включить capability в Apple Developer для этого bundle id.
- [ ] Google Sign-In: iOS client ID в Google Cloud, `GOOGLE_IOS_CLIENT_ID` и reversed client ID в `Info.plist` (URL scheme).
- [ ] Заполнить App Privacy (какие данные собираются) и Export Compliance (только HTTPS → обычно «нет»).
- [ ] Сборка на Mac:
  `flutter build ipa --dart-define=QORI_API_URL=https://api.<домен>/v1 --dart-define=GOOGLE_IOS_CLIENT_ID=… --dart-define=GOOGLE_SERVER_CLIENT_ID=…`
  затем загрузить через Xcode Organizer или Transporter.
- [ ] Внутренние тестировщики (до 100, из команды App Store Connect) получают сборку сразу. Внешним (до 10 000) нужна короткая проверка Apple: описание, что тестировать, тестовый аккаунт для ревьюера.

## 6. Android → Google Play internal testing

- [ ] Создать ключ загрузки:
  `keytool -genkey -v -keystore qori-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
  и `android/key.properties` (storeFile, storePassword, keyAlias, keyPassword). Ключ и пароли хранить вне git, сделать резервную копию.
- [ ] Google Sign-In: Android client ID с SHA-1 ключа загрузки и SHA-1 ключа Play App Signing (из Play Console).
- [ ] Сборка:
  `flutter build appbundle --dart-define=QORI_API_URL=https://api.<домен>/v1 --dart-define=GOOGLE_SERVER_CLIENT_ID=…`
- [ ] В Play Console: создать приложение, заполнить Data safety, рейтинг контента, целевую аудиторию, ссылку на политику конфиденциальности, загрузить `.aab` в Internal testing, добавить email тестировщиков.

## 7. Перед каждой тестовой сборкой

- [ ] Поднять версию в `pubspec.yaml` (`1.0.0+1` → `1.0.0+2`: номер после `+` должен расти с каждой загрузкой).
- [ ] `flutter analyze`, `flutter test`.
- [ ] Прогнать вручную: вход по email, Apple, Google; отметка аятов; выход/вход; офлайн; плеер на нескольких сурах; блокировка экрана.
