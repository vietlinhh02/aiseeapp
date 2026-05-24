import 'package:flutter/material.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../generated/l10n/app_localizations.dart';
import '../services/in_app_message_controller.dart';
import '../theme/style_tokens.dart';

class InAppMessageOverlayHost extends StatelessWidget {
  const InAppMessageOverlayHost({
    super.key,
    required this.child,
    required this.controller,
  });

  final Widget child;
  final AiseeInAppMessageController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? _) {
        final AiseeInAppMessageNotification? notification = controller.current;
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            child,
            if (controller.shouldShow && notification != null)
              _InAppMessageBanner(
                notification: notification,
                onDismiss: controller.hide,
              ),
          ],
        );
      },
    );
  }
}

class _InAppMessageBanner extends StatelessWidget {
  const _InAppMessageBanner({
    required this.notification,
    required this.onDismiss,
  });

  final AiseeInAppMessageNotification notification;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Align(
          alignment: Alignment.topCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, -14 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Material(
                color: StyleTokens.surfaceCard,
                elevation: 10,
                shadowColor: const Color(0x24060913),
                borderRadius: BorderRadius.circular(22),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: StyleTokens.navBarBorder.withValues(alpha: 0.18),
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Row(
                    children: <Widget>[
                      _MessageAvatar(notification: notification),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              notification.senderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: aiseeTextStyle(
                                color: StyleTokens.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              notification.preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: aiseeTextStyle(
                                color: StyleTokens.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.28,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Semantics(
                        label: AppLocalizations.of(context).closeAction,
                        button: true,
                        child: IconButton(
                          onPressed: onDismiss,
                          icon: const Icon(Icons.close_rounded),
                          color: StyleTokens.textSecondary,
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(
                            width: 32,
                            height: 32,
                          ),
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
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: StyleTokens.navInactivePill,
        shape: BoxShape.circle,
        border: Border.all(color: StyleTokens.navGlassBorder),
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
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
