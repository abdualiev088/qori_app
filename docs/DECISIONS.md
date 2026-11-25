# Design decisions

## Sign-in screen: email first (2026-11-19)

Picked from a prototype with three directions.

- **Chosen: email first.** One email field, then the server says whether the email has an account. A known email gets a password step ("Welcome back"). A new one gets name + password ("Nice to meet you"). Apple and Google sit below an "or" divider. Hifdth turns blue on the second step, as when it speaks elsewhere.
- **Opens from** the profile button on Home. The app stays usable without an account.
- **Backend:** `lib/data/auth_api.dart` calls the Django API (`Backend Qori app`, contract in its `docs/api.md`). The server checks the password rules too, and its errors show next to their field. Closing the Apple or Google sheet does nothing. Widget tests use `test/fake_auth_api.dart`.
- **Sync (2026-11-19):** on first launch the app gets a guest account, so progress syncs before sign-up. `lib/data/progress_sync.dart` queues each save while offline, and merges the device's progress into the account on every sign-in.
- **Kept from the mockups:** the glass back button, Hifdth above the title, a black Apple button, a white Google button, the green primary button, and the Terms footer.
- **Fixed over the mockups:**
  - Real Apple and Google logos, and an icon in each field.
  - 16 px input text.
  - Next/Go keyboard actions and iOS autofill hints.
  - Errors show only after the first submit, next to their field, and clear while typing.
  - A loading spinner, and no double submit.
  - Live password rules ("8+ characters", "A number").
- **Rejected:**
  - *Classic* (the mockup layout with Sign in / Create account tabs). It asks for the most at once (tabs plus three methods), and people often pick the wrong tab.
  - *Social first* (Apple and Google up front, email folded away). It costs email users an extra tap and still needed a "New to Qori? Create account" switch.

## Player tab: surah list by juz, with a mini-player (2026-11-20)

Picked from a prototype with three directions (`player-list-proto/DECISION.md`).

- **Chosen: Juz.** The Player tab opens on "Surahs" by Alijon Qori: one section per juz ("Juz 18 الجزء ١٨" and its range), each a white card of surah rows. A surah that spans juz appears in each, and rows that don't start at ayah 1 read "Continues · ayahs 142–252" and open the player there.
- **Search and juz row:** one sticky block with the search field and juz buttons 1–30. The current juz is filled dark green, fully memorized ones get the mint wash and ring. Search is forgiving about names ("yaseen", "kahf") and covers numbers, meanings ("cave") and Arabic without diacritics; results are one flat list, and Enter opens the first.
- **Rows** show the star filled by the memorized share (from the real `LearnedStore`), a check when memorized, and a "30/52" bar on whole rows in progress.
- **Player for any surah:** the screen slides in (native iOS push, 360 ms in, 260 ms back; none under Reduce Motion) with a glass back button. The ayah list runs to the bottom edge and the panel floats over it. Position and selection are saved per surah.
- **Text and audio** come from a `SurahSource` (`lib/data/surah_source.dart`). All 114 surahs' text is bundled (quran-uthmani and Sahih International, from api.alquran.cloud, `assets/quran/quran.json`). Only Al-Qalam has audio (Alijon Qori, bundled); other surahs say "Audio … is coming soon" and their play controls are off.
- **Mini-player** above the nav on the list while a surah is active: the surah, "Ayah 30 of 52 · repeat 2 of 3", play/pause and ×, with a thin progress line. It enters in 220 ms (a 10 px rise), leaves in 150 ms, and hides while the player is open. Leaving the player keeps the audio going. Opening a surah only shows its text (nothing selected, no panel) until an ayah is tapped; that makes it the active surah and stops the old one.
- **Rejected:**
  - *Index* (one flat list with All / Learning / Not started / Memorized filters). Quickest when you know the surah, but it ignores the Mushaf structure that hifz students plan around.
  - *Resume* (a "Continue" card plus sections grouped by progress). Its resume job is now done by the mini-player, and grouping by status hides where a surah sits in the Mushaf.

## Recitation audio: downloaded per ayah, kept on the device (2026-11-20)

- **The server hands out URLs, not audio.** `GET /v1/surahs/{n}/audio` lists each ayah's file with its URL, size, sha256 and length. In production the files sit in object storage (S3 or Cloudflare R2) behind a CDN. Django never streams audio, so many listeners cost CDN bandwidth, not server time.
- **Files never change at a URL.** Their names include their checksum, so phones and the CDN can cache them forever. A corrected recording gets a new name.
- **Downloaded on first play, kept forever.** `lib/data/audio_cache.dart` stores files by checksum in the app's support folder, which iOS doesn't clear, and verifies each download before keeping it. A downloaded ayah plays offline.
- **Neighbours are fetched while an ayah plays.** The ayah before and after start downloading as soon as playback starts, so next and previous begin at once. The cache doesn't fetch further ahead, to avoid spending data on ayahs that may never play.
- **One Basmala for every surah.** The reciter's Basmala is Al-Fatihah's ayah 1, listed as ayah 0 for surahs 2–114 (not 9). Because files are stored by checksum, it's downloaded once.
- **Al-Qalam stays bundled.** `RemoteSurahSource` plays bundled audio where it exists and downloads the rest. Which surahs have audio comes from `GET /v1/recitations`, saved so it's known offline.
- **Rejected:**
  - *Bundling all audio.* Al-Qalam alone is 18 MB.
  - *Streaming each ayah from Django.* Every play would hit the server, and nothing would work offline.
  - *Downloading a whole surah up front.* That wastes data for someone who listens to one ayah, and Al-Baqarah has 286.

## First release without placeholders (2026-11-23)

- **Chosen:** ship TestFlight and Google Play internal testing with only what works: sign-in, Quran progress with sync, the Player. The bottom nav has two tabs, Home and Player. Home shows the greeting, Hifdth's card and Quran progress.
- **Removed until the schedule exists:** today's sessions, the daily goal and the streak (they showed made-up times and a permanent 0), and the empty My Method and Settings tabs. Hifdth stays happy because nothing can put the user behind yet.
- **Android id** is `com.abdualiev088.qori`, the same as the iOS bundle id; Google Play never allows changing it after the first upload. The app is called "Qori" on both home screens.
- **Rejected:** keeping the cards with a "coming soon" label. Testers would judge the app by numbers that never move.

## Memorization plan: one method, 33 repetitions (2026-11-24)

From the My Method prototype (`~/method-proto`, `FLUTTER_PROMPT_33.md`), cut down to a single method. This brings back the My Method tab and Home's plan, goal and streak that the first-release cut (above) removed while they were placeholders; Settings stays out.

- **One method, no picker.** My Method explains "33 repetitions" in full on the first visit. After that it opens straight on Set your plan, with "How it works" folded at the top. Editing the plan doesn't fold it or restart its diagram.
- **The pace is in mushaf lines, not ayahs**, because ayah lengths vary from a few words to a page. Each ayah's length is estimated from its letter count, in the 15-line Madani mushaf. Lessons always end on a whole ayah and keep short surahs whole.
- **Tasks on Home replace the placeholder sessions.**
  - A study day has a Morning recitation (33× the last three lessons) and an Evening new lesson.
  - Ticking a task fills the Daily goal and the Streak, and finishing the day says well done.
  - Hifdth worries when a task's time passes without a tick.
- **On the device only, for now.** The plan isn't tied to an account, so it works signed out. Syncing it is planned.
- **Rejected:**
  - *A list of methods* (the prototype's eight). The spec asks for one, and a single method keeps the setup short.
  - *Ayahs a day.* An ayah count means very different amounts in Al-Baqarah and Juz ʿAmma.

## 2026-11-25 · My Method form: grouped and quieter

- **Chosen:** settings grouped into white cards (range as two stops on a line, pace, rest day as a sliding segmented control), one-line copy, At a glance cut to three facts, a summary card whose day count rolls on change. The save button is grey while there is nothing new to save.
- **Rejected:** keeping the paragraph of instructions and the six At a glance tiles (too much to read before acting); dimming the button to 60% when disabled (a pale green still looks tappable).

## 2026-11-25 · Settings tab and three languages

- **Chosen:** Flutter gen-l10n (`lib/l10n/*.arb`, `flutter_localizations` + `intl`), four locales: en, ru, uz (Latin), uz-Cyrl. Uzbek Cyrillic is transliterated from the Latin file with a short list of fixed exceptions (months, weekday abbreviations, "email"). Dates and plurals are formatted from the ARB files, not from `intl` date symbols, so Uzbek Cyrillic gets real month names. English stays the default instead of following the phone.
- **Rejected:** a hand-rolled string map (no plurals, Material's own texts stay English); following the system language now (the user asked for English by default).
- **Settings contents:** Language, Playback (repeat, then next ayah), About. Account stays behind Home's profile button.

## 2026-11-25 · The name stays Qori

- **Tried and reverted:** renaming the app to "Hifz" everywhere, bundle id included (`com.abdualiev088.hifz`). It needed a new signing profile and new sign-in setup, so the app is back to **Qori** with `com.abdualiev088.qori`. The rename is in the history (e08788a) if it is wanted again.
