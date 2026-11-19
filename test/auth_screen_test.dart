import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/data/auth_api.dart';
import 'package:qori_app/screens/auth_screen.dart';
import 'package:qori_app/theme/tokens.dart';

import 'fake_auth_api.dart';

/// Hifdth's idle loop never stops, so pumpAndSettle can't be used; this lets
/// page transitions and the step switch finish instead.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUp(() => HText.useGoogleFonts = false);

  /// A button under the auth screen that opens it and records what it pops with.
  Future<List<bool?>> open(WidgetTester tester, AuthApi api) async {
    final results = <bool?>[];
    // A tall phone, so the whole create-account step fits on screen.
    tester.view
      ..physicalSize = const Size(1206, 2622)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => results
              .add(await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => AuthScreen(api: api)))),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await settle(tester);
    return results;
  }

  Finder field(String label) => find.descendant(
      of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first, matching: find.byType(TextField));

  testWidgets('errors wait for the first try, then clear while typing', (tester) async {
    await open(tester, FakeAuthApi());
    expect(find.text('Enter your email'), findsNothing);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);

    await tester.enterText(field('Email'), 'aziz@');
    await tester.pump();
    expect(find.text('That email looks incomplete'), findsOneWidget);

    await tester.enterText(field('Email'), 'aziz@mail.com');
    await tester.pump();
    expect(find.text('That email looks incomplete'), findsNothing);
  });

  testWidgets('a new email signs up, and the same email then signs in', (tester) async {
    final api = FakeAuthApi();
    var results = await open(tester, api);

    await tester.enterText(field('Email'), 'aziz@mail.com');
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Nice to meet you'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);

    await tester.enterText(field('Name'), 'Aziz');
    await tester.enterText(field('Password'), 'short');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();
    expect(find.text('Use at least 8 characters'), findsOneWidget);

    await tester.enterText(field('Password'), 'longenough1');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await settle(tester);
    expect(results, [true]);

    results = await open(tester, api);
    await tester.enterText(field('Email'), 'AZIZ@mail.com ');
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Name'), findsNothing);
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('Change goes back to the email step', (tester) async {
    await open(tester, FakeAuthApi());
    await tester.enterText(field('Email'), 'aziz@mail.com');
    await tester.tap(find.text('Continue'));
    await settle(tester);

    await tester.tap(find.text('Change'));
    await settle(tester);
    expect(find.text('Sign in or sign up'), findsOneWidget);
    expect(find.text('aziz@mail.com'), findsOneWidget); // kept, ready to fix
  });

  testWidgets('Apple and Google close the screen as signed in', (tester) async {
    final results = await open(tester, FakeAuthApi());
    await tester.ensureVisible(find.text('Continue with Apple'));
    await tester.tap(find.text('Continue with Apple'));
    await settle(tester);
    expect(results, [true]);
  });

  testWidgets('a wrong password shows under the field and clears while typing', (tester) async {
    final api = FakeAuthApi();
    await api.createAccount(name: 'A', email: 'aziz@mail.com', password: 'x');
    final results = await open(tester, api);
    await tester.enterText(field('Email'), 'aziz@mail.com');
    await tester.tap(find.text('Continue'));
    await settle(tester);

    api.failNext = wrongPassword();
    await tester.enterText(field('Password'), 'nottheone1');
    await tester.tap(find.text('Sign in'));
    await settle(tester);
    expect(find.text('Wrong email or password.'), findsOneWidget);
    expect(results, isEmpty);

    await tester.enterText(field('Password'), 'nottheone12');
    await tester.pump();
    expect(find.text('Wrong email or password.'), findsNothing);
  });

  testWidgets('a rejected sign-up password shows the server rule', (tester) async {
    final api = FakeAuthApi();
    await open(tester, api);
    await tester.enterText(field('Email'), 'new@mail.com');
    await tester.tap(find.text('Continue'));
    await settle(tester);

    await tester.enterText(field('Name'), 'Aziz');
    await tester.enterText(field('Password'), 'nonumbers');
    api.failNext = ApiException(400, 'invalid', 'Password must contain a number.', fields: {
      'password': ['Password must contain a number.'],
    });
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await settle(tester);
    expect(find.text('Password must contain a number.'), findsOneWidget);
  });

  testWidgets('offline shows a snackbar and stays on the step', (tester) async {
    final api = FakeAuthApi()..failNext = ApiException.offline();
    await open(tester, api);
    await tester.enterText(field('Email'), 'aziz@mail.com');
    await tester.tap(find.text('Continue'));
    await settle(tester);
    expect(find.textContaining("Can't reach Qori"), findsOneWidget);
    expect(find.text('Sign in or sign up'), findsOneWidget);
  });

  testWidgets('closing the Apple sheet keeps the screen open, with no message', (tester) async {
    final api = FakeAuthApi()..failNext = SignInCancelled();
    final results = await open(tester, api);
    await tester.ensureVisible(find.text('Continue with Apple'));
    await tester.tap(find.text('Continue with Apple'));
    await settle(tester);
    expect(results, isEmpty);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Sign in or sign up'), findsOneWidget);
  });
}
