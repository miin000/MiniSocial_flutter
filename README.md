# MiniSocial Flutter

Ứng dụng mobile của MiniSocial, xây dựng bằng Flutter và Dart. Ứng dụng dùng
MiniSocial API cho dữ liệu mạng xã hội, Firebase cho các chức năng tích hợp
realtime/xác thực và ML service cho recommendation.

## Tính năng

- Đăng ký, đăng nhập, đăng xuất và quản lý tài khoản.
- Feed bài viết, tạo/chỉnh sửa bài viết, like, comment và report.
- Hồ sơ cá nhân, danh sách bạn bè và gợi ý kết bạn.
- Nhắn tin cá nhân/nhóm, quản lý thành viên, recall và chia sẻ tin nhắn.
- Nhóm, thông báo, upload ảnh và recommendation.
- Các màn hình quản trị phù hợp với quyền tài khoản.

## Công nghệ

- Flutter và Dart SDK `^3.9.2`
- Provider cho state management
- Dio cho HTTP request
- Shared Preferences và Flutter Secure Storage cho dữ liệu local/token
- Firebase Core, Firebase Auth, Firebase Messaging và Cloud Firestore
- Cloudinary Public cho upload ảnh
- `cached_network_image`, `intl`, `timeago` và Flutter Toast

## Yêu cầu môi trường

- Flutter SDK tương thích với Dart 3.9.2
- Android Studio/Android SDK hoặc Xcode (khi build iOS)
- Thiết bị thật hoặc emulator/simulator
- MiniSocial API đang chạy tại URL cấu hình
- ML service nếu sử dụng recommendation

Kiểm tra môi trường:

```bash
flutter doctor
```

## Cài đặt

```bash
git clone https://github.com/miin000/MiniSocial_flutter.git
cd MiniSocial_flutter
flutter pub get
```

## Cấu hình local

URL service được khai báo trong `lib/config/app_config.dart`:

```dart
static const String apiBaseUrl = 'http://localhost:3001/api/v1';
static const String mlBaseUrl = 'http://localhost:8000';
```

Với Android emulator, `localhost` của emulator không trỏ đến máy phát triển;
thường cần dùng `10.0.2.2`. Với thiết bị thật, dùng IP LAN của máy chạy API.
Khi deploy, thay bằng URL HTTPS của API và ML service.

Firebase cần được cấu hình đúng cho từng platform trong
`lib/firebase_options.dart` và các file native tương ứng trước khi dùng các
chức năng Firebase.

## Chạy ứng dụng

Liệt kê thiết bị:

```bash
flutter devices
```

Chạy debug:

```bash
flutter run
```

Chọn thiết bị cụ thể:

```bash
flutter run -d <device-id>
```

Build Android:

```bash
flutter build apk
```

Build iOS (macOS và Xcode bắt buộc):

```bash
flutter build ios
```

Build web:

```bash
flutter build web
```

## Kiểm tra chất lượng

```bash
flutter analyze
flutter test
```

Format mã nguồn Dart:

```bash
dart format lib test
```

## Cấu trúc chính

```text
lib/
├── components/    # Widget dùng lại
├── config/        # URL service và cấu hình Firebase
├── models/        # Model dữ liệu
├── providers/     # State management bằng Provider
├── screens/       # Màn hình theo chức năng
├── services/      # API, auth, chat và recommendation services
├── utils/         # Tiện ích dùng chung
└── main.dart      # Điểm khởi chạy ứng dụng
test/              # Unit/widget tests
android/, ios/     # Cấu hình native theo platform
web/               # Cấu hình Flutter Web
```

`ApiService` quản lý Dio và token; các provider gọi service tương ứng rồi
thông báo thay đổi cho UI. Khi thêm endpoint mới, ưu tiên cập nhật model,
service và provider thay vì đặt request trực tiếp trong screen.

## Luồng service local

```text
Flutter app  http://localhost:3001/api/v1  MiniSocial API
Flutter app  http://localhost:8000         ML Recommendation
```

API mặc định lắng nghe port `3001` và sử dụng global prefix `/api/v1`. Đảm bảo
thiết bị/emulator có thể truy cập các địa chỉ trên trước khi kiểm thử login,
upload, chat hoặc recommendation.

## License

Dự án hiện chưa công bố license open source. Hãy liên hệ chủ dự án trước khi
phân phối lại.
