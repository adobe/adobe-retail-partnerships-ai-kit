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

import { describe, it, expect } from 'vitest';
import jwt from 'jsonwebtoken';
import { requireAuth } from './jwtMiddleware';
import { config } from '../config';
import type { Request, Response, NextFunction } from 'express';

// config.jwtSecret is resolved once at module-load time (from test-setup.ts's
// global JWT_SECRET) — sign test tokens with it directly rather than trying
// to override process.env.JWT_SECRET after the fact, which would have no
// effect on the already-frozen config object.
const SECRET = config.jwtSecret;

function makeReq(authHeader?: string): Partial<Request> {
  return { headers: authHeader ? { authorization: authHeader } : {} } as Partial<Request>;
}

function makeRes(): { status: ReturnType<typeof vi.fn>; json: ReturnType<typeof vi.fn>; statusCode?: number } {
  const res: Record<string, unknown> = {};
  res.status = vi.fn().mockReturnValue(res);
  res.json = vi.fn().mockReturnValue(res);
  return res as never;
}

import { vi } from 'vitest';

describe('requireAuth middleware', () => {
  it('calls next() and sets req.user on valid token', () => {
    const token = jwt.sign({ userId: 'EXAMPLE-001', partnerId: 'EXAMPLE' }, SECRET);
    const req = makeReq(`Bearer ${token}`);
    const res = makeRes();
    const next: NextFunction = vi.fn();

    requireAuth(req as Request, res as Response, next);

    expect(next).toHaveBeenCalledOnce();
    expect((req as Request & { user?: unknown }).user).toEqual({
      userId: 'EXAMPLE-001',
      partnerId: 'EXAMPLE',
    });
  });

  it('returns 401 if no Authorization header', () => {
    const req = makeReq();
    const res = makeRes();
    const next: NextFunction = vi.fn();

    requireAuth(req as Request, res as Response, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('returns 401 if token is invalid', () => {
    const req = makeReq('Bearer bad.token.here');
    const res = makeRes();
    const next: NextFunction = vi.fn();

    requireAuth(req as Request, res as Response, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it('returns 401 if token is signed with wrong secret', () => {
    const token = jwt.sign({ userId: 'X-1', partnerId: 'X' }, 'wrong-secret');
    const req = makeReq(`Bearer ${token}`);
    const res = makeRes();
    const next: NextFunction = vi.fn();

    requireAuth(req as Request, res as Response, next);

    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });
});
