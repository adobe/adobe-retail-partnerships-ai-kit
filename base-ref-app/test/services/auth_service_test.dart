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

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partners_ref_app/services/auth_service.dart';

class _MockDio extends Fake implements Dio {
  late Response<dynamic> Function(String path, dynamic data) _postHandler;

  void mockPost(Response<dynamic> Function(String, dynamic) handler) {
    _postHandler = handler;
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
  }) async {
    return _postHandler(path, data) as Response<T>;
  }
}

void main() {
  late _MockDio mockDio;
  late AuthService service;

  setUp(() {
    mockDio = _MockDio();
    service = AuthService(dio: mockDio);
  });

  test('login builds a Session from { token, partnerId } only (no server-side reference id in response)',
      () async {
    Map<String, dynamic>? capturedBody;
    mockDio.mockPost((path, data) {
      capturedBody = data as Map<String, dynamic>;
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        // The BFF returns ONLY token + partnerId — the reference id is
        // server-authoritative and never sent at login.
        data: {'token': 'jwt-abc', 'partnerId': 'EXAMPLE'},
      );
    });

    final session = await service.login('  EXAMPLE-001  ');

    expect(session.token, 'jwt-abc');
    expect(session.partnerId, 'EXAMPLE');
    // Must not throw on the absent server-side reference id; the trimmed userId is the
    // session's subscription handle.
    expect(session.userId, 'EXAMPLE-001');
    expect(capturedBody?['userId'], 'EXAMPLE-001');
    // userId-prefix login only — no password is sent.
    expect(capturedBody?.containsKey('password'), false);
  });

  test('login throws AuthException on 401', () async {
    mockDio.mockPost((path, data) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: 401,
        ),
      );
    });

    expect(
      () => service.login('EXAMPLE-001'),
      throwsA(isA<AuthException>()),
    );
  });
}
