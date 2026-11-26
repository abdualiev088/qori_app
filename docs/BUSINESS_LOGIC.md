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
- **The profile card** heads Settings: a sky banner with an Edit pill ("Sign in" when signed out), the initial in a ringed circle, a segmented bar of how much of the Quran (6236 ayahs) is memorized, the name and email, and three numbers: surahs fully learned, evening lessons learned (ticked) and the best streak. Tapping it opens the account page, or sign-in when signed out. Home has no profile button.
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
- **The cloud icon is pinned:** they stay at the top right while the page scrolls under them.

## 7. Hifdth's mood (live)

- The mood comes from **tasks behind**: today's plan tasks whose time passed without being ticked (Morning after 12:00, Evening after 22:00).
  - **0 → happy** ("on track")
  - **1 → worried**
  - **2+ → sad**
- The mood sets Hifdth's face, the card's colour and the status line.
- Some days replace the status line: no plan ("Hifdth is waiting for your plan"), the rest day ("Rest day. Hifdth is resting too") and every task ticked ("Today's plan is done. Well done!"). The thresholds are in `moodFor` in `lib/widgets/hifdth_mood.dart`.

## 8. Home behaviour (live)

- When the user scrolls down, Hifdth flies from its card to the bottom-right corner and follows the page. Scrolling back up returns it to the card.
- When about half of the Quran progress section is on screen, Hifdth turns blue, looks left and asks: *"How much of the Quran have you memorised? Tap a surah to tell me."* The question hides after 8 seconds or when the user scrolls away. Tapping it scrolls to the Quran progress card.

## 9. Memorization plan: 33 repetitions (live)

- **One method: "33 repetitions".** Learn the new portion in the evening (about an hour), then recite it 33 times from memory on each of the next three mornings.
- **Set up in My Method.** The first visit shows the full explainer once (stepped diagram, At a glance, Tips). Later visits open on the plan form (**Set your plan**, or **Your plan** once one is saved), with the explainer folded behind "How it works".
  - The form has three groups (What to memorize, Daily pace, Rest day) and a live summary: days, finish date, ayahs, surahs, size and day 1. An impossible range swaps the summary for a hint.
  - **Create my plan** works as soon as the range is valid. Once a plan is saved, **Update my plan** is hidden until something differs from the saved plan; then it rises in above the nav like the mini-player. Changing a value back hides it again, and so does saving.
- **The plan:**
  - Reading order: **from the beginning** (Al-Fatihah first) or **from the end** (An-Nas first; surahs backwards, ayahs forwards). Default: from the end.
  - Start and end ayah. Default: An-Nas 1 → An-Naba 40. The end must come after the start in the reading order, or the plan can't be saved.
  - **New lines a day**, 1–30, in lines of the 15-line Madani mushaf. Default: 5.
  - Rest day: none, Friday, Saturday or Sunday. Default: Friday.
- **Line lengths are estimated** from each ayah's letters (37.18 letters a line), from the app's own Quran text. `tool/gen_ayah_lines.dart` generates `lib/data/ayah_lines.dart`.
- **Lessons:** one per study day, about the day's lines of whole ayahs.
  - A short surah is kept whole, as long as the lesson stays within 1.5× the day's lines.
  - A lesson ends at a surah boundary once it's half full.
  - Only long surahs are split.
  - A single very long ayah (Al-Baqarah 282) is a lesson on its own.
- **Each study day's tasks:**
  - **Morning:** recite, 33 times from memory, the lessons learned on the three study days before (1–3 lessons; none on day 1).
  - **Evening:** memorize the day's lesson, before 22:00.
- **A skipped evening:** when a past day's evening lesson wasn't ticked, that lesson counts as not learned. It is offered again the next study day, it isn't recited on the following mornings, and the plan gets one more study day (the finish date moves). Today's evening counts only once the day is over. Home's status pill then says "Skipped 2 days · finish moved to Sat, 24 Jan", and the day chip shows the longer total ("Day 4/52").
- **The calendar:**
  - A new plan starts today.
  - Rest days have no lesson and push the finish date back.
  - Changing the plan keeps its start date and today's ticks.
- **Home:**
  - "Today's plan" lists the tasks, and the user ticks each one. The morning recitation has an amber sun tile, the evening lesson an indigo moon tile, so the time of day shows at a glance.
  - The "Your plan" card shows the range, a strip of days, and the pace, finish date and rest day as chips; the rest day is spelled out with a capital ("Friday off"). Its edit button opens My Method.
  - Rest days, the days before the start and a finished plan each have their own message.
  - **Day calendar** (once a plan exists): a frosted-glass "‹ Today ›" pill floats in the top bar (left; the offline cloud is on the right), and the week's seven days sit above Hifdth's card, each with its weekday, date and state. Today is always the filled green cell. Home has no greeting or date line. Each day shows its state: done (green check), partly done (half amber ring), missed (soft red cross), today still open (green flame), coming up (gray flame), rest (sofa, as on the plan card). The arrows step a day, a day cell picks it, a sideways swipe moves a week, and tapping the pill opens the whole month in a bottom sheet (tap a day, swipe or arrow between months, "Back to today").
  - Picking another day shows that day's tasks with their ticks in Hifdth's card, titled with the date, plus "All done that day", "1 of 2 done that day", "Missed that day" or "Coming up". Only today can be ticked; a past day's unticked tasks show a red cross instead of a checkbox. Hifdth's mood follows the shown day: a missed day makes it sad, a partly done day worried, a done or upcoming day happy (today keeps the late-task rule). The goal and the streak always follow today.
- **Daily goal:** ticked ÷ today's tasks.
- **Streak:**
  - The number of study days in a row with every task ticked.
  - Rest days are skipped and don't break it.
  - An unfinished today doesn't break it either: counting starts at yesterday.
  - Shown as a ring that this week's done study days fill, with the longest streak so far ("Longest 14 days") under it.
- **Saved on this phone only** (`hifdth.plan.v1`, `hifdth.plan.done.v1`, `hifdth.howseen.v1`). The plan works signed out and isn't synced or cleared on log-out.
- **Planned:** sync the plan and ticks to the account; more methods.

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

## 11. Settings and languages (live)

- The bottom nav has four tabs: **Home**, **Player**, **My Method** and **Settings** (gear).
- **Language:** English (default), Russian, Uzbek in Latin script and Uzbek in Cyrillic, each listed by its own name only; the Uzbek ones say their script: "Oʻzbekcha (lotin)", "Ўзбекча (кирилл)". The choice applies at once and is saved on the device (`hifdth.locale.v1`); the phone's own language is not used yet. Surah meanings and the English ayah translation stay English for now. Surah names stay in their transliteration.
- **Playback:** the same repeat count (1, 3, 5, 7, 10, ∞) and "Then next ayah" switch the player uses; changing them here changes the player.
- **About:** version, reciter; Privacy policy and Contact us are marked "Soon".
- **Small Hifdth:** when Home scrolls and Hifdth flies to the corner, it turns happy (green) on the way and stays happy there whatever the plan's mood; it takes the real mood back as it lands in the card.

## 12. Not built yet

- Changing email or password inside the app (password reset by email works).
- More reciters and translations.
