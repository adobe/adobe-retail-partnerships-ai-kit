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

import { Router } from 'express';
import type { Request, Response, NextFunction } from 'express';
import { config } from '../config';
import { partnerStore } from '../db/partnerStore';

export const adminRouter = Router();

/** App-level guard: an upstream API gateway injects x-gw-ims-client-id after validating the caller's service token. */
function requireAdmin(req: Request, res: Response, next: NextFunction): void {
  const clientId = (req.headers['x-gw-ims-client-id'] as string | undefined)?.trim();
  if (!clientId || !config.adminAllowedClientIds.includes(clientId)) {
    console.warn(`event=admin.forbidden client_id=${clientId || 'MISSING'} path=${req.path}`);
    res.status(403).json({ error: 'FORBIDDEN' });
    return;
  }
  next();
}

adminRouter.use('/admin', requireAdmin);

adminRouter.get('/admin/partners', async (_req, res) => {
  const partners = await partnerStore().list();
  console.log(`event=admin.partners.listed count=${partners.length}`);
  res.status(200).json(partners.map((p) => ({
    id: p.id, displayName: p.displayName, maxClaims: p.maxClaims ?? null,
  })));
});

async function upsert(req: Request, res: Response) {
  const { id, displayName, maxClaims } = req.body ?? {};
  if (!id || !displayName) {
    console.warn(`event=admin.partner.upsert_rejected reason=MISSING_FIELDS id=${id ?? 'MISSING'}`);
    res.status(400).json({ error: 'Missing required fields: id, displayName' });
    return;
  }
  // maxClaims is optional (omit = unlimited). When present it must be a positive integer.
  let maxClaimsValue: number | undefined;
  if (maxClaims !== undefined && maxClaims !== null && maxClaims !== '') {
    const n = Number(maxClaims);
    if (!Number.isInteger(n) || n < 1) {
      console.warn(`event=admin.partner.upsert_rejected reason=INVALID_MAX_CLAIMS id=${id}`);
      res.status(400).json({ error: 'maxClaims must be a positive integer' });
      return;
    }
    maxClaimsValue = n;
  }
  const existing = await partnerStore().get(id);
  await partnerStore().upsert({
    id,
    displayName,
    ...(maxClaimsValue !== undefined ? { maxClaims: maxClaimsValue } : {}),
  });
  console.log(`event=admin.partner.upserted id=${String(id).toUpperCase()} created=${!existing}`);
  res.status(200).json({ id: String(id).toUpperCase(), updated: true });
}
adminRouter.post('/admin/partners', upsert);
adminRouter.put('/admin/partners', upsert);

adminRouter.delete('/admin/partners/:id', async (req, res) => {
  const id = req.params.id.toUpperCase();
  const deleted = await partnerStore().delete(id);
  if (!deleted) {
    console.warn(`event=admin.partner.delete_not_found id=${id}`);
    res.status(404).json({ error: 'NOT_FOUND' });
    return;
  }
  console.log(`event=admin.partner.deleted id=${id}`);
  res.status(200).json({ id, deleted: true });
});
