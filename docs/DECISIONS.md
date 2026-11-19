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
