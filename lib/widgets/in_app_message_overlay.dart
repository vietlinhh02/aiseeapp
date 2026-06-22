import 'package:flutter/material.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../generated/l10n/app_localizations.dart';
import '../services/in_app_message_controller.dart';
import '../theme/style_tokens.dart';

/// Hiển thị popup thông báo khi có tin nhắn đến (khi app đang foreground).
/// Popup căn giữa màn hình, có nút Đóng + bấm ra ngoài để tắt, thiết kế to
/// rõ cho người khiếm thị.
class InAppMessageOverlayHost extends StatefulWidget {
  const InAppMessageOverlayHost({
    super.key,
    required this.child,
    required this.controller,
  });

  final Widget child;
  final AiseeInAppMessageController controller;

  @override
  State<InAppMessageOverlayHost> createState() =>
      _InAppMessageOverlayHostState();
}

class _InAppMessageOverlayHostState extends State<InAppMessageOverlayHost> {
  /// OverlayEntry hiện tại (null nếu không có popup).
  OverlayEntry? _overlayEntry;
  AiseeInAppMessageNotification? _shownNotification;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant InAppMessageOverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onControllerChanged() {
    // Đợi frame tiếp theo để chắc chắn Overlay đã mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncOverlay();
    });
  }

  void _syncOverlay() {
    final AiseeInAppMessageNotification? current = widget.controller.current;
    final bool shouldShow = widget.controller.shouldShow;

    if (!shouldShow || current == null) {
      _removeOverlay();
      return;
    }

    // Notification mới khác cái đang hiện → thay thế.
    if (_shownNotification?.message.id != current.message.id) {
      _removeOverlay();
      _showOverlay(current);
    }
  }

  void _showOverlay(AiseeInAppMessageNotification notification) {
    final OverlayState? overlayState = Overlay.maybeOf(
      context,
      rootOverlay: true,
    );
    if (overlayState == null) {
      return;
    }
    _shownNotification = notification;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        return _MessagePopup(
          notification: notification,
          onDismiss: () {
            // Tránh remove 2 lần nếu popup tự đóng do controller.
            if (_overlayEntry == entry) {
              _removeOverlay();
              widget.controller.hide();
            }
          },
        );
      },
    );
    _overlayEntry = entry;
    overlayState.insert(entry);
  }

  void _removeOverlay() {
    final OverlayEntry? entry = _overlayEntry;
    _overlayEntry = null;
    _shownNotification = null;
    entry?.remove();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Popup căn giữa màn hình, có backdrop mờ + animation scale/fade.
class _MessagePopup extends StatelessWidget {
  const _MessagePopup({required this.notification, required this.onDismiss});

  final AiseeInAppMessageNotification notification;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    return Semantics(
      label: l.messageFrom(notification.senderName),
      liveRegion: true,
      child: Stack(
        children: <Widget>[
          // Backdrop mờ — bấm vào đây để đóng.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                builder: (BuildContext context, double value, Widget? _) {
                  return Container(
                    color: const Color(0x66000000).withValues(alpha: 0.40 * value),
                  );
                },
              ),
            ),
          ),
          // Card popup căn giữa.
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                // Tránh che phím ảo / nav bar.
                vertical: 16 + mediaQuery.viewInsets.bottom / 4,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.85, end: 1),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutBack,
                builder: (BuildContext context, double scale, Widget? child) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    builder: (BuildContext context, double opacity, Widget? c) {
                      return Opacity(
                        opacity: opacity,
                        child: Transform.scale(scale: scale, child: c),
                      );
                    },
                    child: child,
                  );
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Material(
                    color: StyleTokens.surfaceCard,
                    elevation: 16,
                    shadowColor: const Color(0x40060913),
                    borderRadius: BorderRadius.circular(28),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: StyleTokens.navBarBorder.withValues(alpha: 0.20),
                        ),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _MessageAvatar(notification: notification),
                          const SizedBox(height: 14),
                          Text(
                            notification.senderName,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: aiseeTextStyle(
                              color: StyleTokens.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          // Tag "Tin nhắn mới" nhỏ phía dưới tên.
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: StyleTokens.brandSecondary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              l.inAppMessageLabel,
                              style: aiseeTextStyle(
                                color: StyleTokens.brandSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Nội dung tin nhắn — to, dễ đọc.
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: StyleTokens.navInactivePill.withValues(
                                alpha: 0.45,
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              notification.preview,
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: aiseeTextStyle(
                                color: StyleTokens.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                height: 1.32,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          // Nút Đóng — to, dễ bấm.
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: onDismiss,
                              style: FilledButton.styleFrom(
                                backgroundColor: StyleTokens.brandSecondary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: aiseeTextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              child: Text(l.closeAction),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageAvatar extends StatelessWidget {
  const _MessageAvatar({required this.notification});

  final AiseeInAppMessageNotification notification;

  @override
  Widget build(BuildContext context) {
    final String? avatarUrl = notification.senderAvatarUrl;
    final String initial = notification.senderName.characters.isEmpty
        ? '?'
        : notification.senderName.characters.first.toUpperCase();
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: StyleTokens.navInactivePill,
        shape: BoxShape.circle,
        border: Border.all(color: StyleTokens.navGlassBorder, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl == null
          ? _AvatarFallback(initial: initial)
          : Image.network(
              avatarUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stack) {
                    return _AvatarFallback(initial: initial);
                  },
            ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: aiseeTextStyle(
          color: StyleTokens.brandSecondary,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
