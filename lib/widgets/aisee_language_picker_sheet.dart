import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../config/aisee_locale_controller.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/aisee_family_service.dart';
import '../services/aisee_session_store.dart';
import '../models/aisee_api_models.dart';
import '../theme/style_tokens.dart';

class AiseeLanguagePickerSheet extends StatefulWidget {
  const AiseeLanguagePickerSheet({super.key});

  static const int _maxBarrierWaitFrames = 24;

  static Future<void> show(BuildContext context) async {
    final Element? overlayRoot =
        Navigator.of(context, rootNavigator: true).overlay?.context as Element?;
    final Locale? selected = await showModalBottomSheet<Locale>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiseeLanguagePickerSheet(),
    );
    if (selected == null) return;
    await _waitForBarrierToClear(overlayRoot);
    await AiseeLocaleController.instance.setLocale(selected);
    await _syncBackend(selected.languageCode);
  }

  static Future<void> _waitForBarrierToClear(Element? overlayRoot) async {
    if (overlayRoot == null) return;
    for (int i = 0; i < _maxBarrierWaitFrames; i++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!_containsModalBarrier(overlayRoot)) return;
    }
  }

  static bool _containsModalBarrier(Element root) {
    bool found = false;

    void visit(Element element) {
      if (found) return;
      if (element.widget is ModalBarrier) {
        found = true;
        return;
      }
      element.visitChildElements(visit);
    }

    visit(root);
    return found;
  }

  @override
  State<AiseeLanguagePickerSheet> createState() =>
      _AiseeLanguagePickerSheetState();
}

class _AiseeLanguagePickerSheetState extends State<AiseeLanguagePickerSheet> {
  bool _saving = false;

  void _select(Locale locale) {
    if (_saving) return;
    setState(() => _saving = true);
    Navigator.of(context).pop(locale);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final Locale current = AiseeLocaleController.instance.value;
    final bool isEn = current.languageCode == 'en';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: StyleTokens.surfaceCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: StyleTokens.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l.settingsLanguageSection,
                        style: aiseeTextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      l.settingsLanguageLabel,
                      style: aiseeTextStyle(
                        fontSize: 12,
                        color: StyleTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LanguageOption(
                  countryCode: 'VN',
                  label: l.languageVi,
                  nativeName: 'Tiếng Việt',
                  selected: !isEn,
                  enabled: !_saving,
                  onTap: () => _select(const Locale('vi')),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _LanguageOption(
                  countryCode: 'US',
                  label: l.languageEn,
                  nativeName: 'English',
                  selected: isEn,
                  enabled: !_saving,
                  onTap: () => _select(const Locale('en')),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _syncBackend(String code) async {
  final AiseeAuthTokens? tokens = await AiseeSessionStore.instance.read();
  if (tokens == null) return;
  final AiseeFamilyService svc = AiseeFamilyService();
  try {
    await svc.updateProfile(tokens.accessToken, <String, dynamic>{
      'settings': <String, dynamic>{'preferred_language': code},
    });
  } catch (_) {
  } finally {
    svc.close();
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.countryCode,
    required this.label,
    required this.nativeName,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String countryCode;
  final String label;
  final String nativeName;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? StyleTokens.buttonPrimary : StyleTokens.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? StyleTokens.buttonPrimary
                  : StyleTokens.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CountryFlag.fromCountryCode(
                    countryCode,
                    theme: const ImageTheme(
                      width: 44,
                      height: 44,
                      shape: RoundedRectangle(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: aiseeTextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? StyleTokens.buttonOnPrimary
                            : StyleTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nativeName,
                      style: aiseeTextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? StyleTokens.buttonOnPrimary.withValues(
                                alpha: 0.75,
                              )
                            : StyleTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: StyleTokens.buttonPrimary,
                  ),
                )
              else
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: StyleTokens.cardBorder),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
