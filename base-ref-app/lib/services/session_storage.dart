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
import 'package:shared_preferences/shared_preferences.dart';
import '../core/jwt_utils.dart';
import '../models/session.dart';

/// Persists the [Session] across page refreshes/app restarts. Backed by
/// `shared_preferences`, which on web is `localStorage` — the session lives
/// until the JWT's own expiry (checked on [load], not enforced here) or an
/// explicit [clear] on sign-out.
class SessionStorage {
  static const _key = 'partners_ref_app_session';

  Future<void> save(Session session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Returns the persisted session, or null if there isn't one, it's
  /// corrupt, or its JWT has already expired (in which case it's also
  /// cleared, so we don't keep re-checking a dead session on every launch).
  Future<Session?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;

    Session? session;
    try {
      session = Session.tryParse(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      session = null;
    }

    if (session == null || isJwtExpired(session.token)) {
      await clear();
      return null;
    }
    return session;
  }
}
