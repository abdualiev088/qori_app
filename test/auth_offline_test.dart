import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hifz_app/data/api_client.dart';
import 'package:hifz_app/data/auth_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _user = {'id': 'u1', 'email': 'aziz@mail.com', 'display_name': 'Aziz', 'is_guest': false, 'has_password': true};

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  ApiClient client({required bool online}) => ApiClient(
        baseUrl: 'https://api.test/v1',
        tokens: MemoryTokenStore(const Tokens(access: 'a', refresh: 'r')),
        client: MockClient((request) async {
          if (!online) throw http.ClientException('no internet');
          return http.Response(jsonEncode(_user), 200, headers: {'content-type': 'application/json'});
        }),
      );

  test('a signed-in user is remembered across launches and stays signed in offline', () async {
    final first = AuthApi(client(online: true), prefs: prefs);
    expect(await first.loadMe(), isTrue);
    expect(first.signedIn, isTrue);

    // Next launch, no internet: still signed in, from what the device remembers.
    final offline = AuthApi(client(online: false), prefs: prefs);
    expect(offline.signedIn, isTrue);
    expect(offline.user!.displayName, 'Aziz');
    expect(await offline.loadMe(), isFalse);
    expect(offline.signedIn, isTrue);
  });

  test('logging out forgets the remembered user, even offline', () async {
    final api = AuthApi(client(online: true), prefs: prefs);
    await api.loadMe();
    final offline = AuthApi(client(online: false), prefs: prefs);
    await offline.signOut();
    expect(offline.signedIn, isFalse);
    expect(AuthApi(client(online: false), prefs: prefs).signedIn, isFalse);
  });
}
