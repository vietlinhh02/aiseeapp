// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'AiSee';

  @override
  String get languageVi => 'Tiếng Việt';

  @override
  String get languageEn => 'English';

  @override
  String get settingsLanguageSection => 'Ngôn ngữ';

  @override
  String get settingsLanguageLabel => 'Ngôn ngữ ứng dụng';

  @override
  String get actionSave => 'Lưu';

  @override
  String get actionCancel => 'Huỷ';

  @override
  String get actionRetry => 'Thử lại';

  @override
  String get actionContinue => 'Tiếp tục';

  @override
  String get actionConfirm => 'Xác nhận';

  @override
  String get commonError => 'Đã xảy ra lỗi';

  @override
  String get commonLoading => 'Đang tải…';

  @override
  String get personalTabSemanticsLabel =>
      'Cá nhân. Lịch uống thuốc và nhắc nhở của bạn.';

  @override
  String get personalTabIntro => 'Thông tin cá nhân và lịch nhắc nhở của bạn.';

  @override
  String get personalMedicationTitle => 'Lịch uống thuốc';

  @override
  String personalMedicationCount(int count) {
    return '$count nhắc nhở';
  }

  @override
  String get personalMedicationEmpty => 'Chưa có lịch';

  @override
  String get personalAppointmentsTitle => 'Lịch hẹn';

  @override
  String personalAppointmentsCount(int count) {
    return '$count lịch hẹn';
  }

  @override
  String get personalAppointmentsEmpty => 'Chưa có lịch hẹn';

  @override
  String get personalHealthLogTitle => 'Nhật ký sức khỏe';

  @override
  String get personalHealthLogSubtitle => 'Xem chi tiết';

  @override
  String get personalSubscriptionTitle => 'Gói AiSee';

  @override
  String get personalSubscriptionSubtitle => 'Quota và quyền đang có';

  @override
  String get personalSponsorsTitle => 'Nhà tài trợ';

  @override
  String get personalSponsorsSubtitle => 'Các đơn vị đang đồng hành cùng dự án';

  @override
  String get personalSignOutLabel => 'Đăng xuất khỏi AiSee';

  @override
  String get personalSignOutAction => 'Đăng xuất';

  @override
  String get loginTagline => 'Không chỉ nhìn thay bạn — hành động cùng bạn';

  @override
  String get loginIntro =>
      'AiSee là trợ lý AI cho người suy giảm thị lực tại Việt Nam. Bạn chỉ cần nói — AiSee nghe, hiểu và thực hiện. Thiết kế ưu tiên giọng nói, hỗ trợ tiếng Việt.';

  @override
  String get loginGoogleButton => 'Đăng nhập bằng Google';

  @override
  String get loginGoogleHelp =>
      'Đăng nhập bằng Google để vào ứng dụng. Chúng tôi dùng tài khoản Google để xác thực an toàn và đồng bộ hồ sơ của bạn.';

  @override
  String get loginLegalNotice =>
      'Bằng việc đăng nhập, bạn đồng ý với điều khoản dịch vụ của Google và AiSee.';

  @override
  String get roleAppBarExit => 'Thoát';

  @override
  String get roleSelectionTitle => 'Chọn cách bạn dùng AiSee';

  @override
  String get roleSelectionHelp =>
      'Dùng hai chấm bên dưới để đổi trang, hoặc vuốt ngang khi không cuộn dọc.';

  @override
  String get rolePagerUserPage => 'Trang 1 / 2 — Người dùng';

  @override
  String get rolePagerFamilyPage => 'Trang 2 / 2 — Người thân / hỗ trợ';

  @override
  String get roleUserBadge => 'Miễn phí hoàn toàn';

  @override
  String get roleUserTitle => 'Người dùng';

  @override
  String get roleUserSubtitle =>
      'Dành cho bạn trực tiếp dùng AiSee bằng giọng nói.';

  @override
  String get roleUserBullet1 =>
      'Giao diện ưu tiên giọng nói và thao tác ít nhìn màn hình, phù hợp người suy giảm thị lực.';

  @override
  String get roleUserBullet2 =>
      'Gói người dùng: không phí đăng ký, không hiển thị quảng cáo — trải nghiệm miễn phí cho người dùng chính.';

  @override
  String get roleUserBullet3 =>
      'Dữ liệu bạn cung cấp chỉ phục vụ điều khiển ứng dụng và cải thiện trợ lý theo chính sách quyền riêng tư.';

  @override
  String get roleUserCta => 'Tiếp tục với tư cách người dùng';

  @override
  String get roleFamilyBadge => 'Có thể có quảng cáo';

  @override
  String get roleFamilyTitle => 'Người thân / hỗ trợ';

  @override
  String get roleFamilySubtitle =>
      'Dành cho người nhà, tình nguyện viên hoặc người đồng hành chăm sóc.';

  @override
  String get roleFamilyBullet1 =>
      'Bảng điều khiển: theo dõi trạng thái, nhắc lịch, hỗ trợ thiết lập và điều phối từ xa an toàn hơn.';

  @override
  String get roleFamilyBullet2 =>
      'Gói này có thể hiển thị quảng cáo để góp phần duy trì máy chủ và phát triển tính năng — bạn xác nhận điều này khi chọn vai trò này.';

  @override
  String get roleFamilyBullet3 =>
      'AiSee hỗ trợ sinh hoạt hằng ngày, không thay cho tư vấn y tế; trường hợp khẩn cấp hãy liên hệ cơ sở y tế.';

  @override
  String get roleFamilyAccentNote =>
      'Quảng cáo (nếu có) sẽ được đặt sao cho ít ảnh hưởng luồng chăm sóc; bạn vẫn có thể hỗ trợ dự án bằng cách xem quảng cáo có chủ đích.';

  @override
  String get roleFamilyCta => 'Tiếp tục với tư cách người thân / hỗ trợ';

  @override
  String get ttsLanguageTag => 'vi-VN';

  @override
  String announcerMedication(String title, String time) {
    return 'Đến giờ uống thuốc. $title. Lúc $time.';
  }

  @override
  String announcerAppointment(String title) {
    return 'Bạn có lịch hẹn $title sau khoảng 30 phút.';
  }

  @override
  String get homeMicReadyAnnouncement =>
      'Trợ lý đang lắng nghe. Bạn có thể nói.';

  @override
  String get homeCameraBlockedNsfw =>
      'Camera tạm tắt vì phát hiện nội dung không phù hợp';

  @override
  String get homeNoSession => 'Chưa có phiên đăng nhập';

  @override
  String get homeAssistantConnectFail => 'Không kết nối được trợ lý giọng nói.';

  @override
  String get homeTabContacts => 'Liên lạc';

  @override
  String get homeTabPersonal => 'Cá nhân';

  @override
  String homeGreeting(String name) {
    return 'Xin chào, $name';
  }

  @override
  String get assistantTabRetry => 'Thử lại';

  @override
  String get assistantTabSemanticsLoading =>
      'Trang Trợ lý AiSee. Đang tải hồ sơ.';

  @override
  String get assistantTabSemanticsError => 'Trang Trợ lý AiSee. Có lỗi hồ sơ.';

  @override
  String get assistantTabSemanticsConnecting =>
      'Trang Trợ lý AiSee. Đang kết nối trợ lý.';

  @override
  String get assistantTabSemanticsConnectError =>
      'Trang Trợ lý AiSee. Lỗi kết nối. Chạm Thử lại để thử lại.';

  @override
  String get assistantTabSemanticsConnected =>
      'Trang Trợ lý AiSee. Đã kết nối trợ lý giọng nói.';

  @override
  String get assistantTabSemanticsDefault => 'Trang Trợ lý AiSee.';

  @override
  String get assistantTabCameraPreviewLabel =>
      'Xem trước camera của bạn, toàn màn hình';

  @override
  String get assistantTabConnected => 'Đã kết nối trợ lý giọng nói.';

  @override
  String get assistantTabConnecting => 'Đang chờ kết nối…';

  @override
  String get assistantTabWakeHintTitle => 'Gọi “aisee ơi” để đánh thức trợ lý';

  @override
  String get assistantTabWakeHintBody =>
      'Khi AiSee đang nghỉ, chỉ cần nói “aisee ơi” để bắt đầu lại.';

  @override
  String get assistantTabWakeTimedOutTitle => 'AiSee đã nghỉ vì im lặng';

  @override
  String get assistantTabWakeTimedOutBody =>
      'Muốn nói tiếp, hãy gọi lại “aisee ơi”.';

  @override
  String assistantTabNowPlaying(String title) {
    return 'Đang phát: $title';
  }

  @override
  String get homeWakeReminderAnnouncement =>
      'AiSee đã nghỉ. Muốn nói tiếp, hãy gọi lại aisee ơi.';

  @override
  String get authSessionExpired => 'Phiên hết hạn, vui lòng đăng nhập lại';

  @override
  String get authSignInSuccess => 'Đăng nhập thành công';

  @override
  String get authSignedOut => 'Đã đăng xuất';

  @override
  String get authNoIdToken => 'Không lấy được mã xác thực từ Google.';

  @override
  String authBootstrapFailed(String detail) {
    return 'Không khởi tạo được Google Sign-In:\n$detail';
  }

  @override
  String get authBootstrapTitle => 'Đang đăng nhập AiSee…';

  @override
  String get authBootstrapDetail => 'Đang xác thực với máy chủ';

  @override
  String get authGoogleCanceled => 'Đã hủy đăng nhập';

  @override
  String authGoogleError(String detail) {
    return 'Lỗi Google: $detail';
  }

  @override
  String get onboardingSkip => 'Bỏ qua';

  @override
  String get onboardingNext => 'Tiếp tục';

  @override
  String get onboardingFinish => 'Tiếp tục đến đăng nhập';

  @override
  String get onboardingChooseRoleHint => 'Chọn vai trò để tiếp tục đăng nhập.';

  @override
  String get onboardingWelcomeTitle => 'Chào mừng đến với AiSee';

  @override
  String get onboardingWelcomeDesc =>
      'AiSee hỗ trợ người suy giảm thị lực bằng giọng nói, nhắc việc và kết nối nhanh với người thân.';

  @override
  String get onboardingWelcomeBullet1 =>
      'Nói chuyện với trợ lý bằng tiếng Việt';

  @override
  String get onboardingWelcomeBullet2 => 'Thiết kế chữ rõ, thao tác đơn giản';

  @override
  String get onboardingWelcomeBullet3 =>
      'Có thể nhờ người thân đồng hành từ xa';

  @override
  String get onboardingPermsTitle => 'AiSee cần một số quyền cơ bản';

  @override
  String get onboardingPermsDesc =>
      'Mic, camera, thông báo và vị trí sẽ chỉ được dùng để hỗ trợ bạn tốt hơn khi cần.';

  @override
  String get onboardingPermsBullet1 => 'Microphone: nghe câu lệnh của bạn';

  @override
  String get onboardingPermsBullet2 => 'Camera: hỗ trợ nhận biết xung quanh';

  @override
  String get onboardingPermsBullet3 =>
      'Thông báo và vị trí: nhắc việc và điều phối hỗ trợ';

  @override
  String get onboardingFamilyTitle => 'Luôn có người thân bên cạnh';

  @override
  String get onboardingFamilyDesc =>
      'Bạn có thể mời người thân vào ứng dụng để nhắn tin, gọi điện và cùng theo dõi những việc quan trọng.';

  @override
  String get onboardingFamilyBullet1 => 'Mời người thân bằng mã đơn giản';

  @override
  String get onboardingFamilyBullet2 => 'Nhắn tin và gọi ngay trong app';

  @override
  String get onboardingFamilyBullet3 => 'Phối hợp nhanh khi cần trợ giúp';

  @override
  String get onboardingBatteryTitle => 'Để cuộc gọi không bị bỏ lỡ';

  @override
  String get onboardingBatteryDesc =>
      'Một số máy Android tự tắt app trong nền để tiết kiệm pin, dẫn đến không nhận được cuộc gọi. Hãy cho phép AiSee chạy nền liên tục.';

  @override
  String get onboardingBatteryBullet1 =>
      'Cuộc gọi đến hiện ngay cả khi tắt màn hình';

  @override
  String get onboardingBatteryBullet2 =>
      'Nhắc thuốc và nhắc việc luôn đúng giờ';

  @override
  String get onboardingBatteryBullet3 =>
      'AiSee chỉ chạy nhẹ ở nền, không hao pin';

  @override
  String get onboardingRemindersTitle => 'AiSee sẽ nhắc những việc quan trọng';

  @override
  String get onboardingRemindersDesc =>
      'Nhắc thuốc, lịch hẹn và các thông báo cần chú ý để bạn an tâm hơn mỗi ngày.';

  @override
  String get onboardingRemindersBullet1 => 'Nhắc uống thuốc đúng giờ';

  @override
  String get onboardingRemindersBullet2 => 'Nhắc lịch hẹn và việc cần nhớ';

  @override
  String get onboardingRemindersBullet3 => 'Thông báo rõ ràng, ít gây rối';

  @override
  String get onboardingRoleUserTitle => 'Tôi là người dùng khiếm thị';

  @override
  String get onboardingRoleUserSubtitle =>
      'Dùng AiSee trực tiếp bằng giọng nói mỗi ngày.';

  @override
  String get onboardingRoleFamilyTitle => 'Tôi là người thân / hỗ trợ';

  @override
  String get onboardingRoleFamilySubtitle =>
      'Đồng hành, nhắc việc và hỗ trợ người dùng từ xa.';

  @override
  String get onboardingBatteryChecking => 'Đang kiểm tra…';

  @override
  String get onboardingBatteryGranted => 'Đã cho phép chạy nền';

  @override
  String get onboardingBatteryNotGranted => 'Chưa cho phép chạy nền';

  @override
  String get onboardingBatteryButton => 'Tắt tối ưu pin cho AiSee';

  @override
  String get onboardingBatteryOpenSettings => 'Mở cài đặt ứng dụng';

  @override
  String get onboardingBatteryDoneNote =>
      'AiSee có thể nhận cuộc gọi ngay cả khi điện thoại đang ngủ. Bạn có thể đổi lại trong Cài đặt > Pin bất cứ lúc nào.';

  @override
  String get onboardingStatusOn => 'Đã bật';

  @override
  String get onboardingStatusOff => 'Cần bật';

  @override
  String get familyTabFamily => 'Gia đình';

  @override
  String get familyTabMessages => 'Tin nhắn';

  @override
  String get familyTabPersonal => 'Cá nhân';

  @override
  String get familyHomeProfileFailed => 'Không tải được thông tin';

  @override
  String get familyPersonalIntro =>
      'Thông tin tài khoản và đăng ký hỗ trợ của bạn.';

  @override
  String get familyPersonalSemanticsLabel =>
      'Cá nhân. Thông tin tài khoản và tình nguyện viên.';

  @override
  String get familyPersonalCardInfoTitle => 'Thông tin cá nhân';

  @override
  String get familyPersonalCardInfoSubtitle =>
      'Email, vai trò và ngày tham gia';

  @override
  String get familyPersonalCardUsageTitle => 'Giá trị đã dùng';

  @override
  String get familyPersonalCardUsageSubtitle =>
      'Giải thích quota và tính năng theo gói';

  @override
  String get familyPersonalCardSubscriptionTitle => 'Gói AiSee';

  @override
  String get familyPersonalCardSubscriptionSubtitle =>
      'Quản lý gói, quota và quyền chăm sóc';

  @override
  String get familyPersonalCardSponsorsTitle => 'Nhà tài trợ';

  @override
  String get familyPersonalCardSponsorsSubtitle =>
      'Đơn vị đồng hành cùng dự án AiSee';

  @override
  String get familyPersonalSignOutLabel => 'Đăng xuất khỏi AiSee';

  @override
  String get familyPersonalSignOutAction => 'Đăng xuất';

  @override
  String get familyPersonalRoleSupporter => 'Người hỗ trợ';

  @override
  String get familyPersonalSheetClose => 'Đóng';

  @override
  String get familyPersonalSheetTitle => 'Thông tin cá nhân';

  @override
  String get familyPersonalSheetRole => 'Vai trò';

  @override
  String get familyPersonalSheetJoinDate => 'Ngày tham gia';

  @override
  String get familyPersonalCareNeeded =>
      'Hãy mở hồ sơ một người được chăm sóc trước khi xem quota theo nhóm.';

  @override
  String get familyPersonalSubscriptionNeeded =>
      'Hãy mở hồ sơ một người được chăm sóc trước khi quản lý gói.';

  @override
  String get familyPersonalSessionExpired =>
      'Phiên đăng nhập hết hạn. Hãy đăng xuất và đăng nhập lại.';

  @override
  String get familyPersonalRegisterSuccess => 'Đã đăng ký tình nguyện viên';

  @override
  String familyPersonalCardActionHint(String title, String subtitle) {
    return '$title. $subtitle. Chạm để mở.';
  }

  @override
  String get familyVolunteerTitle => 'Tình nguyện viên';

  @override
  String get familyVolunteerSubtitle =>
      'Hỗ trợ người khiếm thị khi người thân không thể trả lời';

  @override
  String get familyVolunteerRegisterAction => 'Đăng ký tình nguyện viên';

  @override
  String get familyVolunteerReadyTitle => 'Sẵn sàng hỗ trợ';

  @override
  String get familyVolunteerReadyOn => 'Bạn sẽ nhận cuộc gọi hỗ trợ';

  @override
  String get familyVolunteerReadyOff => 'Tạm nghỉ, không nhận cuộc gọi';

  @override
  String get careDailySummaryFallback => 'Tóm tắt ngày';

  @override
  String get careDailySummaryError => 'Lỗi không xác định';

  @override
  String get careAlertAcknowledged => 'Đã xác nhận cảnh báo';

  @override
  String get careAlertClosed => 'Đã đóng cảnh báo';

  @override
  String get careAlertSkipped => 'Đã bỏ qua';

  @override
  String get careTaskCreatedToast => 'Đã tạo việc cần làm';

  @override
  String get careTaskCompletedToast => 'Đã hoàn thành';

  @override
  String get careTaskDialogTitle => 'Việc cần làm';

  @override
  String get careTaskDialogContentLabel => 'Nội dung';

  @override
  String get careTaskDialogCreate => 'Tạo';

  @override
  String get careTabIntroTitle => 'Chăm sóc hằng ngày';

  @override
  String get careTabIntroSubtitle =>
      'Tóm tắt ngày, cảnh báo rule-based và việc cần làm cho người thân.';

  @override
  String get careOpenFullSummary => 'Mở đầy đủ tóm tắt ngày';

  @override
  String get careAlertsHeading => 'Cảnh báo';

  @override
  String get careRefreshAction => 'Làm mới';

  @override
  String get careNoAlerts => 'Không có cảnh báo.';

  @override
  String get careTasksHeading => 'Việc cần làm';

  @override
  String get careTasksAdd => 'Thêm';

  @override
  String get careNoTasks => 'Chưa có việc.';

  @override
  String get careSummaryLoadFail => 'Không tải được tóm tắt';

  @override
  String get careRetryAction => 'Thử lại';

  @override
  String get careOpenPlanQuota => 'Xem gói / quota';

  @override
  String get contactsNotLoggedIn => 'Chưa đăng nhập. Vui lòng đăng nhập lại.';

  @override
  String get contactsLoadFailed => 'Không tải được danh sách liên lạc.';

  @override
  String get contactsCallCreateFailed => 'Không tạo được cuộc gọi';

  @override
  String get contactsSessionExpired =>
      'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.';

  @override
  String get contactsLeftGroup => 'Đã rời nhóm chăm sóc';

  @override
  String get contactsLeaveGroupFailed => 'Không rời được nhóm chăm sóc.';

  @override
  String get contactsLeaveGroupTitle => 'Rời nhóm chăm sóc';

  @override
  String get contactsLeaveGroupBody =>
      'Bạn phải rời nhóm hiện tại trước khi tham gia nhóm mới bằng mã mời khác.';

  @override
  String get contactsCancel => 'Huỷ';

  @override
  String get contactsLeaveGroupAction => 'Rời nhóm';

  @override
  String get contactsJoinGroupTitle => 'Tham gia nhóm chăm sóc';

  @override
  String get contactsJoinGroupHint =>
      'Nhập mã mời 6 số từ người nhà để tham gia nhóm';

  @override
  String get contactsJoinAction => 'Tham gia';

  @override
  String get contactsPleaseEnterCode => 'Vui lòng nhập mã mời';

  @override
  String get contactsJoinedGroup => 'Đã tham gia nhóm chăm sóc';

  @override
  String get contactsJoinFailed => 'Không tham gia được nhóm chăm sóc.';

  @override
  String get contactsTabSemantics =>
      'Liên lạc. Nhắn tin và gọi điện người thân.';

  @override
  String get contactsTabIntro => 'Nhắn tin và gọi điện người thân.';

  @override
  String get contactsRetryLabel => 'Thử lại tải danh sách liên lạc';

  @override
  String get contactsRetry => 'Thử lại';

  @override
  String get contactsEmpty =>
      'Chưa tham gia nhóm chăm sóc nào.\nDùng mã mời 6 số từ người nhà để kết nối.';

  @override
  String get contactsWantSwitchGroup => 'Muốn vào nhóm khác?';

  @override
  String get contactsSwitchGroupHint =>
      'Rời nhóm hiện tại trước, rồi quay lại tab này để nhập mã mời 6 số của nhóm mới.';

  @override
  String get contactsLeaveCurrentGroup => 'Rời nhóm hiện tại';

  @override
  String get contactsEnterCodeButton => 'Nhập mã mời 6 số';

  @override
  String get contactsTapToChat => 'Chạm để nhắn tin';

  @override
  String contactsVoiceCallLabel(Object label) {
    return 'Gọi thoại $label';
  }

  @override
  String get contactsVoiceCallTooltip => 'Gọi thoại';

  @override
  String contactsVideoCallLabel(Object label) {
    return 'Gọi video $label';
  }

  @override
  String get contactsVideoCallTooltip => 'Gọi video';

  @override
  String get chatLoadFailed => 'Không tải được tin nhắn.';

  @override
  String get chatSendFailed => 'Không gửi được tin nhắn.';

  @override
  String get chatTakePhoto => 'Chụp ảnh';

  @override
  String get chatTakePhotoLabel => 'Chụp ảnh bằng camera';

  @override
  String get chatPickFromGallery => 'Chọn từ thư viện';

  @override
  String get chatPickFromGalleryLabel => 'Chọn ảnh từ thư viện';

  @override
  String get chatCameraPermission => 'Cần quyền camera để chụp ảnh.';

  @override
  String get chatUploadFailed => 'Gửi không thành công.';

  @override
  String get chatMicPermission => 'Cần quyền microphone để ghi âm.';

  @override
  String get chatRecordFailed => 'Không thể ghi âm.';

  @override
  String get chatVoiceCallTooltip => 'Gọi thoại';

  @override
  String get chatVideoCallTooltip => 'Gọi video';

  @override
  String get chatEmpty => 'Chưa có tin nhắn.\nHãy gửi lời chào!';

  @override
  String get chatImageLoadFailed => 'Không tải được ảnh';

  @override
  String get chatAttachImage => 'Đính kèm ảnh';

  @override
  String get chatInputHint => 'Nhắn tin...';

  @override
  String get chatSend => 'Gửi tin nhắn';

  @override
  String get chatHoldToRecord => 'Giữ để ghi âm';

  @override
  String get chatStopRecordLabel => 'Dừng ghi âm và gửi. Giữ để huỷ.';

  @override
  String get chatSending => 'Đang gửi...';

  @override
  String get usageValueTitle => 'Giá trị đã dùng';

  @override
  String usageValuePlan(Object planName) {
    return 'Gói $planName';
  }

  @override
  String usageValuePeriod(Object end, Object start) {
    return 'Kỳ: $start — $end';
  }

  @override
  String get usageValueChartTitle => 'Biểu đồ đã dùng (kỳ hiện tại)';

  @override
  String get usageValueWhatUsed => 'Bạn đã dùng gì trong kỳ này';

  @override
  String get usageValueUnlimited => 'Không giới hạn';

  @override
  String usageValueUsedLine(
    Object limit,
    Object remaining,
    Object unit,
    Object used,
  ) {
    return 'Đã dùng $used / $limit $unit (còn $remaining)';
  }

  @override
  String get usageValueUpgradeHint =>
      'Gói cao hơn có thể phù hợp nếu bạn cần thêm hạn mức.';

  @override
  String get usageValueEntitlementsTitle => 'Tính năng chăm sóc theo gói';

  @override
  String get usageValueEntitlementCol => 'Quyền / tính năng';

  @override
  String get usageValueDescCol => 'Mô tả';

  @override
  String get usageValueStatusCol => 'Trạng thái';

  @override
  String get usageValueOn => 'Bật';

  @override
  String get usageValueOff => 'Khóa';

  @override
  String get usageValueViewPlan => 'Xem gói và nâng cấp';

  @override
  String get usageValueChartLabel => 'Đã dùng trong kỳ';

  @override
  String get usageValueSessionExpired => 'Phiên đăng nhập hết hạn';

  @override
  String get usageStoryAiMinutes =>
      'Phút trò chuyện với trợ lý — thể hiện mức độ đồng hành hằng ngày.';

  @override
  String get usageStoryPdfExports =>
      'Lượt xuất báo cáo chăm sóc — giúp lưu lại tóm tắt cho bác sĩ hoặc gia đình.';

  @override
  String get usageStoryCameraActivations =>
      'Lần bật camera trong phiên — hỗ trợ xem và hướng dẫn từ xa.';

  @override
  String get usageStoryDefault =>
      'Hoạt động được tính vào gói hiện tại của bạn.';

  @override
  String get entitlementStoryDailyBrief =>
      'Tóm tắt sức khỏe mỗi ngày cho người thân.';

  @override
  String get entitlementStoryWeeklyReport =>
      'Báo cáo tuần — xu hướng chăm sóc dài hơn.';

  @override
  String get entitlementStoryCareTimeline =>
      'Số ngày xem lại timeline chăm sóc.';

  @override
  String get entitlementStoryIncidentReport =>
      'Báo cáo sự cố / leo thang sau SOS.';

  @override
  String get entitlementStoryDefault => 'Quyền theo gói AiSee.';

  @override
  String get navAssistant => 'Trợ lý';

  @override
  String get navAssistantLabel =>
      'Mục 1 trên 3: Trợ lý. Trang chủ. Trợ lý AiSee đang sẵn sàng nghe.';

  @override
  String get navContacts => 'Liên lạc';

  @override
  String get navContactsLabel =>
      'Mục 2 trên 3: Liên lạc. Nhắn tin và gọi điện người thân.';

  @override
  String get navPersonal => 'Cá nhân';

  @override
  String get navPersonalLabel =>
      'Mục 3 trên 3: Cá nhân. Cá nhân. Lịch uống thuốc và tin nhắn của bạn.';

  @override
  String get navFamily => 'Gia đình';

  @override
  String get navFamilyLabel =>
      'Mục 1 trên 3: Gia đình. Danh sách liên lạc gia đình.';

  @override
  String get navMessages => 'Tin nhắn';

  @override
  String get navMessagesLabel => 'Mục 2 trên 3: Tin nhắn. Hộp thư đến.';

  @override
  String get navPersonalFamilyLabel =>
      'Mục 3 trên 3: Cá nhân. Hồ sơ và cài đặt.';

  @override
  String get navDoubleTapHint => 'Chạm hai lần để chọn';

  @override
  String get closeAction => 'Đóng';

  @override
  String get incomingVoiceCall => 'Cuộc gọi thoại đến';

  @override
  String get incomingVideoCall => 'Cuộc gọi video đến';

  @override
  String get declineCall => 'Từ chối';

  @override
  String get ringing => 'Đang đổ chuông';

  @override
  String get agentConnecting => 'Đang kết nối...';

  @override
  String get agentReady => 'Sẵn sàng';

  @override
  String get agentListening => 'Đang nghe...';

  @override
  String get agentThinking => 'Đang xử lý...';

  @override
  String get agentSpeaking => 'Đang trả lời...';

  @override
  String get agentDisconnected => 'Đã ngắt kết nối';

  @override
  String get agentConnectionError => 'Lỗi kết nối';

  @override
  String get callTokenExpired => 'Token cuộc gọi đã hết hạn';

  @override
  String get callJoinFailed => 'Không vào được cuộc gọi. Vui lòng thử lại.';

  @override
  String get livekitNotReady => 'LiveKit chưa sẵn sàng để bật micro.';

  @override
  String livekitBadJson(Object code) {
    return 'Máy chủ trả không phải JSON hợp lệ (HTTP $code). Kiểm tra cấu hình ứng dụng và route POST /api/v1/calls/token.';
  }

  @override
  String livekitTokenError(Object code) {
    return 'Không lấy được token phòng (HTTP $code)';
  }

  @override
  String get livekitTokenEmpty =>
      'API /api/v1/calls/token trả 200 nhưng thân phản hồi trống hoặc không phải JSON object. Kiểm tra phần xử lý của ứng dụng xem có gửi JSON chứa token không.';

  @override
  String get livekitMissingToken => 'Phản hồi token LiveKit thiếu token';

  @override
  String get livekitMissingUrl =>
      'Thiếu URL LiveKit: điền LIVEKIT_URL trong assets/app_config.env';

  @override
  String livekitPermissionDenied(Object permission) {
    return 'Quyền $permission đã bị từ chối. Hãy bật trong Cài đặt cho AiSee.';
  }

  @override
  String livekitPermissionRequired(Object permission) {
    return 'Cần quyền $permission để dùng trợ lý.';
  }

  @override
  String get livekitNoSession => 'Chưa có phiên đăng nhập';

  @override
  String get livekitConnecting => 'Đang kết nối room...';

  @override
  String get livekitDisconnecting => 'Đang ngắt kết nối...';

  @override
  String get livekitNoRoomDisconnect => 'Không có room đang kết nối';

  @override
  String get livekitDisconnected => 'Đã ngắt xong.';

  @override
  String get serviceHealthRecordFail => 'Không ghi nhận uống thuốc được';

  @override
  String get serviceHealthSkipFail => 'Không ghi nhận bỏ thuốc được';

  @override
  String get serviceHealthSymptomFail => 'Không ghi triệu chứng được';

  @override
  String get serviceHealthMetricFail => 'Không ghi chỉ số sức khoẻ được';

  @override
  String get serviceHealthEmergencyFail => 'Không gửi được cảnh báo khẩn cấp';

  @override
  String get serviceHealthRatingFail => 'Không đánh giá được tình nguyện viên';

  @override
  String get serviceHealthLoadMedFail => 'Không tải được lịch thuốc';

  @override
  String get serviceHealthLoadApptFail => 'Không tải được lịch hẹn';

  @override
  String get serviceHealthLoadLogFail => 'Không tải được nhật ký sức khỏe';

  @override
  String get serviceLocationGpsOff => 'GPS đang tắt. Hãy bật định vị.';

  @override
  String get serviceLocationDenied =>
      'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy bật trong Cài đặt.';

  @override
  String get serviceUploadTooBig => 'File quá lớn, tối đa 10MB';

  @override
  String serviceUploadBadFormat(Object mime) {
    return 'Định dạng không được hỗ trợ: $mime';
  }

  @override
  String get serviceUploadNoUrl => 'Upload thành công nhưng không có URL';

  @override
  String get serviceUploadFailed => 'Upload thất bại';

  @override
  String serviceUploadHttpFail(Object code) {
    return 'Upload thất bại (HTTP $code)';
  }

  @override
  String get serviceAuthBadResponse =>
      'Phản hồi máy chủ không hợp lệ (thiếu token)';

  @override
  String get serviceAuthLoginFail => 'Đăng nhập máy chủ thất bại';

  @override
  String get serviceAuthProfileFail => 'Không tải được hồ sơ';

  @override
  String get serviceAuthSessionExpired =>
      'Phiên hết hạn, vui lòng đăng nhập lại';

  @override
  String get serviceCallCreateFail => 'Không tạo được cuộc gọi';

  @override
  String get serviceCallEndFail => 'Không kết thúc được cuộc gọi';

  @override
  String get serviceCallInvalidResponse => 'Phản hồi không hợp lệ';

  @override
  String get serviceCameraNoPermission =>
      'Cần quyền camera để trợ lý nhìn được.';

  @override
  String get serviceCameraUnavailable => 'Thiết bị không có camera khả dụng.';

  @override
  String get dashboardVoiceCall => 'Gọi điện thoại';

  @override
  String get dashboardVideoCall => 'Gọi video';

  @override
  String get dashboardSendChat => 'Gửi tin nhắn';

  @override
  String get dashboardEmergencySOS => 'SOS khẩn cấp';

  @override
  String get dashboardEscalateFamily => 'Gọi người thân';

  @override
  String get dashboardEscalateVolunteer => 'Gọi tình nguyện viên';

  @override
  String get dashboardSetMedication => 'Đặt nhắc thuốc';

  @override
  String get dashboardMarkMedicationTaken => 'Đã uống thuốc';

  @override
  String get dashboardMarkMedicationSkipped => 'Bỏ qua thuốc';

  @override
  String get dashboardLogSymptom => 'Ghi triệu chứng';

  @override
  String get dashboardLogMetric => 'Ghi chỉ số';

  @override
  String get dashboardSetAppointment => 'Đặt lịch hẹn';

  @override
  String get dashboardPlayMusic => 'Phát nhạc';

  @override
  String get dashboardNavigate => 'Chỉ đường';

  @override
  String get dashboardFamilyCreateMed => 'Người thân thêm thuốc';

  @override
  String get dashboardFamilyUpdateMed => 'Người thân sửa thuốc';

  @override
  String get dashboardFamilyDeleteMed => 'Người thân xóa thuốc';

  @override
  String get dashboardCareExportPdf => 'Xuất báo cáo chăm sóc';

  @override
  String get dashboardNoDetail => 'Không có thêm chi tiết trong nhật ký.';

  @override
  String get billingPlanStoreManaged =>
      'Gói được quản lý theo cửa hàng ứng dụng.';

  @override
  String get callerUnknown => 'Người gọi';

  @override
  String get reminderTestTitle => 'Test nhắc nhở';

  @override
  String get reminderTestBody =>
      'Nếu bạn thấy thông báo này, notification hoạt động!';

  @override
  String get reminderMedicationTitle => 'Nhắc uống thuốc';

  @override
  String get reminderAppointmentTitle => 'Lịch hẹn sắp tới';

  @override
  String get reminderChannelName => 'Nhắc nhở AiSee';

  @override
  String get reminderChannelDesc => 'Nhắc nhở uống thuốc và lịch hẹn';

  @override
  String get foregroundChannelName => 'Trợ lý AiSee';

  @override
  String get foregroundChannelDesc => 'Giữ kết nối khi màn hình tắt.';

  @override
  String get foregroundNotificationTitle => 'AiSee đang hoạt động';

  @override
  String get foregroundNotificationText =>
      'Trợ lý giọng nói đang bật — chạm để mở app';

  @override
  String get messageSenderFamily => 'Người thân';

  @override
  String get messageSentImage => 'Đã gửi một hình ảnh';

  @override
  String get messageSentVoice => 'Đã gửi tin nhắn thoại';

  @override
  String get messageNew => 'Tin nhắn mới';

  @override
  String get bootstrapLoadingApp => 'Đang tải ứng dụng…';

  @override
  String get bootstrapCheckingSession => 'Đang kiểm tra phiên đăng nhập…';

  @override
  String get permissionBootstrapTitle => 'Đang chuẩn bị quyền truy cập…';

  @override
  String get familyMedicationEmpty => 'Chưa có lịch';

  @override
  String get healthOverviewTitle => 'Tổng quan';

  @override
  String get healthTakenToday => 'Đã uống hôm nay';

  @override
  String get healthSymptoms => 'Triệu chứng';

  @override
  String get healthMetrics => 'Chỉ số';

  @override
  String get healthTaken => 'Đã uống';

  @override
  String get supporterLabel => 'Người hỗ trợ';

  @override
  String get appBillingFreePlan => 'Miễn phí';

  @override
  String get familyCareApiError => 'Đã xảy ra lỗi';

  @override
  String get familyDashboardHealthTabLabel => 'Sức khỏe';

  @override
  String get familyDashboardContactTabLabel => 'Liên lạc';

  @override
  String get familyDashboardCareTabLabel => 'Chăm sóc';

  @override
  String get careTimelineTitle => 'Timeline chăm sóc';

  @override
  String get careTimelineFallback => 'Timeline';

  @override
  String careTimelinePlanHint(Object effectiveDays, Object requestedDays) {
    return 'Theo gói hiện tại, bạn đang xem $effectiveDays ngày gần nhất (yêu cầu $requestedDays ngày).';
  }

  @override
  String get careTimelineEmpty => 'Chưa có sự kiện trong cửa sổ này.';

  @override
  String get careDailyBriefTitle => 'Tóm tắt ngày';

  @override
  String careDailyBriefDate(Object date) {
    return 'Ngày $date';
  }

  @override
  String get careWeeklyReportTitle => 'Báo cáo tuần';

  @override
  String get careWeeklyReportPickEnd => 'Cuối tuần';

  @override
  String get careIncidentTitle => 'Sự cố / SOS';

  @override
  String careIncidentAlertTime(Object time) {
    return 'Cảnh báo: $time';
  }

  @override
  String careIncidentLocation(Object lat, Object lng) {
    return 'Vị trí: $lat, $lng';
  }

  @override
  String careIncidentTime(Object time) {
    return 'Thời điểm: $time';
  }

  @override
  String careIncidentFamilyNotified(Object notified) {
    return 'Đã báo người thân: $notified';
  }

  @override
  String get careExportCopied => 'Đã sao chép';

  @override
  String get careExportCopyAction => 'Sao chép';

  @override
  String get careExportClose => 'Đóng';

  @override
  String get careExportTitle => 'Xuất báo cáo (định dạng tạm)';

  @override
  String careExportFormat(Object format, Object id) {
    return 'Định dạng: $format\nMã xuất: $id\n\n';
  }

  @override
  String get careExportNoData => '(Không có dữ liệu kèm)';

  @override
  String get careExportFallback => 'Xuất báo cáo';

  @override
  String get careTotalsOverview => 'Tổng quan';

  @override
  String careTotalsActiveMeds(Object count) {
    return 'Thuốc đang dùng: $count';
  }

  @override
  String careTotalsTakenSkipped(Object skipped, Object taken) {
    return 'Đã uống: $taken, bỏ qua: $skipped';
  }

  @override
  String careTotalsSymptoms(Object metrics, Object symptoms) {
    return 'Triệu chứng: $symptoms, chỉ số: $metrics';
  }

  @override
  String careTotalsSOS(Object escalations, Object sos) {
    return 'SOS: $sos, leo thang: $escalations';
  }

  @override
  String careTotalsCalls(Object videoCount, Object videoMin, Object voiceMin) {
    return 'Gọi video: $videoCount ($videoMin phút), thoại: $voiceMin phút';
  }

  @override
  String get careBillingSheetViewPlan => 'Xem gói và nâng cấp';

  @override
  String careBillingQuotaRemaining(Object remaining) {
    return 'Còn lại: $remaining';
  }

  @override
  String get careBillingQuotaExhausted => 'Đã hết quota';

  @override
  String get careBillingFallbackTitle => 'Không thực hiện được';

  @override
  String get careViewPlanAction => 'Xem gói';

  @override
  String get familyMessagesCallFailed => 'Không tạo được cuộc gọi';

  @override
  String get familyMessagesRetry => 'Thử lại';

  @override
  String get familyMessagesEmpty => 'Chưa có người thân để nhắn tin';

  @override
  String get familyMessagesTapToChat => 'Chạm để nhắn tin';

  @override
  String familyMessagesVoiceCall(Object label) {
    return 'Gọi thoại $label';
  }

  @override
  String get familyMessagesVoiceCallTooltip => 'Gọi thoại';

  @override
  String familyMessagesVideoCall(Object label) {
    return 'Gọi video $label';
  }

  @override
  String get familyMessagesVideoCallTooltip => 'Gọi video';

  @override
  String careWidgetOverviewTitle(Object date) {
    return 'Tổng quan ngày $date';
  }

  @override
  String get careWidgetDataTable => 'Bảng số liệu';

  @override
  String get careWidgetCategoryCol => 'Hạng mục';

  @override
  String get careWidgetValueCol => 'Giá trị';

  @override
  String get careWidgetActiveMeds => 'Thuốc đang dùng';

  @override
  String get careWidgetDosesTaken => 'Liều đã uống';

  @override
  String get careWidgetDosesSkipped => 'Liều bỏ qua';

  @override
  String get careWidgetSymptomLogs => 'Ghi nhận triệu chứng';

  @override
  String get careWidgetMetricLogs => 'Ghi nhận chỉ số';

  @override
  String get careWidgetSOSEvents => 'Sự kiện SOS';

  @override
  String get careWidgetEscalations => 'Leo thang / liên hệ';

  @override
  String get careWidgetVideoCalls => 'Cuộc gọi video';

  @override
  String get careWidgetVideoCallMinutes => 'Phút gọi video';

  @override
  String get careWidgetVoiceCallMinutes => 'Phút gọi thoại';

  @override
  String get careWidgetAutoNotes => 'Ghi chú tự động';

  @override
  String get careWidgetWebReportsTitle => 'Báo cáo và dòng thời gian (web)';

  @override
  String get careWidgetWebReportsHint =>
      'Mở trên trình duyệt — cấu hình CARE_WEB_BASE_URL nếu cần.';

  @override
  String get careWidgetBrowserError => 'Không mở được trình duyệt';

  @override
  String get careAlertSeen => 'Đã xem';

  @override
  String get careAlertClose => 'Đóng';

  @override
  String get careAlertSkip => 'Bỏ qua';

  @override
  String get careTaskColumnTask => 'Việc cần làm';

  @override
  String get careTaskColumnDue => 'Hạn';

  @override
  String get careTaskColumnStatus => 'Trạng thái';

  @override
  String get careTaskColumnAction => '';

  @override
  String get careTaskDone => 'Xong';

  @override
  String get careWebTimeline => 'Timeline';

  @override
  String get careWebWeekly => 'Tuần';

  @override
  String get careWebIncident => 'Sự cố';

  @override
  String get careWebExport => 'Xuất dữ liệu';

  @override
  String get dashboardAuditEmpty => 'Chưa có hoạt động nào trong nhật ký.';

  @override
  String dashboardAuditTime(Object time) {
    return 'Thời gian: $time';
  }

  @override
  String dashboardAuditDetails(Object details) {
    return 'Chi tiết: $details';
  }

  @override
  String dashboardAuditResult(Object result) {
    return 'Kết quả: $result';
  }

  @override
  String get dashboardClose => 'Đóng';

  @override
  String get dashboardHealthTitle => 'Theo dõi sức khỏe';

  @override
  String get dashboardHealthSubtitle =>
      'Thuốc trong ngày, triệu chứng và chỉ số gần nhất.';

  @override
  String get dashboardHealthNoData => 'Không có dữ liệu';

  @override
  String get dashboardHealthPullToRefresh => 'Kéo xuống để tải lại.';

  @override
  String get dashboardHealthMedsToday => 'Thuốc hôm nay';

  @override
  String get dashboardHealthNoMeds => 'Chưa có thuốc nào';

  @override
  String get dashboardHealthRecentSymptoms => 'Triệu chứng gần đây';

  @override
  String get dashboardHealthNoSymptoms => 'Không có triệu chứng';

  @override
  String get dashboardHealthMetrics => 'Chỉ số sức khỏe';

  @override
  String get dashboardHealthNoMetrics => 'Không có chỉ số';

  @override
  String get dashboardHealthOverview => 'Tổng quan';

  @override
  String get dashboardHealthTakenToday => 'Đã uống hôm nay';

  @override
  String get dashboardHealthNotTaken => 'Chưa uống';

  @override
  String get dashboardHealthSymptoms => 'Triệu chứng';

  @override
  String get dashboardHealthMetricsPill => 'Chỉ số';

  @override
  String get dashboardHealthTakenStatus => 'Đã uống';

  @override
  String get dashboardHealthNotTakenStatus => 'Chưa uống';

  @override
  String get dashboardHealthOverviewChartLabel => 'Tổng quan sức khỏe';

  @override
  String get dashboardLocationTitle => 'Vị trí người thân';

  @override
  String get dashboardLocationSubtitle =>
      'Xem nhanh trên bản đồ Mapbox (ảnh tĩnh). Chạm nút bên dưới để mở Google Maps.';

  @override
  String get dashboardLocationNoLocation => 'Chưa có vị trí';

  @override
  String get dashboardLocationPullHint => 'Kéo xuống để thử tải lại.';

  @override
  String get dashboardLocationCoordinates => 'Tọa độ';

  @override
  String dashboardLocationUpdated(Object time) {
    return 'Cập nhật: $time';
  }

  @override
  String get dashboardLocationOpenMaps => 'Mở Google Maps';

  @override
  String get dashboardLocationMapSemantics =>
      'Bản đồ Mapbox, ghim tại vị trí người thân';

  @override
  String get dashboardLocationMapboxMissing => 'Chưa cấu hình Mapbox';

  @override
  String get dashboardLocationMapboxHint =>
      'Thêm MAPBOX_ACCESS_TOKEN (pk.*) vào assets/app_config.env hoặc --dart-define=MAPBOX_ACCESS_TOKEN=... rồi chạy lại app.';

  @override
  String get dashboardLocationMapError =>
      'Không tải được bản đồ. Kiểm tra mạng hoặc token Mapbox.';

  @override
  String get dashboardMedsEmpty => 'Chưa có thuốc nào';

  @override
  String get dashboardMedsEdit => 'Sửa';

  @override
  String get dashboardMedsDelete => 'Xóa';

  @override
  String get dashboardMedFormAddTitle => 'Thêm thuốc';

  @override
  String get dashboardMedFormEditTitle => 'Sửa thuốc';

  @override
  String get dashboardMedFormNameLabel => 'Tên thuốc';

  @override
  String get dashboardMedFormNameHint => 'VD: Paracetamol';

  @override
  String get dashboardMedFormDosageLabel => 'Liều lượng';

  @override
  String get dashboardMedFormDosageHint => 'VD: 1 viên';

  @override
  String get dashboardMedFormTimesLabel => 'Giờ uống';

  @override
  String get dashboardMedFormTimesHint => 'VD: 07:00, 21:00';

  @override
  String get dashboardMedFormFreqLabel => 'Tần suất';

  @override
  String get dashboardMedFormFreqHint => 'VD: daily';

  @override
  String get dashboardMedFormCancel => 'Hủy';

  @override
  String get dashboardMedFormSave => 'Lưu';

  @override
  String get careReportBarMedsActive => 'Thuốc BK';

  @override
  String get careReportBarTaken => 'Đã uống';

  @override
  String get careReportBarSkipped => 'Bỏ qua';

  @override
  String get careReportBarSymptoms => 'Triệu chứng';

  @override
  String get careReportBarMetrics => 'Chỉ số';

  @override
  String get careReportBarSOS => 'SOS';

  @override
  String get careReportChartLabel => 'Tóm tắt ngày';

  @override
  String get careAlertPillLevel => 'Mức';

  @override
  String get careAlertPillStatus => 'Trạng thái';

  @override
  String get careAlertPillCode => 'Mã';

  @override
  String get careAlertPillTime => 'Lúc';

  @override
  String get callMicOff => 'Tắt mic';

  @override
  String get callMicOn => 'Bật mic';

  @override
  String get callSpeakerOff => 'Tắt loa';

  @override
  String get callSpeakerOn => 'Bật loa';

  @override
  String get callEnd => 'Kết thúc cuộc gọi';

  @override
  String get callCameraOff => 'Tắt camera';

  @override
  String get callCameraOn => 'Bật camera';

  @override
  String get callDialing => 'Đang gọi…';

  @override
  String get callEnded => 'Đã kết thúc';

  @override
  String get familyContactsCaredUser => 'Người bệnh';

  @override
  String get familyContactsFamilyMember => 'Người nhà';

  @override
  String get familyContactsCreateInviteCode => 'Tạo mã mời 6 số';

  @override
  String get familyContactsTransferOwnership => 'Chuyển quyền';

  @override
  String get familyContactsLeaveGroup => 'Rời nhóm';

  @override
  String get familyContactsGroupOwner => 'Chủ nhóm';

  @override
  String get familyContactsLeftGroup => 'Đã rời nhóm chăm sóc';

  @override
  String familyContactsOwnershipTransferred(String target) {
    return 'Đã chuyển quyền chủ nhóm cho $target';
  }

  @override
  String get familyContactsCreateCareGroup => 'Tạo nhóm chăm sóc';

  @override
  String get familyContactsCreateCodeToInvite =>
      'Tạo mã mời 6 số để mời người bệnh hoặc người nhà vào nhóm của bạn';

  @override
  String get familyContactsCodeCopied => 'Đã sao chép mã mời';

  @override
  String get familyContactsNoOtherMember =>
      'Chưa có người nhà khác trong nhóm để chuyển quyền.';

  @override
  String get familyContactsTransferOwnershipTitle => 'Chuyển quyền chủ nhóm';

  @override
  String get familyContactsSelectNewOwner =>
      'Chọn người nhà sẽ tiếp tục mời thành viên mới và quản lý subscription của nhóm.';

  @override
  String get familyContactsInviteCodeSent => 'Mã mời 6 số';

  @override
  String get familyContactsNoCaredUsers =>
      'Chưa có người bệnh nào trong nhóm. Tạo mã mời để thêm người bệnh hoặc người nhà khác.';

  @override
  String get familyContactsCaredUsersSection => 'Người bệnh trong nhóm';

  @override
  String get familyContactsFamilyMembersSection => 'Người nhà trong nhóm';

  @override
  String get familyContactsYouAreOwner => 'Bạn là chủ nhóm';

  @override
  String get familyContactsOnlyOwnerWarning =>
      'Chỉ chủ nhóm mới được tạo mã mời và quản lý subscription của cả nhóm.';

  @override
  String get familyContactsTapForInfo => 'Chạm để xem thông tin';

  @override
  String get familyContactsSessionExpired =>
      'Phiên đăng nhập hết hạn. Hãy đăng xuất và đăng nhập lại.';

  @override
  String get familyContactsLeaveBeforeTransfer =>
      'Chuyển quyền trước khi rời nhóm';

  @override
  String get familyContactsLeaveGroupTitle => 'Rời nhóm chăm sóc';

  @override
  String get familyContactsLeaveBody =>
      'Bạn đang là chủ nhóm. Hãy chuyển quyền cho một người nhà khác trước, rồi mới rời nhóm.';

  @override
  String get familyContactsLeaveConfirmBody =>
      'Bạn sẽ rời nhóm chăm sóc hiện tại. Muốn vào nhóm khác, bạn sẽ dùng mã mời mới sau khi rời nhóm.';

  @override
  String get familyContactsCannotLeave =>
      'Hãy mời hoặc chờ thêm một người nhà khác trước khi chuyển quyền và rời nhóm.';

  @override
  String get familyContactsCopyCode => 'Sao chép mã';

  @override
  String get familyDashboardMedsTabLabel => 'Thuốc';

  @override
  String get familyDashboardAuditTabLabel => 'Hoạt động';

  @override
  String get familyDashboardLocationTabLabel => 'Vị trí';

  @override
  String get remindersLoadFailed => 'Không tải được dữ liệu.';

  @override
  String get remindersRetry => 'Thử lại';

  @override
  String get remindersMedication => 'Thuốc';

  @override
  String get remindersEmpty =>
      'Chưa có nhắc nhở nào.\nThêm thuốc từ tab Cá nhân.';

  @override
  String get remindersTaken => '✓ Đã uống';

  @override
  String get remindersSkipped => '✗ Bỏ qua';

  @override
  String get remindersTakenStatus => 'Đã uống';

  @override
  String get remindersSkippedStatus => 'Bỏ qua';

  @override
  String get remindersDeletePrompt => 'Xoá nhắc nhở';

  @override
  String remindersDetailSemantics(String title, String subtitle) {
    return '$title. $subtitle. Chạm để xem chi tiết.';
  }

  @override
  String get sponsorsTitle => 'Nhà tài trợ';

  @override
  String get sponsorsOpenWebsite => 'Mở website';

  @override
  String get sponsorsOpenDavo => 'Mở website DAVO';

  @override
  String get sponsorsCannotOpen => 'Không mở được website nhà tài trợ.';

  @override
  String get familyDashboardCancel => 'Huỷ';

  @override
  String familyDashboardMedDeleted(String name) {
    return 'Đã xoá $name';
  }

  @override
  String get familyDashboardMedAdded => 'Đã thêm thuốc';

  @override
  String get familyDashboardMedUpdated => 'Đã cập nhật thuốc';

  @override
  String get familyDashboardCannotOpenMaps => 'Không mở được Google Maps.';

  @override
  String get familyDashboardCannotOpenAppMaps => 'Không mở được bản đồ.';

  @override
  String get subscriptionTitle => 'Gói AiSee';

  @override
  String get subscriptionRetry => 'Thử lại';

  @override
  String get subscriptionCurrentPlan => 'Gói hiện tại';

  @override
  String get subscriptionUsing => 'Đang dùng';

  @override
  String get subscriptionSuitable => 'Phù hợp';

  @override
  String get subscriptionFree => 'Miễn phí';

  @override
  String get subscriptionViewPlansToBuy => 'Xem gói để mua';

  @override
  String get subscriptionViewSuitablePlans => 'Xem gói phù hợp';

  @override
  String get subscriptionChooseCarePlan => 'Chọn gói chăm sóc';

  @override
  String get subscriptionChooseToContinue => 'Chọn gói để tiếp tục';

  @override
  String get subscriptionAlreadyHighest => 'Bạn đang ở gói cao nhất';

  @override
  String get subscriptionProcessing => 'Đang xử lý…';

  @override
  String get subscriptionNoDowngrade => 'Không hỗ trợ hạ gói';

  @override
  String get subscriptionAlreadyUsing => 'Bạn đang dùng gói này';

  @override
  String get subscriptionUpgradeOnly => 'Chỉ hỗ trợ nâng lên gói cao hơn';

  @override
  String subscriptionContinueWith(String plan) {
    return 'Tiếp tục với $plan';
  }

  @override
  String get subscriptionRenewalOff =>
      'Đã tắt gia hạn. Gói vẫn dùng đến cuối chu kỳ hiện tại.';

  @override
  String subscriptionRenewalOffEndDate(String date) {
    return 'Đã tắt gia hạn. Gói vẫn dùng đến $date.';
  }

  @override
  String get subscriptionPlanHistory => 'Lịch sử gói';

  @override
  String get subscriptionNoHistory =>
      'Chưa có lịch sử hóa đơn hoặc thay đổi gói.';

  @override
  String get subscriptionInvoiceDetail => 'Hóa đơn và thanh toán chi tiết';

  @override
  String get subscriptionInvoicePlaceholder =>
      'Thông tin giao dịch sẽ hiển thị ở đây. Chạm nút bên dưới để mở trang quản lý tài khoản trên cửa hàng ứng dụng.';

  @override
  String get subscriptionOpenStoreManagement =>
      'Mở trang quản lý thanh toán (store)';

  @override
  String get subscriptionManageSubscription => 'Quản lý subscription';

  @override
  String get subscriptionOpenCustomerCenter => 'Mở trung tâm khách hàng';

  @override
  String get subscriptionOpenStorePage => 'Mở trang quản lý store';

  @override
  String get subscriptionSyncTransactions => 'Đồng bộ giao dịch';

  @override
  String get subscriptionSyncHint =>
      'Lưu lại các sự kiện mua gói và kéo trạng thái subscription mới nhất.';

  @override
  String get subscriptionPriceMonthSuffix => '/ tháng';

  @override
  String get subscriptionQuotaRemaining => 'Quota còn lại';

  @override
  String get subscriptionNoQuota => 'Chưa có quota sử dụng.';

  @override
  String get subscriptionUnlimitedReasonable => 'Không giới hạn hợp lý';

  @override
  String get subscriptionActiveEntitlements => 'Quyền đang có';

  @override
  String get subscriptionLockedFeatures => 'Tính năng bị khóa';

  @override
  String get subscriptionNoEntitlements => 'Chưa có quyền nào được bật.';

  @override
  String get subscriptionNoLockedFeatures =>
      'Không có tính năng khóa trong gói này.';

  @override
  String get subscriptionOnlyGroupOwner =>
      'Chỉ người nhà tạo nhóm mới quản lý được gói.';

  @override
  String get subscriptionOnlyGroupOwnerPurchase =>
      'Chỉ người nhà tạo nhóm mới mua gói được.';

  @override
  String get subscriptionCannotOpenManagement =>
      'Không mở được trang quản lý gói';

  @override
  String get subscriptionCannotOpenCustomerCenter =>
      'Không mở được trung tâm khách hàng';

  @override
  String get subscriptionPaymentSuccess =>
      'Thanh toán thành công. AiSee đang đồng bộ gói.';

  @override
  String subscriptionPlanUpdated(String plan) {
    return 'Gói $plan đã được cập nhật.';
  }

  @override
  String get subscriptionSyncInProgress =>
      'Giao dịch đã thành công. Ứng dụng vẫn đang đồng bộ gói, hãy kéo để tải lại hoặc bấm Đồng bộ giao dịch sau ít phút.';

  @override
  String get subscriptionProSynced =>
      'Đã đồng bộ AiSee Pro. AiSee đang cập nhật gói.';

  @override
  String get subscriptionStoreEntitlement =>
      'Store đã trả về entitlement hợp lệ. Hệ thống có thể vẫn đang chờ đồng bộ từ RevenueCat.';

  @override
  String get subscriptionNoProFound =>
      'Chưa tìm thấy gói AiSee Pro trên tài khoản này.';

  @override
  String get subscriptionSuggestUpgrade =>
      'Gợi ý nâng gói. Chạm để xem gói phù hợp.';

  @override
  String get subscriptionQuotaLowWarning =>
      'Nhóm đang dùng gần hết quota. Nâng gói giúp gia đình theo dõi ổn định hơn.';

  @override
  String subscriptionGroupInfo(
    String groupName,
    int caredCount,
    int memberCount,
  ) {
    return '$groupName · $caredCount người được chăm sóc · $memberCount người thân';
  }

  @override
  String subscriptionStorePaymentInfo(String groupName) {
    return '$groupName · thanh toán qua cửa hàng ứng dụng';
  }

  @override
  String get subscriptionPriceNoteVND =>
      'Giá VND theo bảng gói AiSee. Thanh toán, gia hạn và hủy gói vẫn được xử lý qua cửa hàng ứng dụng.';

  @override
  String get subscriptionFeaturesInPlan => 'Tính năng trong gói';

  @override
  String get subscriptionTransactionRecorded =>
      'Giao dịch đã ghi nhận. AiSee đang đồng bộ.';

  @override
  String get subscriptionSessionExpired => 'Phiên đăng nhập hết hạn';

  @override
  String get subscriptionClose => 'Đóng';

  @override
  String get subscriptionPlansPeriodSuffix => 'đ / tháng';

  @override
  String get subscriptionPlanStarted => 'Bắt đầu gói';

  @override
  String get subscriptionPlanRenewed => 'Gia hạn gói';

  @override
  String get subscriptionPlanRenewalOff => 'Hủy gia hạn';

  @override
  String get subscriptionPlanExpired => 'Gói hết hạn';

  @override
  String get subscriptionPlanChanged => 'Đổi gói';

  @override
  String get subscriptionPlanRenewalOn => 'Bật lại gia hạn';

  @override
  String get subscriptionPlanBillingError => 'Lỗi thanh toán';

  @override
  String get subscriptionPlanPaused => 'Tạm dừng gói';

  @override
  String get subscriptionPlanPurchasedNonRenewing => 'Mua gói không gia hạn';

  @override
  String get subscriptionPlanOwnershipTransferred => 'Chuyển quyền mua';

  @override
  String get subscriptionPlanAccountLinked => 'Liên kết tài khoản mua';

  @override
  String get subscriptionPlanCancelled => 'Hủy gói';

  @override
  String get subscriptionPlanUpdated2 => 'Cập nhật gói';

  @override
  String get subscriptionGrantedManually => 'Cấp thủ công';

  @override
  String get subscriptionDavoFeaturesSos => 'SOS khẩn cấp';

  @override
  String get subscriptionDavoFeaturesSosDesc => 'Gửi cảnh báo tới người thân.';

  @override
  String get subscriptionDavoFeaturesMeds => 'Nhắc thuốc';

  @override
  String get subscriptionDavoFeaturesMedsDesc =>
      'Theo dõi lịch uống thuốc và lịch khám.';

  @override
  String get subscriptionDavoFeaturesDailyBrief => 'Tóm tắt hằng ngày';

  @override
  String get subscriptionDavoFeaturesDailyBriefDesc =>
      'Gia đình nhận tóm tắt chăm sóc trong ngày.';

  @override
  String get subscriptionDavoFeaturesWeeklyReport => 'Báo cáo tuần';

  @override
  String get subscriptionDavoFeaturesWeeklyReportDesc =>
      'Tổng hợp xu hướng sức khỏe và hoạt động.';

  @override
  String get subscriptionDavoFeaturesPdfExport => 'Xuất báo cáo PDF';

  @override
  String get subscriptionDavoFeaturesPdfExportDesc =>
      'Tải báo cáo chăm sóc để lưu hoặc gửi bác sĩ.';

  @override
  String get subscriptionDavoFeaturesSmartAlert => 'Cảnh báo thông minh';

  @override
  String get subscriptionDavoFeaturesSmartAlertDesc =>
      'Nhận tín hiệu bất thường chủ động hơn.';

  @override
  String get subscriptionDavoFeaturesIncidentReport => 'Báo cáo sự cố';

  @override
  String get subscriptionDavoFeaturesIncidentReportDesc =>
      'Lưu lại các sự kiện cần gia đình theo dõi.';

  @override
  String get subscriptionDavoFeaturesPrioritySupport => 'Hỗ trợ ưu tiên';

  @override
  String get subscriptionDavoFeaturesPrioritySupportDesc =>
      'Ưu tiên xử lý khi cần hỗ trợ.';

  @override
  String subscriptionVndPricePerMonth(String price) {
    return '$price₫ / tháng';
  }

  @override
  String get subscriptionFreeTrial => 'Miễn phí trong 1 tháng';

  @override
  String get subscriptionPlanFeatureBasic1 => '150 phút AI mỗi tháng';

  @override
  String get subscriptionPlanFeatureBasic1Desc =>
      'Phù hợp cho một người dùng chính với nhu cầu theo dõi cơ bản.';

  @override
  String get subscriptionPlanFeatureBasic2 => '3 lần bật camera mỗi ngày';

  @override
  String get subscriptionPlanFeatureBasic2Desc =>
      'Kiểm tra nhanh tình huống khi người dùng cần hỗ trợ.';

  @override
  String get subscriptionPlanFeatureBasic3 => 'Timeline chăm sóc 7 ngày';

  @override
  String get subscriptionPlanFeatureBasic3Desc =>
      'Xem lại hoạt động gần đây của gia đình trong tuần.';

  @override
  String get subscriptionPlanFeatureBasic4 => '2 thành viên gia đình';

  @override
  String get subscriptionPlanFeatureBasic4Desc =>
      'Cho phép thêm người thân cùng theo dõi một người được chăm sóc.';

  @override
  String get subscriptionPlanFeaturePlus1 => '600 phút AI mỗi tháng';

  @override
  String get subscriptionPlanFeaturePlus1Desc =>
      'Dư dùng hơn cho gia đình cần trợ lý hoạt động thường xuyên.';

  @override
  String get subscriptionPlanFeaturePlus2 => '20 lần bật camera mỗi ngày';

  @override
  String get subscriptionPlanFeaturePlus2Desc =>
      'Theo dõi linh hoạt hơn khi có nhiều tình huống cần kiểm tra.';

  @override
  String get subscriptionPlanFeaturePlus3 => 'Daily brief và weekly report';

  @override
  String get subscriptionPlanFeaturePlus3Desc =>
      'Tóm tắt chăm sóc định kỳ để gia đình nắm tình hình nhanh.';

  @override
  String get subscriptionPlanFeaturePlus4 =>
      '5 thành viên, 3 người được chăm sóc';

  @override
  String get subscriptionPlanFeaturePlus4Desc =>
      'Phù hợp cho gia đình có nhiều người cùng quản lý.';

  @override
  String get subscriptionPlanFeaturePremium1 => 'AI và camera fair use';

  @override
  String get subscriptionPlanFeaturePremium1Desc =>
      'Ưu tiên trải nghiệm gần như không giới hạn theo chính sách hợp lý.';

  @override
  String get subscriptionPlanFeaturePremium2 => 'Báo cáo nâng cao PDF/CSV';

  @override
  String get subscriptionPlanFeaturePremium2Desc =>
      'Xuất báo cáo chăm sóc để lưu trữ hoặc chia sẻ khi cần.';

  @override
  String get subscriptionPlanFeaturePremium3 =>
      '10 thành viên, 4 người được chăm sóc';

  @override
  String get subscriptionPlanFeaturePremium3Desc =>
      'Dành cho nhóm gia đình lớn hoặc chăm sóc nhiều người.';

  @override
  String get subscriptionPlanFeaturePremium4 =>
      'Hỗ trợ ưu tiên và incident report';

  @override
  String get subscriptionPlanFeaturePremium4Desc =>
      'Tăng mức hỗ trợ vận hành khi có tình huống quan trọng.';

  @override
  String get subscriptionTemporaryUnavailable =>
      'Tính năng thanh toán tạm thời không khả dụng. Vui lòng thử lại sau.';

  @override
  String get subscriptionBillingHistoryPlaceholder =>
      'Lịch sử hóa đơn sẽ hiển thị sau. Ứng dụng sẽ mở gói test cho người dùng thử.';

  @override
  String get sponsorsDavoDescription =>
      'DAVO phát triển công nghệ voice AI chạy trực tiếp trên thiết bị, gồm wake word, speaker recognition, VAD, STT và TTS, ưu tiên tốc độ và quyền riêng tư.';

  @override
  String familyDashboardMedDeleteConfirm(String name) {
    return 'Bạn có chắc muốn xóa $name?';
  }

  @override
  String get metricBloodPressure => 'Huyết áp';

  @override
  String get metricHeartRate => 'Nhịp tim';

  @override
  String get metricTemperature => 'Nhiệt độ';

  @override
  String get metricBloodSugar => 'Đường huyết';

  @override
  String get metricWeight => 'Cân nặng';

  @override
  String get metricHeight => 'Chiều cao';

  @override
  String get freqDaily => 'Hàng ngày';

  @override
  String get freqWeekly => 'Hàng tuần';

  @override
  String get freqMonthly => 'Hàng tháng';

  @override
  String get freqTwiceDaily => '2 lần/ngày';

  @override
  String get reminderAtSeparator => ' lúc ';

  @override
  String get supporterTabSupport => 'Hỗ trợ';

  @override
  String get navSupport => 'Hỗ trợ';

  @override
  String get navSupportLabel => 'Mục 1 trên 3: Hỗ trợ. Tổng quan hỗ trợ.';

  @override
  String get supporterPersonalPeopleSupported => 'Người đang hỗ trợ';

  @override
  String get supporterPersonalAITurnsGifted => 'Lượt hỗ trợ đã tặng';

  @override
  String get supporterPersonalAdsWatched => 'Quảng cáo đã xem';

  @override
  String get supporterWatchAdButton => 'Xem quảng cáo để ủng hộ';

  @override
  String get supporterMyFamilyLink => 'Gia đình của tôi';

  @override
  String get supporterBalanceTitle => 'Số dư của bạn';

  @override
  String supporterBalanceConversion(int count) {
    return '$count lượt hỗ trợ';
  }

  @override
  String get supporterRedeemButton => 'Đổi ngay để ủng hộ';

  @override
  String get supporterRateHint => 'Xem quảng cáo → nhận xu → đổi lượt hỗ trợ';

  @override
  String get supporterCommunityTitle => 'Cộng đồng';

  @override
  String get supporterCommunityPeopleSupported => 'Người đang được hỗ trợ';

  @override
  String get supporterCommunityAITurnsGifted => 'Lượt hỗ trợ đã được tặng';

  @override
  String get supporterCommunityActiveSupporters => 'Người hỗ trợ tích cực';

  @override
  String get supporterInfoTitle => 'Cách thức hoạt động';

  @override
  String get supporterInfoStep1 => 'Xem quảng cáo → nhận xu';

  @override
  String get supporterInfoStep2 => 'Tích lũy đủ xu → đổi lấy lượt hỗ trợ';

  @override
  String get supporterInfoStep3 => 'Tặng cho người thân hoặc quỹ chung';

  @override
  String get supporterInfoDailyLimit =>
      'Mỗi ngày bạn có thể xem tối đa 10 quảng cáo';

  @override
  String get supporterInfoLearnMore => 'Tìm hiểu thêm';

  @override
  String get supporterCoinLabel => 'xu';

  @override
  String get supporterAdLimitReached => 'Bạn đã đạt giới hạn quảng cáo hôm nay';

  @override
  String get supporterInsufficientBalance => 'Số dư không đủ để đổi';

  @override
  String supporterRedeemSuccess(int turns) {
    return 'Đã đổi $turns lượt hỗ trợ thành công';
  }

  @override
  String get supporterAdWatchSuccess => 'Nhận được 100 xu';

  @override
  String get supporterRedeemDialogTitle => 'Đổi xu lấy lượt hỗ trợ';

  @override
  String get supporterRedeemCommunityFund => 'Quỹ chung cộng đồng';

  @override
  String supporterRedeemConfirm(int amount, int turns) {
    return 'Đổi $amount xu = $turns lượt hỗ trợ';
  }

  @override
  String get supporterRedeemRecipientLabel => 'Người nhận';
}
