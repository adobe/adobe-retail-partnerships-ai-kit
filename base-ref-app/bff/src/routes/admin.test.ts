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

import { describe, it, expect, vi, beforeAll, afterAll, beforeEach } from 'vitest';
import express from 'express';
import type { Server } from 'http';

// Must mock config BEFORE importing anything that pulls config.ts.
// adminAllowedClientIds reflects the allowlist used in these tests.
vi.mock('../config', () => ({
  config: {
    adminAllowedClientIds: ['admin_svc'],
  },
}));

import { setPartnerStore, InMemoryPartnerStore } from '../db/partnerStore';
import { adminRouter } from './admin';

let server: Server;
let baseUrl: string;

beforeAll(async () => {
  const app = express();
  app.use(express.json());
  app.use('/', adminRouter);
  await new Promise<void>((resolve) => {
    server = app.listen(0, () => {
      const addr = server.address();
      const port = typeof addr === 'object' && addr ? addr.port : 0;
      baseUrl = `http://127.0.0.1:${port}`;
      resolve();
    });
  });
});

afterAll(() => new Promise<void>((resolve) => server.close(() => resolve())));

beforeEach(() => {
  vi.clearAllMocks();
  setPartnerStore(new InMemoryPartnerStore());
});

function post(payload: unknown) {
  return fetch(`${baseUrl}/admin/partners`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-gw-ims-client-id': 'admin_svc' },
    body: JSON.stringify(payload),
  });
}

function del(id: string) {
  return fetch(`${baseUrl}/admin/partners/${id}`, {
    method: 'DELETE',
    headers: { 'x-gw-ims-client-id': 'admin_svc' },
  });
}

describe('Admin partner endpoints', () => {
  it('POST /admin/partners with allowlisted client-id upserts and returns 200', async () => {
    const res = await fetch(`${baseUrl}/admin/partners`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-gw-ims-client-id': 'admin_svc',
      },
      body: JSON.stringify({
        id: 'EXAMPLE',
        displayName: 'Example Partner',
      }),
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.id).toBe('EXAMPLE');
    expect(body.updated).toBe(true);
  });

  it('GET /admin/partners lists upserted partners', async () => {
    // Seed via POST first
    await fetch(`${baseUrl}/admin/partners`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-gw-ims-client-id': 'admin_svc',
      },
      body: JSON.stringify({
        id: 'EXAMPLE',
        displayName: 'Example Partner',
      }),
    });

    const res = await fetch(`${baseUrl}/admin/partners`, {
      headers: { 'x-gw-ims-client-id': 'admin_svc' },
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(Array.isArray(body)).toBe(true);
    expect(body).toHaveLength(1);
    expect(body[0].id).toBe('EXAMPLE');
    expect(body[0].displayName).toBe('Example Partner');
  });

  it('rejects missing required fields with 400', async () => {
    const res = await post({ id: 'EXAMPLE' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toBe('Missing required fields: id, displayName');
  });

  it('returns 403 for a non-allowlisted client-id', async () => {
    const res = await fetch(`${baseUrl}/admin/partners`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-gw-ims-client-id': 'rogue_client',
      },
      body: JSON.stringify({
        id: 'EXAMPLE',
        displayName: 'Example Partner',
      }),
    });
    expect(res.status).toBe(403);
    const body = await res.json();
    expect(body.error).toBe('FORBIDDEN');
  });

  it('returns 403 when x-gw-ims-client-id header is missing', async () => {
    const res = await fetch(`${baseUrl}/admin/partners`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: 'EXAMPLE',
        displayName: 'Example Partner',
      }),
    });
    expect(res.status).toBe(403);
    const body = await res.json();
    expect(body.error).toBe('FORBIDDEN');
  });

  it('stores maxClaims and returns it on GET', async () => {
    await post({ id: 'EXAMPLE', displayName: 'Example', maxClaims: 5 });
    const res = await fetch(`${baseUrl}/admin/partners`, { headers: { 'x-gw-ims-client-id': 'admin_svc' } });
    const body = await res.json();
    expect(body[0].maxClaims).toBe(5);
  });

  it('returns maxClaims: null when omitted (unlimited)', async () => {
    await post({ id: 'EXAMPLE', displayName: 'Example' });
    const res = await fetch(`${baseUrl}/admin/partners`, { headers: { 'x-gw-ims-client-id': 'admin_svc' } });
    const body = await res.json();
    expect(body[0].maxClaims).toBeNull();
  });

  it('rejects a non-positive-integer maxClaims with 400', async () => {
    const res = await post({ id: 'EXAMPLE', displayName: 'Example', maxClaims: 0 });
    expect(res.status).toBe(400);
    const res2 = await post({ id: 'EXAMPLE', displayName: 'Example', maxClaims: 'abc' });
    expect(res2.status).toBe(400);
  });

  it('DELETE /admin/partners/:id removes an existing partner and returns 200', async () => {
    await post({ id: 'EXAMPLE', displayName: 'Example' });

    const res = await del('EXAMPLE');
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ id: 'EXAMPLE', deleted: true });

    const getRes = await fetch(`${baseUrl}/admin/partners`, { headers: { 'x-gw-ims-client-id': 'admin_svc' } });
    expect(await getRes.json()).toEqual([]);
  });

  it('DELETE /admin/partners/:id returns 404 for a partner that does not exist', async () => {
    const res = await del('NOPE');
    expect(res.status).toBe(404);
    expect((await res.json()).error).toBe('NOT_FOUND');
  });

  it('DELETE /admin/partners/:id returns 403 for a non-allowlisted client-id', async () => {
    await post({ id: 'EXAMPLE', displayName: 'Example' });
    const res = await fetch(`${baseUrl}/admin/partners/EXAMPLE`, {
      method: 'DELETE',
      headers: { 'x-gw-ims-client-id': 'rogue_client' },
    });
    expect(res.status).toBe(403);
  });
});
