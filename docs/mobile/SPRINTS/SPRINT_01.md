# Sprint 01 — Auth, Session, Shell and Profile

Date: 2026-08-10  
Goal: app production từ `lib/main.dart` cho guest/auth lifecycle và shell 5 tab.

## Committed

| Story | Result | Evidence |
|---|---|---|
| MOB-101 Splash/bootstrap | Done | session controller, `/me` restore, branded splash |
| MOB-102 Login/change password/errors | Done with credential limitation | routed forms, 409/422/503 mapping |
| MOB-103 Register/verification | Done | token and verification response branches |
| MOB-104 Token lifecycle/returnTo | Done | one TokenStorage, refresh mutex retained, safe allowlist |
| MOB-105 Shell/profile/settings | Done | indexed 5 tabs, guest/auth profile, vi/en, light/dark/system |

## Delivered

- Removed production home placeholder.
- `StatefulShellRoute.indexedStack`: Bản đồ, Hiện trường, Tin tức, Tài liệu, Cá nhân.
- Production Mapbox basemap root with retained branch state.
- Auth repository no longer owns duplicate secure storage or manual Authorization.
- Backend sanitized user parses string BIGINT, nested role and runtime permissions.
- Login/register/forgot/change-password with validation, submit lock and recovery errors.
- Guest/auth profile, theme system/light/dark, vi/en persistence and confirmed logout.
- Future Sprint tabs state schedule honestly; no mock API content.

## Verification

```text
dart format lib test: clean
flutter analyze: No issues found
flutter test: 6/6 passed
Android dev APK: built, installed, launched from lib/main.dart
```

Android evidence:

- `design/sprint1_shell_android.png`
- `design/sprint1_profile_android.png`
- `design/sprint1_login_android.png`

UI Automator confirmed:

- Mapbox view and attribution.
- Five canonical tabs.
- Guest profile, login/register, language and system appearance.
- Login email/password/recovery/register controls.

## Not Done / Blocked

- Authenticated live login/session restore/change-password evidence: Blocked until runtime password is supplied or user enters it manually. No secret stored.
- Google mobile login: Not committed; native Google sign-in dependency/config unavailable.
- iOS runtime: Windows environment; macOS gate retained.

## Review Decision

Sprint 1 product increment accepted for public/guest flow and code contract. Authenticated backend acceptance remains a named evidence gap, not hidden mock acceptance.

Sprint 2 entry gate passes for session/router architecture. CMS serializers must be corrected before first list.

## Retrospective

- Keep: exact route/validator/service audit before UI.
- Improve: inject config seams earlier to avoid dotenv widget-test coupling.
- Stop: repository-level manual token headers.
