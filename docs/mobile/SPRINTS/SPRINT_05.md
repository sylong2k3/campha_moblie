# Sprint 05 — Phản ánh hiện trường

## Sprint Goal

Cung cấp luồng phản ánh hiện trường mobile từ khám phá công khai đến gửi minh chứng, theo dõi trạng thái và nhận deep link thông báo; dùng đúng API/storage contracts, không mock backend blocker.

## Phạm vi hoàn thành

### M15 — Danh sách và bản đồ

- `GET /field-reports/public` với `data.items + metadata`, phân trang và hủy request cũ.
- Chuyển danh sách/bản đồ; status filter dùng chung dữ liệu.
- Nearby status lọc local vì backend nearby không nhận status; không trộn public paging.
- Bottom sheet native cho phép chọn date range và radius 10–500 m.
- Picker giới hạn 365 ngày lịch; end-of-day expansion luôn nằm trong backend max 366 ngày.
- GPS chỉ xin sau khi user xác nhận filter.
- Pull-to-refresh/retry nearby chạy lại exact stored query, không rơi về public list.
- Card chỉ hiện `photo_count`; không tạo thumbnail giả khi public API không trả URL.
- Real report markers từ longitude/latitude.
- Loading, public empty, filtered empty, error và stale-data states.
- Guest đọc public; create/mine/detail dùng safe auth return.
- Nearby repository luôn gửi `from/to`, radius và coordinate; live smoke trả `200`.

### M16 — Tạo phản ánh ba bước

1. Minh chứng: camera/gallery, 1–5 ảnh, remove, per-item progress.
2. Vị trí: foreground GPS, accuracy và pin điều chỉnh bằng map tap.
3. Mô tả: 10–2000 ký tự, xác nhận trung thực, submit lock.

Media được decode và encode lại PNG trong app support:

- Loại EXIF/metadata.
- Giới hạn input 30 MB, output 10 MB và cạnh 2400 px.
- Persist đường dẫn durable để sống qua restart.
- Không upload trước Submit.
- Failure giữ form/files và upload stage để retry.
- Success/clear xóa local draft files.

Storage lifecycle:

1. Shared Dio presign.
2. Isolated `Dio()` PUT absolute URL, không rò Bearer sang MinIO.
3. Shared Dio commit.
4. Create report chỉ với committed `photoIds`.

### M17 — Của tôi và chi tiết

- Mine state partition theo authenticated user ID; response cũ không commit sau identity change.
- Authenticated detail hiển thị status, description, coordinates/geometry, photo carousel, history và review reason.
- Photo URL lỗi/hết hạn reload detail để xin URL mới; URL không persist.
- Delete gửi bắt buộc `expectedUpdatedAt`, confirm trước thao tác và giữ lỗi conflict.
- Mine status chips và pagination dùng đúng authenticated controller.

### Push

- Shared-Dio register/unregister exact `/devices/push-token` payload.
- Register theo authenticated identity; unregister trước auth token bị xóa.
- Chỉ deep link khi `reportId` parse thành positive integer.
- Firebase init thiếu native resources vẫn no-op an toàn, không crash.

## Verification

### Static và automated

```text
dart format lib test: PASS
flutter analyze: No issues found
flutter test: 29/29 passed (current tree, includes later Sprint 6 tests)
```

Contract tests khóa public page/BIGINT IDs, private detail, presign/commit, status/URL rejection và safe report routes.

### Live public API

```text
GET /field-reports/public?page=1&limit=20: 200, items=[]
GET /field-reports/nearby?...&from=<ISO>&to=<ISO>: 200, data=[]
```

## Definition of Done

| Hạng mục | Trạng thái | Bằng chứng/Ghi chú |
|---|---|---|
| M15 public list/map/filter/paging | Done | Code + tests + live 200; Android final capture |
| M16 native local composer | Done | Code + analyze/tests |
| Exact storage lifecycle | Done | Contract/code; authenticated runtime Blocked |
| M17 mine/detail/delete | Done | Code + contract tests; authenticated runtime Blocked |
| Push device/deep link wiring | Done | Code/analyze; Firebase delivery Blocked |
| Android `lib/main.dart` guest/public runtime | Done | Dev APK rebuilt/installed/launched; M15 evidence |
| iOS runtime | Blocked | Windows host; needs macOS |

Android evidence:

- `docs/mobile/design/sprint5_reports_android.png`
- `docs/mobile/design/sprint5_reports_final.xml`
- `docs/mobile/design/sprint5_nearby_filter.png`
- `docs/mobile/design/sprint5_nearby_filter.xml`
- Semantics xác nhận list/map/status, date range, radius 10–500 m và create action.

## Blocked — không mock

1. Không có runtime password credential:
   - Login/auth bootstrap proof.
   - Submit/upload lifecycle thật.
   - Mine/detail/delete thật.
2. Không có flavor Firebase resources/plugins:
   - FCM register/delivery/tap runtime.
   - Native Crashlytics runtime.
3. Public backend hiện không có report fixture; list/nearby empty là response thật.

## Sprint Review

Public code path và Android guest path có thể chạy từ `lib/main.dart`. Authenticated acceptance chưa được claim Done. Blockers chuyển Sprint 7 hardening/RC trừ khi credential/Firebase resources được cung cấp sớm hơn.
