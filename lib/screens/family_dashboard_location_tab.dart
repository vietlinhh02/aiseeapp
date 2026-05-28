import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:aiseeapp/theme/aisee_typography.dart';


import '../config/mapbox_static_preview.dart';

import '../models/aisee_dashboard_models.dart';

import '../theme/style_tokens.dart';

import '../generated/l10n/app_localizations.dart';

import 'family_dashboard_format.dart';
import '../widgets/app_loading_indicator.dart';


class FamilyDashboardLocationTab extends StatelessWidget {
  const FamilyDashboardLocationTab({
    required this.loading,
    required this.location,
    required this.onRefresh,
    required this.onOpenMaps,
    super.key,
  });

  final bool loading;
  final UserLocation? location;
  final Future<void> Function() onRefresh;
  final void Function(double lat, double lng) onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (loading) {
      return const ColoredBox(
        color: StyleTokens.background,
        child: AppLoadingIndicator(),
      );
    }
    final loc = location;
    if (loc == null || !loc.hasLocation) {
      return _EmptyLocationState(onRefresh: onRefresh);
    }
    final lat = loc.lat!;
    final lng = loc.lng!;

    return ColoredBox(
      color: StyleTokens.background,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: StyleTokens.buttonPrimary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    l10n.dashboardLocationTitle,
                    style: aiseeTextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: StyleTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.dashboardLocationSubtitle,
                    style: aiseeTextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                      color: StyleTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _MapPreviewCard(
                    lat: lat,
                    lng: lng,
                    updatedAt: loc.updatedAt,
                    onOpenMaps: () => onOpenMaps(lat, lng),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLocationState extends StatelessWidget {
  const _EmptyLocationState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: StyleTokens.background,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        color: StyleTokens.buttonPrimary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/nav/ic_location.svg',
                      width: 56,
                      height: 56,
                      colorFilter: const ColorFilter.mode(
                        StyleTokens.textMuted,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.dashboardLocationNoLocation,
                      textAlign: TextAlign.center,
                      style: aiseeTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: StyleTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.dashboardLocationPullHint,
                      textAlign: TextAlign.center,
                      style: aiseeTextStyle(
                        fontSize: 13,
                        color: StyleTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPreviewCard extends StatelessWidget {
  const _MapPreviewCard({
    required this.lat,
    required this.lng,
    required this.updatedAt,
    required this.onOpenMaps,
  });

  final double lat;
  final double lng;
  final DateTime? updatedAt;
  final VoidCallback onOpenMaps;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final mq = MediaQuery.of(context);
    final wPx = ((mq.size.width - 32) * mq.devicePixelRatio).round().clamp(
      400,
      1280,
    );
    final hPx = (wPx * 0.56).round().clamp(240, 1280);
    final uri = MapboxStaticPreview.previewUri(
      lng,
      lat,
      widthPx: wPx,
      heightPx: hPx,
    );

    return Container(
      decoration: BoxDecoration(
        color: StyleTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StyleTokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: wPx / hPx,
            child: uri != null
                ? _MapboxNetworkPreview(
                    key: ValueKey<String>(uri.toString()),
                    uri: uri,
                  )
                : const _MapboxMissingTokenPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.dashboardLocationCoordinates,
                  style: aiseeTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: StyleTokens.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                  style: aiseeTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: StyleTokens.textPrimary,
                    height: 1.25,
                  ),
                ),
                if (updatedAt != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.dashboardLocationUpdated(
                      formatFamilyDashboardTime(updatedAt!),
                    ),
                    style: aiseeTextStyle(
                      fontSize: 13,
                      color: StyleTokens.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: StyleTokens.buttonPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(31),
                  ),
                ),
                onPressed: onOpenMaps,
                icon: SvgPicture.asset(
                  'assets/icons/nav/ic_location.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                label: Text(
                  l10n.dashboardLocationOpenMaps,
                  style: aiseeTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

class _MapboxNetworkPreview extends StatelessWidget {
  const _MapboxNetworkPreview({required this.uri, super.key});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.dashboardLocationMapSemantics,
      child: Image.network(
        uri.toString(),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return ColoredBox(
            color: StyleTokens.background,
            child: Center(
              child: SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: StyleTokens.buttonPrimary,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const _MapLoadErrorPlaceholder();
        },
      ),
    );
  }
}

class _MapboxMissingTokenPlaceholder extends StatelessWidget {
  const _MapboxMissingTokenPlaceholder();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: StyleTokens.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/nav/ic_discovery.svg',
                width: 40,
                height: 40,
                colorFilter: const ColorFilter.mode(
                  StyleTokens.textMuted,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.dashboardLocationMapboxMissing,
                textAlign: TextAlign.center,
                style: aiseeTextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: StyleTokens.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.dashboardLocationMapboxHint,
                textAlign: TextAlign.center,
                style: aiseeTextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: StyleTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapLoadErrorPlaceholder extends StatelessWidget {
  const _MapLoadErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: StyleTokens.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            l10n.dashboardLocationMapError,
            textAlign: TextAlign.center,
            style: aiseeTextStyle(
              fontSize: 13,
              color: StyleTokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
