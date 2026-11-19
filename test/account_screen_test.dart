import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/data/auth_api.dart';
import 'package:qori_app/screens/account_screen.dart';
import 'package:qori_app/theme/tokens.dart';

import 'fake_auth_api.dart';

/// Hifdth's idle loop never stops, so pumpAndSettle can't be used.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => HText.useGoogleFonts = false);

  FakeAuthApi signedIn({bool hasPassword = true}) =>
      FakeAuthApi()..user = QoriUser(id: '1', email: 'aziz@mail.com', displayName: 'Aziz', hasPassword: hasPassword);

  Future<void> open(WidgetTester tester, AuthApi api) async {
    tester.view
      ..physicalSize = const Size(1206, 2622)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => AccountScreen(api: api))),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  testWidgets('shows only account settings and log out', (tester) async {
    await open(tester, signedIn());
    expect(find.text('ACCOUNT SETTINGS'), findsOneWidget);
    expect(find.text('Aziz'), findsNWidgets(2)); // heading and the Name row
    expect(find.text('aziz@mail.com'), findsNWidgets(2)); // under the name and the Email row
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('Apple- or Google-only accounts have no password row', (tester) async {
    await open(tester, signedIn(hasPassword: false));
    expect(find.text('Password'), findsNothing);
  });

  testWidgets('log out asks first, then signs out and closes', (tester) async {
    final api = signedIn();
    await open(tester, api);

    await tester.tap(find.text('Log out'));
    await settle(tester);
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(api.user, isNotNull);

    await tester.tap(find.text('Log out'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Log out'));
    await settle(tester);
    expect(api.user, isNull);
    expect(find.byType(AccountScreen), findsNothing);
  });

  testWidgets('renaming updates the page', (tester) async {
    final api = signedIn();
    await open(tester, api);
    await tester.tap(find.text('Name'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Abdulaziz');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(api.user!.displayName, 'Abdulaziz');
    expect(find.text('Abdulaziz'), findsNWidgets(2));
  });
}
