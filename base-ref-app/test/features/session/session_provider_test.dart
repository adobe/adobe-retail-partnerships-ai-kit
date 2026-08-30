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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partners_ref_app/features/session/session_provider.dart';
import 'package:partners_ref_app/models/session.dart';
import 'package:partners_ref_app/services/session_storage.dart';

class _FakeSessionStorage implements SessionStorage {
  Session? saved;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<void> save(Session session) async {
    saved = session;
    saveCalls++;
  }

  @override
  Future<void> clear() async {
    saved = null;
    clearCalls++;
  }

  @override
  Future<Session?> load() async => saved;
}

void main() {
  late ProviderContainer container;
  late _FakeSessionStorage storage;

  setUp(() {
    storage = _FakeSessionStorage();
    container = ProviderContainer(
      overrides: [sessionStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
  });

  const testSession = Session(
    token: 'test.jwt.token',
    userId: 'EXAMPLE-001',
    partnerId: 'EXAMPLE',
  );

  test('initial session is null (signed out)', () {
    expect(container.read(sessionProvider), isNull);
  });

  test('signIn sets the session', () {
    container.read(sessionProvider.notifier).signIn(testSession);
    final s = container.read(sessionProvider);
    expect(s?.token, 'test.jwt.token');
    expect(s?.userId, 'EXAMPLE-001');
    expect(s?.partnerId, 'EXAMPLE');
  });

  test('signOut clears the session', () {
    container.read(sessionProvider.notifier).signIn(testSession);
    container.read(sessionProvider.notifier).signOut();
    expect(container.read(sessionProvider), isNull);
  });

  test('signIn persists the session to storage', () {
    container.read(sessionProvider.notifier).signIn(testSession);
    expect(storage.saveCalls, 1);
    expect(storage.saved?.userId, 'EXAMPLE-001');
  });

  test('signOut clears the session from storage', () {
    container.read(sessionProvider.notifier).signIn(testSession);
    container.read(sessionProvider.notifier).signOut();
    expect(storage.clearCalls, 1);
    expect(storage.saved, isNull);
  });
}
