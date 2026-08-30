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

import 'package:flutter_test/flutter_test.dart';
import 'package:partners_ref_app/models/session.dart';

void main() {
  group('Session.toJson / tryParse', () {
    const session = Session(
      token: 'a.b.c',
      userId: 'EXAMPLE-001',
      partnerId: 'EXAMPLE',
    );

    test('round-trips through toJson/tryParse', () {
      final restored = Session.tryParse(session.toJson());
      expect(restored?.token, 'a.b.c');
      expect(restored?.userId, 'EXAMPLE-001');
      expect(restored?.partnerId, 'EXAMPLE');
    });

    test('tryParse returns null when a field is missing', () {
      expect(Session.tryParse({'token': 'a.b.c', 'partnerId': 'EXAMPLE'}), isNull);
    });

    test('tryParse returns null when a field has the wrong type', () {
      expect(
        Session.tryParse({'token': 1, 'userId': 'x', 'partnerId': 'EXAMPLE'}),
        isNull,
      );
    });

    test('tryParse returns null for an empty map', () {
      expect(Session.tryParse({}), isNull);
    });
  });
}
