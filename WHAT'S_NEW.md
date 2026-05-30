# AiSee v1.0.3 - What's New 🎉

## ✨ Cải tiến & Tính năng mới

### 🎨 Giao diện Supporter được thiết kế lại
- **Redesign supporter UI** với giao diện hoàn toàn mới
- **Real ad flow** - Hệ thống quảng cáo thực tế cho supporter
- **Mời bạn bè bằng QR** - Chia sẻ mã QR để mời bạn bè tham gia
- **Supporter overview tab** - Xem thống kê, quảng cáo và đổi quà dễ dàng

### 🔧 Cải thiện hiệu suất
- **Tối ưu pin hiệu quả** - Giảm đáng kể mức tiêu thụ pin
- **Stop wave decay timer** khi microphone không hoạt động để tiết kiệm pin
- **Deep performance optimizations** cho trải nghiệm mượt mà hơn

### 🌐 Cải thiện kết nối
- **Fix reconnect throttle** - Chỉ reset counter sau 10 giây kết nối ổn định
- **Fix 401 token expiry deadlock** trên WebSocket reconnect sau khi app chạy nền
- **Cải thiện giao tiếp AI** - Sửa các vấn đề giao tiếp trong aiseeapp

### 🗣️ Hỗ trợ ngôn ngữ
- **Chuyển tiếng Việt không dấu thành có dấu** - Hỗ trợ tốt hơn cho ngôn ngữ tiếng Việt

### 📱 Cải thiện UX
- **Compact usage header card** - Giao diện gọn hơn
- **Fix owner có thể xem plan/quota** mà không cần chọn cared user trước
- **Tăng daily ad limit** từ 10 lên 50 quảng cáo/ngày

### 🛡️ Bảo mật & An toàn
- **Fix NSFW detection** - Gọi sendNsfwDetected() khi camera phát hiện nội dung không an toàn
- **Configure release signing** và cập nhật Google Sign-In với Firebase OAuth client IDs mới

### 🎯 Sửa lỗi quan trọng
- **Fix AdMob startup crash** - Sửa lỗi crash khi khởi động
- **Bundle local app fonts** - Fonts được bundle trực tiếp trong app
- **Fix assistant support call edge cases**
- **Remove 17 unnecessary non-null assertions** trên AppLocalizations

## 📦 Thông tin phiên bản
- **Phiên bản:** 1.0.3
- **Build number:** 4
- **Kích thước:** ~232.5 MB
- **Yêu cầu:** Android 5.0+

---
*Cảm ơn bạn đã sử dụng AiSee! Nếu có bất kỳ vấn đề nào, vui lòng liên hệ support.*