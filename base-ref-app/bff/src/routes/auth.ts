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
import { login } from '../auth/authService';

export const authRouter = Router();

// POST /api/auth/login  { userId }   — userId-prefix login only, no password (see authService.ts)
authRouter.post('/auth/login', async (req, res) => {
  const { userId } = req.body ?? {};
  if (!userId) {
    console.warn('event=auth.login_rejected reason=MISSING_FIELDS');
    res.status(400).json({ error: 'userId is required' });
    return;
  }

  try {
    const result = await login(userId as string);
    console.log(`event=auth.login_succeeded user_id=${userId} partner_id=${result.partnerId}`);
    res.status(200).json(result);
  } catch (err) {
    const code = (err as Error).message;
    if (code === 'INVALID_CREDENTIALS' || code === 'INVALID_USER_ID') {
      console.warn(`event=auth.login_failed user_id=${userId} reason=${code}`);
      res.status(401).json({ error: 'Invalid user ID' });
    } else {
      console.error(`event=auth.login_error user_id=${userId} error=${String(err)}`);
      res.status(500).json({ error: 'Login failed', detail: String(err) });
    }
  }
});

// POST /api/auth/logout  - stateless; client discards the JWT
authRouter.post('/auth/logout', (_req, res) => {
  res.status(204).send();
});
