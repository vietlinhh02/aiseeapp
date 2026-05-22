import 'package:aiseeapp/generated/l10n/app_localizations.dart';
import 'package:aiseeapp/models/agent_state.dart';
import 'package:aiseeapp/screens/user_assistant_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('assistant tab shows persistent wake hint card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildTab(showWakeReminder: false));

    expect(find.text('Gọi “aisee ơi” để đánh thức trợ lý'), findsOneWidget);
  });

  testWidgets(
    'assistant tab shows timeout reminder card when session ended by silence',
    (WidgetTester tester) async {
      await tester.pumpWidget(_buildTab(showWakeReminder: true));

      expect(find.text('AiSee đã nghỉ vì im lặng'), findsOneWidget);
      expect(
        find.text('Muốn nói tiếp, hãy gọi lại “aisee ơi”.'),
        findsOneWidget,
      );
    },
  );
}

Widget _buildTab({required bool showWakeReminder}) {
  return MaterialApp(
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: UserAssistantTab(
        aiseeLoading: false,
        aiseeError: null,
        assistantConnecting: false,
        assistantError: null,
        assistantConnected: true,
        assistantWaveEnergy: ValueNotifier<double>(0),
        agentState: ValueNotifier<AgentState>(AgentState.idle),
        showWakeReminder: showWakeReminder,
        onRetryAssistant: () async {},
      ),
    ),
  );
}
