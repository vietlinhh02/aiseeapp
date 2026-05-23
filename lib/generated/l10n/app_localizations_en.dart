// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AiSee';

  @override
  String get languageVi => 'Tiếng Việt';

  @override
  String get languageEn => 'English';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguageLabel => 'App language';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get personalTabSemanticsLabel =>
      'Personal. Your medication and reminder schedule.';

  @override
  String get personalTabIntro => 'Your personal info and reminder schedule.';

  @override
  String get personalMedicationTitle => 'Medication schedule';

  @override
  String personalMedicationCount(int count) {
    return '$count reminders';
  }

  @override
  String get personalMedicationEmpty => 'No schedule yet';

  @override
  String get personalAppointmentsTitle => 'Appointments';

  @override
  String personalAppointmentsCount(int count) {
    return '$count appointments';
  }

  @override
  String get personalAppointmentsEmpty => 'No appointments yet';

  @override
  String get personalHealthLogTitle => 'Health log';

  @override
  String get personalHealthLogSubtitle => 'View details';

  @override
  String get personalSubscriptionTitle => 'AiSee plan';

  @override
  String get personalSubscriptionSubtitle => 'Your quota and entitlements';

  @override
  String get personalSponsorsTitle => 'Sponsors';

  @override
  String get personalSponsorsSubtitle => 'Partners supporting this project';

  @override
  String get personalSignOutLabel => 'Sign out of AiSee';

  @override
  String get personalSignOutAction => 'Sign out';

  @override
  String get loginTagline => 'Not just seeing for you — acting with you';

  @override
  String get loginIntro =>
      'AiSee is an AI assistant for people with visual impairments in Vietnam. Just speak — AiSee listens, understands, and acts. Voice-first by design, with full Vietnamese support.';

  @override
  String get loginGoogleButton => 'Sign in with Google';

  @override
  String get loginGoogleHelp =>
      'Sign in with Google to access the app. We use your Google account for secure authentication and to sync your profile.';

  @override
  String get loginLegalNotice =>
      'By signing in, you agree to Google\'s and AiSee\'s terms of service.';

  @override
  String get roleAppBarExit => 'Exit';

  @override
  String get roleSelectionTitle => 'Choose how you\'ll use AiSee';

  @override
  String get roleSelectionHelp =>
      'Tap the dots below to switch pages, or swipe horizontally when not scrolling.';

  @override
  String get rolePagerUserPage => 'Page 1 of 2 — User';

  @override
  String get rolePagerFamilyPage => 'Page 2 of 2 — Family / supporter';

  @override
  String get roleUserBadge => 'Free forever';

  @override
  String get roleUserTitle => 'User';

  @override
  String get roleUserSubtitle =>
      'For people who use AiSee directly with their voice.';

  @override
  String get roleUserBullet1 =>
      'Voice-first UI with minimal screen interaction, designed for people with visual impairments.';

  @override
  String get roleUserBullet2 =>
      'User plan: no subscription fee, no ads — a free experience for the primary user.';

  @override
  String get roleUserBullet3 =>
      'Data you provide is used only to operate the app and improve the assistant per the privacy policy.';

  @override
  String get roleUserCta => 'Continue as a user';

  @override
  String get roleFamilyBadge => 'May show ads';

  @override
  String get roleFamilyTitle => 'Family / supporter';

  @override
  String get roleFamilySubtitle =>
      'For family members, volunteers, or anyone who helps with care.';

  @override
  String get roleFamilyBullet1 =>
      'Dashboard: monitor status, set reminders, configure and coordinate care remotely with peace of mind.';

  @override
  String get roleFamilyBullet2 =>
      'This plan may show ads to help cover server costs and feature development — you accept this when choosing this role.';

  @override
  String get roleFamilyBullet3 =>
      'AiSee supports daily life, not medical advice; for emergencies, contact a medical facility.';

  @override
  String get roleFamilyAccentNote =>
      'Ads (if shown) are placed to minimize disruption to care; you can still support the project by intentionally engaging with ads.';

  @override
  String get roleFamilyCta => 'Continue as family / supporter';

  @override
  String get ttsLanguageTag => 'en-US';

  @override
  String announcerMedication(String title, String time) {
    return 'Time to take your medication. $title. At $time.';
  }

  @override
  String announcerAppointment(String title) {
    return 'You have an appointment, $title, in about 30 minutes.';
  }

  @override
  String get homeMicReadyAnnouncement =>
      'The assistant is listening. You can speak now.';

  @override
  String get homeCameraBlockedNsfw =>
      'Camera paused: inappropriate content detected';

  @override
  String get homeNoSession => 'No active session. Please sign in again.';

  @override
  String get homeAssistantConnectFail =>
      'Could not connect to the voice assistant.';

  @override
  String get homeTabContacts => 'Contacts';

  @override
  String get homeTabPersonal => 'Personal';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get assistantTabRetry => 'Retry';

  @override
  String get assistantTabSemanticsLoading =>
      'AiSee assistant page. Loading your profile.';

  @override
  String get assistantTabSemanticsError =>
      'AiSee assistant page. Profile error.';

  @override
  String get assistantTabSemanticsConnecting =>
      'AiSee assistant page. Connecting to the assistant.';

  @override
  String get assistantTabSemanticsConnectError =>
      'AiSee assistant page. Connection error. Tap Retry to try again.';

  @override
  String get assistantTabSemanticsConnected =>
      'AiSee assistant page. Voice assistant connected.';

  @override
  String get assistantTabSemanticsDefault => 'AiSee assistant page.';

  @override
  String get assistantTabCameraPreviewLabel =>
      'Your camera preview, fullscreen';

  @override
  String get assistantTabConnected => 'Voice assistant connected.';

  @override
  String get assistantTabConnecting => 'Waiting to connect…';

  @override
  String get assistantTabWakeHintTitle =>
      'Say “aisee oi” to wake the assistant';

  @override
  String get assistantTabWakeHintBody =>
      'When AiSee is resting, just say “aisee oi” to start again.';

  @override
  String get assistantTabWakeTimedOutTitle => 'AiSee stopped after silence';

  @override
  String get assistantTabWakeTimedOutBody =>
      'To continue, say “aisee oi” again.';

  @override
  String assistantTabNowPlaying(String title) {
    return 'Now playing: $title';
  }

  @override
  String get homeWakeReminderAnnouncement =>
      'AiSee stopped. To continue, say aisee oi again.';

  @override
  String get authSessionExpired => 'Session expired, please sign in again';

  @override
  String get authSignInSuccess => 'Signed in successfully';

  @override
  String get authSignedOut => 'Signed out';

  @override
  String get authNoIdToken => 'Could not get an auth code from Google.';

  @override
  String authBootstrapFailed(String detail) {
    return 'Could not initialize Google Sign-In:\n$detail';
  }

  @override
  String get authBootstrapTitle => 'Signing in to AiSee…';

  @override
  String get authBootstrapDetail => 'Authenticating with the server';

  @override
  String get authGoogleCanceled => 'Sign-in canceled';

  @override
  String authGoogleError(String detail) {
    return 'Google error: $detail';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Continue';

  @override
  String get onboardingFinish => 'Continue to sign-in';

  @override
  String get onboardingChooseRoleHint =>
      'Choose a role to continue to sign-in.';

  @override
  String get onboardingWelcomeTitle => 'Welcome to AiSee';

  @override
  String get onboardingWelcomeDesc =>
      'AiSee helps people with visual impairments through voice, reminders, and quick contact with family.';

  @override
  String get onboardingWelcomeBullet1 =>
      'Talk to the assistant in your language';

  @override
  String get onboardingWelcomeBullet2 => 'Clear text, simple gestures';

  @override
  String get onboardingWelcomeBullet3 => 'Family members can support remotely';

  @override
  String get onboardingPermsTitle => 'AiSee needs a few basic permissions';

  @override
  String get onboardingPermsDesc =>
      'Mic, camera, notifications, and location are only used to help you better when needed.';

  @override
  String get onboardingPermsBullet1 =>
      'Microphone: to hear your voice commands';

  @override
  String get onboardingPermsBullet2 => 'Camera: to help describe surroundings';

  @override
  String get onboardingPermsBullet3 =>
      'Notifications and location: reminders and coordinated support';

  @override
  String get onboardingFamilyTitle => 'Always have someone close by';

  @override
  String get onboardingFamilyDesc =>
      'Invite family members so they can chat, call, and follow important things with you.';

  @override
  String get onboardingFamilyBullet1 => 'Invite family with a simple code';

  @override
  String get onboardingFamilyBullet2 => 'Chat and call right inside the app';

  @override
  String get onboardingFamilyBullet3 =>
      'Coordinate quickly when help is needed';

  @override
  String get onboardingBatteryTitle => 'So calls don\'t get missed';

  @override
  String get onboardingBatteryDesc =>
      'Some Android phones close apps in the background to save battery, which can drop calls. Allow AiSee to keep running in the background.';

  @override
  String get onboardingBatteryBullet1 =>
      'Incoming calls show even with the screen off';

  @override
  String get onboardingBatteryBullet2 =>
      'Medication and event reminders fire on time';

  @override
  String get onboardingBatteryBullet3 =>
      'AiSee runs lightly in the background, no battery drain';

  @override
  String get onboardingRemindersTitle => 'AiSee will nudge you on what matters';

  @override
  String get onboardingRemindersDesc =>
      'Medication, appointments, and important notifications so your day feels easier.';

  @override
  String get onboardingRemindersBullet1 => 'Take medication on time';

  @override
  String get onboardingRemindersBullet2 =>
      'Reminders for appointments and to-dos';

  @override
  String get onboardingRemindersBullet3 => 'Clear notifications, low noise';

  @override
  String get onboardingRoleUserTitle => 'I have low vision';

  @override
  String get onboardingRoleUserSubtitle =>
      'I use AiSee directly with my voice every day.';

  @override
  String get onboardingRoleFamilyTitle => 'I\'m a family member / supporter';

  @override
  String get onboardingRoleFamilySubtitle =>
      'I support a user remotely with reminders and check-ins.';

  @override
  String get onboardingBatteryChecking => 'Checking…';

  @override
  String get onboardingBatteryGranted => 'Background allowed';

  @override
  String get onboardingBatteryNotGranted => 'Background not allowed yet';

  @override
  String get onboardingBatteryButton =>
      'Disable battery optimization for AiSee';

  @override
  String get onboardingBatteryOpenSettings => 'Open app settings';

  @override
  String get onboardingBatteryDoneNote =>
      'AiSee can take calls even when the phone is asleep. You can change this anytime in Settings > Battery.';

  @override
  String get onboardingStatusOn => 'On';

  @override
  String get onboardingStatusOff => 'Needs on';

  @override
  String get familyTabFamily => 'Family';

  @override
  String get familyTabMessages => 'Messages';

  @override
  String get familyTabPersonal => 'Personal';

  @override
  String get familyHomeProfileFailed => 'Could not load your profile';

  @override
  String get familyPersonalIntro =>
      'Your account info and supporter registration.';

  @override
  String get familyPersonalSemanticsLabel =>
      'Personal. Account info and volunteer registration.';

  @override
  String get familyPersonalCardInfoTitle => 'Personal info';

  @override
  String get familyPersonalCardInfoSubtitle => 'Email, role, and join date';

  @override
  String get familyPersonalCardUsageTitle => 'Usage value';

  @override
  String get familyPersonalCardUsageSubtitle =>
      'Quota and plan features explained';

  @override
  String get familyPersonalCardSubscriptionTitle => 'AiSee plan';

  @override
  String get familyPersonalCardSubscriptionSubtitle =>
      'Manage plan, quotas, and care permissions';

  @override
  String get familyPersonalCardSponsorsTitle => 'Sponsors';

  @override
  String get familyPersonalCardSponsorsSubtitle => 'Partners supporting AiSee';

  @override
  String get familyPersonalSignOutLabel => 'Sign out of AiSee';

  @override
  String get familyPersonalSignOutAction => 'Sign out';

  @override
  String get familyPersonalRoleSupporter => 'Supporter';

  @override
  String get familyPersonalSheetClose => 'Close';

  @override
  String get familyPersonalSheetTitle => 'Personal info';

  @override
  String get familyPersonalSheetRole => 'Role';

  @override
  String get familyPersonalSheetJoinDate => 'Join date';

  @override
  String get familyPersonalCareNeeded =>
      'Open a cared user\'s profile before viewing per-group quota.';

  @override
  String get familyPersonalSubscriptionNeeded =>
      'Open a cared user\'s profile before managing the plan.';

  @override
  String get familyPersonalSessionExpired =>
      'Session expired. Sign out and sign in again.';

  @override
  String get familyPersonalRegisterSuccess => 'Registered as a volunteer';

  @override
  String familyPersonalCardActionHint(String title, String subtitle) {
    return '$title. $subtitle. Tap to open.';
  }

  @override
  String get familyVolunteerTitle => 'Volunteer';

  @override
  String get familyVolunteerSubtitle =>
      'Help low-vision users when family is unavailable';

  @override
  String get familyVolunteerRegisterAction => 'Register as volunteer';

  @override
  String get familyVolunteerReadyTitle => 'Ready to help';

  @override
  String get familyVolunteerReadyOn => 'You will receive support calls';

  @override
  String get familyVolunteerReadyOff => 'On break, not receiving calls';

  @override
  String get careDailySummaryFallback => 'Daily summary';

  @override
  String get careDailySummaryError => 'Unknown error';

  @override
  String get careAlertAcknowledged => 'Alert acknowledged';

  @override
  String get careAlertClosed => 'Alert closed';

  @override
  String get careAlertSkipped => 'Skipped';

  @override
  String get careTaskCreatedToast => 'Task created';

  @override
  String get careTaskCompletedToast => 'Marked done';

  @override
  String get careTaskDialogTitle => 'Task';

  @override
  String get careTaskDialogContentLabel => 'Content';

  @override
  String get careTaskDialogCreate => 'Create';

  @override
  String get careTabIntroTitle => 'Daily care';

  @override
  String get careTabIntroSubtitle =>
      'Daily summary, rule-based alerts, and tasks for your loved ones.';

  @override
  String get careOpenFullSummary => 'Open full daily summary';

  @override
  String get careAlertsHeading => 'Alerts';

  @override
  String get careRefreshAction => 'Refresh';

  @override
  String get careNoAlerts => 'No alerts.';

  @override
  String get careTasksHeading => 'Tasks';

  @override
  String get careTasksAdd => 'Add';

  @override
  String get careNoTasks => 'No tasks yet.';

  @override
  String get careSummaryLoadFail => 'Could not load summary';

  @override
  String get careRetryAction => 'Retry';

  @override
  String get careOpenPlanQuota => 'View plan / quota';

  @override
  String get contactsNotLoggedIn => 'Not logged in. Please sign in again.';

  @override
  String get contactsLoadFailed => 'Could not load contact list.';

  @override
  String get contactsCallCreateFailed => 'Could not create call';

  @override
  String get contactsSessionExpired => 'Session expired. Please sign in again.';

  @override
  String get contactsLeftGroup => 'Left care group';

  @override
  String get contactsLeaveGroupFailed => 'Could not leave care group.';

  @override
  String get contactsLeaveGroupTitle => 'Leave care group';

  @override
  String get contactsLeaveGroupBody =>
      'You must leave your current group before joining another with a different invite code.';

  @override
  String get contactsCancel => 'Cancel';

  @override
  String get contactsLeaveGroupAction => 'Leave group';

  @override
  String get contactsJoinGroupTitle => 'Join care group';

  @override
  String get contactsJoinGroupHint =>
      'Enter the 6-digit invite code from a family member to join the group';

  @override
  String get contactsJoinAction => 'Join';

  @override
  String get contactsPleaseEnterCode => 'Please enter an invite code';

  @override
  String get contactsJoinedGroup => 'Joined care group';

  @override
  String get contactsJoinFailed => 'Could not join care group.';

  @override
  String get contactsTabSemantics => 'Contacts. Chat and call family members.';

  @override
  String get contactsTabIntro => 'Chat and call family members.';

  @override
  String get contactsRetryLabel => 'Retry loading contact list';

  @override
  String get contactsRetry => 'Retry';

  @override
  String get contactsEmpty =>
      'Not in any care group yet.\nUse the 6-digit code from a family member to connect.';

  @override
  String get contactsWantSwitchGroup => 'Want to switch groups?';

  @override
  String get contactsSwitchGroupHint =>
      'Leave your current group first, then come back to this tab to enter the 6-digit invite code for the new group.';

  @override
  String get contactsLeaveCurrentGroup => 'Leave current group';

  @override
  String get contactsEnterCodeButton => 'Enter 6-digit code';

  @override
  String get contactsTapToChat => 'Tap to chat';

  @override
  String contactsVoiceCallLabel(Object label) {
    return 'Voice call $label';
  }

  @override
  String get contactsVoiceCallTooltip => 'Voice call';

  @override
  String contactsVideoCallLabel(Object label) {
    return 'Video call $label';
  }

  @override
  String get contactsVideoCallTooltip => 'Video call';

  @override
  String get chatLoadFailed => 'Could not load messages.';

  @override
  String get chatSendFailed => 'Could not send message.';

  @override
  String get chatTakePhoto => 'Take photo';

  @override
  String get chatTakePhotoLabel => 'Take photo with camera';

  @override
  String get chatPickFromGallery => 'Pick from gallery';

  @override
  String get chatPickFromGalleryLabel => 'Choose image from gallery';

  @override
  String get chatCameraPermission => 'Camera permission needed to take photos.';

  @override
  String get chatUploadFailed => 'Send failed.';

  @override
  String get chatMicPermission => 'Microphone permission needed to record.';

  @override
  String get chatRecordFailed => 'Could not record.';

  @override
  String get chatVoiceCallTooltip => 'Voice call';

  @override
  String get chatVideoCallTooltip => 'Video call';

  @override
  String get chatEmpty => 'No messages yet.\nSay hello!';

  @override
  String get chatImageLoadFailed => 'Could not load image';

  @override
  String get chatAttachImage => 'Attach image';

  @override
  String get chatInputHint => 'Type a message...';

  @override
  String get chatSend => 'Send message';

  @override
  String get chatHoldToRecord => 'Hold to record';

  @override
  String get chatStopRecordLabel => 'Stop recording and send. Hold to cancel.';

  @override
  String get chatSending => 'Sending...';

  @override
  String get usageValueTitle => 'Usage value';

  @override
  String usageValuePlan(Object planName) {
    return '$planName plan';
  }

  @override
  String usageValuePeriod(Object end, Object start) {
    return 'Period: $start — $end';
  }

  @override
  String get usageValueChartTitle => 'Usage chart (current period)';

  @override
  String get usageValueWhatUsed => 'What you\'ve used this period';

  @override
  String get usageValueUnlimited => 'Unlimited';

  @override
  String usageValueUsedLine(
    Object limit,
    Object remaining,
    Object unit,
    Object used,
  ) {
    return 'Used $used / $limit $unit ($remaining left)';
  }

  @override
  String get usageValueUpgradeHint =>
      'A higher plan may suit you if you need more quota.';

  @override
  String get usageValueEntitlementsTitle => 'Care features by plan';

  @override
  String get usageValueEntitlementCol => 'Entitlement / feature';

  @override
  String get usageValueDescCol => 'Description';

  @override
  String get usageValueStatusCol => 'Status';

  @override
  String get usageValueOn => 'On';

  @override
  String get usageValueOff => 'Locked';

  @override
  String get usageValueViewPlan => 'View plans & upgrade';

  @override
  String get usageValueChartLabel => 'Used this period';

  @override
  String get usageValueSessionExpired => 'Session expired';

  @override
  String get usageStoryAiMinutes =>
      'Minutes chatting with the assistant — shows your daily engagement level.';

  @override
  String get usageStoryPdfExports =>
      'Care report exports — save summaries for doctors or family.';

  @override
  String get usageStoryCameraActivations =>
      'Camera activations in sessions — supports remote viewing and guidance.';

  @override
  String get usageStoryDefault => 'Activity counted toward your current plan.';

  @override
  String get entitlementStoryDailyBrief =>
      'Daily health summary for your loved one.';

  @override
  String get entitlementStoryWeeklyReport =>
      'Weekly report — longer-term care trends.';

  @override
  String get entitlementStoryCareTimeline =>
      'Number of days to review care timeline.';

  @override
  String get entitlementStoryIncidentReport =>
      'Incident / escalation report after SOS.';

  @override
  String get entitlementStoryDefault => 'AiSee plan entitlement.';

  @override
  String get navAssistant => 'Assistant';

  @override
  String get navAssistantLabel =>
      'Tab 1 of 3: Assistant. Home. AiSee assistant ready to listen.';

  @override
  String get navContacts => 'Contacts';

  @override
  String get navContactsLabel =>
      'Tab 2 of 3: Contacts. Chat and call family members.';

  @override
  String get navPersonal => 'Personal';

  @override
  String get navPersonalLabel =>
      'Tab 3 of 3: Personal. Your medication schedule and messages.';

  @override
  String get navFamily => 'Family';

  @override
  String get navFamilyLabel => 'Tab 1 of 3: Family. Family contact list.';

  @override
  String get navMessages => 'Messages';

  @override
  String get navMessagesLabel => 'Tab 2 of 3: Messages. Inbox.';

  @override
  String get navPersonalFamilyLabel =>
      'Tab 3 of 3: Personal. Profile and settings.';

  @override
  String get navDoubleTapHint => 'Double-tap to select';

  @override
  String get closeAction => 'Close';

  @override
  String get incomingVoiceCall => 'Incoming voice call';

  @override
  String get incomingVideoCall => 'Incoming video call';

  @override
  String get declineCall => 'Decline';

  @override
  String get ringing => 'Ringing';

  @override
  String get agentConnecting => 'Connecting...';

  @override
  String get agentReady => 'Ready';

  @override
  String get agentListening => 'Listening...';

  @override
  String get agentThinking => 'Thinking...';

  @override
  String get agentSpeaking => 'Speaking...';

  @override
  String get agentDisconnected => 'Disconnected';

  @override
  String get agentConnectionError => 'Connection error';

  @override
  String get callTokenExpired => 'Call token expired';

  @override
  String get callJoinFailed => 'Could not join the call. Please try again.';

  @override
  String get livekitNotReady => 'LiveKit not ready to enable microphone.';

  @override
  String livekitBadJson(Object code) {
    return 'Server returned invalid JSON (HTTP $code). Check the app configuration and POST /api/v1/calls/token route.';
  }

  @override
  String livekitTokenError(Object code) {
    return 'Could not get room token (HTTP $code)';
  }

  @override
  String get livekitTokenEmpty =>
      '/api/v1/calls/token returned 200 but response body empty or not a JSON object. Check the app handling for this token response.';

  @override
  String get livekitMissingToken => 'LiveKit token response missing token';

  @override
  String get livekitMissingUrl =>
      'Missing LiveKit URL: set LIVEKIT_URL in assets/app_config.env';

  @override
  String livekitPermissionDenied(Object permission) {
    return '$permission permission denied. Enable it in Settings for AiSee.';
  }

  @override
  String livekitPermissionRequired(Object permission) {
    return '$permission permission is required to use the assistant.';
  }

  @override
  String get livekitNoSession => 'No active session';

  @override
  String get livekitConnecting => 'Connecting to room...';

  @override
  String get livekitDisconnecting => 'Disconnecting...';

  @override
  String get livekitNoRoomDisconnect => 'No room currently connected';

  @override
  String get livekitDisconnected => 'Disconnected.';

  @override
  String get serviceHealthRecordFail => 'Could not record medication taken';

  @override
  String get serviceHealthSkipFail => 'Could not record medication skipped';

  @override
  String get serviceHealthSymptomFail => 'Could not log symptom';

  @override
  String get serviceHealthMetricFail => 'Could not log health metric';

  @override
  String get serviceHealthEmergencyFail => 'Could not send emergency alert';

  @override
  String get serviceHealthRatingFail => 'Could not rate volunteer';

  @override
  String get serviceHealthLoadMedFail => 'Could not load medication schedule';

  @override
  String get serviceHealthLoadApptFail => 'Could not load appointments';

  @override
  String get serviceHealthLoadLogFail => 'Could not load health log';

  @override
  String get serviceLocationGpsOff => 'GPS is off. Please enable location.';

  @override
  String get serviceLocationDenied =>
      'Location permission permanently denied. Enable in Settings.';

  @override
  String get serviceUploadTooBig => 'File too large, max 10MB';

  @override
  String serviceUploadBadFormat(Object mime) {
    return 'Unsupported format: $mime';
  }

  @override
  String get serviceUploadNoUrl => 'Upload succeeded but no URL returned';

  @override
  String get serviceUploadFailed => 'Upload failed';

  @override
  String serviceUploadHttpFail(Object code) {
    return 'Upload failed (HTTP $code)';
  }

  @override
  String get serviceAuthBadResponse =>
      'Server response invalid (missing token)';

  @override
  String get serviceAuthLoginFail => 'Server login failed';

  @override
  String get serviceAuthProfileFail => 'Could not load profile';

  @override
  String get serviceAuthSessionExpired =>
      'Session expired, please sign in again';

  @override
  String get serviceCallCreateFail => 'Could not create call';

  @override
  String get serviceCallEndFail => 'Could not end call';

  @override
  String get serviceCallInvalidResponse => 'Invalid response';

  @override
  String get serviceCameraNoPermission =>
      'Camera permission required for the assistant to see.';

  @override
  String get serviceCameraUnavailable => 'Device has no available camera.';

  @override
  String get dashboardVoiceCall => 'Voice call';

  @override
  String get dashboardVideoCall => 'Video call';

  @override
  String get dashboardSendChat => 'Send chat message';

  @override
  String get dashboardEmergencySOS => 'Emergency SOS';

  @override
  String get dashboardEscalateFamily => 'Call family member';

  @override
  String get dashboardEscalateVolunteer => 'Call volunteer';

  @override
  String get dashboardSetMedication => 'Set medication reminder';

  @override
  String get dashboardMarkMedicationTaken => 'Mark medication taken';

  @override
  String get dashboardMarkMedicationSkipped => 'Skip medication';

  @override
  String get dashboardLogSymptom => 'Log symptom';

  @override
  String get dashboardLogMetric => 'Log health metric';

  @override
  String get dashboardSetAppointment => 'Set appointment reminder';

  @override
  String get dashboardPlayMusic => 'Play music';

  @override
  String get dashboardNavigate => 'Navigate';

  @override
  String get dashboardFamilyCreateMed => 'Family: add medication';

  @override
  String get dashboardFamilyUpdateMed => 'Family: edit medication';

  @override
  String get dashboardFamilyDeleteMed => 'Family: delete medication';

  @override
  String get dashboardCareExportPdf => 'Export care report';

  @override
  String get dashboardNoDetail => 'No further detail in log.';

  @override
  String get billingPlanStoreManaged => 'Plan managed by app store.';

  @override
  String get callerUnknown => 'Caller';

  @override
  String get reminderTestTitle => 'Test reminder';

  @override
  String get reminderTestBody =>
      'If you see this notification, notifications are working!';

  @override
  String get reminderMedicationTitle => 'Medication reminder';

  @override
  String get reminderAppointmentTitle => 'Upcoming appointment';

  @override
  String get reminderChannelName => 'AiSee Reminders';

  @override
  String get reminderChannelDesc => 'Medication and appointment reminders';

  @override
  String get foregroundChannelName => 'AiSee Assistant';

  @override
  String get foregroundChannelDesc => 'Keeps connection when screen is off.';

  @override
  String get foregroundNotificationTitle => 'AiSee is active';

  @override
  String get foregroundNotificationText =>
      'Voice assistant is on — tap to open app';

  @override
  String get messageSenderFamily => 'Family member';

  @override
  String get messageSentImage => 'Sent an image';

  @override
  String get messageSentVoice => 'Sent a voice message';

  @override
  String get messageNew => 'New message';

  @override
  String get bootstrapLoadingApp => 'Loading app…';

  @override
  String get bootstrapCheckingSession => 'Checking session…';

  @override
  String get permissionBootstrapTitle => 'Preparing permissions…';

  @override
  String get familyMedicationEmpty => 'No schedule yet';

  @override
  String get healthOverviewTitle => 'Overview';

  @override
  String get healthTakenToday => 'Taken today';

  @override
  String get healthSymptoms => 'Symptoms';

  @override
  String get healthMetrics => 'Metrics';

  @override
  String get healthTaken => 'Taken';

  @override
  String get supporterLabel => 'Supporter';

  @override
  String get appBillingFreePlan => 'Free';

  @override
  String get familyCareApiError => 'An error occurred';

  @override
  String get familyDashboardHealthTabLabel => 'Health';

  @override
  String get familyDashboardContactTabLabel => 'Contact';

  @override
  String get familyDashboardCareTabLabel => 'Care';

  @override
  String get careTimelineTitle => 'Care timeline';

  @override
  String get careTimelineFallback => 'Timeline';

  @override
  String careTimelinePlanHint(Object effectiveDays, Object requestedDays) {
    return 'With your current plan, you\'re viewing $effectiveDays most recent days (requested $requestedDays days).';
  }

  @override
  String get careTimelineEmpty => 'No events in this window.';

  @override
  String get careDailyBriefTitle => 'Daily summary';

  @override
  String careDailyBriefDate(Object date) {
    return '$date';
  }

  @override
  String get careWeeklyReportTitle => 'Weekly report';

  @override
  String get careWeeklyReportPickEnd => 'Week end';

  @override
  String get careIncidentTitle => 'Incident / SOS';

  @override
  String careIncidentAlertTime(Object time) {
    return 'Alert: $time';
  }

  @override
  String careIncidentLocation(Object lat, Object lng) {
    return 'Location: $lat, $lng';
  }

  @override
  String careIncidentTime(Object time) {
    return 'Time: $time';
  }

  @override
  String careIncidentFamilyNotified(Object notified) {
    return 'Family notified: $notified';
  }

  @override
  String get careExportCopied => 'Copied';

  @override
  String get careExportCopyAction => 'Copy';

  @override
  String get careExportClose => 'Close';

  @override
  String get careExportTitle => 'Export report (temporary format)';

  @override
  String careExportFormat(Object format, Object id) {
    return 'Format: $format\nExport ID: $id\n\n';
  }

  @override
  String get careExportNoData => '(No data attached)';

  @override
  String get careExportFallback => 'Export report';

  @override
  String get careTotalsOverview => 'Overview';

  @override
  String careTotalsActiveMeds(Object count) {
    return 'Active medications: $count';
  }

  @override
  String careTotalsTakenSkipped(Object skipped, Object taken) {
    return 'Taken: $taken, skipped: $skipped';
  }

  @override
  String careTotalsSymptoms(Object metrics, Object symptoms) {
    return 'Symptoms: $symptoms, metrics: $metrics';
  }

  @override
  String careTotalsSOS(Object escalations, Object sos) {
    return 'SOS: $sos, escalations: $escalations';
  }

  @override
  String careTotalsCalls(Object videoCount, Object videoMin, Object voiceMin) {
    return 'Video calls: $videoCount ($videoMin min), voice: $voiceMin min';
  }

  @override
  String get careBillingSheetViewPlan => 'View plans & upgrade';

  @override
  String careBillingQuotaRemaining(Object remaining) {
    return 'Remaining: $remaining';
  }

  @override
  String get careBillingQuotaExhausted => 'Quota exhausted';

  @override
  String get careBillingFallbackTitle => 'Could not complete';

  @override
  String get careViewPlanAction => 'View plan';

  @override
  String get familyMessagesCallFailed => 'Could not create call';

  @override
  String get familyMessagesRetry => 'Retry';

  @override
  String get familyMessagesEmpty => 'No family members to message';

  @override
  String get familyMessagesTapToChat => 'Tap to chat';

  @override
  String familyMessagesVoiceCall(Object label) {
    return 'Voice call $label';
  }

  @override
  String get familyMessagesVoiceCallTooltip => 'Voice call';

  @override
  String familyMessagesVideoCall(Object label) {
    return 'Video call $label';
  }

  @override
  String get familyMessagesVideoCallTooltip => 'Video call';

  @override
  String careWidgetOverviewTitle(Object date) {
    return 'Overview for $date';
  }

  @override
  String get careWidgetDataTable => 'Data table';

  @override
  String get careWidgetCategoryCol => 'Category';

  @override
  String get careWidgetValueCol => 'Value';

  @override
  String get careWidgetActiveMeds => 'Active medications';

  @override
  String get careWidgetDosesTaken => 'Doses taken';

  @override
  String get careWidgetDosesSkipped => 'Doses skipped';

  @override
  String get careWidgetSymptomLogs => 'Symptom logs';

  @override
  String get careWidgetMetricLogs => 'Metric logs';

  @override
  String get careWidgetSOSEvents => 'SOS events';

  @override
  String get careWidgetEscalations => 'Escalations / contacts';

  @override
  String get careWidgetVideoCalls => 'Video calls';

  @override
  String get careWidgetVideoCallMinutes => 'Video call minutes';

  @override
  String get careWidgetVoiceCallMinutes => 'Voice call minutes';

  @override
  String get careWidgetAutoNotes => 'Auto-generated notes';

  @override
  String get careWidgetWebReportsTitle => 'Reports & timeline (web)';

  @override
  String get careWidgetWebReportsHint =>
      'Open in browser — set CARE_WEB_BASE_URL if needed.';

  @override
  String get careWidgetBrowserError => 'Could not open browser';

  @override
  String get careAlertSeen => 'Seen';

  @override
  String get careAlertClose => 'Close';

  @override
  String get careAlertSkip => 'Skip';

  @override
  String get careTaskColumnTask => 'Task';

  @override
  String get careTaskColumnDue => 'Due';

  @override
  String get careTaskColumnStatus => 'Status';

  @override
  String get careTaskColumnAction => '';

  @override
  String get careTaskDone => 'Done';

  @override
  String get careWebTimeline => 'Timeline';

  @override
  String get careWebWeekly => 'Week';

  @override
  String get careWebIncident => 'Incident';

  @override
  String get careWebExport => 'Export data';

  @override
  String get dashboardAuditEmpty => 'No activity in the log yet.';

  @override
  String dashboardAuditTime(Object time) {
    return 'Time: $time';
  }

  @override
  String dashboardAuditDetails(Object details) {
    return 'Details: $details';
  }

  @override
  String dashboardAuditResult(Object result) {
    return 'Result: $result';
  }

  @override
  String get dashboardClose => 'Close';

  @override
  String get dashboardHealthTitle => 'Health tracking';

  @override
  String get dashboardHealthSubtitle =>
      'Today\'s medications, recent symptoms and metrics.';

  @override
  String get dashboardHealthNoData => 'No data';

  @override
  String get dashboardHealthPullToRefresh => 'Pull down to reload.';

  @override
  String get dashboardHealthMedsToday => 'Today\'s medications';

  @override
  String get dashboardHealthNoMeds => 'No medications';

  @override
  String get dashboardHealthRecentSymptoms => 'Recent symptoms';

  @override
  String get dashboardHealthNoSymptoms => 'No symptoms';

  @override
  String get dashboardHealthMetrics => 'Health metrics';

  @override
  String get dashboardHealthNoMetrics => 'No metrics';

  @override
  String get dashboardHealthOverview => 'Overview';

  @override
  String get dashboardHealthTakenToday => 'Taken today';

  @override
  String get dashboardHealthNotTaken => 'Not taken';

  @override
  String get dashboardHealthSymptoms => 'Symptoms';

  @override
  String get dashboardHealthMetricsPill => 'Metrics';

  @override
  String get dashboardHealthTakenStatus => 'Taken';

  @override
  String get dashboardHealthNotTakenStatus => 'Not taken';

  @override
  String get dashboardHealthOverviewChartLabel => 'Health overview';

  @override
  String get dashboardLocationTitle => 'Family member location';

  @override
  String get dashboardLocationSubtitle =>
      'Quick view on Mapbox map (static image). Tap button below to open Google Maps.';

  @override
  String get dashboardLocationNoLocation => 'No location yet';

  @override
  String get dashboardLocationPullHint => 'Pull down to try reloading.';

  @override
  String get dashboardLocationCoordinates => 'Coordinates';

  @override
  String dashboardLocationUpdated(Object time) {
    return 'Updated: $time';
  }

  @override
  String get dashboardLocationOpenMaps => 'Open Google Maps';

  @override
  String get dashboardLocationMapSemantics =>
      'Mapbox map, pinned at family member\'s location';

  @override
  String get dashboardLocationMapboxMissing => 'Mapbox not configured';

  @override
  String get dashboardLocationMapboxHint =>
      'Add MAPBOX_ACCESS_TOKEN (pk.*) to assets/app_config.env or --dart-define=MAPBOX_ACCESS_TOKEN=... and restart the app.';

  @override
  String get dashboardLocationMapError =>
      'Could not load map. Check network or Mapbox token.';

  @override
  String get dashboardMedsEmpty => 'No medications';

  @override
  String get dashboardMedsEdit => 'Edit';

  @override
  String get dashboardMedsDelete => 'Delete';

  @override
  String get dashboardMedFormAddTitle => 'Add medication';

  @override
  String get dashboardMedFormEditTitle => 'Edit medication';

  @override
  String get dashboardMedFormNameLabel => 'Medication name';

  @override
  String get dashboardMedFormNameHint => 'e.g. Paracetamol';

  @override
  String get dashboardMedFormDosageLabel => 'Dosage';

  @override
  String get dashboardMedFormDosageHint => 'e.g. 1 tablet';

  @override
  String get dashboardMedFormTimesLabel => 'Times';

  @override
  String get dashboardMedFormTimesHint => 'e.g. 07:00, 21:00';

  @override
  String get dashboardMedFormFreqLabel => 'Frequency';

  @override
  String get dashboardMedFormFreqHint => 'e.g. daily';

  @override
  String get dashboardMedFormCancel => 'Cancel';

  @override
  String get dashboardMedFormSave => 'Save';

  @override
  String get careReportBarMedsActive => 'Active meds';

  @override
  String get careReportBarTaken => 'Taken';

  @override
  String get careReportBarSkipped => 'Skipped';

  @override
  String get careReportBarSymptoms => 'Symptoms';

  @override
  String get careReportBarMetrics => 'Metrics';

  @override
  String get careReportBarSOS => 'SOS';

  @override
  String get careReportChartLabel => 'Daily summary';

  @override
  String get careAlertPillLevel => 'Level';

  @override
  String get careAlertPillStatus => 'Status';

  @override
  String get careAlertPillCode => 'Code';

  @override
  String get careAlertPillTime => 'At';

  @override
  String get callMicOff => 'Mute mic';

  @override
  String get callMicOn => 'Unmute mic';

  @override
  String get callSpeakerOff => 'Mute speaker';

  @override
  String get callSpeakerOn => 'Unmute speaker';

  @override
  String get callEnd => 'End call';

  @override
  String get callCameraOff => 'Camera off';

  @override
  String get callCameraOn => 'Camera on';

  @override
  String get callDialing => 'Calling…';

  @override
  String get callEnded => 'Call ended';

  @override
  String get familyContactsCaredUser => 'Cared person';

  @override
  String get familyContactsFamilyMember => 'Family member';

  @override
  String get familyContactsCreateInviteCode => 'Create 6-digit code';

  @override
  String get familyContactsTransferOwnership => 'Transfer ownership';

  @override
  String get familyContactsLeaveGroup => 'Leave group';

  @override
  String get familyContactsGroupOwner => 'Group owner';

  @override
  String get familyContactsLeftGroup => 'Left care group';

  @override
  String familyContactsOwnershipTransferred(String target) {
    return 'Ownership transferred to $target';
  }

  @override
  String get familyContactsCreateCareGroup => 'Create care group';

  @override
  String get familyContactsCreateCodeToInvite =>
      'Create a 6-digit invite code for the cared person or family member to join';

  @override
  String get familyContactsCodeCopied => 'Invite code copied';

  @override
  String get familyContactsNoOtherMember =>
      'No other family members in the group to transfer ownership to.';

  @override
  String get familyContactsTransferOwnershipTitle => 'Transfer group ownership';

  @override
  String get familyContactsSelectNewOwner =>
      'Choose the family member who will continue inviting members and managing the group subscription.';

  @override
  String get familyContactsInviteCodeSent => 'Code sent to cared person';

  @override
  String get familyContactsNoCaredUsers =>
      'No cared person in the group yet. Create an invite code to add a cared person or another family member.';

  @override
  String get familyContactsCaredUsersSection => 'Cared persons in group';

  @override
  String get familyContactsFamilyMembersSection => 'Family members in group';

  @override
  String get familyContactsYouAreOwner => 'You are the group owner';

  @override
  String get familyContactsOnlyOwnerWarning =>
      'Only the group owner can create invite codes and manage the subscription.';

  @override
  String get familyContactsTapForInfo => 'Tap for details';

  @override
  String get familyContactsSessionExpired =>
      'Session expired. Please sign out and sign in again.';

  @override
  String get familyContactsLeaveBeforeTransfer =>
      'Transfer ownership before leaving the group';

  @override
  String get familyContactsLeaveGroupTitle => 'Leave care group';

  @override
  String get familyContactsLeaveBody =>
      'You are the group owner. Please transfer ownership to another family member first, then leave the group.';

  @override
  String get familyContactsLeaveConfirmBody =>
      'You will leave the current care group. To join another group, use a new invite code after leaving.';

  @override
  String get familyContactsCannotLeave =>
      'Please invite or wait for another family member before transferring ownership and leaving.';

  @override
  String get familyContactsCopyCode => 'Copy code';

  @override
  String get familyDashboardMedsTabLabel => 'Medications';

  @override
  String get familyDashboardAuditTabLabel => 'Activity';

  @override
  String get familyDashboardLocationTabLabel => 'Location';

  @override
  String get remindersLoadFailed => 'Could not load data.';

  @override
  String get remindersRetry => 'Retry';

  @override
  String get remindersMedication => 'Medication';

  @override
  String get remindersEmpty =>
      'No reminders yet.\nAdd medications from the Personal tab.';

  @override
  String get remindersTaken => '✓ Taken';

  @override
  String get remindersSkipped => '✗ Skipped';

  @override
  String get remindersTakenStatus => 'Taken';

  @override
  String get remindersSkippedStatus => 'Skipped';

  @override
  String get remindersDeletePrompt => 'Delete reminder';

  @override
  String remindersDetailSemantics(String title, String subtitle) {
    return '$title. $subtitle. Tap for details.';
  }

  @override
  String get sponsorsTitle => 'Sponsors';

  @override
  String get sponsorsOpenWebsite => 'Open website';

  @override
  String get sponsorsOpenDavo => 'Open DAVO website';

  @override
  String get sponsorsCannotOpen => 'Could not open sponsor website.';

  @override
  String get familyDashboardCancel => 'Cancel';

  @override
  String familyDashboardMedDeleted(String name) {
    return 'Deleted $name';
  }

  @override
  String get familyDashboardMedAdded => 'Medication added';

  @override
  String get familyDashboardMedUpdated => 'Medication updated';

  @override
  String get familyDashboardCannotOpenMaps => 'Could not open Google Maps.';

  @override
  String get familyDashboardCannotOpenAppMaps => 'Could not open map.';

  @override
  String get subscriptionTitle => 'AiSee Plan';

  @override
  String get subscriptionRetry => 'Retry';

  @override
  String get subscriptionCurrentPlan => 'Current plan';

  @override
  String get subscriptionUsing => 'Active';

  @override
  String get subscriptionSuitable => 'Recommended';

  @override
  String get subscriptionFree => 'Free';

  @override
  String get subscriptionViewPlansToBuy => 'View plans to buy';

  @override
  String get subscriptionViewSuitablePlans => 'View suitable plans';

  @override
  String get subscriptionChooseCarePlan => 'Choose care plan';

  @override
  String get subscriptionChooseToContinue => 'Choose a plan to continue';

  @override
  String get subscriptionAlreadyHighest => 'You\'re on the highest plan';

  @override
  String get subscriptionProcessing => 'Processing…';

  @override
  String get subscriptionNoDowngrade => 'Downgrade not supported';

  @override
  String get subscriptionAlreadyUsing => 'You\'re using this plan';

  @override
  String get subscriptionUpgradeOnly => 'Only upgrade to higher plan supported';

  @override
  String subscriptionContinueWith(String plan) {
    return 'Continue with $plan';
  }

  @override
  String get subscriptionRenewalOff =>
      'Auto-renewal off. Plan remains active until end of current period.';

  @override
  String subscriptionRenewalOffEndDate(String date) {
    return 'Auto-renewal off. Plan remains active until $date.';
  }

  @override
  String get subscriptionPlanHistory => 'Plan history';

  @override
  String get subscriptionNoHistory => 'No billing or plan change history yet.';

  @override
  String get subscriptionInvoiceDetail => 'Invoice and payment details';

  @override
  String get subscriptionInvoicePlaceholder =>
      'Transaction details appear here. Tap the button below to open the account management page on the app store.';

  @override
  String get subscriptionOpenStoreManagement =>
      'Open payment management (store)';

  @override
  String get subscriptionManageSubscription => 'Manage subscription';

  @override
  String get subscriptionOpenCustomerCenter => 'Open customer center';

  @override
  String get subscriptionOpenStorePage => 'Open store management page';

  @override
  String get subscriptionSyncTransactions => 'Sync transactions';

  @override
  String get subscriptionSyncHint =>
      'Save purchase events and pull the latest subscription status.';

  @override
  String get subscriptionPriceMonthSuffix => '/ month';

  @override
  String get subscriptionQuotaRemaining => 'Remaining quota';

  @override
  String get subscriptionNoQuota => 'No quota available.';

  @override
  String get subscriptionUnlimitedReasonable => 'Unlimited (within fair use)';

  @override
  String get subscriptionActiveEntitlements => 'Active entitlements';

  @override
  String get subscriptionLockedFeatures => 'Locked in this plan';

  @override
  String get subscriptionNoEntitlements => 'No entitlements enabled.';

  @override
  String get subscriptionNoLockedFeatures => 'No locked features in this plan.';

  @override
  String get subscriptionOnlyGroupOwner =>
      'Only the group creator can manage the plan.';

  @override
  String get subscriptionOnlyGroupOwnerPurchase =>
      'Only the group creator can purchase plans.';

  @override
  String get subscriptionCannotOpenManagement =>
      'Could not open plan management';

  @override
  String get subscriptionCannotOpenCustomerCenter =>
      'Could not open customer center';

  @override
  String get subscriptionPaymentSuccess =>
      'Payment successful. AiSee is syncing your plan.';

  @override
  String subscriptionPlanUpdated(String plan) {
    return '$plan plan has been updated.';
  }

  @override
  String get subscriptionSyncInProgress =>
      'Transaction successful. The app is still syncing your plan — pull to refresh or tap Sync Transactions in a few minutes.';

  @override
  String get subscriptionProSynced =>
      'AiSee Pro synced. AiSee is updating your plan.';

  @override
  String get subscriptionStoreEntitlement =>
      'Store returned a valid entitlement. The system may still be waiting for RevenueCat to sync.';

  @override
  String get subscriptionNoProFound =>
      'No AiSee Pro plan found on this account.';

  @override
  String get subscriptionSuggestUpgrade =>
      'Consider upgrading. Tap to view suitable plans.';

  @override
  String get subscriptionQuotaLowWarning =>
      'Group is nearly out of quota. Upgrading helps track your family more reliably.';

  @override
  String subscriptionGroupInfo(
    String groupName,
    int caredCount,
    int memberCount,
  ) {
    return '$groupName · $caredCount cared · $memberCount family members';
  }

  @override
  String subscriptionStorePaymentInfo(String groupName) {
    return '$groupName · payment via app store';
  }

  @override
  String get subscriptionPriceNoteVND =>
      'VND pricing per AiSee plan table. Payment, renewal, and cancellation are handled through the app store.';

  @override
  String get subscriptionFeaturesInPlan => 'Features in plan';

  @override
  String get subscriptionTransactionRecorded =>
      'Transaction recorded. AiSee is syncing.';

  @override
  String get subscriptionSessionExpired => 'Session expired';

  @override
  String get subscriptionClose => 'Close';

  @override
  String get subscriptionPlansPeriodSuffix => 'VND / month';

  @override
  String get subscriptionPlanStarted => 'Plan started';

  @override
  String get subscriptionPlanRenewed => 'Plan renewed';

  @override
  String get subscriptionPlanRenewalOff => 'Auto-renewal off';

  @override
  String get subscriptionPlanExpired => 'Plan expired';

  @override
  String get subscriptionPlanChanged => 'Plan changed';

  @override
  String get subscriptionPlanRenewalOn => 'Auto-renewal on';

  @override
  String get subscriptionPlanBillingError => 'Billing error';

  @override
  String get subscriptionPlanPaused => 'Plan paused';

  @override
  String get subscriptionPlanPurchasedNonRenewing => 'Non-renewing purchase';

  @override
  String get subscriptionPlanOwnershipTransferred => 'Purchase transfer';

  @override
  String get subscriptionPlanAccountLinked => 'Purchase account linked';

  @override
  String get subscriptionPlanCancelled => 'Cancelled';

  @override
  String get subscriptionPlanUpdated2 => 'Cập nhật gói';

  @override
  String get subscriptionGrantedManually => 'Granted manually';

  @override
  String get subscriptionDavoFeaturesSos => 'Emergency SOS';

  @override
  String get subscriptionDavoFeaturesSosDesc => 'Send alerts to loved ones.';

  @override
  String get subscriptionDavoFeaturesMeds => 'Medication Reminders';

  @override
  String get subscriptionDavoFeaturesMedsDesc =>
      'Track medication schedule and appointments.';

  @override
  String get subscriptionDavoFeaturesDailyBrief => 'Daily Briefing';

  @override
  String get subscriptionDavoFeaturesDailyBriefDesc =>
      'Family receives a daily summary of care activities.';

  @override
  String get subscriptionDavoFeaturesWeeklyReport => 'Weekly Report';

  @override
  String get subscriptionDavoFeaturesWeeklyReportDesc =>
      'Summary of health trends and activities.';

  @override
  String get subscriptionDavoFeaturesPdfExport => 'PDF Report Export';

  @override
  String get subscriptionDavoFeaturesPdfExportDesc =>
      'Download care reports to save or send to doctors.';

  @override
  String get subscriptionDavoFeaturesSmartAlert => 'Smart Alerts';

  @override
  String get subscriptionDavoFeaturesSmartAlertDesc =>
      'Proactively receive alerts on abnormal signals.';

  @override
  String get subscriptionDavoFeaturesIncidentReport => 'Incident Reporting';

  @override
  String get subscriptionDavoFeaturesIncidentReportDesc =>
      'Save events requiring family monitoring.';

  @override
  String get subscriptionDavoFeaturesPrioritySupport => 'Priority Support';

  @override
  String get subscriptionDavoFeaturesPrioritySupportDesc =>
      'Priority handling when support is needed.';

  @override
  String subscriptionVndPricePerMonth(String price) {
    return '$price₫ / month';
  }

  @override
  String get subscriptionFreeTrial => 'Free for 1 month';

  @override
  String get subscriptionPlanFeatureBasic1 => '150 AI minutes per month';

  @override
  String get subscriptionPlanFeatureBasic1Desc =>
      'Suitable for a primary user with basic monitoring needs.';

  @override
  String get subscriptionPlanFeatureBasic2 => '3 camera activations per day';

  @override
  String get subscriptionPlanFeatureBasic2Desc =>
      'Quick checks in situations where the user needs support.';

  @override
  String get subscriptionPlanFeatureBasic3 => '7-day care timeline';

  @override
  String get subscriptionPlanFeatureBasic3Desc =>
      'Review recent family activity during the week.';

  @override
  String get subscriptionPlanFeatureBasic4 => '2 family members';

  @override
  String get subscriptionPlanFeatureBasic4Desc =>
      'Allows adding relatives to track one cared user.';

  @override
  String get subscriptionPlanFeaturePlus1 => '600 AI minutes per month';

  @override
  String get subscriptionPlanFeaturePlus1Desc =>
      'More ample for families needing regular assistant activity.';

  @override
  String get subscriptionPlanFeaturePlus2 => '20 camera activations per day';

  @override
  String get subscriptionPlanFeaturePlus2Desc =>
      'More flexible monitoring for multiple check-in situations.';

  @override
  String get subscriptionPlanFeaturePlus3 => 'Daily brief and weekly report';

  @override
  String get subscriptionPlanFeaturePlus3Desc =>
      'Periodic care summaries to keep the family updated quickly.';

  @override
  String get subscriptionPlanFeaturePlus4 => '5 members, 3 cared users';

  @override
  String get subscriptionPlanFeaturePlus4Desc =>
      'Suitable for families with multiple managers.';

  @override
  String get subscriptionPlanFeaturePremium1 => 'AI and camera fair use';

  @override
  String get subscriptionPlanFeaturePremium1Desc =>
      'Priority access with near-unlimited usage under a fair use policy.';

  @override
  String get subscriptionPlanFeaturePremium2 => 'Advanced PDF/CSV reports';

  @override
  String get subscriptionPlanFeaturePremium2Desc =>
      'Export care reports to save or share as needed.';

  @override
  String get subscriptionPlanFeaturePremium3 => '10 members, 4 cared users';

  @override
  String get subscriptionPlanFeaturePremium3Desc =>
      'Designed for large families or managing multiple users.';

  @override
  String get subscriptionPlanFeaturePremium4 =>
      'Priority support and incident reports';

  @override
  String get subscriptionPlanFeaturePremium4Desc =>
      'Enhanced operational support for critical situations.';

  @override
  String get subscriptionTemporaryUnavailable =>
      'Temporary payment features are unavailable. Please try again later.';

  @override
  String get subscriptionBillingHistoryPlaceholder =>
      'Billing history will appear later. The app will open a test plan for trial users.';

  @override
  String get sponsorsDavoDescription =>
      'DAVO develops on-device voice AI technologies, including wake word, speaker recognition, VAD, STT, and TTS, prioritizing speed and privacy.';

  @override
  String familyDashboardMedDeleteConfirm(String name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get metricBloodPressure => 'Blood pressure';

  @override
  String get metricHeartRate => 'Heart rate';

  @override
  String get metricTemperature => 'Temperature';

  @override
  String get metricBloodSugar => 'Blood sugar';

  @override
  String get metricWeight => 'Weight';

  @override
  String get metricHeight => 'Height';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqTwiceDaily => '2 times/day';

  @override
  String get reminderAtSeparator => ' at ';

  @override
  String get supporterTabSupport => 'Support';

  @override
  String get navSupport => 'Support';

  @override
  String get navSupportLabel => 'Tab 1 of 3: Support. Supporter overview.';

  @override
  String get supporterPersonalPeopleSupported => 'People supported';

  @override
  String get supporterPersonalAITurnsGifted => 'AI turns gifted';

  @override
  String get supporterPersonalAdsWatched => 'Ads watched';

  @override
  String get supporterWatchAdButton => 'Watch ad to support';

  @override
  String get supporterMyFamilyLink => 'My family';

  @override
  String get supporterBalanceTitle => 'Your balance';

  @override
  String supporterBalanceConversion(int count) {
    return '$count AI turns';
  }

  @override
  String get supporterRedeemButton => 'Redeem to support';

  @override
  String get supporterRateHint => '1 ad = 100 coins = 1 AI turn';

  @override
  String get supporterCommunityTitle => 'Community';

  @override
  String get supporterCommunityPeopleSupported => 'People being supported';

  @override
  String get supporterCommunityAITurnsGifted => 'AI turns gifted';

  @override
  String get supporterCommunityActiveSupporters => 'Active supporters';

  @override
  String get supporterInfoTitle => 'How it works';

  @override
  String get supporterInfoStep1 => 'Watch ads → earn coins';

  @override
  String get supporterInfoStep2 => 'Save enough coins → redeem AI turns';

  @override
  String get supporterInfoStep3 => 'Gift to family or community fund';

  @override
  String get supporterInfoDailyLimit => 'You can watch up to 10 ads per day';

  @override
  String get supporterInfoLearnMore => 'Learn more';

  @override
  String get supporterCoinLabel => 'coins';

  @override
  String get supporterAdLimitReached => 'Daily ad limit reached';

  @override
  String get supporterInsufficientBalance => 'Not enough balance';

  @override
  String supporterRedeemSuccess(int turns) {
    return 'Redeemed $turns AI turns';
  }

  @override
  String get supporterAdWatchSuccess => 'Received 100 coins';

  @override
  String get supporterRedeemDialogTitle => 'Redeem coins for AI turns';

  @override
  String get supporterRedeemCommunityFund => 'Community fund';

  @override
  String supporterRedeemConfirm(int amount, int turns) {
    return 'Redeem $amount coins = $turns AI turns';
  }

  @override
  String get supporterRedeemRecipientLabel => 'Recipient';
}
