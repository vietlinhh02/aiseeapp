import 'package:flutter/material.dart';
import 'package:aiseeapp/theme/aisee_typography.dart';

import '../theme/style_tokens.dart';
import '../generated/l10n/app_localizations.dart';

class FamilyDashboardMedFormSheet extends StatefulWidget {
  const FamilyDashboardMedFormSheet({
    this.name = '',
    this.dosage = '',
    this.times = '',
    this.frequency = 'daily',
    super.key,
  });

  final String name;
  final String dosage;
  final String times;
  final String frequency;

  @override
  State<FamilyDashboardMedFormSheet> createState() =>
      _FamilyDashboardMedFormSheetState();
}

class _FamilyDashboardMedFormSheetState
    extends State<FamilyDashboardMedFormSheet> {
  late final TextEditingController nameC;
  late final TextEditingController dosageC;
  late final TextEditingController timesC;
  late final TextEditingController freqC;

  @override
  void initState() {
    super.initState();
    nameC = TextEditingController(text: widget.name);
    dosageC = TextEditingController(text: widget.dosage);
    timesC = TextEditingController(text: widget.times);
    freqC = TextEditingController(text: widget.frequency);
  }

  @override
  void dispose() {
    nameC.dispose();
    dosageC.dispose();
    timesC.dispose();
    freqC.dispose();
    super.dispose();
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: aiseeTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: StyleTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: aiseeTextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: StyleTokens.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: StyleTokens.inputHint(),
            filled: true,
            fillColor: StyleTokens.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: StyleTokens.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: StyleTokens.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: StyleTokens.buttonPrimary),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: StyleTokens.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.name.isEmpty
                ? l10n.dashboardMedFormAddTitle
                : l10n.dashboardMedFormEditTitle,
            style: aiseeTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: StyleTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            nameC,
            l10n.dashboardMedFormNameLabel,
            l10n.dashboardMedFormNameHint,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            dosageC,
            l10n.dashboardMedFormDosageLabel,
            l10n.dashboardMedFormDosageHint,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            timesC,
            l10n.dashboardMedFormTimesLabel,
            l10n.dashboardMedFormTimesHint,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            freqC,
            l10n.dashboardMedFormFreqLabel,
            l10n.dashboardMedFormFreqHint,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: StyleTokens.surfaceCard,
                  borderRadius: BorderRadius.circular(31),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(31),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.dashboardMedFormCancel,
                        style: aiseeTextStyle(
                          fontWeight: FontWeight.w600,
                          color: StyleTokens.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: StyleTokens.buttonPrimary,
                  borderRadius: BorderRadius.circular(31),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(31),
                    onTap: () {
                      if (nameC.text.trim().isEmpty) return;
                      Navigator.pop(context, {
                        'name': nameC.text.trim(),
                        'dosage': dosageC.text.trim(),
                        'times': timesC.text.trim(),
                        'frequency': freqC.text.trim(),
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.dashboardMedFormSave,
                        style: aiseeTextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
