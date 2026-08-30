/*
Copyright (c) 2026 Adobe. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:partners_ref_app/models/session.dart';
import 'package:partners_ref_app/services/session_storage.dart';

String _jwt(int expUnixSeconds) {
  String seg(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${seg({
        'alg': 'none'
      })}.${seg({
        'exp': expUnixSeconds
      })}.sig';
}

void main() {
  late SessionStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = SessionStorage();
  });

  test('load returns null when nothing has been saved', () async {
    expect(await storage.load(), isNull);
  });

  test('save then load round-trips a non-expired session', () async {
    final future = DateTime.now().toUtc().add(const Duration(hours: 1));
    final session = Session(
      token: _jwt(future.millisecondsSinceEpoch ~/ 1000),
      userId: 'EXAMPLE-001',
      partnerId: 'EXAMPLE',
    );

    await storage.save(session);
    final loaded = await storage.load();

    expect(loaded?.userId, 'EXAMPLE-001');
    expect(loaded?.partnerId, 'EXAMPLE');
  });

  test('load returns null and self-clears for an already-expired token', () async {
    final past = DateTime.now().toUtc().subtract(const Duration(hours: 1));
    final session = Session(
      token: _jwt(past.millisecondsSinceEpoch ~/ 1000),
      userId: 'EXAMPLE-001',
      partnerId: 'EXAMPLE',
    );
    await storage.save(session);

    expect(await storage.load(), isNull);
    // Self-cleared: a second load (fresh instance) still sees nothing.
    expect(await SessionStorage().load(), isNull);
  });

  test('load returns null for corrupt stored data (does not throw)', () async {
    SharedPreferences.setMockInitialValues({'partners_ref_app_session': 'not-json'});
    expect(await SessionStorage().load(), isNull);
  });

  test('load returns null when a required field is missing', () async {
    SharedPreferences.setMockInitialValues({
      'partners_ref_app_session': jsonEncode({'token': 'a.b.c'}),
    });
    expect(await SessionStorage().load(), isNull);
  });

  test('clear removes a previously saved session', () async {
    final future = DateTime.now().toUtc().add(const Duration(hours: 1));
    final session = Session(
      token: _jwt(future.millisecondsSinceEpoch ~/ 1000),
      userId: 'EXAMPLE-001',
      partnerId: 'EXAMPLE',
    );
    await storage.save(session);
    await storage.clear();
    expect(await storage.load(), isNull);
  });
}
