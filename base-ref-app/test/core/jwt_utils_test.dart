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
import 'package:partners_ref_app/core/jwt_utils.dart';

String _jwt(Map<String, dynamic> payload) {
  String seg(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${seg({
        'alg': 'none'
      })}.${seg(payload)}.sig';
}

void main() {
  group('isJwtExpired', () {
    test('returns false for a token with a future exp', () {
      final future = DateTime.now().toUtc().add(const Duration(hours: 1));
      final token = _jwt({'exp': future.millisecondsSinceEpoch ~/ 1000});
      expect(isJwtExpired(token), false);
    });

    test('returns true for a token with a past exp', () {
      final past = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final token = _jwt({'exp': past.millisecondsSinceEpoch ~/ 1000});
      expect(isJwtExpired(token), true);
    });

    test('returns true for a token expiring exactly now', () {
      final now = DateTime.now().toUtc();
      final token = _jwt({'exp': now.millisecondsSinceEpoch ~/ 1000});
      expect(isJwtExpired(token), true);
    });

    test('returns true when exp claim is missing', () {
      expect(isJwtExpired(_jwt({'userId': 'EXAMPLE-001'})), true);
    });

    test('returns true when exp is not an int', () {
      expect(isJwtExpired(_jwt({'exp': 'not-a-number'})), true);
    });

    test('returns true for a malformed token (not 3 parts)', () {
      expect(isJwtExpired('not-a-jwt'), true);
    });

    test('returns true for a token with an unparseable payload segment', () {
      expect(isJwtExpired('header.not-base64url!!!.sig'), true);
    });
  });
}
