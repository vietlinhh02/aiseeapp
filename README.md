# AiSee App

Ứng dụng hỗ trợ người khiếm thị, xây dựng bằng Flutter.

## Tính năng chính

- Trợ lý giọng nói (LiveKit)
- Gọi điện / nhắn tin với người thân
- Quản lý danh bạ gia đình
- Nhắc nhở uống thuốc, lịch hẹn
- Thông báo đẩy (FCM)

## Cài đặt

```bash
flutter pub get
flutter run
```

## Cấu hình

Chỉnh sửa `assets/app_config.env` để thay đổi backend URL và các thông số khác.

RevenueCat nên truyền bằng `--dart-define` khi chạy/build:

```bash
flutter run --dart-define=REVENUECAT_API_KEY=<revenuecat_public_sdk_key>
```
