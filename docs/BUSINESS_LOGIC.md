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

- **Signed out means read-only:** Quran progress belongs to a signed-in account. There are no guest accounts.
  - The app works signed out: the **Player** plays every available surah.
  - Signed out, Home looks the same except for **the Quran progress card**, which becomes a locked card: a faded grid, the Hifz guide saying "Sign in to save your Quran progress", and **Sign in** and **Register** buttons (both open the sign-in screen; tapping the art does too). Hifdth doesn't ask its "Tap a surah" question while signed out.
  - Nothing on the phone can change progress until the user signs in, and the server refuses progress requests from anyone not signed in (`403 account_required`).
  - A guest session left over from an older app version is dropped on launch, together with any progress on the phone.
- **Email first:** the user enters an email, and the server says whether it has an account.
  - A known email → password step ("Welcome back") with "Forgot password?".
  - A new email → name and password step ("Nice to meet you").
- **Password rules:** 8+ characters and at least one number. The app checks them while you type, and the server checks again.
- **Apple and Google** sign-in are on the first step. Closing their sheet does nothing.
- **When signing in:** an account that already has ayahs replaces whatever is on the phone; an empty account gets what's on the phone (normally nothing, since signed out can't change progress). Sign-in sends no earlier session, so the server never merges anything in.
- **Errors:** show only after the first submit, next to their field, and clear as the user types. Unexpected failures always show a message, never nothing.
- **The profile button** on Home opens the sign-in screen, or the account page when signed in.
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
- **Log out** asks first, then revokes this device's session and **clears Quran progress on the phone**. The account keeps its ayahs; signing in again brings them back. Home goes back to the signed-out card.
- **Delete account** asks first, then deletes the account and all its synced data on the server. This can't be undone.
- Every confirmation and edit uses the app's own bottom sheets, never system or Material dialogs.

## 6. Sync (live)

The rules are in `lib/data/progress_sync.dart`.

- **The device is the source of truth while offline.** Every save is queued: the latest set per surah, with the time it changed. The queue is sent when online.
- **Conflicts:** last write per surah wins. If the server has a newer write (`409`), its set replaces the local one for that surah.
- **New session:** see "When signing in" (section 4). **Signed out, nothing syncs.**
- **With nothing queued,** the server's progress replaces the local copy. That's how changes from other devices arrive.
- **When it syncs:** on launch, when the app returns to the foreground, and after every save.
- **Offline:** every change is saved on the phone first and queued. Server errors keep everything queued. While offline the app retries every 10 seconds, so the queue goes out as soon as the internet is back.
- **Offline indicator:** while the server can't be reached, a glass cloud icon (crossed out) appears left of the profile icon on Home, in the same style. Tapping it explains that changes are saved on the phone and will sync when back online. It disappears on the next successful request.
- **The cloud and profile icons are pinned:** they stay at the top right while the page scrolls under them.

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

## 10. Player (live)

- **The Player tab opens on the surah list**, grouped by the 30 juz. A surah that spans juz appears in each; rows that start partway open the player at their first ayah. Search covers names (forgiving spelling), numbers, meanings and Arabic.
- **List progress** comes from Quran progress: the star fills by the memorized share, memorized surahs get a check, whole rows in progress show "learned/total".
- **Every surah's text** is in the app (Arabic and Sahih International English). **Only Al-Qalam (68) has audio** (Alijon Qori, bundled); other surahs open with their text and say audio is coming soon.
- **Repeat** each ayah 1, 3, 5, 7 or 10 times, or forever. The default is 3.
- **With no selection:** the player stops after the current ayah, unless "Then next ayah" (auto-next) is on or the user taps Next.
- **With a selection:** it plays only the selected ayahs in order. At the end it wraps to the first only if "Loop selected" is on.
- Previous and Next follow the same rules backwards and forwards. Surahs 1 and 9 have no Basmala row.
- **Saved on the device:** the current ayah and selection **per surah**; repeat, auto-next and loop for all surahs.
- **One surah is active at a time.** Closing the player keeps it playing; the mini-player above the nav shows it on the list (play/pause, ×, tap to reopen at the same place). × stops it.
- **Opening a surah only reads it** (unless it's already the active one): no ayah is highlighted, the full player panel stays hidden, and leaving it shows no mini-player. Any surah that was active keeps playing in the mini-player. **Tapping an ayah** makes that surah the active one: the old one stops, the tapped ayah plays (when it has audio), and the full player appears.
- **Planned:** audio for every surah (the reciter's), streamed from storage behind a CDN.

## 11. Not built yet

- The **My Method** and **Settings** tabs are placeholders.
- Changing email or password inside the app (password reset by email works).
- More reciters and translations.
