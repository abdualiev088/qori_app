# Qori backend: handoff

This is the starting brief for the backend of Qori (the Hifdth app). It covers what the app does today, which data is real or placeholder, what the backend has to provide, and a first API shape. The code wins wherever this doc and the code disagree.

## Where the backend lives

Put it in a `backend/` folder in this same repository, next to the Flutter app:

```
Qori app/
  lib/            Flutter app (unchanged)
  test/
  backend/        the server, with its own README, dependencies and tests
  docs/
    BACKEND.md    this file
    api.md        the API contract, once written (or an OpenAPI file)
```

Why one repository rather than a separate folder or repo:
- **One change, one commit.** When an endpoint changes shape, the server and the app's client code change together and never drift apart.
- **One context.** A coding session (or Claude) opened here sees both sides, so it can check the app's models against the API without switching projects.
- **It's just you.** A separate repo pays off when a different person or team owns the server, or when the two release on unrelated schedules. Neither is true yet, and splitting later is easy.

Flutter ignores folders it doesn't know about. Add `backend/**` to `analyzer: exclude:` in `analysis_options.yaml` if the analyzer ever picks up its files.

## What the app is

A Quran memorisation (hifdth) companion. There are four tabs:

| Tab | State |
| --- | --- |
| **Home** | Hifdth (the mascot, whose mood follows how far behind you are), today's sessions, daily goal, weekly streak, and a 114-surah grid where you mark learned ayahs. |
| **Player** | Ayah-by-ayah recitation with repeat count, auto-next, loop-selected and a selection queue. Only **Al-Qalam (surah 68)** exists so far. |
| **My Method** | Placeholder. |
| **Settings** | Placeholder. |

There are no accounts, and no network calls of any kind. Everything lives on the device.

## The app's data today

| Data | Where it is now | Code |
| --- | --- | --- |
| Learned ayahs per surah | `SharedPreferences` key `hifdth.learned.v1`, JSON `{"68": [1,2,3], ...}` | `lib/data/learned_store.dart` |
| Player state (current ayah, repeat, auto-next, loop, selection) | `SharedPreferences` keys `hifdth.qalam.*` | `lib/player/player_controller.dart` |
| Surah names and ayah counts (all 114) | Hardcoded constants | `lib/data/surahs.dart` |
| Al-Qalam text (Arabic and English) | Generated constants | `lib/data/al_qalam.dart` |
| Al-Qalam audio | Bundled MP3s, `assets/audio/068_000.mp3` (Basmala) to `068_052.mp3`, about 18 MB | `assets/audio/` |
| Today's sessions (Morning, Review, Evening) | **Hardcoded placeholder** | `lib/screens/home_screen.dart` (`DayStep` list) |
| Sessions behind, which drives Hifdth's mood | **Hardcoded `0`** | `home_screen.dart` (`_sessionsBehind`) |
| Daily goal (67%, "1 session left") | **Hardcoded placeholder** | `home_screen.dart` (`_GoalCard`) |
| Streak (Mon–Fri done) | **Hardcoded placeholder** | `home_screen.dart` (`_StreakCard`) |
| User name, greeting, profile | Greeting from the clock; profile button does nothing | `home_screen.dart` |

Rules already in the app that the server must respect:
- Ayah numbers run from 1 to that surah's count (`surahAyahCounts`), and surahs from 1 to 114. Anything outside is dropped silently.
- A surah counts as **learned** when every one of its ayahs is learned. There is no separate flag, so don't store one.
- In the Player, ayah `0` means the Basmala.

## What the backend has to provide

In order of what unblocks the app first:

1. **Accounts.** Sign in with Apple and Google, plus an anonymous or device account so the app works before sign-up. When the user signs in, the anonymous account becomes the real one and keeps its data.
2. **Progress sync.** Learned ayahs per surah, synced across devices. This is the one piece of real user data the app has today.
3. **Schedule and sessions.** The user's daily plan (sessions, their times and what each covers) and a log of completed sessions. This replaces the hardcoded `DayStep` list.
4. **Derived stats.** Daily goal progress, streak and "sessions behind" (the input to Hifdth's mood), computed from the session log in the **user's time zone**.
5. **Content.** Text and recitation audio for all 114 surahs, so the Player can move beyond Al-Qalam. Bundling all of it in the app isn't practical: Al-Qalam alone is 18 MB. Serve audio from a CDN or object storage, and download it per surah.
6. **Player preferences** (repeat count, auto-next and so on). These are optional to sync and can stay on the device.

## Data model (first draft)

```
users            id, created_at, display_name, time_zone, auth_provider(s)
learned_ayahs    user_id, surah (1–114), ayah, learned_at       PK (user_id, surah, ayah)
schedules        user_id, session_kind, time_of_day, days_of_week, target (surah + ayah range)
session_log      id, user_id, kind, scheduled_for, completed_at, surah, ayahs[]
surahs           n, name, ayah_count                            (static; mirrors lib/data/surahs.dart)
ayahs            surah, n, arabic, translation                  (static)
recitations      surah, ayah, reciter, audio_url, duration_ms   (static)
```

Storing one row per learned ayah (rather than one JSON blob per user) makes merges and "learned this week" queries simple. Learned count per surah is `COUNT(*)`, and a surah is fully learned when that count equals its ayah count.

## API (first draft)

Plain JSON over HTTPS, with a bearer token from the auth provider. Times are ISO 8601 UTC, and stats are computed in the user's time zone.

```
POST   /auth/anonymous                    → { token, user }
POST   /auth/link                         { provider, id_token } → { token, user }   anonymous → real account

GET    /me                                → user
PATCH  /me                                { display_name?, time_zone? }

GET    /progress                          → { "68": [1,2,3], ... }                   same shape as hifdth.learned.v1
PUT    /progress/{surah}                  { ayahs: [1,2,3] }                         replaces that surah's set (mirrors LearnedStore.commit)

GET    /schedule                          → sessions[]
PUT    /schedule                          sessions[]
POST   /sessions/{id}/complete            { completed_at, surah?, ayahs? }

GET    /today                             → { sessions[], goal: { done, total }, streak: { days[], count }, sessions_behind }

GET    /surahs                            → [{ n, name, ayah_count }]
GET    /surahs/{n}                        → { ayahs: [{ n, arabic, translation }] }
GET    /surahs/{n}/audio?reciter=…        → [{ ayah, url, duration_ms }]
```

`PUT /progress/{surah}` replacing the whole set matches how the app already saves (the learned sheet commits a full surah at once). This keeps the client change small.

## Offline and sync

The app has to keep working with no network, as it does today.
- **The device stays the source of truth while offline.** Keep `SharedPreferences` as a local cache and queue changes to push when back online.
- **Merge rule for learned ayahs:** last write per surah wins, using the client's `updated_at`. If that ever loses data in practice, switch to per-ayah add and remove events.
- **First sign-in:** upload the local `hifdth.learned.v1` and merge it with anything already on the server (union, so nothing is lost).

## Decisions still open

- **Stack.** Two realistic routes for a solo Flutter developer:
  - *Supabase* (Postgres, auth with Apple and Google, storage for audio, row-level security). Least server code to write.
  - *A custom server* (Dart Frog or Shelf to stay in Dart, or Node/Go) on Postgres. More control, more to run.
- **Reciter(s)** and the audio licence.
- **Translation source** and its licence.
- **What counts as a "session"** for the streak: any completed session that day, or all of them.
- **Hifdth's mood thresholds.** These are in `moodFor` in `lib/widgets/hifdth_mood.dart`: 0 sessions behind is happy, 1 is worried, 2 or more is sad. Decide whether the server sends `sessions_behind` or the mood itself. Sending `sessions_behind` keeps the thresholds in the app.
