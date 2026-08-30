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
import '../core/config.dart';
import '../models/session.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  final Dio _dio;

  AuthService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.bffBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ));

  Future<Session> login(String userId) async {
    final trimmedUserId = userId.trim();
    try {
      final response = await _dio.post<dynamic>(
        '/api/auth/login',
        data: {'userId': trimmedUserId},
      );
      final data = response.data as Map<String, dynamic>;
      // The BFF resolves partnerId server-side from the userId prefix and
      // returns only { token, partnerId } — the client never supplies it.
      return Session(
        token: data['token'] as String,
        partnerId: data['partnerId'] as String,
        userId: trimmedUserId,
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 500;
      if (statusCode == 401) {
        throw const AuthException('Invalid user ID');
      }
      throw const AuthException('Login failed. Please try again.');
    }
  }
}
