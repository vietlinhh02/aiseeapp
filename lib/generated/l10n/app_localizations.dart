import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'AiSee'**
  String get appTitle;

  /// No description provided for @languageVi.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVi;

  /// No description provided for @languageEn.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ ứng dụng'**
  String get settingsLanguageLabel;

  /// No description provided for @actionSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get actionRetry;

  /// No description provided for @actionContinue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get actionContinue;

  /// No description provided for @actionConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get actionConfirm;

  /// No description provided for @commonError.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi'**
  String get commonError;

  /// No description provided for @commonLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải…'**
  String get commonLoading;

  /// No description provided for @personalTabSemanticsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân. Lịch uống thuốc và nhắc nhở của bạn.'**
  String get personalTabSemanticsLabel;

  /// No description provided for @personalTabIntro.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cá nhân và lịch nhắc nhở của bạn.'**
  String get personalTabIntro;

  /// No description provided for @personalMedicationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch uống thuốc'**
  String get personalMedicationTitle;

  /// No description provided for @personalMedicationCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} nhắc nhở'**
  String personalMedicationCount(int count);

  /// No description provided for @personalMedicationEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch'**
  String get personalMedicationEmpty;

  /// No description provided for @personalAppointmentsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch hẹn'**
  String get personalAppointmentsTitle;

  /// No description provided for @personalAppointmentsCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} lịch hẹn'**
  String personalAppointmentsCount(int count);

  /// No description provided for @personalAppointmentsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch hẹn'**
  String get personalAppointmentsEmpty;

  /// No description provided for @personalHealthLogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký sức khỏe'**
  String get personalHealthLogTitle;

  /// No description provided for @personalHealthLogSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết'**
  String get personalHealthLogSubtitle;

  /// No description provided for @personalSubscriptionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gói AiSee'**
  String get personalSubscriptionTitle;

  /// No description provided for @personalSubscriptionSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quota và quyền đang có'**
  String get personalSubscriptionSubtitle;

  /// No description provided for @personalSponsorsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhà tài trợ'**
  String get personalSponsorsTitle;

  /// No description provided for @personalSponsorsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Các đơn vị đang đồng hành cùng dự án'**
  String get personalSponsorsSubtitle;

  /// No description provided for @personalSignOutLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất khỏi AiSee'**
  String get personalSignOutLabel;

  /// No description provided for @personalSignOutAction.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get personalSignOutAction;

  /// No description provided for @loginTagline.
  ///
  /// In vi, this message translates to:
  /// **'Không chỉ nhìn thay bạn — hành động cùng bạn'**
  String get loginTagline;

  /// No description provided for @loginIntro.
  ///
  /// In vi, this message translates to:
  /// **'AiSee là trợ lý AI cho người suy giảm thị lực tại Việt Nam. Bạn chỉ cần nói — AiSee nghe, hiểu và thực hiện. Thiết kế ưu tiên giọng nói, hỗ trợ tiếng Việt.'**
  String get loginIntro;

  /// No description provided for @loginGoogleButton.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng Google'**
  String get loginGoogleButton;

  /// No description provided for @loginGoogleHelp.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng Google để vào ứng dụng. Chúng tôi dùng tài khoản Google để xác thực an toàn và đồng bộ hồ sơ của bạn.'**
  String get loginGoogleHelp;

  /// No description provided for @loginLegalNotice.
  ///
  /// In vi, this message translates to:
  /// **'Bằng việc đăng nhập, bạn đồng ý với điều khoản dịch vụ của Google và AiSee.'**
  String get loginLegalNotice;

  /// No description provided for @roleAppBarExit.
  ///
  /// In vi, this message translates to:
  /// **'Thoát'**
  String get roleAppBarExit;

  /// No description provided for @roleSelectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn cách bạn dùng AiSee'**
  String get roleSelectionTitle;

  /// No description provided for @roleSelectionHelp.
  ///
  /// In vi, this message translates to:
  /// **'Dùng hai chấm bên dưới để đổi trang, hoặc vuốt ngang khi không cuộn dọc.'**
  String get roleSelectionHelp;

  /// No description provided for @rolePagerUserPage.
  ///
  /// In vi, this message translates to:
  /// **'Trang 1 / 2 — Người dùng'**
  String get rolePagerUserPage;

  /// No description provided for @rolePagerFamilyPage.
  ///
  /// In vi, this message translates to:
  /// **'Trang 2 / 2 — Người thân / hỗ trợ'**
  String get rolePagerFamilyPage;

  /// No description provided for @roleUserBadge.
  ///
  /// In vi, this message translates to:
  /// **'Miễn phí hoàn toàn'**
  String get roleUserBadge;

  /// No description provided for @roleUserTitle.
  ///
  /// In vi, this message translates to:
  /// **'Người dùng'**
  String get roleUserTitle;

  /// No description provided for @roleUserSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Dành cho bạn trực tiếp dùng AiSee bằng giọng nói.'**
  String get roleUserSubtitle;

  /// No description provided for @roleUserBullet1.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện ưu tiên giọng nói và thao tác ít nhìn màn hình, phù hợp người suy giảm thị lực.'**
  String get roleUserBullet1;

  /// No description provided for @roleUserBullet2.
  ///
  /// In vi, this message translates to:
  /// **'Gói người dùng: không phí đăng ký, không hiển thị quảng cáo — trải nghiệm miễn phí cho người dùng chính.'**
  String get roleUserBullet2;

  /// No description provided for @roleUserBullet3.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu bạn cung cấp chỉ phục vụ điều khiển ứng dụng và cải thiện trợ lý theo chính sách quyền riêng tư.'**
  String get roleUserBullet3;

  /// No description provided for @roleUserCta.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với tư cách người dùng'**
  String get roleUserCta;

  /// No description provided for @roleFamilyBadge.
  ///
  /// In vi, this message translates to:
  /// **'Có thể có quảng cáo'**
  String get roleFamilyBadge;

  /// No description provided for @roleFamilyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Người thân / hỗ trợ'**
  String get roleFamilyTitle;

  /// No description provided for @roleFamilySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Dành cho người nhà, tình nguyện viên hoặc người đồng hành chăm sóc.'**
  String get roleFamilySubtitle;

  /// No description provided for @roleFamilyBullet1.
  ///
  /// In vi, this message translates to:
  /// **'Bảng điều khiển: theo dõi trạng thái, nhắc lịch, hỗ trợ thiết lập và điều phối từ xa an toàn hơn.'**
  String get roleFamilyBullet1;

  /// No description provided for @roleFamilyBullet2.
  ///
  /// In vi, this message translates to:
  /// **'Gói này có thể hiển thị quảng cáo để góp phần duy trì máy chủ và phát triển tính năng — bạn xác nhận điều này khi chọn vai trò này.'**
  String get roleFamilyBullet2;

  /// No description provided for @roleFamilyBullet3.
  ///
  /// In vi, this message translates to:
  /// **'AiSee hỗ trợ sinh hoạt hằng ngày, không thay cho tư vấn y tế; trường hợp khẩn cấp hãy liên hệ cơ sở y tế.'**
  String get roleFamilyBullet3;

  /// No description provided for @roleFamilyAccentNote.
  ///
  /// In vi, this message translates to:
  /// **'Quảng cáo (nếu có) sẽ được đặt sao cho ít ảnh hưởng luồng chăm sóc; bạn vẫn có thể hỗ trợ dự án bằng cách xem quảng cáo có chủ đích.'**
  String get roleFamilyAccentNote;

  /// No description provided for @roleFamilyCta.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với tư cách người thân / hỗ trợ'**
  String get roleFamilyCta;

  /// No description provided for @ttsLanguageTag.
  ///
  /// In vi, this message translates to:
  /// **'vi-VN'**
  String get ttsLanguageTag;

  /// No description provided for @announcerMedication.
  ///
  /// In vi, this message translates to:
  /// **'Đến giờ uống thuốc. {title}. Lúc {time}.'**
  String announcerMedication(String title, String time);

  /// No description provided for @announcerAppointment.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có lịch hẹn {title} sau khoảng 30 phút.'**
  String announcerAppointment(String title);

  /// No description provided for @homeMicReadyAnnouncement.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý đang lắng nghe. Bạn có thể nói.'**
  String get homeMicReadyAnnouncement;

  /// No description provided for @homeCameraBlockedNsfw.
  ///
  /// In vi, this message translates to:
  /// **'Camera tạm tắt vì phát hiện nội dung không phù hợp'**
  String get homeCameraBlockedNsfw;

  /// No description provided for @homeNoSession.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có phiên đăng nhập'**
  String get homeNoSession;

  /// No description provided for @homeAssistantConnectFail.
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được trợ lý giọng nói.'**
  String get homeAssistantConnectFail;

  /// No description provided for @homeTabContacts.
  ///
  /// In vi, this message translates to:
  /// **'Liên lạc'**
  String get homeTabContacts;

  /// No description provided for @homeTabPersonal.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get homeTabPersonal;

  /// No description provided for @homeGreeting.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào, {name}'**
  String homeGreeting(String name);

  /// No description provided for @assistantTabRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get assistantTabRetry;

  /// No description provided for @assistantTabSemanticsLoading.
  ///
  /// In vi, this message translates to:
  /// **'Trang Trợ lý AiSee. Đang tải hồ sơ.'**
  String get assistantTabSemanticsLoading;

  /// No description provided for @assistantTabSemanticsError.
  ///
  /// In vi, this message translates to:
  /// **'Trang Trợ lý AiSee. Có lỗi hồ sơ.'**
  String get assistantTabSemanticsError;

  /// No description provided for @assistantTabSemanticsConnecting.
  ///
  /// In vi, this message translates to:
  /// **'Trang Trợ lý AiSee. Đang kết nối trợ lý.'**
  String get assistantTabSemanticsConnecting;

  /// No description provided for @assistantTabSemanticsConnectError.
  ///
  /// In vi, this message translates to:
  /// **'Trang Trợ lý AiSee. Lỗi kết nối. Chạm Thử lại để thử lại.'**
  String get assistantTabSemanticsConnectError;

  /// No description provided for @assistantTabSemanticsConnected.
  ///
  /// In vi, this message translates to:
  /// **'Trang Trợ lý AiSee. Đã kết nối trợ lý giọng nói.'**
  String get assistantTabSemanticsConnected;

  /// No description provided for @assistantTabSemanticsDefault.
  ///
  /// In vi, this message translates to:
  /// **'Trang Trợ lý AiSee.'**
  String get assistantTabSemanticsDefault;

  /// No description provided for @assistantTabCameraPreviewLabel.
  ///
  /// In vi, this message translates to:
  /// **'Xem trước camera của bạn, toàn màn hình'**
  String get assistantTabCameraPreviewLabel;

  /// No description provided for @assistantTabConnected.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết nối trợ lý giọng nói.'**
  String get assistantTabConnected;

  /// No description provided for @assistantTabConnecting.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ kết nối…'**
  String get assistantTabConnecting;

  /// No description provided for @assistantTabWakeHintTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gọi “aisee ơi” để đánh thức trợ lý'**
  String get assistantTabWakeHintTitle;

  /// No description provided for @assistantTabWakeHintBody.
  ///
  /// In vi, this message translates to:
  /// **'Khi AiSee đang nghỉ, chỉ cần nói “aisee ơi” để bắt đầu lại.'**
  String get assistantTabWakeHintBody;

  /// No description provided for @assistantTabWakeTimedOutTitle.
  ///
  /// In vi, this message translates to:
  /// **'AiSee đã nghỉ vì im lặng'**
  String get assistantTabWakeTimedOutTitle;

  /// No description provided for @assistantTabWakeTimedOutBody.
  ///
  /// In vi, this message translates to:
  /// **'Muốn nói tiếp, hãy gọi lại “aisee ơi”.'**
  String get assistantTabWakeTimedOutBody;

  /// No description provided for @assistantTabNowPlaying.
  ///
  /// In vi, this message translates to:
  /// **'Đang phát: {title}'**
  String assistantTabNowPlaying(String title);

  /// No description provided for @homeWakeReminderAnnouncement.
  ///
  /// In vi, this message translates to:
  /// **'AiSee đã nghỉ. Muốn nói tiếp, hãy gọi lại aisee ơi.'**
  String get homeWakeReminderAnnouncement;

  /// No description provided for @authSessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên hết hạn, vui lòng đăng nhập lại'**
  String get authSessionExpired;

  /// No description provided for @authSignInSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thành công'**
  String get authSignInSuccess;

  /// No description provided for @authSignedOut.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng xuất'**
  String get authSignedOut;

  /// No description provided for @authNoIdToken.
  ///
  /// In vi, this message translates to:
  /// **'Không lấy được mã xác thực từ Google.'**
  String get authNoIdToken;

  /// No description provided for @authBootstrapFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không khởi tạo được Google Sign-In:\n{detail}'**
  String authBootstrapFailed(String detail);

  /// No description provided for @authBootstrapTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng nhập AiSee…'**
  String get authBootstrapTitle;

  /// No description provided for @authBootstrapDetail.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác thực với máy chủ'**
  String get authBootstrapDetail;

  /// No description provided for @authGoogleCanceled.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy đăng nhập'**
  String get authGoogleCanceled;

  /// No description provided for @authGoogleError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi Google: {detail}'**
  String authGoogleError(String detail);

  /// No description provided for @onboardingSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get onboardingNext;

  /// No description provided for @onboardingFinish.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục đến đăng nhập'**
  String get onboardingFinish;

  /// No description provided for @onboardingChooseRoleHint.
  ///
  /// In vi, this message translates to:
  /// **'Chọn vai trò để tiếp tục đăng nhập.'**
  String get onboardingChooseRoleHint;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng đến với AiSee'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeDesc.
  ///
  /// In vi, this message translates to:
  /// **'AiSee hỗ trợ người suy giảm thị lực bằng giọng nói, nhắc việc và kết nối nhanh với người thân.'**
  String get onboardingWelcomeDesc;

  /// No description provided for @onboardingWelcomeBullet1.
  ///
  /// In vi, this message translates to:
  /// **'Nói chuyện với trợ lý bằng tiếng Việt'**
  String get onboardingWelcomeBullet1;

  /// No description provided for @onboardingWelcomeBullet2.
  ///
  /// In vi, this message translates to:
  /// **'Thiết kế chữ rõ, thao tác đơn giản'**
  String get onboardingWelcomeBullet2;

  /// No description provided for @onboardingWelcomeBullet3.
  ///
  /// In vi, this message translates to:
  /// **'Có thể nhờ người thân đồng hành từ xa'**
  String get onboardingWelcomeBullet3;

  /// No description provided for @onboardingPermsTitle.
  ///
  /// In vi, this message translates to:
  /// **'AiSee cần một số quyền cơ bản'**
  String get onboardingPermsTitle;

  /// No description provided for @onboardingPermsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Mic, camera, thông báo và vị trí sẽ chỉ được dùng để hỗ trợ bạn tốt hơn khi cần.'**
  String get onboardingPermsDesc;

  /// No description provided for @onboardingPermsBullet1.
  ///
  /// In vi, this message translates to:
  /// **'Microphone: nghe câu lệnh của bạn'**
  String get onboardingPermsBullet1;

  /// No description provided for @onboardingPermsBullet2.
  ///
  /// In vi, this message translates to:
  /// **'Camera: hỗ trợ nhận biết xung quanh'**
  String get onboardingPermsBullet2;

  /// No description provided for @onboardingPermsBullet3.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo và vị trí: nhắc việc và điều phối hỗ trợ'**
  String get onboardingPermsBullet3;

  /// No description provided for @onboardingFamilyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Luôn có người thân bên cạnh'**
  String get onboardingFamilyTitle;

  /// No description provided for @onboardingFamilyDesc.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể mời người thân vào ứng dụng để nhắn tin, gọi điện và cùng theo dõi những việc quan trọng.'**
  String get onboardingFamilyDesc;

  /// No description provided for @onboardingFamilyBullet1.
  ///
  /// In vi, this message translates to:
  /// **'Mời người thân bằng mã đơn giản'**
  String get onboardingFamilyBullet1;

  /// No description provided for @onboardingFamilyBullet2.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn tin và gọi ngay trong app'**
  String get onboardingFamilyBullet2;

  /// No description provided for @onboardingFamilyBullet3.
  ///
  /// In vi, this message translates to:
  /// **'Phối hợp nhanh khi cần trợ giúp'**
  String get onboardingFamilyBullet3;

  /// No description provided for @onboardingBatteryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Để cuộc gọi không bị bỏ lỡ'**
  String get onboardingBatteryTitle;

  /// No description provided for @onboardingBatteryDesc.
  ///
  /// In vi, this message translates to:
  /// **'Một số máy Android tự tắt app trong nền để tiết kiệm pin, dẫn đến không nhận được cuộc gọi. Hãy cho phép AiSee chạy nền liên tục.'**
  String get onboardingBatteryDesc;

  /// No description provided for @onboardingBatteryBullet1.
  ///
  /// In vi, this message translates to:
  /// **'Cuộc gọi đến hiện ngay cả khi tắt màn hình'**
  String get onboardingBatteryBullet1;

  /// No description provided for @onboardingBatteryBullet2.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc thuốc và nhắc việc luôn đúng giờ'**
  String get onboardingBatteryBullet2;

  /// No description provided for @onboardingBatteryBullet3.
  ///
  /// In vi, this message translates to:
  /// **'AiSee chỉ chạy nhẹ ở nền, không hao pin'**
  String get onboardingBatteryBullet3;

  /// No description provided for @onboardingRemindersTitle.
  ///
  /// In vi, this message translates to:
  /// **'AiSee sẽ nhắc những việc quan trọng'**
  String get onboardingRemindersTitle;

  /// No description provided for @onboardingRemindersDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc thuốc, lịch hẹn và các thông báo cần chú ý để bạn an tâm hơn mỗi ngày.'**
  String get onboardingRemindersDesc;

  /// No description provided for @onboardingRemindersBullet1.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc uống thuốc đúng giờ'**
  String get onboardingRemindersBullet1;

  /// No description provided for @onboardingRemindersBullet2.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc lịch hẹn và việc cần nhớ'**
  String get onboardingRemindersBullet2;

  /// No description provided for @onboardingRemindersBullet3.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo rõ ràng, ít gây rối'**
  String get onboardingRemindersBullet3;

  /// No description provided for @onboardingRoleUserTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tôi là người dùng khiếm thị'**
  String get onboardingRoleUserTitle;

  /// No description provided for @onboardingRoleUserSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Dùng AiSee trực tiếp bằng giọng nói mỗi ngày.'**
  String get onboardingRoleUserSubtitle;

  /// No description provided for @onboardingRoleFamilyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tôi là người thân / hỗ trợ'**
  String get onboardingRoleFamilyTitle;

  /// No description provided for @onboardingRoleFamilySubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đồng hành, nhắc việc và hỗ trợ người dùng từ xa.'**
  String get onboardingRoleFamilySubtitle;

  /// No description provided for @onboardingBatteryChecking.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra…'**
  String get onboardingBatteryChecking;

  /// No description provided for @onboardingBatteryGranted.
  ///
  /// In vi, this message translates to:
  /// **'Đã cho phép chạy nền'**
  String get onboardingBatteryGranted;

  /// No description provided for @onboardingBatteryNotGranted.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cho phép chạy nền'**
  String get onboardingBatteryNotGranted;

  /// No description provided for @onboardingBatteryButton.
  ///
  /// In vi, this message translates to:
  /// **'Tắt tối ưu pin cho AiSee'**
  String get onboardingBatteryButton;

  /// No description provided for @onboardingBatteryOpenSettings.
  ///
  /// In vi, this message translates to:
  /// **'Mở cài đặt ứng dụng'**
  String get onboardingBatteryOpenSettings;

  /// No description provided for @onboardingBatteryDoneNote.
  ///
  /// In vi, this message translates to:
  /// **'AiSee có thể nhận cuộc gọi ngay cả khi điện thoại đang ngủ. Bạn có thể đổi lại trong Cài đặt > Pin bất cứ lúc nào.'**
  String get onboardingBatteryDoneNote;

  /// No description provided for @onboardingStatusOn.
  ///
  /// In vi, this message translates to:
  /// **'Đã bật'**
  String get onboardingStatusOn;

  /// No description provided for @onboardingStatusOff.
  ///
  /// In vi, this message translates to:
  /// **'Cần bật'**
  String get onboardingStatusOff;

  /// No description provided for @familyTabFamily.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình'**
  String get familyTabFamily;

  /// No description provided for @familyTabMessages.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn'**
  String get familyTabMessages;

  /// No description provided for @familyTabPersonal.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get familyTabPersonal;

  /// No description provided for @familyHomeProfileFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được thông tin'**
  String get familyHomeProfileFailed;

  /// No description provided for @familyPersonalIntro.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin tài khoản và đăng ký hỗ trợ của bạn.'**
  String get familyPersonalIntro;

  /// No description provided for @familyPersonalSemanticsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân. Thông tin tài khoản và tình nguyện viên.'**
  String get familyPersonalSemanticsLabel;

  /// No description provided for @familyPersonalCardInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cá nhân'**
  String get familyPersonalCardInfoTitle;

  /// No description provided for @familyPersonalCardInfoSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Email, vai trò và ngày tham gia'**
  String get familyPersonalCardInfoSubtitle;

  /// No description provided for @familyPersonalCardUsageTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị đã dùng'**
  String get familyPersonalCardUsageTitle;

  /// No description provided for @familyPersonalCardUsageSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Giải thích quota và tính năng theo gói'**
  String get familyPersonalCardUsageSubtitle;

  /// No description provided for @familyPersonalCardSubscriptionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gói AiSee'**
  String get familyPersonalCardSubscriptionTitle;

  /// No description provided for @familyPersonalCardSubscriptionSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý gói, quota và quyền chăm sóc'**
  String get familyPersonalCardSubscriptionSubtitle;

  /// No description provided for @familyPersonalCardSponsorsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhà tài trợ'**
  String get familyPersonalCardSponsorsTitle;

  /// No description provided for @familyPersonalCardSponsorsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đơn vị đồng hành cùng dự án AiSee'**
  String get familyPersonalCardSponsorsSubtitle;

  /// No description provided for @familyPersonalSignOutLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất khỏi AiSee'**
  String get familyPersonalSignOutLabel;

  /// No description provided for @familyPersonalSignOutAction.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get familyPersonalSignOutAction;

  /// No description provided for @familyPersonalRoleSupporter.
  ///
  /// In vi, this message translates to:
  /// **'Người hỗ trợ'**
  String get familyPersonalRoleSupporter;

  /// No description provided for @familyPersonalSheetClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get familyPersonalSheetClose;

  /// No description provided for @familyPersonalSheetTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin cá nhân'**
  String get familyPersonalSheetTitle;

  /// No description provided for @familyPersonalSheetRole.
  ///
  /// In vi, this message translates to:
  /// **'Vai trò'**
  String get familyPersonalSheetRole;

  /// No description provided for @familyPersonalSheetJoinDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày tham gia'**
  String get familyPersonalSheetJoinDate;

  /// No description provided for @familyPersonalCareNeeded.
  ///
  /// In vi, this message translates to:
  /// **'Hãy mở hồ sơ một người được chăm sóc trước khi xem quota theo nhóm.'**
  String get familyPersonalCareNeeded;

  /// No description provided for @familyPersonalSubscriptionNeeded.
  ///
  /// In vi, this message translates to:
  /// **'Hãy mở hồ sơ một người được chăm sóc trước khi quản lý gói.'**
  String get familyPersonalSubscriptionNeeded;

  /// No description provided for @familyPersonalSessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập hết hạn. Hãy đăng xuất và đăng nhập lại.'**
  String get familyPersonalSessionExpired;

  /// No description provided for @familyPersonalRegisterSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng ký tình nguyện viên'**
  String get familyPersonalRegisterSuccess;

  /// No description provided for @familyPersonalCardActionHint.
  ///
  /// In vi, this message translates to:
  /// **'{title}. {subtitle}. Chạm để mở.'**
  String familyPersonalCardActionHint(String title, String subtitle);

  /// No description provided for @familyVolunteerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tình nguyện viên'**
  String get familyVolunteerTitle;

  /// No description provided for @familyVolunteerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ người khiếm thị khi người thân không thể trả lời'**
  String get familyVolunteerSubtitle;

  /// No description provided for @familyVolunteerRegisterAction.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký tình nguyện viên'**
  String get familyVolunteerRegisterAction;

  /// No description provided for @familyVolunteerReadyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng hỗ trợ'**
  String get familyVolunteerReadyTitle;

  /// No description provided for @familyVolunteerReadyOn.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ nhận cuộc gọi hỗ trợ'**
  String get familyVolunteerReadyOn;

  /// No description provided for @familyVolunteerReadyOff.
  ///
  /// In vi, this message translates to:
  /// **'Tạm nghỉ, không nhận cuộc gọi'**
  String get familyVolunteerReadyOff;

  /// No description provided for @careDailySummaryFallback.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt ngày'**
  String get careDailySummaryFallback;

  /// No description provided for @careDailySummaryError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi không xác định'**
  String get careDailySummaryError;

  /// No description provided for @careAlertAcknowledged.
  ///
  /// In vi, this message translates to:
  /// **'Đã xác nhận cảnh báo'**
  String get careAlertAcknowledged;

  /// No description provided for @careAlertClosed.
  ///
  /// In vi, this message translates to:
  /// **'Đã đóng cảnh báo'**
  String get careAlertClosed;

  /// No description provided for @careAlertSkipped.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ qua'**
  String get careAlertSkipped;

  /// No description provided for @careTaskCreatedToast.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạo việc cần làm'**
  String get careTaskCreatedToast;

  /// No description provided for @careTaskCompletedToast.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn thành'**
  String get careTaskCompletedToast;

  /// No description provided for @careTaskDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Việc cần làm'**
  String get careTaskDialogTitle;

  /// No description provided for @careTaskDialogContentLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung'**
  String get careTaskDialogContentLabel;

  /// No description provided for @careTaskDialogCreate.
  ///
  /// In vi, this message translates to:
  /// **'Tạo'**
  String get careTaskDialogCreate;

  /// No description provided for @careTabIntroTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chăm sóc hằng ngày'**
  String get careTabIntroTitle;

  /// No description provided for @careTabIntroSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt ngày, cảnh báo rule-based và việc cần làm cho người thân.'**
  String get careTabIntroSubtitle;

  /// No description provided for @careOpenFullSummary.
  ///
  /// In vi, this message translates to:
  /// **'Mở đầy đủ tóm tắt ngày'**
  String get careOpenFullSummary;

  /// No description provided for @careAlertsHeading.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo'**
  String get careAlertsHeading;

  /// No description provided for @careRefreshAction.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới'**
  String get careRefreshAction;

  /// No description provided for @careNoAlerts.
  ///
  /// In vi, this message translates to:
  /// **'Không có cảnh báo.'**
  String get careNoAlerts;

  /// No description provided for @careTasksHeading.
  ///
  /// In vi, this message translates to:
  /// **'Việc cần làm'**
  String get careTasksHeading;

  /// No description provided for @careTasksAdd.
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get careTasksAdd;

  /// No description provided for @careNoTasks.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có việc.'**
  String get careNoTasks;

  /// No description provided for @careSummaryLoadFail.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được tóm tắt'**
  String get careSummaryLoadFail;

  /// No description provided for @careRetryAction.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get careRetryAction;

  /// No description provided for @careOpenPlanQuota.
  ///
  /// In vi, this message translates to:
  /// **'Xem gói / quota'**
  String get careOpenPlanQuota;

  /// No description provided for @contactsNotLoggedIn.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đăng nhập. Vui lòng đăng nhập lại.'**
  String get contactsNotLoggedIn;

  /// No description provided for @contactsLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách liên lạc.'**
  String get contactsLoadFailed;

  /// No description provided for @contactsCallCreateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tạo được cuộc gọi'**
  String get contactsCallCreateFailed;

  /// No description provided for @contactsSessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.'**
  String get contactsSessionExpired;

  /// No description provided for @contactsLeftGroup.
  ///
  /// In vi, this message translates to:
  /// **'Đã rời nhóm chăm sóc'**
  String get contactsLeftGroup;

  /// No description provided for @contactsLeaveGroupFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không rời được nhóm chăm sóc.'**
  String get contactsLeaveGroupFailed;

  /// No description provided for @contactsLeaveGroupTitle.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm chăm sóc'**
  String get contactsLeaveGroupTitle;

  /// No description provided for @contactsLeaveGroupBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn phải rời nhóm hiện tại trước khi tham gia nhóm mới bằng mã mời khác.'**
  String get contactsLeaveGroupBody;

  /// No description provided for @contactsCancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get contactsCancel;

  /// No description provided for @contactsLeaveGroupAction.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm'**
  String get contactsLeaveGroupAction;

  /// No description provided for @contactsJoinGroupTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia nhóm chăm sóc'**
  String get contactsJoinGroupTitle;

  /// No description provided for @contactsJoinGroupHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã mời 6 số từ người nhà để tham gia nhóm'**
  String get contactsJoinGroupHint;

  /// No description provided for @contactsJoinAction.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia'**
  String get contactsJoinAction;

  /// No description provided for @contactsPleaseEnterCode.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập mã mời'**
  String get contactsPleaseEnterCode;

  /// No description provided for @contactsJoinedGroup.
  ///
  /// In vi, this message translates to:
  /// **'Đã tham gia nhóm chăm sóc'**
  String get contactsJoinedGroup;

  /// No description provided for @contactsJoinFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tham gia được nhóm chăm sóc.'**
  String get contactsJoinFailed;

  /// No description provided for @contactsTabSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Liên lạc. Nhắn tin và gọi điện người thân.'**
  String get contactsTabSemantics;

  /// No description provided for @contactsTabIntro.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn tin và gọi điện người thân.'**
  String get contactsTabIntro;

  /// No description provided for @contactsRetryLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại tải danh sách liên lạc'**
  String get contactsRetryLabel;

  /// No description provided for @contactsRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get contactsRetry;

  /// No description provided for @contactsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tham gia nhóm chăm sóc nào.\nDùng mã mời 6 số từ người nhà để kết nối.'**
  String get contactsEmpty;

  /// No description provided for @contactsWantSwitchGroup.
  ///
  /// In vi, this message translates to:
  /// **'Muốn vào nhóm khác?'**
  String get contactsWantSwitchGroup;

  /// No description provided for @contactsSwitchGroupHint.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm hiện tại trước, rồi quay lại tab này để nhập mã mời 6 số của nhóm mới.'**
  String get contactsSwitchGroupHint;

  /// No description provided for @contactsLeaveCurrentGroup.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm hiện tại'**
  String get contactsLeaveCurrentGroup;

  /// No description provided for @contactsEnterCodeButton.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã mời 6 số'**
  String get contactsEnterCodeButton;

  /// No description provided for @contactsTapToChat.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để nhắn tin'**
  String get contactsTapToChat;

  /// No description provided for @contactsVoiceCallLabel.
  ///
  /// In vi, this message translates to:
  /// **'Gọi thoại {label}'**
  String contactsVoiceCallLabel(Object label);

  /// No description provided for @contactsVoiceCallTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Gọi thoại'**
  String get contactsVoiceCallTooltip;

  /// No description provided for @contactsVideoCallLabel.
  ///
  /// In vi, this message translates to:
  /// **'Gọi video {label}'**
  String contactsVideoCallLabel(Object label);

  /// No description provided for @contactsVideoCallTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Gọi video'**
  String get contactsVideoCallTooltip;

  /// No description provided for @chatLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được tin nhắn.'**
  String get chatLoadFailed;

  /// No description provided for @chatSendFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không gửi được tin nhắn.'**
  String get chatSendFailed;

  /// No description provided for @chatTakePhoto.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get chatTakePhoto;

  /// No description provided for @chatTakePhotoLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh bằng camera'**
  String get chatTakePhotoLabel;

  /// No description provided for @chatPickFromGallery.
  ///
  /// In vi, this message translates to:
  /// **'Chọn từ thư viện'**
  String get chatPickFromGallery;

  /// No description provided for @chatPickFromGalleryLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh từ thư viện'**
  String get chatPickFromGalleryLabel;

  /// No description provided for @chatCameraPermission.
  ///
  /// In vi, this message translates to:
  /// **'Cần quyền camera để chụp ảnh.'**
  String get chatCameraPermission;

  /// No description provided for @chatUploadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Gửi không thành công.'**
  String get chatUploadFailed;

  /// No description provided for @chatMicPermission.
  ///
  /// In vi, this message translates to:
  /// **'Cần quyền microphone để ghi âm.'**
  String get chatMicPermission;

  /// No description provided for @chatRecordFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể ghi âm.'**
  String get chatRecordFailed;

  /// No description provided for @chatVoiceCallTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Gọi thoại'**
  String get chatVoiceCallTooltip;

  /// No description provided for @chatVideoCallTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Gọi video'**
  String get chatVideoCallTooltip;

  /// No description provided for @chatEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tin nhắn.\nHãy gửi lời chào!'**
  String get chatEmpty;

  /// No description provided for @chatImageLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được ảnh'**
  String get chatImageLoadFailed;

  /// No description provided for @chatAttachImage.
  ///
  /// In vi, this message translates to:
  /// **'Đính kèm ảnh'**
  String get chatAttachImage;

  /// No description provided for @chatInputHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhắn tin...'**
  String get chatInputHint;

  /// No description provided for @chatSend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi tin nhắn'**
  String get chatSend;

  /// No description provided for @chatHoldToRecord.
  ///
  /// In vi, this message translates to:
  /// **'Giữ để ghi âm'**
  String get chatHoldToRecord;

  /// No description provided for @chatStopRecordLabel.
  ///
  /// In vi, this message translates to:
  /// **'Dừng ghi âm và gửi. Giữ để huỷ.'**
  String get chatStopRecordLabel;

  /// No description provided for @chatSending.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi...'**
  String get chatSending;

  /// No description provided for @usageValueTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị đã dùng'**
  String get usageValueTitle;

  /// No description provided for @usageValuePlan.
  ///
  /// In vi, this message translates to:
  /// **'Gói {planName}'**
  String usageValuePlan(Object planName);

  /// No description provided for @usageValuePeriod.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ: {start} — {end}'**
  String usageValuePeriod(Object end, Object start);

  /// No description provided for @usageValueChartTitle.
  ///
  /// In vi, this message translates to:
  /// **'Biểu đồ đã dùng (kỳ hiện tại)'**
  String get usageValueChartTitle;

  /// No description provided for @usageValueWhatUsed.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã dùng gì trong kỳ này'**
  String get usageValueWhatUsed;

  /// No description provided for @usageValueUnlimited.
  ///
  /// In vi, this message translates to:
  /// **'Không giới hạn'**
  String get usageValueUnlimited;

  /// No description provided for @usageValueUsedLine.
  ///
  /// In vi, this message translates to:
  /// **'Đã dùng {used} / {limit} {unit} (còn {remaining})'**
  String usageValueUsedLine(
    Object limit,
    Object remaining,
    Object unit,
    Object used,
  );

  /// No description provided for @usageValueUpgradeHint.
  ///
  /// In vi, this message translates to:
  /// **'Gói cao hơn có thể phù hợp nếu bạn cần thêm hạn mức.'**
  String get usageValueUpgradeHint;

  /// No description provided for @usageValueEntitlementsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng chăm sóc theo gói'**
  String get usageValueEntitlementsTitle;

  /// No description provided for @usageValueEntitlementCol.
  ///
  /// In vi, this message translates to:
  /// **'Quyền / tính năng'**
  String get usageValueEntitlementCol;

  /// No description provided for @usageValueDescCol.
  ///
  /// In vi, this message translates to:
  /// **'Mô tả'**
  String get usageValueDescCol;

  /// No description provided for @usageValueStatusCol.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get usageValueStatusCol;

  /// No description provided for @usageValueOn.
  ///
  /// In vi, this message translates to:
  /// **'Bật'**
  String get usageValueOn;

  /// No description provided for @usageValueOff.
  ///
  /// In vi, this message translates to:
  /// **'Khóa'**
  String get usageValueOff;

  /// No description provided for @usageValueViewPlan.
  ///
  /// In vi, this message translates to:
  /// **'Xem gói và nâng cấp'**
  String get usageValueViewPlan;

  /// No description provided for @usageValueChartLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đã dùng trong kỳ'**
  String get usageValueChartLabel;

  /// No description provided for @usageValueSessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập hết hạn'**
  String get usageValueSessionExpired;

  /// No description provided for @usageStoryAiMinutes.
  ///
  /// In vi, this message translates to:
  /// **'Phút trò chuyện với trợ lý — thể hiện mức độ đồng hành hằng ngày.'**
  String get usageStoryAiMinutes;

  /// No description provided for @usageStoryPdfExports.
  ///
  /// In vi, this message translates to:
  /// **'Lượt xuất báo cáo chăm sóc — giúp lưu lại tóm tắt cho bác sĩ hoặc gia đình.'**
  String get usageStoryPdfExports;

  /// No description provided for @usageStoryCameraActivations.
  ///
  /// In vi, this message translates to:
  /// **'Lần bật camera trong phiên — hỗ trợ xem và hướng dẫn từ xa.'**
  String get usageStoryCameraActivations;

  /// No description provided for @usageStoryDefault.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động được tính vào gói hiện tại của bạn.'**
  String get usageStoryDefault;

  /// No description provided for @entitlementStoryDailyBrief.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt sức khỏe mỗi ngày cho người thân.'**
  String get entitlementStoryDailyBrief;

  /// No description provided for @entitlementStoryWeeklyReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo tuần — xu hướng chăm sóc dài hơn.'**
  String get entitlementStoryWeeklyReport;

  /// No description provided for @entitlementStoryCareTimeline.
  ///
  /// In vi, this message translates to:
  /// **'Số ngày xem lại timeline chăm sóc.'**
  String get entitlementStoryCareTimeline;

  /// No description provided for @entitlementStoryIncidentReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo sự cố / leo thang sau SOS.'**
  String get entitlementStoryIncidentReport;

  /// No description provided for @entitlementStoryDefault.
  ///
  /// In vi, this message translates to:
  /// **'Quyền theo gói AiSee.'**
  String get entitlementStoryDefault;

  /// No description provided for @navAssistant.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý'**
  String get navAssistant;

  /// No description provided for @navAssistantLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mục 1 trên 3: Trợ lý. Trang chủ. Trợ lý AiSee đang sẵn sàng nghe.'**
  String get navAssistantLabel;

  /// No description provided for @navContacts.
  ///
  /// In vi, this message translates to:
  /// **'Liên lạc'**
  String get navContacts;

  /// No description provided for @navContactsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mục 2 trên 3: Liên lạc. Nhắn tin và gọi điện người thân.'**
  String get navContactsLabel;

  /// No description provided for @navPersonal.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get navPersonal;

  /// No description provided for @navPersonalLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mục 3 trên 3: Cá nhân. Cá nhân. Lịch uống thuốc và tin nhắn của bạn.'**
  String get navPersonalLabel;

  /// No description provided for @navFamily.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình'**
  String get navFamily;

  /// No description provided for @navFamilyLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mục 1 trên 3: Gia đình. Danh sách liên lạc gia đình.'**
  String get navFamilyLabel;

  /// No description provided for @navMessages.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn'**
  String get navMessages;

  /// No description provided for @navMessagesLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mục 2 trên 3: Tin nhắn. Hộp thư đến.'**
  String get navMessagesLabel;

  /// No description provided for @navPersonalFamilyLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mục 3 trên 3: Cá nhân. Hồ sơ và cài đặt.'**
  String get navPersonalFamilyLabel;

  /// No description provided for @navDoubleTapHint.
  ///
  /// In vi, this message translates to:
  /// **'Chạm hai lần để chọn'**
  String get navDoubleTapHint;

  /// No description provided for @closeAction.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get closeAction;

  /// No description provided for @incomingVoiceCall.
  ///
  /// In vi, this message translates to:
  /// **'Cuộc gọi thoại đến'**
  String get incomingVoiceCall;

  /// No description provided for @incomingVideoCall.
  ///
  /// In vi, this message translates to:
  /// **'Cuộc gọi video đến'**
  String get incomingVideoCall;

  /// No description provided for @declineCall.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get declineCall;

  /// No description provided for @ringing.
  ///
  /// In vi, this message translates to:
  /// **'Đang đổ chuông'**
  String get ringing;

  /// No description provided for @agentConnecting.
  ///
  /// In vi, this message translates to:
  /// **'Đang kết nối...'**
  String get agentConnecting;

  /// No description provided for @agentReady.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng'**
  String get agentReady;

  /// No description provided for @agentListening.
  ///
  /// In vi, this message translates to:
  /// **'Đang nghe...'**
  String get agentListening;

  /// No description provided for @agentThinking.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý...'**
  String get agentThinking;

  /// No description provided for @agentSpeaking.
  ///
  /// In vi, this message translates to:
  /// **'Đang trả lời...'**
  String get agentSpeaking;

  /// No description provided for @agentDisconnected.
  ///
  /// In vi, this message translates to:
  /// **'Đã ngắt kết nối'**
  String get agentDisconnected;

  /// No description provided for @agentConnectionError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi kết nối'**
  String get agentConnectionError;

  /// No description provided for @callTokenExpired.
  ///
  /// In vi, this message translates to:
  /// **'Token cuộc gọi đã hết hạn'**
  String get callTokenExpired;

  /// No description provided for @callJoinFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không vào được cuộc gọi. Vui lòng thử lại.'**
  String get callJoinFailed;

  /// No description provided for @livekitNotReady.
  ///
  /// In vi, this message translates to:
  /// **'LiveKit chưa sẵn sàng để bật micro.'**
  String get livekitNotReady;

  /// No description provided for @livekitBadJson.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ trả không phải JSON hợp lệ (HTTP {code}). Kiểm tra cấu hình ứng dụng và route POST /api/v1/calls/token.'**
  String livekitBadJson(Object code);

  /// No description provided for @livekitTokenError.
  ///
  /// In vi, this message translates to:
  /// **'Không lấy được token phòng (HTTP {code})'**
  String livekitTokenError(Object code);

  /// No description provided for @livekitTokenEmpty.
  ///
  /// In vi, this message translates to:
  /// **'API /api/v1/calls/token trả 200 nhưng thân phản hồi trống hoặc không phải JSON object. Kiểm tra phần xử lý của ứng dụng xem có gửi JSON chứa token không.'**
  String get livekitTokenEmpty;

  /// No description provided for @livekitMissingToken.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi token LiveKit thiếu token'**
  String get livekitMissingToken;

  /// No description provided for @livekitMissingUrl.
  ///
  /// In vi, this message translates to:
  /// **'Thiếu URL LiveKit: điền LIVEKIT_URL trong assets/app_config.env'**
  String get livekitMissingUrl;

  /// No description provided for @livekitPermissionDenied.
  ///
  /// In vi, this message translates to:
  /// **'Quyền {permission} đã bị từ chối. Hãy bật trong Cài đặt cho AiSee.'**
  String livekitPermissionDenied(Object permission);

  /// No description provided for @livekitPermissionRequired.
  ///
  /// In vi, this message translates to:
  /// **'Cần quyền {permission} để dùng trợ lý.'**
  String livekitPermissionRequired(Object permission);

  /// No description provided for @livekitNoSession.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có phiên đăng nhập'**
  String get livekitNoSession;

  /// No description provided for @livekitConnecting.
  ///
  /// In vi, this message translates to:
  /// **'Đang kết nối room...'**
  String get livekitConnecting;

  /// No description provided for @livekitDisconnecting.
  ///
  /// In vi, this message translates to:
  /// **'Đang ngắt kết nối...'**
  String get livekitDisconnecting;

  /// No description provided for @livekitNoRoomDisconnect.
  ///
  /// In vi, this message translates to:
  /// **'Không có room đang kết nối'**
  String get livekitNoRoomDisconnect;

  /// No description provided for @livekitDisconnected.
  ///
  /// In vi, this message translates to:
  /// **'Đã ngắt xong.'**
  String get livekitDisconnected;

  /// No description provided for @serviceHealthRecordFail.
  ///
  /// In vi, this message translates to:
  /// **'Không ghi nhận uống thuốc được'**
  String get serviceHealthRecordFail;

  /// No description provided for @serviceHealthSkipFail.
  ///
  /// In vi, this message translates to:
  /// **'Không ghi nhận bỏ thuốc được'**
  String get serviceHealthSkipFail;

  /// No description provided for @serviceHealthSymptomFail.
  ///
  /// In vi, this message translates to:
  /// **'Không ghi triệu chứng được'**
  String get serviceHealthSymptomFail;

  /// No description provided for @serviceHealthMetricFail.
  ///
  /// In vi, this message translates to:
  /// **'Không ghi chỉ số sức khoẻ được'**
  String get serviceHealthMetricFail;

  /// No description provided for @serviceHealthEmergencyFail.
  ///
  /// In vi, this message translates to:
  /// **'Không gửi được cảnh báo khẩn cấp'**
  String get serviceHealthEmergencyFail;

  /// No description provided for @serviceHealthRatingFail.
  ///
  /// In vi, this message translates to:
  /// **'Không đánh giá được tình nguyện viên'**
  String get serviceHealthRatingFail;

  /// No description provided for @serviceHealthLoadMedFail.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được lịch thuốc'**
  String get serviceHealthLoadMedFail;

  /// No description provided for @serviceHealthLoadApptFail.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được lịch hẹn'**
  String get serviceHealthLoadApptFail;

  /// No description provided for @serviceHealthLoadLogFail.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được nhật ký sức khỏe'**
  String get serviceHealthLoadLogFail;

  /// No description provided for @serviceLocationGpsOff.
  ///
  /// In vi, this message translates to:
  /// **'GPS đang tắt. Hãy bật định vị.'**
  String get serviceLocationGpsOff;

  /// No description provided for @serviceLocationDenied.
  ///
  /// In vi, this message translates to:
  /// **'Quyền vị trí đã bị từ chối vĩnh viễn. Hãy bật trong Cài đặt.'**
  String get serviceLocationDenied;

  /// No description provided for @serviceUploadTooBig.
  ///
  /// In vi, this message translates to:
  /// **'File quá lớn, tối đa 10MB'**
  String get serviceUploadTooBig;

  /// No description provided for @serviceUploadBadFormat.
  ///
  /// In vi, this message translates to:
  /// **'Định dạng không được hỗ trợ: {mime}'**
  String serviceUploadBadFormat(Object mime);

  /// No description provided for @serviceUploadNoUrl.
  ///
  /// In vi, this message translates to:
  /// **'Upload thành công nhưng không có URL'**
  String get serviceUploadNoUrl;

  /// No description provided for @serviceUploadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Upload thất bại'**
  String get serviceUploadFailed;

  /// No description provided for @serviceUploadHttpFail.
  ///
  /// In vi, this message translates to:
  /// **'Upload thất bại (HTTP {code})'**
  String serviceUploadHttpFail(Object code);

  /// No description provided for @serviceAuthBadResponse.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi máy chủ không hợp lệ (thiếu token)'**
  String get serviceAuthBadResponse;

  /// No description provided for @serviceAuthLoginFail.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập máy chủ thất bại'**
  String get serviceAuthLoginFail;

  /// No description provided for @serviceAuthProfileFail.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được hồ sơ'**
  String get serviceAuthProfileFail;

  /// No description provided for @serviceAuthSessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên hết hạn, vui lòng đăng nhập lại'**
  String get serviceAuthSessionExpired;

  /// No description provided for @serviceCallCreateFail.
  ///
  /// In vi, this message translates to:
  /// **'Không tạo được cuộc gọi'**
  String get serviceCallCreateFail;

  /// No description provided for @serviceCallEndFail.
  ///
  /// In vi, this message translates to:
  /// **'Không kết thúc được cuộc gọi'**
  String get serviceCallEndFail;

  /// No description provided for @serviceCallInvalidResponse.
  ///
  /// In vi, this message translates to:
  /// **'Phản hồi không hợp lệ'**
  String get serviceCallInvalidResponse;

  /// No description provided for @serviceCameraNoPermission.
  ///
  /// In vi, this message translates to:
  /// **'Cần quyền camera để trợ lý nhìn được.'**
  String get serviceCameraNoPermission;

  /// No description provided for @serviceCameraUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không có camera khả dụng.'**
  String get serviceCameraUnavailable;

  /// No description provided for @dashboardVoiceCall.
  ///
  /// In vi, this message translates to:
  /// **'Gọi điện thoại'**
  String get dashboardVoiceCall;

  /// No description provided for @dashboardVideoCall.
  ///
  /// In vi, this message translates to:
  /// **'Gọi video'**
  String get dashboardVideoCall;

  /// No description provided for @dashboardSendChat.
  ///
  /// In vi, this message translates to:
  /// **'Gửi tin nhắn'**
  String get dashboardSendChat;

  /// No description provided for @dashboardEmergencySOS.
  ///
  /// In vi, this message translates to:
  /// **'SOS khẩn cấp'**
  String get dashboardEmergencySOS;

  /// No description provided for @dashboardEscalateFamily.
  ///
  /// In vi, this message translates to:
  /// **'Gọi người thân'**
  String get dashboardEscalateFamily;

  /// No description provided for @dashboardEscalateVolunteer.
  ///
  /// In vi, this message translates to:
  /// **'Gọi tình nguyện viên'**
  String get dashboardEscalateVolunteer;

  /// No description provided for @dashboardSetMedication.
  ///
  /// In vi, this message translates to:
  /// **'Đặt nhắc thuốc'**
  String get dashboardSetMedication;

  /// No description provided for @dashboardMarkMedicationTaken.
  ///
  /// In vi, this message translates to:
  /// **'Đã uống thuốc'**
  String get dashboardMarkMedicationTaken;

  /// No description provided for @dashboardMarkMedicationSkipped.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua thuốc'**
  String get dashboardMarkMedicationSkipped;

  /// No description provided for @dashboardLogSymptom.
  ///
  /// In vi, this message translates to:
  /// **'Ghi triệu chứng'**
  String get dashboardLogSymptom;

  /// No description provided for @dashboardLogMetric.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chỉ số'**
  String get dashboardLogMetric;

  /// No description provided for @dashboardSetAppointment.
  ///
  /// In vi, this message translates to:
  /// **'Đặt lịch hẹn'**
  String get dashboardSetAppointment;

  /// No description provided for @dashboardPlayMusic.
  ///
  /// In vi, this message translates to:
  /// **'Phát nhạc'**
  String get dashboardPlayMusic;

  /// No description provided for @dashboardNavigate.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ đường'**
  String get dashboardNavigate;

  /// No description provided for @dashboardFamilyCreateMed.
  ///
  /// In vi, this message translates to:
  /// **'Người thân thêm thuốc'**
  String get dashboardFamilyCreateMed;

  /// No description provided for @dashboardFamilyUpdateMed.
  ///
  /// In vi, this message translates to:
  /// **'Người thân sửa thuốc'**
  String get dashboardFamilyUpdateMed;

  /// No description provided for @dashboardFamilyDeleteMed.
  ///
  /// In vi, this message translates to:
  /// **'Người thân xóa thuốc'**
  String get dashboardFamilyDeleteMed;

  /// No description provided for @dashboardCareExportPdf.
  ///
  /// In vi, this message translates to:
  /// **'Xuất báo cáo chăm sóc'**
  String get dashboardCareExportPdf;

  /// No description provided for @dashboardNoDetail.
  ///
  /// In vi, this message translates to:
  /// **'Không có thêm chi tiết trong nhật ký.'**
  String get dashboardNoDetail;

  /// No description provided for @billingPlanStoreManaged.
  ///
  /// In vi, this message translates to:
  /// **'Gói được quản lý theo cửa hàng ứng dụng.'**
  String get billingPlanStoreManaged;

  /// No description provided for @callerUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Người gọi'**
  String get callerUnknown;

  /// No description provided for @reminderTestTitle.
  ///
  /// In vi, this message translates to:
  /// **'Test nhắc nhở'**
  String get reminderTestTitle;

  /// No description provided for @reminderTestBody.
  ///
  /// In vi, this message translates to:
  /// **'Nếu bạn thấy thông báo này, notification hoạt động!'**
  String get reminderTestBody;

  /// No description provided for @reminderMedicationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc uống thuốc'**
  String get reminderMedicationTitle;

  /// No description provided for @reminderAppointmentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch hẹn sắp tới'**
  String get reminderAppointmentTitle;

  /// No description provided for @reminderChannelName.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc nhở AiSee'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc nhở uống thuốc và lịch hẹn'**
  String get reminderChannelDesc;

  /// No description provided for @foregroundChannelName.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý AiSee'**
  String get foregroundChannelName;

  /// No description provided for @foregroundChannelDesc.
  ///
  /// In vi, this message translates to:
  /// **'Giữ kết nối khi màn hình tắt.'**
  String get foregroundChannelDesc;

  /// No description provided for @foregroundNotificationTitle.
  ///
  /// In vi, this message translates to:
  /// **'AiSee đang hoạt động'**
  String get foregroundNotificationTitle;

  /// No description provided for @foregroundNotificationText.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý giọng nói đang bật — chạm để mở app'**
  String get foregroundNotificationText;

  /// No description provided for @messageSenderFamily.
  ///
  /// In vi, this message translates to:
  /// **'Người thân'**
  String get messageSenderFamily;

  /// No description provided for @messageSentImage.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi một hình ảnh'**
  String get messageSentImage;

  /// No description provided for @messageSentVoice.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi tin nhắn thoại'**
  String get messageSentVoice;

  /// No description provided for @messageNew.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn mới'**
  String get messageNew;

  /// No description provided for @bootstrapLoadingApp.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải ứng dụng…'**
  String get bootstrapLoadingApp;

  /// No description provided for @bootstrapCheckingSession.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra phiên đăng nhập…'**
  String get bootstrapCheckingSession;

  /// No description provided for @permissionBootstrapTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đang chuẩn bị quyền truy cập…'**
  String get permissionBootstrapTitle;

  /// No description provided for @familyMedicationEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch'**
  String get familyMedicationEmpty;

  /// No description provided for @healthOverviewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get healthOverviewTitle;

  /// No description provided for @healthTakenToday.
  ///
  /// In vi, this message translates to:
  /// **'Đã uống hôm nay'**
  String get healthTakenToday;

  /// No description provided for @healthSymptoms.
  ///
  /// In vi, this message translates to:
  /// **'Triệu chứng'**
  String get healthSymptoms;

  /// No description provided for @healthMetrics.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ số'**
  String get healthMetrics;

  /// No description provided for @healthTaken.
  ///
  /// In vi, this message translates to:
  /// **'Đã uống'**
  String get healthTaken;

  /// No description provided for @supporterLabel.
  ///
  /// In vi, this message translates to:
  /// **'Người hỗ trợ'**
  String get supporterLabel;

  /// No description provided for @appBillingFreePlan.
  ///
  /// In vi, this message translates to:
  /// **'Miễn phí'**
  String get appBillingFreePlan;

  /// No description provided for @familyCareApiError.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi'**
  String get familyCareApiError;

  /// No description provided for @familyDashboardHealthTabLabel.
  ///
  /// In vi, this message translates to:
  /// **'Sức khỏe'**
  String get familyDashboardHealthTabLabel;

  /// No description provided for @familyDashboardContactTabLabel.
  ///
  /// In vi, this message translates to:
  /// **'Liên lạc'**
  String get familyDashboardContactTabLabel;

  /// No description provided for @familyDashboardCareTabLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chăm sóc'**
  String get familyDashboardCareTabLabel;

  /// No description provided for @careTimelineTitle.
  ///
  /// In vi, this message translates to:
  /// **'Timeline chăm sóc'**
  String get careTimelineTitle;

  /// No description provided for @careTimelineFallback.
  ///
  /// In vi, this message translates to:
  /// **'Timeline'**
  String get careTimelineFallback;

  /// No description provided for @careTimelinePlanHint.
  ///
  /// In vi, this message translates to:
  /// **'Theo gói hiện tại, bạn đang xem {effectiveDays} ngày gần nhất (yêu cầu {requestedDays} ngày).'**
  String careTimelinePlanHint(Object effectiveDays, Object requestedDays);

  /// No description provided for @careTimelineEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có sự kiện trong cửa sổ này.'**
  String get careTimelineEmpty;

  /// No description provided for @careDailyBriefTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt ngày'**
  String get careDailyBriefTitle;

  /// No description provided for @careDailyBriefDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {date}'**
  String careDailyBriefDate(Object date);

  /// No description provided for @careWeeklyReportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo tuần'**
  String get careWeeklyReportTitle;

  /// No description provided for @careWeeklyReportPickEnd.
  ///
  /// In vi, this message translates to:
  /// **'Cuối tuần'**
  String get careWeeklyReportPickEnd;

  /// No description provided for @careIncidentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sự cố / SOS'**
  String get careIncidentTitle;

  /// No description provided for @careIncidentAlertTime.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo: {time}'**
  String careIncidentAlertTime(Object time);

  /// No description provided for @careIncidentLocation.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí: {lat}, {lng}'**
  String careIncidentLocation(Object lat, Object lng);

  /// No description provided for @careIncidentTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời điểm: {time}'**
  String careIncidentTime(Object time);

  /// No description provided for @careIncidentFamilyNotified.
  ///
  /// In vi, this message translates to:
  /// **'Đã báo người thân: {notified}'**
  String careIncidentFamilyNotified(Object notified);

  /// No description provided for @careExportCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép'**
  String get careExportCopied;

  /// No description provided for @careExportCopyAction.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get careExportCopyAction;

  /// No description provided for @careExportClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get careExportClose;

  /// No description provided for @careExportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xuất báo cáo (định dạng tạm)'**
  String get careExportTitle;

  /// No description provided for @careExportFormat.
  ///
  /// In vi, this message translates to:
  /// **'Định dạng: {format}\nMã xuất: {id}\n\n'**
  String careExportFormat(Object format, Object id);

  /// No description provided for @careExportNoData.
  ///
  /// In vi, this message translates to:
  /// **'(Không có dữ liệu kèm)'**
  String get careExportNoData;

  /// No description provided for @careExportFallback.
  ///
  /// In vi, this message translates to:
  /// **'Xuất báo cáo'**
  String get careExportFallback;

  /// No description provided for @careTotalsOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get careTotalsOverview;

  /// No description provided for @careTotalsActiveMeds.
  ///
  /// In vi, this message translates to:
  /// **'Thuốc đang dùng: {count}'**
  String careTotalsActiveMeds(Object count);

  /// No description provided for @careTotalsTakenSkipped.
  ///
  /// In vi, this message translates to:
  /// **'Đã uống: {taken}, bỏ qua: {skipped}'**
  String careTotalsTakenSkipped(Object skipped, Object taken);

  /// No description provided for @careTotalsSymptoms.
  ///
  /// In vi, this message translates to:
  /// **'Triệu chứng: {symptoms}, chỉ số: {metrics}'**
  String careTotalsSymptoms(Object metrics, Object symptoms);

  /// No description provided for @careTotalsSOS.
  ///
  /// In vi, this message translates to:
  /// **'SOS: {sos}, leo thang: {escalations}'**
  String careTotalsSOS(Object escalations, Object sos);

  /// No description provided for @careTotalsCalls.
  ///
  /// In vi, this message translates to:
  /// **'Gọi video: {videoCount} ({videoMin} phút), thoại: {voiceMin} phút'**
  String careTotalsCalls(Object videoCount, Object videoMin, Object voiceMin);

  /// No description provided for @careBillingSheetViewPlan.
  ///
  /// In vi, this message translates to:
  /// **'Xem gói và nâng cấp'**
  String get careBillingSheetViewPlan;

  /// No description provided for @careBillingQuotaRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại: {remaining}'**
  String careBillingQuotaRemaining(Object remaining);

  /// No description provided for @careBillingQuotaExhausted.
  ///
  /// In vi, this message translates to:
  /// **'Đã hết quota'**
  String get careBillingQuotaExhausted;

  /// No description provided for @careBillingFallbackTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thực hiện được'**
  String get careBillingFallbackTitle;

  /// No description provided for @careViewPlanAction.
  ///
  /// In vi, this message translates to:
  /// **'Xem gói'**
  String get careViewPlanAction;

  /// No description provided for @familyMessagesCallFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tạo được cuộc gọi'**
  String get familyMessagesCallFailed;

  /// No description provided for @familyMessagesRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get familyMessagesRetry;

  /// No description provided for @familyMessagesEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có người thân để nhắn tin'**
  String get familyMessagesEmpty;

  /// No description provided for @familyMessagesTapToChat.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để nhắn tin'**
  String get familyMessagesTapToChat;

  /// No description provided for @familyMessagesVoiceCall.
  ///
  /// In vi, this message translates to:
  /// **'Gọi thoại {label}'**
  String familyMessagesVoiceCall(Object label);

  /// No description provided for @familyMessagesVoiceCallTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Gọi thoại'**
  String get familyMessagesVoiceCallTooltip;

  /// No description provided for @familyMessagesVideoCall.
  ///
  /// In vi, this message translates to:
  /// **'Gọi video {label}'**
  String familyMessagesVideoCall(Object label);

  /// No description provided for @familyMessagesVideoCallTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Gọi video'**
  String get familyMessagesVideoCallTooltip;

  /// No description provided for @careWidgetOverviewTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan ngày {date}'**
  String careWidgetOverviewTitle(Object date);

  /// No description provided for @careWidgetDataTable.
  ///
  /// In vi, this message translates to:
  /// **'Bảng số liệu'**
  String get careWidgetDataTable;

  /// No description provided for @careWidgetCategoryCol.
  ///
  /// In vi, this message translates to:
  /// **'Hạng mục'**
  String get careWidgetCategoryCol;

  /// No description provided for @careWidgetValueCol.
  ///
  /// In vi, this message translates to:
  /// **'Giá trị'**
  String get careWidgetValueCol;

  /// No description provided for @careWidgetActiveMeds.
  ///
  /// In vi, this message translates to:
  /// **'Thuốc đang dùng'**
  String get careWidgetActiveMeds;

  /// No description provided for @careWidgetDosesTaken.
  ///
  /// In vi, this message translates to:
  /// **'Liều đã uống'**
  String get careWidgetDosesTaken;

  /// No description provided for @careWidgetDosesSkipped.
  ///
  /// In vi, this message translates to:
  /// **'Liều bỏ qua'**
  String get careWidgetDosesSkipped;

  /// No description provided for @careWidgetSymptomLogs.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận triệu chứng'**
  String get careWidgetSymptomLogs;

  /// No description provided for @careWidgetMetricLogs.
  ///
  /// In vi, this message translates to:
  /// **'Ghi nhận chỉ số'**
  String get careWidgetMetricLogs;

  /// No description provided for @careWidgetSOSEvents.
  ///
  /// In vi, this message translates to:
  /// **'Sự kiện SOS'**
  String get careWidgetSOSEvents;

  /// No description provided for @careWidgetEscalations.
  ///
  /// In vi, this message translates to:
  /// **'Leo thang / liên hệ'**
  String get careWidgetEscalations;

  /// No description provided for @careWidgetVideoCalls.
  ///
  /// In vi, this message translates to:
  /// **'Cuộc gọi video'**
  String get careWidgetVideoCalls;

  /// No description provided for @careWidgetVideoCallMinutes.
  ///
  /// In vi, this message translates to:
  /// **'Phút gọi video'**
  String get careWidgetVideoCallMinutes;

  /// No description provided for @careWidgetVoiceCallMinutes.
  ///
  /// In vi, this message translates to:
  /// **'Phút gọi thoại'**
  String get careWidgetVoiceCallMinutes;

  /// No description provided for @careWidgetAutoNotes.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú tự động'**
  String get careWidgetAutoNotes;

  /// No description provided for @careWidgetWebReportsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo và dòng thời gian (web)'**
  String get careWidgetWebReportsTitle;

  /// No description provided for @careWidgetWebReportsHint.
  ///
  /// In vi, this message translates to:
  /// **'Mở trên trình duyệt — cấu hình CARE_WEB_BASE_URL nếu cần.'**
  String get careWidgetWebReportsHint;

  /// No description provided for @careWidgetBrowserError.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được trình duyệt'**
  String get careWidgetBrowserError;

  /// No description provided for @careAlertSeen.
  ///
  /// In vi, this message translates to:
  /// **'Đã xem'**
  String get careAlertSeen;

  /// No description provided for @careAlertClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get careAlertClose;

  /// No description provided for @careAlertSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get careAlertSkip;

  /// No description provided for @careTaskColumnTask.
  ///
  /// In vi, this message translates to:
  /// **'Việc cần làm'**
  String get careTaskColumnTask;

  /// No description provided for @careTaskColumnDue.
  ///
  /// In vi, this message translates to:
  /// **'Hạn'**
  String get careTaskColumnDue;

  /// No description provided for @careTaskColumnStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get careTaskColumnStatus;

  /// No description provided for @careTaskColumnAction.
  ///
  /// In vi, this message translates to:
  /// **''**
  String get careTaskColumnAction;

  /// No description provided for @careTaskDone.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get careTaskDone;

  /// No description provided for @careWebTimeline.
  ///
  /// In vi, this message translates to:
  /// **'Timeline'**
  String get careWebTimeline;

  /// No description provided for @careWebWeekly.
  ///
  /// In vi, this message translates to:
  /// **'Tuần'**
  String get careWebWeekly;

  /// No description provided for @careWebIncident.
  ///
  /// In vi, this message translates to:
  /// **'Sự cố'**
  String get careWebIncident;

  /// No description provided for @careWebExport.
  ///
  /// In vi, this message translates to:
  /// **'Xuất dữ liệu'**
  String get careWebExport;

  /// No description provided for @dashboardAuditEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hoạt động nào trong nhật ký.'**
  String get dashboardAuditEmpty;

  /// No description provided for @dashboardAuditTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian: {time}'**
  String dashboardAuditTime(Object time);

  /// No description provided for @dashboardAuditDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết: {details}'**
  String dashboardAuditDetails(Object details);

  /// No description provided for @dashboardAuditResult.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả: {result}'**
  String dashboardAuditResult(Object result);

  /// No description provided for @dashboardClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get dashboardClose;

  /// No description provided for @dashboardHealthTitle.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi sức khỏe'**
  String get dashboardHealthTitle;

  /// No description provided for @dashboardHealthSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Thuốc trong ngày, triệu chứng và chỉ số gần nhất.'**
  String get dashboardHealthSubtitle;

  /// No description provided for @dashboardHealthNoData.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu'**
  String get dashboardHealthNoData;

  /// No description provided for @dashboardHealthPullToRefresh.
  ///
  /// In vi, this message translates to:
  /// **'Kéo xuống để tải lại.'**
  String get dashboardHealthPullToRefresh;

  /// No description provided for @dashboardHealthMedsToday.
  ///
  /// In vi, this message translates to:
  /// **'Thuốc hôm nay'**
  String get dashboardHealthMedsToday;

  /// No description provided for @dashboardHealthNoMeds.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thuốc nào'**
  String get dashboardHealthNoMeds;

  /// No description provided for @dashboardHealthRecentSymptoms.
  ///
  /// In vi, this message translates to:
  /// **'Triệu chứng gần đây'**
  String get dashboardHealthRecentSymptoms;

  /// No description provided for @dashboardHealthNoSymptoms.
  ///
  /// In vi, this message translates to:
  /// **'Không có triệu chứng'**
  String get dashboardHealthNoSymptoms;

  /// No description provided for @dashboardHealthMetrics.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ số sức khỏe'**
  String get dashboardHealthMetrics;

  /// No description provided for @dashboardHealthNoMetrics.
  ///
  /// In vi, this message translates to:
  /// **'Không có chỉ số'**
  String get dashboardHealthNoMetrics;

  /// No description provided for @dashboardHealthOverview.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get dashboardHealthOverview;

  /// No description provided for @dashboardHealthTakenToday.
  ///
  /// In vi, this message translates to:
  /// **'Đã uống hôm nay'**
  String get dashboardHealthTakenToday;

  /// No description provided for @dashboardHealthNotTaken.
  ///
  /// In vi, this message translates to:
  /// **'Chưa uống'**
  String get dashboardHealthNotTaken;

  /// No description provided for @dashboardHealthSymptoms.
  ///
  /// In vi, this message translates to:
  /// **'Triệu chứng'**
  String get dashboardHealthSymptoms;

  /// No description provided for @dashboardHealthMetricsPill.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ số'**
  String get dashboardHealthMetricsPill;

  /// No description provided for @dashboardHealthTakenStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã uống'**
  String get dashboardHealthTakenStatus;

  /// No description provided for @dashboardHealthNotTakenStatus.
  ///
  /// In vi, this message translates to:
  /// **'Chưa uống'**
  String get dashboardHealthNotTakenStatus;

  /// No description provided for @dashboardHealthOverviewChartLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan sức khỏe'**
  String get dashboardHealthOverviewChartLabel;

  /// No description provided for @dashboardLocationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí người thân'**
  String get dashboardLocationTitle;

  /// No description provided for @dashboardLocationSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem nhanh trên bản đồ Mapbox (ảnh tĩnh). Chạm nút bên dưới để mở Google Maps.'**
  String get dashboardLocationSubtitle;

  /// No description provided for @dashboardLocationNoLocation.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có vị trí'**
  String get dashboardLocationNoLocation;

  /// No description provided for @dashboardLocationPullHint.
  ///
  /// In vi, this message translates to:
  /// **'Kéo xuống để thử tải lại.'**
  String get dashboardLocationPullHint;

  /// No description provided for @dashboardLocationCoordinates.
  ///
  /// In vi, this message translates to:
  /// **'Tọa độ'**
  String get dashboardLocationCoordinates;

  /// No description provided for @dashboardLocationUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật: {time}'**
  String dashboardLocationUpdated(Object time);

  /// No description provided for @dashboardLocationOpenMaps.
  ///
  /// In vi, this message translates to:
  /// **'Mở Google Maps'**
  String get dashboardLocationOpenMaps;

  /// No description provided for @dashboardLocationMapSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ Mapbox, ghim tại vị trí người thân'**
  String get dashboardLocationMapSemantics;

  /// No description provided for @dashboardLocationMapboxMissing.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cấu hình Mapbox'**
  String get dashboardLocationMapboxMissing;

  /// No description provided for @dashboardLocationMapboxHint.
  ///
  /// In vi, this message translates to:
  /// **'Thêm MAPBOX_ACCESS_TOKEN (pk.*) vào assets/app_config.env hoặc --dart-define=MAPBOX_ACCESS_TOKEN=... rồi chạy lại app.'**
  String get dashboardLocationMapboxHint;

  /// No description provided for @dashboardLocationMapError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được bản đồ. Kiểm tra mạng hoặc token Mapbox.'**
  String get dashboardLocationMapError;

  /// No description provided for @dashboardMedsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thuốc nào'**
  String get dashboardMedsEmpty;

  /// No description provided for @dashboardMedsEdit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get dashboardMedsEdit;

  /// No description provided for @dashboardMedsDelete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get dashboardMedsDelete;

  /// No description provided for @dashboardMedFormAddTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thuốc'**
  String get dashboardMedFormAddTitle;

  /// No description provided for @dashboardMedFormEditTitle.
  ///
  /// In vi, this message translates to:
  /// **'Sửa thuốc'**
  String get dashboardMedFormEditTitle;

  /// No description provided for @dashboardMedFormNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên thuốc'**
  String get dashboardMedFormNameLabel;

  /// No description provided for @dashboardMedFormNameHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: Paracetamol'**
  String get dashboardMedFormNameHint;

  /// No description provided for @dashboardMedFormDosageLabel.
  ///
  /// In vi, this message translates to:
  /// **'Liều lượng'**
  String get dashboardMedFormDosageLabel;

  /// No description provided for @dashboardMedFormDosageHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: 1 viên'**
  String get dashboardMedFormDosageHint;

  /// No description provided for @dashboardMedFormTimesLabel.
  ///
  /// In vi, this message translates to:
  /// **'Giờ uống'**
  String get dashboardMedFormTimesLabel;

  /// No description provided for @dashboardMedFormTimesHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: 07:00, 21:00'**
  String get dashboardMedFormTimesHint;

  /// No description provided for @dashboardMedFormFreqLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tần suất'**
  String get dashboardMedFormFreqLabel;

  /// No description provided for @dashboardMedFormFreqHint.
  ///
  /// In vi, this message translates to:
  /// **'VD: daily'**
  String get dashboardMedFormFreqHint;

  /// No description provided for @dashboardMedFormCancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get dashboardMedFormCancel;

  /// No description provided for @dashboardMedFormSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get dashboardMedFormSave;

  /// No description provided for @careReportBarMedsActive.
  ///
  /// In vi, this message translates to:
  /// **'Thuốc BK'**
  String get careReportBarMedsActive;

  /// No description provided for @careReportBarTaken.
  ///
  /// In vi, this message translates to:
  /// **'Đã uống'**
  String get careReportBarTaken;

  /// No description provided for @careReportBarSkipped.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get careReportBarSkipped;

  /// No description provided for @careReportBarSymptoms.
  ///
  /// In vi, this message translates to:
  /// **'Triệu chứng'**
  String get careReportBarSymptoms;

  /// No description provided for @careReportBarMetrics.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ số'**
  String get careReportBarMetrics;

  /// No description provided for @careReportBarSOS.
  ///
  /// In vi, this message translates to:
  /// **'SOS'**
  String get careReportBarSOS;

  /// No description provided for @careReportChartLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt ngày'**
  String get careReportChartLabel;

  /// No description provided for @careAlertPillLevel.
  ///
  /// In vi, this message translates to:
  /// **'Mức'**
  String get careAlertPillLevel;

  /// No description provided for @careAlertPillStatus.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get careAlertPillStatus;

  /// No description provided for @careAlertPillCode.
  ///
  /// In vi, this message translates to:
  /// **'Mã'**
  String get careAlertPillCode;

  /// No description provided for @careAlertPillTime.
  ///
  /// In vi, this message translates to:
  /// **'Lúc'**
  String get careAlertPillTime;

  /// No description provided for @callMicOff.
  ///
  /// In vi, this message translates to:
  /// **'Tắt mic'**
  String get callMicOff;

  /// No description provided for @callMicOn.
  ///
  /// In vi, this message translates to:
  /// **'Bật mic'**
  String get callMicOn;

  /// No description provided for @callSpeakerOff.
  ///
  /// In vi, this message translates to:
  /// **'Tắt loa'**
  String get callSpeakerOff;

  /// No description provided for @callSpeakerOn.
  ///
  /// In vi, this message translates to:
  /// **'Bật loa'**
  String get callSpeakerOn;

  /// No description provided for @callEnd.
  ///
  /// In vi, this message translates to:
  /// **'Kết thúc cuộc gọi'**
  String get callEnd;

  /// No description provided for @callCameraOff.
  ///
  /// In vi, this message translates to:
  /// **'Tắt camera'**
  String get callCameraOff;

  /// No description provided for @callCameraOn.
  ///
  /// In vi, this message translates to:
  /// **'Bật camera'**
  String get callCameraOn;

  /// No description provided for @callDialing.
  ///
  /// In vi, this message translates to:
  /// **'Đang gọi…'**
  String get callDialing;

  /// No description provided for @callEnded.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết thúc'**
  String get callEnded;

  /// No description provided for @familyContactsCaredUser.
  ///
  /// In vi, this message translates to:
  /// **'Người bệnh'**
  String get familyContactsCaredUser;

  /// No description provided for @familyContactsFamilyMember.
  ///
  /// In vi, this message translates to:
  /// **'Người nhà'**
  String get familyContactsFamilyMember;

  /// No description provided for @familyContactsCreateInviteCode.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mã mời 6 số'**
  String get familyContactsCreateInviteCode;

  /// No description provided for @familyContactsTransferOwnership.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển quyền'**
  String get familyContactsTransferOwnership;

  /// No description provided for @familyContactsLeaveGroup.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm'**
  String get familyContactsLeaveGroup;

  /// No description provided for @familyContactsGroupOwner.
  ///
  /// In vi, this message translates to:
  /// **'Chủ nhóm'**
  String get familyContactsGroupOwner;

  /// No description provided for @familyContactsLeftGroup.
  ///
  /// In vi, this message translates to:
  /// **'Đã rời nhóm chăm sóc'**
  String get familyContactsLeftGroup;

  /// No description provided for @familyContactsOwnershipTransferred.
  ///
  /// In vi, this message translates to:
  /// **'Đã chuyển quyền chủ nhóm cho {target}'**
  String familyContactsOwnershipTransferred(String target);

  /// No description provided for @familyContactsCreateCareGroup.
  ///
  /// In vi, this message translates to:
  /// **'Tạo nhóm chăm sóc'**
  String get familyContactsCreateCareGroup;

  /// No description provided for @familyContactsCreateCodeToInvite.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mã mời 6 số để mời người bệnh hoặc người nhà vào nhóm của bạn'**
  String get familyContactsCreateCodeToInvite;

  /// No description provided for @familyContactsCodeCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã mời'**
  String get familyContactsCodeCopied;

  /// No description provided for @familyContactsNoOtherMember.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có người nhà khác trong nhóm để chuyển quyền.'**
  String get familyContactsNoOtherMember;

  /// No description provided for @familyContactsTransferOwnershipTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển quyền chủ nhóm'**
  String get familyContactsTransferOwnershipTitle;

  /// No description provided for @familyContactsSelectNewOwner.
  ///
  /// In vi, this message translates to:
  /// **'Chọn người nhà sẽ tiếp tục mời thành viên mới và quản lý subscription của nhóm.'**
  String get familyContactsSelectNewOwner;

  /// No description provided for @familyContactsInviteCodeSent.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời 6 số'**
  String get familyContactsInviteCodeSent;

  /// No description provided for @familyContactsNoCaredUsers.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có người bệnh nào trong nhóm. Tạo mã mời để thêm người bệnh hoặc người nhà khác.'**
  String get familyContactsNoCaredUsers;

  /// No description provided for @familyContactsCaredUsersSection.
  ///
  /// In vi, this message translates to:
  /// **'Người bệnh trong nhóm'**
  String get familyContactsCaredUsersSection;

  /// No description provided for @familyContactsFamilyMembersSection.
  ///
  /// In vi, this message translates to:
  /// **'Người nhà trong nhóm'**
  String get familyContactsFamilyMembersSection;

  /// No description provided for @familyContactsYouAreOwner.
  ///
  /// In vi, this message translates to:
  /// **'Bạn là chủ nhóm'**
  String get familyContactsYouAreOwner;

  /// No description provided for @familyContactsOnlyOwnerWarning.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chủ nhóm mới được tạo mã mời và quản lý subscription của cả nhóm.'**
  String get familyContactsOnlyOwnerWarning;

  /// No description provided for @familyContactsTapForInfo.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để xem thông tin'**
  String get familyContactsTapForInfo;

  /// No description provided for @familyContactsSessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập hết hạn. Hãy đăng xuất và đăng nhập lại.'**
  String get familyContactsSessionExpired;

  /// No description provided for @familyContactsLeaveBeforeTransfer.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển quyền trước khi rời nhóm'**
  String get familyContactsLeaveBeforeTransfer;

  /// No description provided for @familyContactsLeaveGroupTitle.
  ///
  /// In vi, this message translates to:
  /// **'Rời nhóm chăm sóc'**
  String get familyContactsLeaveGroupTitle;

  /// No description provided for @familyContactsLeaveBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang là chủ nhóm. Hãy chuyển quyền cho một người nhà khác trước, rồi mới rời nhóm.'**
  String get familyContactsLeaveBody;

  /// No description provided for @familyContactsLeaveConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ rời nhóm chăm sóc hiện tại. Muốn vào nhóm khác, bạn sẽ dùng mã mời mới sau khi rời nhóm.'**
  String get familyContactsLeaveConfirmBody;

  /// No description provided for @familyContactsCannotLeave.
  ///
  /// In vi, this message translates to:
  /// **'Hãy mời hoặc chờ thêm một người nhà khác trước khi chuyển quyền và rời nhóm.'**
  String get familyContactsCannotLeave;

  /// No description provided for @familyContactsCopyCode.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã'**
  String get familyContactsCopyCode;

  /// No description provided for @familyDashboardMedsTabLabel.
  ///
  /// In vi, this message translates to:
  /// **'Thuốc'**
  String get familyDashboardMedsTabLabel;

  /// No description provided for @familyDashboardAuditTabLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động'**
  String get familyDashboardAuditTabLabel;

  /// No description provided for @familyDashboardLocationTabLabel.
  ///
  /// In vi, this message translates to:
  /// **'Vị trí'**
  String get familyDashboardLocationTabLabel;

  /// No description provided for @remindersLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được dữ liệu.'**
  String get remindersLoadFailed;

  /// No description provided for @remindersRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get remindersRetry;

  /// No description provided for @remindersMedication.
  ///
  /// In vi, this message translates to:
  /// **'Thuốc'**
  String get remindersMedication;

  /// No description provided for @remindersEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có nhắc nhở nào.\nThêm thuốc từ tab Cá nhân.'**
  String get remindersEmpty;

  /// No description provided for @remindersTaken.
  ///
  /// In vi, this message translates to:
  /// **'✓ Đã uống'**
  String get remindersTaken;

  /// No description provided for @remindersSkipped.
  ///
  /// In vi, this message translates to:
  /// **'✗ Bỏ qua'**
  String get remindersSkipped;

  /// No description provided for @remindersTakenStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã uống'**
  String get remindersTakenStatus;

  /// No description provided for @remindersSkippedStatus.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get remindersSkippedStatus;

  /// No description provided for @remindersDeletePrompt.
  ///
  /// In vi, this message translates to:
  /// **'Xoá nhắc nhở'**
  String get remindersDeletePrompt;

  /// No description provided for @remindersDetailSemantics.
  ///
  /// In vi, this message translates to:
  /// **'{title}. {subtitle}. Chạm để xem chi tiết.'**
  String remindersDetailSemantics(String title, String subtitle);

  /// No description provided for @sponsorsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhà tài trợ'**
  String get sponsorsTitle;

  /// No description provided for @sponsorsOpenWebsite.
  ///
  /// In vi, this message translates to:
  /// **'Mở website'**
  String get sponsorsOpenWebsite;

  /// No description provided for @sponsorsOpenDavo.
  ///
  /// In vi, this message translates to:
  /// **'Mở website DAVO'**
  String get sponsorsOpenDavo;

  /// No description provided for @sponsorsCannotOpen.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được website nhà tài trợ.'**
  String get sponsorsCannotOpen;

  /// No description provided for @familyDashboardCancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get familyDashboardCancel;

  /// No description provided for @familyDashboardMedDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá {name}'**
  String familyDashboardMedDeleted(String name);

  /// No description provided for @familyDashboardMedAdded.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm thuốc'**
  String get familyDashboardMedAdded;

  /// No description provided for @familyDashboardMedUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật thuốc'**
  String get familyDashboardMedUpdated;

  /// No description provided for @familyDashboardCannotOpenMaps.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được Google Maps.'**
  String get familyDashboardCannotOpenMaps;

  /// No description provided for @familyDashboardCannotOpenAppMaps.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được bản đồ.'**
  String get familyDashboardCannotOpenAppMaps;

  /// No description provided for @subscriptionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Gói AiSee'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get subscriptionRetry;

  /// No description provided for @subscriptionCurrentPlan.
  ///
  /// In vi, this message translates to:
  /// **'Gói hiện tại'**
  String get subscriptionCurrentPlan;

  /// No description provided for @subscriptionUsing.
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng'**
  String get subscriptionUsing;

  /// No description provided for @subscriptionSuitable.
  ///
  /// In vi, this message translates to:
  /// **'Phù hợp'**
  String get subscriptionSuitable;

  /// No description provided for @subscriptionFree.
  ///
  /// In vi, this message translates to:
  /// **'Miễn phí'**
  String get subscriptionFree;

  /// No description provided for @subscriptionViewPlansToBuy.
  ///
  /// In vi, this message translates to:
  /// **'Xem gói để mua'**
  String get subscriptionViewPlansToBuy;

  /// No description provided for @subscriptionViewSuitablePlans.
  ///
  /// In vi, this message translates to:
  /// **'Xem gói phù hợp'**
  String get subscriptionViewSuitablePlans;

  /// No description provided for @subscriptionChooseCarePlan.
  ///
  /// In vi, this message translates to:
  /// **'Chọn gói chăm sóc'**
  String get subscriptionChooseCarePlan;

  /// No description provided for @subscriptionChooseToContinue.
  ///
  /// In vi, this message translates to:
  /// **'Chọn gói để tiếp tục'**
  String get subscriptionChooseToContinue;

  /// No description provided for @subscriptionAlreadyHighest.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang ở gói cao nhất'**
  String get subscriptionAlreadyHighest;

  /// No description provided for @subscriptionProcessing.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý…'**
  String get subscriptionProcessing;

  /// No description provided for @subscriptionNoDowngrade.
  ///
  /// In vi, this message translates to:
  /// **'Không hỗ trợ hạ gói'**
  String get subscriptionNoDowngrade;

  /// No description provided for @subscriptionAlreadyUsing.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang dùng gói này'**
  String get subscriptionAlreadyUsing;

  /// No description provided for @subscriptionUpgradeOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ hỗ trợ nâng lên gói cao hơn'**
  String get subscriptionUpgradeOnly;

  /// No description provided for @subscriptionContinueWith.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với {plan}'**
  String subscriptionContinueWith(String plan);

  /// No description provided for @subscriptionRenewalOff.
  ///
  /// In vi, this message translates to:
  /// **'Đã tắt gia hạn. Gói vẫn dùng đến cuối chu kỳ hiện tại.'**
  String get subscriptionRenewalOff;

  /// No description provided for @subscriptionRenewalOffEndDate.
  ///
  /// In vi, this message translates to:
  /// **'Đã tắt gia hạn. Gói vẫn dùng đến {date}.'**
  String subscriptionRenewalOffEndDate(String date);

  /// No description provided for @subscriptionPlanHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử gói'**
  String get subscriptionPlanHistory;

  /// No description provided for @subscriptionNoHistory.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch sử hóa đơn hoặc thay đổi gói.'**
  String get subscriptionNoHistory;

  /// No description provided for @subscriptionInvoiceDetail.
  ///
  /// In vi, this message translates to:
  /// **'Hóa đơn và thanh toán chi tiết'**
  String get subscriptionInvoiceDetail;

  /// No description provided for @subscriptionInvoicePlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin giao dịch sẽ hiển thị ở đây. Chạm nút bên dưới để mở trang quản lý tài khoản trên cửa hàng ứng dụng.'**
  String get subscriptionInvoicePlaceholder;

  /// No description provided for @subscriptionOpenStoreManagement.
  ///
  /// In vi, this message translates to:
  /// **'Mở trang quản lý thanh toán (store)'**
  String get subscriptionOpenStoreManagement;

  /// No description provided for @subscriptionManageSubscription.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý subscription'**
  String get subscriptionManageSubscription;

  /// No description provided for @subscriptionOpenCustomerCenter.
  ///
  /// In vi, this message translates to:
  /// **'Mở trung tâm khách hàng'**
  String get subscriptionOpenCustomerCenter;

  /// No description provided for @subscriptionOpenStorePage.
  ///
  /// In vi, this message translates to:
  /// **'Mở trang quản lý store'**
  String get subscriptionOpenStorePage;

  /// No description provided for @subscriptionSyncTransactions.
  ///
  /// In vi, this message translates to:
  /// **'Đồng bộ giao dịch'**
  String get subscriptionSyncTransactions;

  /// No description provided for @subscriptionSyncHint.
  ///
  /// In vi, this message translates to:
  /// **'Lưu lại các sự kiện mua gói và kéo trạng thái subscription mới nhất.'**
  String get subscriptionSyncHint;

  /// No description provided for @subscriptionPriceMonthSuffix.
  ///
  /// In vi, this message translates to:
  /// **'/ tháng'**
  String get subscriptionPriceMonthSuffix;

  /// No description provided for @subscriptionQuotaRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Quota còn lại'**
  String get subscriptionQuotaRemaining;

  /// No description provided for @subscriptionNoQuota.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có quota sử dụng.'**
  String get subscriptionNoQuota;

  /// No description provided for @subscriptionUnlimitedReasonable.
  ///
  /// In vi, this message translates to:
  /// **'Không giới hạn hợp lý'**
  String get subscriptionUnlimitedReasonable;

  /// No description provided for @subscriptionActiveEntitlements.
  ///
  /// In vi, this message translates to:
  /// **'Quyền đang có'**
  String get subscriptionActiveEntitlements;

  /// No description provided for @subscriptionLockedFeatures.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng bị khóa'**
  String get subscriptionLockedFeatures;

  /// No description provided for @subscriptionNoEntitlements.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có quyền nào được bật.'**
  String get subscriptionNoEntitlements;

  /// No description provided for @subscriptionNoLockedFeatures.
  ///
  /// In vi, this message translates to:
  /// **'Không có tính năng khóa trong gói này.'**
  String get subscriptionNoLockedFeatures;

  /// No description provided for @subscriptionOnlyGroupOwner.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ người nhà tạo nhóm mới quản lý được gói.'**
  String get subscriptionOnlyGroupOwner;

  /// No description provided for @subscriptionOnlyGroupOwnerPurchase.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ người nhà tạo nhóm mới mua gói được.'**
  String get subscriptionOnlyGroupOwnerPurchase;

  /// No description provided for @subscriptionCannotOpenManagement.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được trang quản lý gói'**
  String get subscriptionCannotOpenManagement;

  /// No description provided for @subscriptionCannotOpenCustomerCenter.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được trung tâm khách hàng'**
  String get subscriptionCannotOpenCustomerCenter;

  /// No description provided for @subscriptionPaymentSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Thanh toán thành công. AiSee đang đồng bộ gói.'**
  String get subscriptionPaymentSuccess;

  /// No description provided for @subscriptionPlanUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Gói {plan} đã được cập nhật.'**
  String subscriptionPlanUpdated(String plan);

  /// No description provided for @subscriptionSyncInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch đã thành công. Ứng dụng vẫn đang đồng bộ gói, hãy kéo để tải lại hoặc bấm Đồng bộ giao dịch sau ít phút.'**
  String get subscriptionSyncInProgress;

  /// No description provided for @subscriptionProSynced.
  ///
  /// In vi, this message translates to:
  /// **'Đã đồng bộ AiSee Pro. AiSee đang cập nhật gói.'**
  String get subscriptionProSynced;

  /// No description provided for @subscriptionStoreEntitlement.
  ///
  /// In vi, this message translates to:
  /// **'Store đã trả về entitlement hợp lệ. Hệ thống có thể vẫn đang chờ đồng bộ từ RevenueCat.'**
  String get subscriptionStoreEntitlement;

  /// No description provided for @subscriptionNoProFound.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tìm thấy gói AiSee Pro trên tài khoản này.'**
  String get subscriptionNoProFound;

  /// No description provided for @subscriptionSuggestUpgrade.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý nâng gói. Chạm để xem gói phù hợp.'**
  String get subscriptionSuggestUpgrade;

  /// No description provided for @subscriptionQuotaLowWarning.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm đang dùng gần hết quota. Nâng gói giúp gia đình theo dõi ổn định hơn.'**
  String get subscriptionQuotaLowWarning;

  /// No description provided for @subscriptionGroupInfo.
  ///
  /// In vi, this message translates to:
  /// **'{groupName} · {caredCount} người được chăm sóc · {memberCount} người thân'**
  String subscriptionGroupInfo(
    String groupName,
    int caredCount,
    int memberCount,
  );

  /// No description provided for @subscriptionStorePaymentInfo.
  ///
  /// In vi, this message translates to:
  /// **'{groupName} · thanh toán qua cửa hàng ứng dụng'**
  String subscriptionStorePaymentInfo(String groupName);

  /// No description provided for @subscriptionPriceNoteVND.
  ///
  /// In vi, this message translates to:
  /// **'Giá VND theo bảng gói AiSee. Thanh toán, gia hạn và hủy gói vẫn được xử lý qua cửa hàng ứng dụng.'**
  String get subscriptionPriceNoteVND;

  /// No description provided for @subscriptionFeaturesInPlan.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng trong gói'**
  String get subscriptionFeaturesInPlan;

  /// No description provided for @subscriptionTransactionRecorded.
  ///
  /// In vi, this message translates to:
  /// **'Giao dịch đã ghi nhận. AiSee đang đồng bộ.'**
  String get subscriptionTransactionRecorded;

  /// No description provided for @subscriptionSessionExpired.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập hết hạn'**
  String get subscriptionSessionExpired;

  /// No description provided for @subscriptionClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get subscriptionClose;

  /// No description provided for @subscriptionPlansPeriodSuffix.
  ///
  /// In vi, this message translates to:
  /// **'đ / tháng'**
  String get subscriptionPlansPeriodSuffix;

  /// No description provided for @subscriptionPlanStarted.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu gói'**
  String get subscriptionPlanStarted;

  /// No description provided for @subscriptionPlanRenewed.
  ///
  /// In vi, this message translates to:
  /// **'Gia hạn gói'**
  String get subscriptionPlanRenewed;

  /// No description provided for @subscriptionPlanRenewalOff.
  ///
  /// In vi, this message translates to:
  /// **'Hủy gia hạn'**
  String get subscriptionPlanRenewalOff;

  /// No description provided for @subscriptionPlanExpired.
  ///
  /// In vi, this message translates to:
  /// **'Gói hết hạn'**
  String get subscriptionPlanExpired;

  /// No description provided for @subscriptionPlanChanged.
  ///
  /// In vi, this message translates to:
  /// **'Đổi gói'**
  String get subscriptionPlanChanged;

  /// No description provided for @subscriptionPlanRenewalOn.
  ///
  /// In vi, this message translates to:
  /// **'Bật lại gia hạn'**
  String get subscriptionPlanRenewalOn;

  /// No description provided for @subscriptionPlanBillingError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi thanh toán'**
  String get subscriptionPlanBillingError;

  /// No description provided for @subscriptionPlanPaused.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng gói'**
  String get subscriptionPlanPaused;

  /// No description provided for @subscriptionPlanPurchasedNonRenewing.
  ///
  /// In vi, this message translates to:
  /// **'Mua gói không gia hạn'**
  String get subscriptionPlanPurchasedNonRenewing;

  /// No description provided for @subscriptionPlanOwnershipTransferred.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển quyền mua'**
  String get subscriptionPlanOwnershipTransferred;

  /// No description provided for @subscriptionPlanAccountLinked.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết tài khoản mua'**
  String get subscriptionPlanAccountLinked;

  /// No description provided for @subscriptionPlanCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Hủy gói'**
  String get subscriptionPlanCancelled;

  /// No description provided for @subscriptionPlanUpdated2.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật gói'**
  String get subscriptionPlanUpdated2;

  /// No description provided for @subscriptionGrantedManually.
  ///
  /// In vi, this message translates to:
  /// **'Cấp thủ công'**
  String get subscriptionGrantedManually;

  /// No description provided for @subscriptionDavoFeaturesSos.
  ///
  /// In vi, this message translates to:
  /// **'SOS khẩn cấp'**
  String get subscriptionDavoFeaturesSos;

  /// No description provided for @subscriptionDavoFeaturesSosDesc.
  ///
  /// In vi, this message translates to:
  /// **'Gửi cảnh báo tới người thân.'**
  String get subscriptionDavoFeaturesSosDesc;

  /// No description provided for @subscriptionDavoFeaturesMeds.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc thuốc'**
  String get subscriptionDavoFeaturesMeds;

  /// No description provided for @subscriptionDavoFeaturesMedsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi lịch uống thuốc và lịch khám.'**
  String get subscriptionDavoFeaturesMedsDesc;

  /// No description provided for @subscriptionDavoFeaturesDailyBrief.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt hằng ngày'**
  String get subscriptionDavoFeaturesDailyBrief;

  /// No description provided for @subscriptionDavoFeaturesDailyBriefDesc.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình nhận tóm tắt chăm sóc trong ngày.'**
  String get subscriptionDavoFeaturesDailyBriefDesc;

  /// No description provided for @subscriptionDavoFeaturesWeeklyReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo tuần'**
  String get subscriptionDavoFeaturesWeeklyReport;

  /// No description provided for @subscriptionDavoFeaturesWeeklyReportDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tổng hợp xu hướng sức khỏe và hoạt động.'**
  String get subscriptionDavoFeaturesWeeklyReportDesc;

  /// No description provided for @subscriptionDavoFeaturesPdfExport.
  ///
  /// In vi, this message translates to:
  /// **'Xuất báo cáo PDF'**
  String get subscriptionDavoFeaturesPdfExport;

  /// No description provided for @subscriptionDavoFeaturesPdfExportDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tải báo cáo chăm sóc để lưu hoặc gửi bác sĩ.'**
  String get subscriptionDavoFeaturesPdfExportDesc;

  /// No description provided for @subscriptionDavoFeaturesSmartAlert.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo thông minh'**
  String get subscriptionDavoFeaturesSmartAlert;

  /// No description provided for @subscriptionDavoFeaturesSmartAlertDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nhận tín hiệu bất thường chủ động hơn.'**
  String get subscriptionDavoFeaturesSmartAlertDesc;

  /// No description provided for @subscriptionDavoFeaturesIncidentReport.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo sự cố'**
  String get subscriptionDavoFeaturesIncidentReport;

  /// No description provided for @subscriptionDavoFeaturesIncidentReportDesc.
  ///
  /// In vi, this message translates to:
  /// **'Lưu lại các sự kiện cần gia đình theo dõi.'**
  String get subscriptionDavoFeaturesIncidentReportDesc;

  /// No description provided for @subscriptionDavoFeaturesPrioritySupport.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ ưu tiên'**
  String get subscriptionDavoFeaturesPrioritySupport;

  /// No description provided for @subscriptionDavoFeaturesPrioritySupportDesc.
  ///
  /// In vi, this message translates to:
  /// **'Ưu tiên xử lý khi cần hỗ trợ.'**
  String get subscriptionDavoFeaturesPrioritySupportDesc;

  /// No description provided for @subscriptionVndPricePerMonth.
  ///
  /// In vi, this message translates to:
  /// **'{price}₫ / tháng'**
  String subscriptionVndPricePerMonth(String price);

  /// No description provided for @subscriptionFreeTrial.
  ///
  /// In vi, this message translates to:
  /// **'Miễn phí trong 1 tháng'**
  String get subscriptionFreeTrial;

  /// No description provided for @subscriptionPlanFeatureBasic1.
  ///
  /// In vi, this message translates to:
  /// **'150 phút AI mỗi tháng'**
  String get subscriptionPlanFeatureBasic1;

  /// No description provided for @subscriptionPlanFeatureBasic1Desc.
  ///
  /// In vi, this message translates to:
  /// **'Phù hợp cho một người dùng chính với nhu cầu theo dõi cơ bản.'**
  String get subscriptionPlanFeatureBasic1Desc;

  /// No description provided for @subscriptionPlanFeatureBasic2.
  ///
  /// In vi, this message translates to:
  /// **'3 lần bật camera mỗi ngày'**
  String get subscriptionPlanFeatureBasic2;

  /// No description provided for @subscriptionPlanFeatureBasic2Desc.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra nhanh tình huống khi người dùng cần hỗ trợ.'**
  String get subscriptionPlanFeatureBasic2Desc;

  /// No description provided for @subscriptionPlanFeatureBasic3.
  ///
  /// In vi, this message translates to:
  /// **'Timeline chăm sóc 7 ngày'**
  String get subscriptionPlanFeatureBasic3;

  /// No description provided for @subscriptionPlanFeatureBasic3Desc.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại hoạt động gần đây của gia đình trong tuần.'**
  String get subscriptionPlanFeatureBasic3Desc;

  /// No description provided for @subscriptionPlanFeatureBasic4.
  ///
  /// In vi, this message translates to:
  /// **'2 thành viên gia đình'**
  String get subscriptionPlanFeatureBasic4;

  /// No description provided for @subscriptionPlanFeatureBasic4Desc.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép thêm người thân cùng theo dõi một người được chăm sóc.'**
  String get subscriptionPlanFeatureBasic4Desc;

  /// No description provided for @subscriptionPlanFeaturePlus1.
  ///
  /// In vi, this message translates to:
  /// **'600 phút AI mỗi tháng'**
  String get subscriptionPlanFeaturePlus1;

  /// No description provided for @subscriptionPlanFeaturePlus1Desc.
  ///
  /// In vi, this message translates to:
  /// **'Dư dùng hơn cho gia đình cần trợ lý hoạt động thường xuyên.'**
  String get subscriptionPlanFeaturePlus1Desc;

  /// No description provided for @subscriptionPlanFeaturePlus2.
  ///
  /// In vi, this message translates to:
  /// **'20 lần bật camera mỗi ngày'**
  String get subscriptionPlanFeaturePlus2;

  /// No description provided for @subscriptionPlanFeaturePlus2Desc.
  ///
  /// In vi, this message translates to:
  /// **'Theo dõi linh hoạt hơn khi có nhiều tình huống cần kiểm tra.'**
  String get subscriptionPlanFeaturePlus2Desc;

  /// No description provided for @subscriptionPlanFeaturePlus3.
  ///
  /// In vi, this message translates to:
  /// **'Daily brief và weekly report'**
  String get subscriptionPlanFeaturePlus3;

  /// No description provided for @subscriptionPlanFeaturePlus3Desc.
  ///
  /// In vi, this message translates to:
  /// **'Tóm tắt chăm sóc định kỳ để gia đình nắm tình hình nhanh.'**
  String get subscriptionPlanFeaturePlus3Desc;

  /// No description provided for @subscriptionPlanFeaturePlus4.
  ///
  /// In vi, this message translates to:
  /// **'5 thành viên, 3 người được chăm sóc'**
  String get subscriptionPlanFeaturePlus4;

  /// No description provided for @subscriptionPlanFeaturePlus4Desc.
  ///
  /// In vi, this message translates to:
  /// **'Phù hợp cho gia đình có nhiều người cùng quản lý.'**
  String get subscriptionPlanFeaturePlus4Desc;

  /// No description provided for @subscriptionPlanFeaturePremium1.
  ///
  /// In vi, this message translates to:
  /// **'AI và camera fair use'**
  String get subscriptionPlanFeaturePremium1;

  /// No description provided for @subscriptionPlanFeaturePremium1Desc.
  ///
  /// In vi, this message translates to:
  /// **'Ưu tiên trải nghiệm gần như không giới hạn theo chính sách hợp lý.'**
  String get subscriptionPlanFeaturePremium1Desc;

  /// No description provided for @subscriptionPlanFeaturePremium2.
  ///
  /// In vi, this message translates to:
  /// **'Báo cáo nâng cao PDF/CSV'**
  String get subscriptionPlanFeaturePremium2;

  /// No description provided for @subscriptionPlanFeaturePremium2Desc.
  ///
  /// In vi, this message translates to:
  /// **'Xuất báo cáo chăm sóc để lưu trữ hoặc chia sẻ khi cần.'**
  String get subscriptionPlanFeaturePremium2Desc;

  /// No description provided for @subscriptionPlanFeaturePremium3.
  ///
  /// In vi, this message translates to:
  /// **'10 thành viên, 4 người được chăm sóc'**
  String get subscriptionPlanFeaturePremium3;

  /// No description provided for @subscriptionPlanFeaturePremium3Desc.
  ///
  /// In vi, this message translates to:
  /// **'Dành cho nhóm gia đình lớn hoặc chăm sóc nhiều người.'**
  String get subscriptionPlanFeaturePremium3Desc;

  /// No description provided for @subscriptionPlanFeaturePremium4.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ ưu tiên và incident report'**
  String get subscriptionPlanFeaturePremium4;

  /// No description provided for @subscriptionPlanFeaturePremium4Desc.
  ///
  /// In vi, this message translates to:
  /// **'Tăng mức hỗ trợ vận hành khi có tình huống quan trọng.'**
  String get subscriptionPlanFeaturePremium4Desc;

  /// No description provided for @subscriptionTemporaryUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Tính năng thanh toán tạm thời không khả dụng. Vui lòng thử lại sau.'**
  String get subscriptionTemporaryUnavailable;

  /// No description provided for @subscriptionBillingHistoryPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử hóa đơn sẽ hiển thị sau. Ứng dụng sẽ mở gói test cho người dùng thử.'**
  String get subscriptionBillingHistoryPlaceholder;

  /// No description provided for @sponsorsDavoDescription.
  ///
  /// In vi, this message translates to:
  /// **'DAVO phát triển công nghệ voice AI chạy trực tiếp trên thiết bị, gồm wake word, speaker recognition, VAD, STT và TTS, ưu tiên tốc độ và quyền riêng tư.'**
  String get sponsorsDavoDescription;

  /// No description provided for @familyDashboardMedDeleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc muốn xóa {name}?'**
  String familyDashboardMedDeleteConfirm(String name);

  /// No description provided for @metricBloodPressure.
  ///
  /// In vi, this message translates to:
  /// **'Huyết áp'**
  String get metricBloodPressure;

  /// No description provided for @metricHeartRate.
  ///
  /// In vi, this message translates to:
  /// **'Nhịp tim'**
  String get metricHeartRate;

  /// No description provided for @metricTemperature.
  ///
  /// In vi, this message translates to:
  /// **'Nhiệt độ'**
  String get metricTemperature;

  /// No description provided for @metricBloodSugar.
  ///
  /// In vi, this message translates to:
  /// **'Đường huyết'**
  String get metricBloodSugar;

  /// No description provided for @metricWeight.
  ///
  /// In vi, this message translates to:
  /// **'Cân nặng'**
  String get metricWeight;

  /// No description provided for @metricHeight.
  ///
  /// In vi, this message translates to:
  /// **'Chiều cao'**
  String get metricHeight;

  /// No description provided for @freqDaily.
  ///
  /// In vi, this message translates to:
  /// **'Hàng ngày'**
  String get freqDaily;

  /// No description provided for @freqWeekly.
  ///
  /// In vi, this message translates to:
  /// **'Hàng tuần'**
  String get freqWeekly;

  /// No description provided for @freqMonthly.
  ///
  /// In vi, this message translates to:
  /// **'Hàng tháng'**
  String get freqMonthly;

  /// No description provided for @freqTwiceDaily.
  ///
  /// In vi, this message translates to:
  /// **'2 lần/ngày'**
  String get freqTwiceDaily;

  /// No description provided for @reminderAtSeparator.
  ///
  /// In vi, this message translates to:
  /// **' lúc '**
  String get reminderAtSeparator;

  /// No description provided for @supporterTabSupport.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ'**
  String get supporterTabSupport;

  /// No description provided for @navSupport.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ'**
  String get navSupport;

  /// No description provided for @navSupportLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mục 1 trên 3: Hỗ trợ. Tổng quan hỗ trợ.'**
  String get navSupportLabel;

  /// No description provided for @supporterPersonalPeopleSupported.
  ///
  /// In vi, this message translates to:
  /// **'Người đang hỗ trợ'**
  String get supporterPersonalPeopleSupported;

  /// No description provided for @supporterPersonalAITurnsGifted.
  ///
  /// In vi, this message translates to:
  /// **'Lượt hỗ trợ đã tặng'**
  String get supporterPersonalAITurnsGifted;

  /// No description provided for @supporterPersonalAdsWatched.
  ///
  /// In vi, this message translates to:
  /// **'Quảng cáo đã xem'**
  String get supporterPersonalAdsWatched;

  /// No description provided for @supporterWatchAdButton.
  ///
  /// In vi, this message translates to:
  /// **'Xem quảng cáo để ủng hộ'**
  String get supporterWatchAdButton;

  /// No description provided for @supporterMyFamilyLink.
  ///
  /// In vi, this message translates to:
  /// **'Gia đình của tôi'**
  String get supporterMyFamilyLink;

  /// No description provided for @supporterBalanceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Số dư của bạn'**
  String get supporterBalanceTitle;

  /// No description provided for @supporterBalanceConversion.
  ///
  /// In vi, this message translates to:
  /// **'{count} lượt hỗ trợ'**
  String supporterBalanceConversion(int count);

  /// No description provided for @supporterRedeemButton.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ngay để ủng hộ'**
  String get supporterRedeemButton;

  /// No description provided for @supporterRateHint.
  ///
  /// In vi, this message translates to:
  /// **'Xem quảng cáo → nhận xu → đổi lượt hỗ trợ'**
  String get supporterRateHint;

  /// No description provided for @supporterCommunityTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cộng đồng'**
  String get supporterCommunityTitle;

  /// No description provided for @supporterCommunityPeopleSupported.
  ///
  /// In vi, this message translates to:
  /// **'Người đang được hỗ trợ'**
  String get supporterCommunityPeopleSupported;

  /// No description provided for @supporterCommunityAITurnsGifted.
  ///
  /// In vi, this message translates to:
  /// **'Lượt hỗ trợ đã được tặng'**
  String get supporterCommunityAITurnsGifted;

  /// No description provided for @supporterCommunityActiveSupporters.
  ///
  /// In vi, this message translates to:
  /// **'Người hỗ trợ tích cực'**
  String get supporterCommunityActiveSupporters;

  /// No description provided for @supporterInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cách thức hoạt động'**
  String get supporterInfoTitle;

  /// No description provided for @supporterInfoStep1.
  ///
  /// In vi, this message translates to:
  /// **'Xem quảng cáo → nhận xu'**
  String get supporterInfoStep1;

  /// No description provided for @supporterInfoStep2.
  ///
  /// In vi, this message translates to:
  /// **'Tích lũy đủ xu → đổi lấy lượt hỗ trợ'**
  String get supporterInfoStep2;

  /// No description provided for @supporterInfoStep3.
  ///
  /// In vi, this message translates to:
  /// **'Tặng cho người thân hoặc quỹ chung'**
  String get supporterInfoStep3;

  /// No description provided for @supporterInfoDailyLimit.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi ngày bạn có thể xem tối đa 50 quảng cáo'**
  String get supporterInfoDailyLimit;

  /// No description provided for @supporterInfoLearnMore.
  ///
  /// In vi, this message translates to:
  /// **'Tìm hiểu thêm'**
  String get supporterInfoLearnMore;

  /// No description provided for @supporterCoinLabel.
  ///
  /// In vi, this message translates to:
  /// **'xu'**
  String get supporterCoinLabel;

  /// No description provided for @supporterAdLimitReached.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã đạt giới hạn quảng cáo hôm nay'**
  String get supporterAdLimitReached;

  /// No description provided for @supporterInsufficientBalance.
  ///
  /// In vi, this message translates to:
  /// **'Số dư không đủ để đổi'**
  String get supporterInsufficientBalance;

  /// No description provided for @supporterRedeemSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi {turns} lượt hỗ trợ thành công'**
  String supporterRedeemSuccess(int turns);

  /// No description provided for @supporterAdWatchSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Nhận được 100 xu'**
  String get supporterAdWatchSuccess;

  /// No description provided for @supporterRedeemDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi xu lấy lượt hỗ trợ'**
  String get supporterRedeemDialogTitle;

  /// No description provided for @supporterRedeemCommunityFund.
  ///
  /// In vi, this message translates to:
  /// **'Quỹ chung cộng đồng'**
  String get supporterRedeemCommunityFund;

  /// No description provided for @supporterRedeemConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Đổi {amount} xu = {turns} lượt hỗ trợ'**
  String supporterRedeemConfirm(int amount, int turns);

  /// No description provided for @supporterRedeemRecipientLabel.
  ///
  /// In vi, this message translates to:
  /// **'Người nhận'**
  String get supporterRedeemRecipientLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
