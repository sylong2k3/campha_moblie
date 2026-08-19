# Product Vision — Mobile GIS Cẩm Phả

## Vision

Mobile GIS Cẩm Phả giúp người dân và cơ quan thành phố đọc cùng một nguồn dữ liệu không gian,
thu thập bằng chứng hiện trường và xử lý công việc GIS an toàn ngay tại vị trí phát sinh.
Sản phẩm ưu tiên **map-first, tin cậy, dễ dùng ngoài hiện trường**, không thu nhỏ dashboard web.

## Problem Statement

- Dữ liệu GIS, tin tức, tài liệu và phản ánh nằm ở nhiều luồng rời nhau.
- Tác nghiệp hiện trường cần GPS, ảnh, hình học và trạng thái xử lý nhưng mạng có thể gián đoạn.
- Quyền truy cập khác nhau theo cơ quan; thao tác sai quyền hoặc ghi đè phiên bản gây rủi ro dữ liệu.
- Ứng dụng mobile hiện mới có core/repository, chưa có luồng sản phẩm hoàn chỉnh.

## Personas

| Persona | Nhu cầu chính | Rào cản cần giải quyết |
|---|---|---|
| Khách | Xem bản đồ, tin, tài liệu công khai | Không bị ép đăng nhập sớm |
| Người dân | Gửi/theo dõi phản ánh, bình luận, lưu draft | Quyền riêng tư, bằng chứng, mạng yếu |
| Cán bộ UBND | Xem dữ liệu, tài liệu nội bộ, duyệt phản ánh theo quyền | Thông tin nhanh, trạng thái rõ |
| Cán bộ Sở TNMT | Truy vấn, đo, route, sửa feature và xử lý conflict | Dữ liệu gốc phải an toàn, có lịch sử |
| Cán bộ Sở Xây dựng | Xem lớp/tài liệu và phản ánh được cấp | Không lộ tài nguyên ngoài ACL |
| Quản trị hệ thống | Vận hành, nội dung và giám sát | Permission payload phải thắng giả định UI |

## Value Proposition

> Một ứng dụng civic GIS bản địa cho Cẩm Phả: mở là thấy bản đồ, thao tác tại hiện trường,
> dùng API thành phố làm nguồn thật, giữ an toàn quyền và phiên bản dữ liệu.

## Product Outcomes

1. Guest mở được map/content công khai mà không gặp dead-end.
2. Citizen gửi phản ánh thật gồm mô tả, vị trí, ảnh và theo dõi trạng thái.
3. Cán bộ dùng công cụ GIS và nội dung đúng permission từ server.
4. `so_tnmt` sửa feature có optimistic conflict, history và restore; không ghi đè im lặng.
5. Form/queue chịu được gián đoạn mạng trong phạm vi MVP.
6. Android/iOS có UI nhất quán, accessibility AA và không lộ secret/PII.

## Success Metrics

| Chỉ số | Mục tiêu Release Candidate |
|---|---:|
| Crash-free smoke sessions | 100% trong device matrix UAT |
| Public API happy paths | 100% acceptance endpoint bắt buộc |
| Role UAT paths | 100% role/capability đã chọn |
| Analyze/test | 0 lỗi; test bắt buộc đạt |
| Placeholder/dead button | 0 |
| Touch target | ≥ 48dp |
| Text/controls contrast | WCAG AA |
| Map first meaningful frame | Đo trên Android tầm trung; không bị CMS chặn |
| Silent conflict/data overwrite | 0 |
| Secret/PII trong log/evidence | 0 |

## Scope

### In Scope

- Auth/session/profile; guest-first navigation.
- Mapbox basemap, MVT, search, identify, GPS, weather, nearby, measure, route, draft.
- CMS news/comments, documents, PDF maps và presigned download.
- Field reports, storage upload lifecycle, push deep link.
- TNMT feature edit/history/restore.
- Offline form/change queue có giới hạn và conflict review.
- Light/dark, vi/en, accessibility, release hardening.

### Non-goals

- Không thay backend hay database bằng client-side logic.
- Không dùng Mapbox Directions thay pgRouting backend.
- Không offline toàn bộ GIS trong MVP.
- Không đưa quản trị web đầy đủ vào mobile.
- Không tạo renderer abstraction có một implementation.
- Không ship credential/private secret trong asset hoặc source.

## Product Principles

1. Dữ liệu GIS quan trọng hơn trang trí.
2. API, validator và permission payload hiện hành là nguồn thật.
3. Guest được khám phá; đăng nhập tại thời điểm hành động ghi.
4. Lỗi phải có cách khắc phục; conflict phải có lựa chọn an toàn.
5. Mỗi Sprint giao vertical slice UI → API → state → test → evidence.
