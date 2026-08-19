# Sprint 2 — CMS Content Review

## Goal

Hoàn thiện M18–M21 trên app production `lib/main.dart` bằng API thật: tin tức,
bình luận, văn bản và bản đồ PDF. Không dùng mock, HTML WebView hoặc Chrome UAT.

## Delivered

- News list: `data.items + metadata`, pull-to-refresh, infinite paging, empty/error/stale states.
- Search: debounce 400 ms, giới hạn 100 ký tự, huỷ Dio request cũ.
- News detail: nội dung thật, native share, renderer text an toàn cho Markdown/legacy HTML.
- Comments: list thật, guest-to-login `returnTo`, validation 1–2000, pending moderation.
- Documents/PDF: hai nhánh giữ state riêng, search/paging/detail metadata thật.
- File actions: xin presigned URL 300 giây chỉ sau tap; open hệ thống/native share.
- Router: `/news/:id`, `/documents/:id`, `/documents/pdf/:id`; numeric safe `returnTo`.
- CMS IDs dùng `String`; `size_bytes` chấp nhận JSON string/int.
- Dio localization chỉ dùng `Accept-Language`; bỏ global `lang` gây Joi HTTP 400.
- vi/en đầy đủ. `share_plus 12.0.2` cung cấp native share sheet.

## Verification

### Automated

```text
dart format lib test: PASS
flutter analyze: No issues found
flutter test: 10/10 passed
```

Contract tests khóa:

- BIGINT-safe IDs.
- `data.items + metadata`.
- Exact snake_case document/PDF/comment fields.
- Download grant.
- Malformed envelope rejection.
- Safe dynamic CMS `returnTo`.

### Live API smoke

```json
{"newsStatus":200,"newsCount":3,"newsTotal":7,"commentCount":5,"documentCount":3,"pdfCount":3}
```

### Android runtime

Command:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:3006 tcp:3006
flutter run --flavor dev -d emulator-5554 -t lib/main.dart --no-resident
```

Result:

- `app-dev-debug.apk` built, installed and launched from `lib/main.dart`.
- Live news titles and summaries visible.
- Live article detail visible; share control exposed.
- Live documents and PDF maps visible with exact metadata.
- PDF detail visible; open/share protected controls exposed.
- Guest file action opens login and retains safe numeric return route.

Evidence:

- `design/sprint2_news_live_android.png`
- `design/sprint2_article_android.png`
- `design/sprint2_documents_android.png`
- `design/sprint2_pdf_android.png`
- `design/sprint2_pdf_detail_android.png`
- `design/sprint2_auth_return_android.png`

## Definition of Done

| Item | Status | Evidence / blocker |
|---|---|---|
| News list/search/paging/detail/share | Done | Automated + Android live API |
| Comments list and guest auth handoff | Done | Android detail/auth handoff |
| Authenticated comment create | Blocked | Runtime credential unavailable; no mock accepted |
| Documents/PDF list/search/detail | Done | Android live API |
| Presigned open/share UI and on-demand implementation | Done | Code/route/runtime controls |
| Successful authenticated download grant/open/share | Blocked | Runtime credential + permission required |
| No persistent internal CMS cache/presigned URL | Done | In-memory providers/local action scope only |
| Android production entrypoint | Done | APK build/install/launch |
| iOS runtime | Not Done | Windows environment; macOS gate remains |

## Sprint Decision

Sprint 2 implementation and guest/public Android acceptance: **Done**.
Authenticated permission-dependent acceptance remains named blocker, not replaced by mock.
Proceed Sprint 3 with existing real-MVT backend blocker visible.
