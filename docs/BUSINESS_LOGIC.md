# Qori: business logic

The rules the app follows, in plain words. If this file and the code disagree, the code wins: fix this file in the same change.

Status tags: **live** (works today), **placeholder** (hardcoded until the real logic exists), **planned** (not built).

## 1. What Qori is

Qori helps a person memorise the Quran (hifdth). Hifdth, a round green mascot, reflects how the user is doing and talks to them. The app works fully offline and syncs to the Qori server when it can.

## 2. Core facts

- The Quran has **114 surahs**, numbered in Hafs order, with **6,236 ayahs**. Surah names and ayah counts are fixed in `lib/data/surahs.dart`.
- An ayah is valid only if the surah is 1–114 and the ayah is 1 to that surah's count. Anything else is dropped silently, on the device and on the server.
- In the player, ayah **0 is the Basmala**. It's never counted as learned.

## 3. Learned progress (live)

- The user marks which ayahs of each surah they have memorised. Progress is stored as a set of ayah numbers per surah: `{"68": [1, 2, 3]}`.
- **A surah is learned when every one of its ayahs is learned.** There's no separate "surah learned" flag, here or on the server.
- **Quran progress** on Home is the count of fully learned surahs out of 114.
- **Marking** happens in the learned sheet (`lib/widgets/learned_sheet.dart`):
  - Tap toggles one ayah.
  - Sliding marks every ayah the finger passes, all set to the opposite of the first ayah's state.
  - Edits are a draft until the user saves them. The sheet won't close with unsaved edits; it asks "Save changes?".
  - Saving replaces that surah's whole set.
- The next ayah to learn gets a dashed outline.

## 4. Accounts and sign-in (live)

- **Guest first:** on first launch the app silently creates a guest account, so progress syncs before the user signs up. The app never requires an account.
- **Email first:** the user enters an email, and the server says whether it has an account.
  - A known email → password step ("Welcome back") with "Forgot password?".
  - A new email → name and password step ("Nice to meet you").
- **Password rules:** 8+ characters and at least one number. The app checks them while you type, and the server checks again.
- **Apple and Google** sign-in are on the first step. Closing their sheet does nothing.
- **Guest carry-over:**
  - Signing up, or a first Apple/Google sign-in, turns the guest into the account and keeps its id.
  - Signing in to an existing account merges the guest's progress into it (union) and deletes the guest.
- **Errors:** show only after the first submit, next to their field, and clear as the user types. Unexpected failures always show a message, never nothing.
- **The profile button** on Home opens the sign-in screen, or the account page when signed in to a real (non-guest) account.
- **Signed in stays signed in offline:** the device remembers who is signed in. On launch, and whenever the account page opens, the app checks with the server.
  - **Offline:** the remembered account is shown, with the notice "You're offline. Turn on the internet to update your account."
  - **The server ended the session** (signed out elsewhere, or the account was deleted): the app forgets the account, closes the page and says "You were signed out."
  - Log out works offline: the session ends on the phone straight away.

## 5. Account page (live)

- Shows only account settings and Log out:
  - **Name:** editable.
  - **Email:** read-only. The server can't change it yet.
  - **Password:** sends a reset link. Hidden for Apple/Google-only accounts.
  - **Delete account:** required by the App Store.
- **Log out** asks first, then revokes this device's session. Progress **stays on the phone** and syncs to a fresh guest account.
- **Delete account** asks first, then deletes the account and all its synced data on the server. This can't be undone.
- Every confirmation and edit uses the app's own bottom sheets, never system or Material dialogs.

## 6. Sync (live)

The rules are in `lib/data/progress_sync.dart`.

- **The device is the source of truth while offline.** Every save is queued: the latest set per surah, with the time it changed. The queue is sent when online.
- **Conflicts:** last write per surah wins. If the server has a newer write (`409`), its set replaces the local one for that surah.
- **New session** (a new guest or any sign-in): the device's whole progress is merged into the account first (union), so nothing is lost.
- **With nothing queued,** the server's progress replaces the local copy. That's how changes from other devices arrive.
- **When it syncs:** on launch, when the app returns to the foreground, and after every save. Offline or server errors keep everything queued for next time.

## 7. Hifdth's mood (placeholder rules)

- The mood comes from **sessions behind**: sessions whose time passed without being done.
  - **0 → happy** ("on track")
  - **1 → worried**
  - **2+ → sad**
- The mood sets Hifdth's face, the card's colour and the status line.
- Today `sessionsBehind` is hardcoded to `0`. The real value will come from the schedule (section 9). The thresholds are in `moodFor` in `lib/widgets/hifdth_mood.dart`.

## 8. Home behaviour (live)

- When the user scrolls down, Hifdth flies from its card to the bottom-right corner and follows the page. Scrolling back up returns it to the card.
- When about half of the Quran progress section is on screen, Hifdth turns blue, looks left and asks: *"How much of the Quran have you memorised? Tap a surah to tell me."* The question hides after 8 seconds or when the user scrolls away. Tapping it scrolls to the Quran progress card.

## 9. Daily plan, goal and streak (placeholder)

These are hardcoded on Home until the schedule exists:
- **Today's sessions:** Morning session, Review, Evening session, each done or upcoming.
- **Daily goal:** a percentage and how many sessions are left.
- **Streak:** the days of the week with a session done.

**Planned:**
- The user sets a schedule.
- Completed sessions are logged on the server.
- Goal, streak and sessions behind are computed from that log **in the user's time zone**.
- Still open: whether a day counts toward the streak with any one session done, or only with all of them. See `docs/BACKEND.md`.

## 10. Player (live, Al-Qalam only)

- Only **Surah 68, Al-Qalam** (52 ayahs plus the Basmala) is available. Its audio is bundled in the app.
- **Repeat** each ayah 1, 3, 5, 7 or 10 times, or forever. The default is 3.
- **With no selection:** the player stops after the current ayah, unless "Then next ayah" (auto-next) is on or the user taps Next.
- **With a selection:** it plays only the selected ayahs in order. At the end it wraps to the first only if "Loop selected" is on.
- Previous and Next follow the same rules backwards and forwards.
- The current ayah, repeat count, auto-next, loop and selection are remembered between launches, on the device only.
- **Planned:** all 114 surahs, with audio streamed from storage behind a CDN and downloaded per surah.

## 11. Not built yet

- The **My Method** and **Settings** tabs are placeholders.
- Changing email or password inside the app (password reset by email works).
- More reciters and translations.
