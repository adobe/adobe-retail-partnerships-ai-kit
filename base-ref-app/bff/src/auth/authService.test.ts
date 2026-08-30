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

import { describe, it, expect, beforeAll, beforeEach } from 'vitest';

beforeAll(() => {
  process.env.JWT_SECRET = 'test-secret';
});

describe('authService (DB-backed)', () => {
  beforeEach(async () => {
    const { InMemoryPartnerStore, setPartnerStore } = await import('../db/partnerStore');
    const store = new InMemoryPartnerStore();
    await store.upsert({ id: 'EXAMPLE', displayName: 'Example' });
    setPartnerStore(store);
  });

  // userId-prefix login only — no password (see authService.ts).
  it('logs in via the store (prefix-only) and issues a { userId, partnerId } JWT', async () => {
    const jwt = (await import('jsonwebtoken')).default;
    const { login } = await import('./authService');
    const result = await login('EXAMPLE-001');
    expect(result.partnerId).toBe('EXAMPLE');
    const payload = jwt.verify(result.token, 'test-secret') as any;
    expect(payload.userId).toBe('EXAMPLE-001');
    expect(payload.partnerId).toBe('EXAMPLE');
  });

  it('rejects an unknown partner', async () => {
    const { login } = await import('./authService');
    await expect(login('UNKNOWN-001')).rejects.toThrow('INVALID_CREDENTIALS');
  });

  it('rejects a malformed user id', async () => {
    const { login } = await import('./authService');
    await expect(login('EXAMPLE001')).rejects.toThrow('INVALID_USER_ID');
  });
});
