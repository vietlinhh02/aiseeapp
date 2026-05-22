import 'dart:async';

import 'package:aiseeapp/generated/l10n/app_localizations.dart';
import 'package:aiseeapp/models/aisee_family_member.dart';
import 'package:aiseeapp/models/aisee_family_group.dart';
import 'package:aiseeapp/services/aisee_family_service.dart';
import 'package:aiseeapp/screens/family_contacts_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'closing create-invite sheet does not use a disposed controller',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FamilyContactsTab(
              familyService: _FakeFamilyService(),
              readAccessToken: () async => 'test-access-token',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Tạo mã mời 6 số'), findsWidgets);

      await tester.tap(find.text('Tạo mã mời 6 số').first);
      await tester.pumpAndSettle();

      expect(find.text('Mã mời 6 số'), findsOneWidget);

      Navigator.of(tester.element(find.text('Sao chép mã'))).pop();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'successful invite creation closes the sheet without using a disposed controller',
    (WidgetTester tester) async {
      final Completer<String> inviteCompleter = Completer<String>();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FamilyContactsTab(
              familyService: _FakeFamilyService(
                inviteCompleter: inviteCompleter,
              ),
              readAccessToken: () async => 'test-access-token',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tạo mã mời 6 số').first);
      await tester.pump();

      inviteCompleter.complete('123456');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('non-owner hides invite action and still shows leave action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FamilyContactsTab(
            familyService: _FakeFamilyService(
              currentGroup: const AiseeCurrentGroup(
                id: 'group-1',
                name: 'Gia dinh A',
                ownerUserId: 'owner-1',
                currentUserRole: 'family',
                canManageGroup: false,
                canManageBilling: false,
                familyMembers: <AiseeCareGroupPerson>[
                  AiseeCareGroupPerson(
                    id: 'owner-1',
                    email: 'owner@example.com',
                    accountRole: 'family',
                    groupRole: 'owner',
                  ),
                  AiseeCareGroupPerson(
                    id: 'member-1',
                    email: 'member@example.com',
                    accountRole: 'family',
                    groupRole: 'family',
                  ),
                ],
                caredUsers: <AiseeCareGroupPerson>[
                  AiseeCareGroupPerson(
                    id: 'user-1',
                    email: 'user@example.com',
                    accountRole: 'user',
                    groupRole: 'cared_user',
                  ),
                ],
              ),
            ),
            readAccessToken: () async => 'test-access-token',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tạo mã mời 6 số'), findsNothing);
    expect(find.text('Rời nhóm'), findsOneWidget);
  });
}

class _FakeFamilyService extends AiseeFamilyService {
  _FakeFamilyService({this.inviteCompleter, this.currentGroup});

  final Completer<String>? inviteCompleter;
  final AiseeCurrentGroup? currentGroup;

  @override
  Future<List<AiseeFamilyMember>> fetchFamily(String accessToken) async {
    return const <AiseeFamilyMember>[
      AiseeFamilyMember(
        id: 'member-1',
        email: 'family@example.com',
        displayName: 'Nguoi than',
        role: 'family',
      ),
    ];
  }

  @override
  Future<String> createInvite(String accessToken, String relationship) async {
    return inviteCompleter == null ? '123456' : inviteCompleter!.future;
  }

  @override
  Future<AiseeCurrentGroup?> fetchCurrentGroup(String accessToken) async {
    return currentGroup ??
        const AiseeCurrentGroup(
          id: 'group-1',
          name: 'Gia dinh A',
          ownerUserId: 'owner-1',
          currentUserRole: 'owner',
          canManageGroup: true,
          canManageBilling: true,
          familyMembers: <AiseeCareGroupPerson>[
            AiseeCareGroupPerson(
              id: 'owner-1',
              email: 'owner@example.com',
              accountRole: 'family',
              groupRole: 'owner',
            ),
          ],
          caredUsers: <AiseeCareGroupPerson>[
            AiseeCareGroupPerson(
              id: 'member-1',
              email: 'family@example.com',
              displayName: 'Nguoi than',
              accountRole: 'user',
              groupRole: 'cared_user',
            ),
          ],
        );
  }

  @override
  void close() {}
}
