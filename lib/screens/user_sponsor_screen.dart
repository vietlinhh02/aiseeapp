import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/style_tokens.dart';
import '../utils/app_toast.dart';
import '../generated/l10n/app_localizations.dart';

typedef SponsorUrlLauncher = Future<bool> Function(Uri url, {LaunchMode mode});

class _SponsorInfo {
  const _SponsorInfo({
    required this.name,
    required this.websiteLabel,
    required this.websiteUri,
    required this.logoUrl,
    required this.description,
  });

  final String name;
  final String websiteLabel;
  final Uri websiteUri;
  final String logoUrl;
  final String description;
}

class UserSponsorScreen extends StatelessWidget {
  const UserSponsorScreen({super.key, this.launchUrlFn = launchUrl});

  final SponsorUrlLauncher launchUrlFn;

  _SponsorInfo _getDavo(AppLocalizations l10n) {
    return _SponsorInfo(
      name: 'DAVO',
      websiteLabel: 'davoice.io',
      websiteUri: Uri.parse('https://davoice.io/'),
      logoUrl: 'https://davoice.io/logo%20new%2096px.jpg',
      description: l10n.sponsorsDavoDescription,
    );
  }

  Future<void> _openSponsorWebsite(BuildContext context) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final _SponsorInfo davo = _getDavo(l10n);
    try {
      final bool launched = await launchUrlFn(
        davo.websiteUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await AppToast.show(l10n.sponsorsCannotOpen, isError: true);
      }
    } catch (_) {
      await AppToast.show(l10n.sponsorsCannotOpen, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final _SponsorInfo davo = _getDavo(l10n);
    return Scaffold(
      backgroundColor: StyleTokens.background,
      appBar: AppBar(
        title: Text(
          l10n.sponsorsTitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: StyleTokens.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Text(
            l10n.personalSponsorsSubtitle,
            style: StyleTokens.bodySmall().copyWith(
              fontSize: 14,
              color: StyleTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            container: true,
            label:
                '${l10n.sponsorsTitle} ${davo.name}. Website ${davo.websiteLabel}.',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: StyleTokens.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: StyleTokens.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: StyleTokens.background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          davo.logoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) {
                            return Center(
                              child: Text(
                                davo.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: StyleTokens.buttonPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              davo.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: StyleTokens.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              davo.websiteLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: StyleTokens.linkAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(davo.description, style: StyleTokens.bodySmall()),
                  const SizedBox(height: 16),
                  Semantics(
                    button: true,
                    label: l10n.sponsorsOpenDavo,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _openSponsorWebsite(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: StyleTokens.buttonPrimary,
                          foregroundColor: StyleTokens.buttonOnPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.sponsorsOpenWebsite,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
